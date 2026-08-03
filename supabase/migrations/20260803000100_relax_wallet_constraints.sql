-- ============================================================
-- Follow-up: relax wallet_transactions CHECK constraints
-- The original live constraint (wallet_transactions_type_check)
-- blocks the 'unmatched' status used by the SMS webhook.
-- ============================================================

do $$ begin
  alter table public.wallet_transactions drop constraint if exists wallet_transactions_type_check;
  alter table public.wallet_transactions drop constraint if exists wallet_transactions_status_check;
exception when others then null; end $$;

do $$ begin
  alter table public.wallet_transactions add constraint wallet_transactions_type_check
    check (type in ('deposit','withdrawal','payment','subscription'));
  alter table public.wallet_transactions add constraint wallet_transactions_status_check
    check (status in ('pending','success','failed','unmatched','completed','cancelled'));
exception when others then null; end $$;