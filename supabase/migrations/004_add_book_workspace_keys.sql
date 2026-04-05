-- B1.1: align cloud sync schema with local multi-book boundaries
-- Run this after migrations 001-003.

alter table public.transactions
  add column if not exists book_key text;

alter table public.accounts
  add column if not exists book_key text;

alter table public.budgets
  add column if not exists book_key text;

alter table public.shared_ledgers
  add column if not exists workspace_key text;

-- Existing transaction/account rows predate explicit workspace scoping.
-- Backfill them to the default local workspace boundary.
update public.transactions
set book_key = 'book_default'
where book_key is null;

update public.accounts
set book_key = 'book_default'
where book_key is null;

-- Existing shared ledgers are temporarily bound to the default workspace
-- until the app exposes an explicit book-to-shared-ledger binding flow.
update public.shared_ledgers
set workspace_key = 'book_default'
where workspace_key is null;

create index if not exists idx_transactions_user_book_updated
  on public.transactions(user_id, book_key, updated_at);

create index if not exists idx_accounts_user_book_updated
  on public.accounts(user_id, book_key, updated_at);

create index if not exists idx_budgets_user_book_updated
  on public.budgets(user_id, book_key, updated_at);

create index if not exists idx_shared_ledgers_owner_workspace
  on public.shared_ledgers(owner_user_id, workspace_key, updated_at);
