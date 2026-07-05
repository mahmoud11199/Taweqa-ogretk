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
