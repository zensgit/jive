-- B2.2: track subscription webhook notifications for idempotent processing.
-- Run this after migrations 001-008.

create table if not exists public.subscription_webhook_notifications (
  notification_id text primary key,
  provider text not null check (provider in ('google_play', 'apple_app_store')),
  source text not null,
  status text not null default 'processing' check (
    status in ('processing', 'processed', 'failed')
  ),
  payload jsonb not null default '{}'::jsonb,
  last_error text,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subscription_webhook_notifications enable row level security;

create index if not exists idx_subscription_webhook_notifications_provider_status
  on public.subscription_webhook_notifications(provider, status, updated_at desc);

create index if not exists idx_subscription_webhook_notifications_processed_at
  on public.subscription_webhook_notifications(processed_at desc)
  where processed_at is not null;
