-- ============================================================
-- SMS-to-Webhook wallet deposit system (replaces Paymob)
-- Migration: extends wallet_transactions + confirm RPC + realtime
-- ============================================================

-- 1. Extend wallet_transactions with fields needed for webhook matching
do $$ begin alter table public.wallet_transactions add column if not exists transaction_id text; exception when others then null; end $$;
do $$ begin alter table public.wallet_transactions add column if not exists raw_sms text; exception when others then null; end $$;
do $$ begin alter table public.wallet_transactions add column if not exists expires_at timestamptz default now() + interval '30 minutes'; exception when others then null; end $$;

-- 2. Anti-replay: unique index on transaction_id (partial, only for non-null)
create unique index if not exists uq_wallet_tx_transaction_id
  on public.wallet_transactions(transaction_id)
  where transaction_id is not null;

-- 3. Rename paymob_ref on transactions -> generic reference (keep column for safety)
do $$ begin alter table public.transactions add column if not exists reference text; exception when others then null; end $$;

-- 4. Realtime publication for live balance updates
do $$ begin
  alter publication supabase_realtime add table public.wallet_transactions;
exception when duplicate_object then null; end $$;

-- 5. Secure deposit-confirmation RPC (security definer, service-only)
create or replace function public.confirm_wallet_deposit(
  p_transaction_id text,
  p_sender_phone text,
  p_amount double precision,
  p_raw_sms text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dup_status text;
  v_pending record;
  v_wallet_id uuid;
begin
  -- Anti-replay: same transaction_id already processed successfully
  select status into v_dup_status
    from public.wallet_transactions
   where transaction_id = p_transaction_id
   limit 1;
  if v_dup_status is not null and v_dup_status = 'success' then
    return jsonb_build_object('success', false, 'code', 'ALREADY_PROCESSED');
  end if;

  -- Pre-match: find pending deposit within window (same sender phone + same amount)
  select id, user_id, amount
    into v_pending
    from public.wallet_transactions
   where type = 'deposit'
     and status = 'pending'
     and sender_phone = p_sender_phone
     and abs(amount - p_amount) < 0.01
     and created_at >= now() - interval '30 minutes'
   order by created_at desc
   limit 1
   for update skip locked;

  if not found then
    -- Log unmatched incoming SMS for admin review
    insert into public.wallet_transactions (
      type, amount, status, sender_phone, raw_sms, transaction_id, reference_type, reference_id
    ) values (
      'deposit', p_amount, 'unmatched', p_sender_phone, p_raw_sms, p_transaction_id, 'sms', p_transaction_id
    );
    return jsonb_build_object('success', false, 'code', 'NO_MATCH');
  end if;

  -- Credit wallet (upsert in case missing)
  insert into public.wallets (user_id, balance, updated_at)
  values (v_pending.user_id, p_amount, now())
  on conflict (user_id)
  do update set balance = public.wallets.balance + p_amount, updated_at = now()
  returning id into v_wallet_id;

  -- Record in transactions ledger
  insert into public.transactions (user_id, type, amount, balance_after, description, status, reference)
  values (
    v_pending.user_id, 'deposit', p_amount,
    (select balance from public.wallets where user_id = v_pending.user_id),
    'إيداع عبر محفظة', 'completed', p_transaction_id
  );

  -- Mark pending as success
  update public.wallet_transactions
     set status = 'success', transaction_id = p_transaction_id, raw_sms = p_raw_sms
   where id = v_pending.id;

  return jsonb_build_object('success', true, 'wallet_transaction_id', v_pending.id);
end;
$$;

-- Only the service role may confirm deposits (never the client)
revoke execute on function public.confirm_wallet_deposit(text, text, double precision, text) from public, anon, authenticated;
grant execute on function public.confirm_wallet_deposit(text, text, double precision, text) to service_role;