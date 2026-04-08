-- B5.2: notification queue + dedupe for SaaS alerts and system notices.
-- Run this after migrations 001-010.

create table if not exists public.notification_queue (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_subscription_id bigint references public.user_subscriptions(id) on delete cascade,
  action text not null check (action in ('expiry_reminder', 'expired_notice', 'system_notice')),
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  dedupe_key text not null,
  status text not null default 'queued' check (status in ('queued', 'sent', 'failed', 'canceled')),
  attempt_count integer not null default 0,
  queued_at timestamptz not null default now(),
  sent_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notification_queue enable row level security;

create policy "notification_queue_select_own"
  on public.notification_queue for select
  using (auth.uid() = user_id);

create unique index if not exists idx_notification_queue_dedupe_unique
  on public.notification_queue(dedupe_key);

create index if not exists idx_notification_queue_user_status_queued
  on public.notification_queue(user_id, status, queued_at desc);

create index if not exists idx_notification_queue_status_queued_at
  on public.notification_queue(status, queued_at desc);

create index if not exists idx_notification_queue_action_queued_at
  on public.notification_queue(action, queued_at desc);
