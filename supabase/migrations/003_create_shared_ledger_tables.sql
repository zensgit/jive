-- Jive shared family ledger tables
-- Run this in Supabase Dashboard → SQL Editor

-- ── Shared Ledgers ──
create table if not exists public.shared_ledgers (
  id bigserial primary key,
  key text not null unique,
  name text not null default '',
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  currency text default 'CNY',
  invite_code text unique,
  member_count int not null default 1,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.shared_ledgers enable row level security;

-- Owner can do anything
create policy "ledger_owner_all" on public.shared_ledgers
  for all using (auth.uid() = owner_user_id);

-- Members can read ledgers they belong to
create policy "ledger_member_select" on public.shared_ledgers
  for select using (
    exists (
      select 1 from public.shared_ledger_members m
      where m.ledger_key = key and m.user_id = auth.uid()
    )
  );

-- Anyone can look up by invite code (for joining)
create policy "ledger_invite_lookup" on public.shared_ledgers
  for select using (invite_code is not null);

create index if not exists idx_shared_ledgers_owner on public.shared_ledgers(owner_user_id);
create index if not exists idx_shared_ledgers_invite on public.shared_ledgers(invite_code);

-- ── Shared Ledger Members ──
create table if not exists public.shared_ledger_members (
  id bigserial primary key,
  ledger_key text not null references public.shared_ledgers(key) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  unique(ledger_key, user_id)
);

alter table public.shared_ledger_members enable row level security;

-- Members can see other members in their ledgers
create policy "member_select" on public.shared_ledger_members
  for select using (
    exists (
      select 1 from public.shared_ledger_members m2
      where m2.ledger_key = ledger_key and m2.user_id = auth.uid()
    )
  );

-- Owner/admin can manage members
create policy "member_manage" on public.shared_ledger_members
  for all using (
    exists (
      select 1 from public.shared_ledger_members m2
      where m2.ledger_key = ledger_key
        and m2.user_id = auth.uid()
        and m2.role in ('owner', 'admin')
    )
  );

-- Users can insert themselves (joining)
create policy "member_self_insert" on public.shared_ledger_members
  for insert with check (auth.uid() = user_id);

-- Users can remove themselves (leaving)
create policy "member_self_delete" on public.shared_ledger_members
  for delete using (auth.uid() = user_id);

create index if not exists idx_shared_members_ledger on public.shared_ledger_members(ledger_key);
create index if not exists idx_shared_members_user on public.shared_ledger_members(user_id);
