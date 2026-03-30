-- Jive transactions sync table
-- Run this in Supabase Dashboard → SQL Editor

create table if not exists public.transactions (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id bigint not null,
  amount double precision not null default 0,
  source text not null default '',
  type text,
  timestamp timestamptz not null default now(),
  category_key text,
  sub_category_key text,
  category text,
  sub_category text,
  note text,
  account_id bigint,
  raw_text text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),

  -- Unique per user + local ID for upsert
  unique(user_id, local_id)
);

-- Row Level Security: users can only access their own data
alter table public.transactions enable row level security;

create policy "Users can read own transactions"
  on public.transactions for select
  using (auth.uid() = user_id);

create policy "Users can insert own transactions"
  on public.transactions for insert
  with check (auth.uid() = user_id);

create policy "Users can update own transactions"
  on public.transactions for update
  using (auth.uid() = user_id);

create policy "Users can delete own transactions"
  on public.transactions for delete
  using (auth.uid() = user_id);

-- Index for incremental sync queries
create index if not exists idx_transactions_user_updated
  on public.transactions(user_id, updated_at);
