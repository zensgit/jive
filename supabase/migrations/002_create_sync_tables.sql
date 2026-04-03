-- Jive multi-table sync: accounts, categories, tags, budgets
-- Run this in Supabase Dashboard → SQL Editor

-- ── Accounts ──
create table if not exists public.accounts (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id bigint not null,
  name text not null default '',
  type text not null default 'asset',
  sub_type text,
  opening_balance double precision not null default 0,
  credit_limit double precision,
  currency text default 'CNY',
  is_archived boolean not null default false,
  sort_order int not null default 0,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, local_id)
);

alter table public.accounts enable row level security;
create policy "accounts_select" on public.accounts for select using (auth.uid() = user_id);
create policy "accounts_insert" on public.accounts for insert with check (auth.uid() = user_id);
create policy "accounts_update" on public.accounts for update using (auth.uid() = user_id);
create policy "accounts_delete" on public.accounts for delete using (auth.uid() = user_id);
create index if not exists idx_accounts_user_updated on public.accounts(user_id, updated_at);

-- ── Categories ──
create table if not exists public.categories (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id bigint not null,
  key text not null,
  name text not null default '',
  parent_key text,
  icon_name text,
  is_income boolean not null default false,
  is_system boolean not null default false,
  is_hidden boolean not null default false,
  sort_order int not null default 0,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, local_id)
);

alter table public.categories enable row level security;
create policy "categories_select" on public.categories for select using (auth.uid() = user_id);
create policy "categories_insert" on public.categories for insert with check (auth.uid() = user_id);
create policy "categories_update" on public.categories for update using (auth.uid() = user_id);
create policy "categories_delete" on public.categories for delete using (auth.uid() = user_id);
create index if not exists idx_categories_user_updated on public.categories(user_id, updated_at);

-- ── Tags ──
create table if not exists public.tags (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id bigint not null,
  key text not null,
  name text not null default '',
  group_key text,
  color_hex text,
  is_archived boolean not null default false,
  sort_order int not null default 0,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, local_id)
);

alter table public.tags enable row level security;
create policy "tags_select" on public.tags for select using (auth.uid() = user_id);
create policy "tags_insert" on public.tags for insert with check (auth.uid() = user_id);
create policy "tags_update" on public.tags for update using (auth.uid() = user_id);
create policy "tags_delete" on public.tags for delete using (auth.uid() = user_id);
create index if not exists idx_tags_user_updated on public.tags(user_id, updated_at);

-- ── Budgets ──
create table if not exists public.budgets (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id bigint not null,
  name text not null default '',
  amount double precision not null default 0,
  period text not null default 'monthly',
  start_date timestamptz not null default now(),
  end_date timestamptz not null default now(),
  category_keys jsonb default '[]',
  is_active boolean not null default true,
  carry_over boolean not null default false,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, local_id)
);

alter table public.budgets enable row level security;
create policy "budgets_select" on public.budgets for select using (auth.uid() = user_id);
create policy "budgets_insert" on public.budgets for insert with check (auth.uid() = user_id);
create policy "budgets_update" on public.budgets for update using (auth.uid() = user_id);
create policy "budgets_delete" on public.budgets for delete using (auth.uid() = user_id);
create index if not exists idx_budgets_user_updated on public.budgets(user_id, updated_at);
