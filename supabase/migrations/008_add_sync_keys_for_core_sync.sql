-- B1.2: de-localize sync payload identities for core sync tables.
--
-- Compatibility strategy:
-- - Keep legacy local_id columns and existing unique(user_id, local_id) constraints.
-- - Add stable sync_key columns for transactions / accounts / budgets.
-- - Add transaction account sync references so cross-device merges stop depending
--   on per-device Isar int IDs.
-- - Add key-based uniqueness for categories / tags so the Dart sync engine can
--   upsert on stable keys instead of local_id.

alter table public.transactions
  add column if not exists sync_key text,
  add column if not exists account_sync_key text,
  add column if not exists to_account_id bigint,
  add column if not exists to_account_sync_key text;

alter table public.accounts
  add column if not exists sync_key text;

alter table public.budgets
  add column if not exists sync_key text;

create unique index if not exists idx_transactions_user_sync_key
  on public.transactions(user_id, sync_key);

create unique index if not exists idx_accounts_user_sync_key
  on public.accounts(user_id, sync_key);

create unique index if not exists idx_budgets_user_sync_key
  on public.budgets(user_id, sync_key);

create unique index if not exists idx_categories_user_key
  on public.categories(user_id, key);

create unique index if not exists idx_tags_user_key
  on public.tags(user_id, key);

create index if not exists idx_transactions_account_sync_key
  on public.transactions(user_id, account_sync_key);

create index if not exists idx_transactions_to_account_sync_key
  on public.transactions(user_id, to_account_sync_key);

create index if not exists idx_transactions_user_local_id
  on public.transactions(user_id, local_id);

create index if not exists idx_accounts_user_local_id
  on public.accounts(user_id, local_id);

create index if not exists idx_budgets_user_local_id
  on public.budgets(user_id, local_id);
