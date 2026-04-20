-- B2.4: domestic payment orders and webhook event history.
-- Run this after migrations 001-012.

alter table public.user_subscriptions
  drop constraint if exists user_subscriptions_platform_check;

alter table public.user_subscriptions
  add constraint user_subscriptions_platform_check
  check (
    platform in (
      'google_play',
      'apple_app_store',
      'admin_override',
      'wechat_pay',
      'alipay'
    )
  );

alter table public.user_subscriptions
  add column if not exists source_order_no text,
  add column if not exists provider_trade_no text;

create table if not exists public.payment_orders (
  id bigserial primary key,
  order_no text not null unique,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('wechat_pay', 'alipay')),
  plan_code text not null,
  status text not null check (
    status in ('created', 'pending', 'paid', 'failed', 'expired', 'closed')
  ),
  amount_cents integer not null check (amount_cents > 0),
  currency text not null default 'CNY',
  product_id text,
  client_channel text not null,
  provider_trade_no text,
  redirect_url text,
  qr_code_url text,
  expires_at timestamptz,
  paid_at timestamptz,
  raw_request jsonb not null default '{}'::jsonb,
  raw_response jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payment_orders enable row level security;

create policy "payment_orders_select_own"
  on public.payment_orders for select
  using (auth.uid() = user_id);

create index if not exists idx_payment_orders_user_updated
  on public.payment_orders(user_id, updated_at desc);

create unique index if not exists idx_payment_orders_provider_trade_unique
  on public.payment_orders(provider, provider_trade_no)
  where provider_trade_no is not null;

create table if not exists public.payment_events (
  id bigserial primary key,
  provider text not null check (provider in ('wechat_pay', 'alipay')),
  event_id text not null,
  event_type text not null,
  order_no text not null,
  provider_trade_no text,
  payload jsonb not null default '{}'::jsonb,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.payment_events enable row level security;

create unique index if not exists idx_payment_events_provider_event_unique
  on public.payment_events(provider, event_id);

create index if not exists idx_payment_events_order_created
  on public.payment_events(order_no, created_at desc);
