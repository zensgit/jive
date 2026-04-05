-- B1.2: reduce transaction/account sync dependence on local integer IDs.
-- Run this after migrations 001-004.

alter table public.accounts
  add column if not exists key text;

alter table public.transactions
  add column if not exists account_key text;

alter table public.transactions
  add column if not exists to_account_id bigint;

alter table public.transactions
  add column if not exists to_account_key text;

create unique index if not exists idx_accounts_user_key_unique
  on public.accounts(user_id, key)
  where key is not null;

create index if not exists idx_transactions_user_account_key_updated
  on public.transactions(user_id, account_key, updated_at);

create index if not exists idx_transactions_user_to_account_key_updated
  on public.transactions(user_id, to_account_key, updated_at);
