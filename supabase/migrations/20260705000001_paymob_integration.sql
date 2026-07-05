-- Paymob integration: wallet charge function + RLS update

-- Allow service_role to update wallets (for edge function)
drop policy if exists "Service role can update wallets" on public.wallets;
create policy "Service role can update wallets"
on public.wallets for update
to service_role
using (true)
with check (true);

drop policy if exists "Service role can insert transactions" on public.wallet_transactions;
create policy "Service role can insert transactions"
on public.wallet_transactions for insert
to service_role
with check (true);

-- Allow regular users to update their own wallets
drop policy if exists "Users can update own wallet" on public.wallets;
create policy "Users can update own wallet"
on public.wallets for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Allow regular users to insert their own wallet row (first charge)
drop policy if exists "Users can insert own wallet" on public.wallets;
create policy "Users can insert own wallet"
on public.wallets for insert
to authenticated
with check (user_id = auth.uid());

-- Function to apply wallet charge (called by edge function after Paymob confirmation)
create or replace function public.apply_wallet_charge(p_user_id uuid, p_amount double precision)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.wallets (user_id, balance)
  values (p_user_id, p_amount)
  on conflict (user_id)
  do update set balance = public.wallets.balance + p_amount, updated_at = now();
end;
$$;

-- Function for withdrawal: atomic deduct + insert transaction
create or replace function public.process_user_withdrawal(p_user_id uuid, p_amount double precision)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance double precision;
begin
  select balance into v_balance from public.wallets where user_id = p_user_id;
  if v_balance is null or v_balance < p_amount then
    return json_build_object('success', false, 'error', 'Insufficient balance');
  end if;

  update public.wallets set balance = balance - p_amount, updated_at = now() where user_id = p_user_id;

  insert into public.wallet_transactions (user_id, amount, type, status, description)
  values (p_user_id, -p_amount, 'withdrawal', 'pending', 'طلب سحب - قيد المراجعة');

  return json_build_object('success', true);
end;
$$;
