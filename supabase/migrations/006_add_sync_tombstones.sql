-- B1.3: add deleted_at tombstones for long-lived sync.
-- Run this after migrations 001-005.

alter table public.transactions
  add column if not exists deleted_at timestamptz;

alter table public.budgets
  add column if not exists deleted_at timestamptz;

create index if not exists idx_transactions_user_deleted_updated
  on public.transactions(user_id, deleted_at, updated_at);

create index if not exists idx_budgets_user_deleted_updated
  on public.budgets(user_id, deleted_at, updated_at);
