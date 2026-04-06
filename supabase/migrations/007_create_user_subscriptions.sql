-- B2.1: authoritative server-side subscription truth.
-- Run this after migrations 001-006.

create table if not exists public.user_subscriptions (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  plan text not null check (plan in ('free', 'paid', 'subscriber')),
  status text not null check (
    status in ('active', 'grace', 'pending', 'canceled', 'expired', 'revoked')
  ),
  platform text not null check (platform in ('google_play', 'apple_app_store')),
  product_id text,
  purchase_token text,
  order_id text,
  entitlement_tier text not null default 'free' check (
    entitlement_tier in ('free', 'paid', 'subscriber')
  ),
  expires_at timestamptz,
  last_verified_at timestamptz,
  verification_source text not null default 'server',
  receipt_data jsonb not null default '{}'::jsonb,
  raw_response jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_subscriptions enable row level security;

create policy "user_subscriptions_select_own"
  on public.user_subscriptions for select
  using (auth.uid() = user_id);

create unique index if not exists idx_user_subscriptions_platform_token_unique
  on public.user_subscriptions(platform, purchase_token)
  where purchase_token is not null;

create index if not exists idx_user_subscriptions_user_updated
  on public.user_subscriptions(user_id, updated_at desc);

create index if not exists idx_user_subscriptions_user_status
  on public.user_subscriptions(user_id, status, updated_at desc);
