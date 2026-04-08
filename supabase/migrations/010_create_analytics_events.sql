-- B5.1: SaaS analytics event pipeline.
-- Run this after migrations 001-009.

create table if not exists public.analytics_events (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete set null,
  device_id text,
  session_id text,
  event_name text not null check (nullif(btrim(event_name), '') is not null),
  event_group text not null default 'app'
    check (nullif(btrim(event_group), '') is not null),
  platform text,
  app_version text,
  properties jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  occurred_on date not null default (timezone('utc', now())::date),
  created_at timestamptz not null default now(),
  check (
    user_id is not null or nullif(btrim(device_id), '') is not null
  )
);

alter table public.analytics_events enable row level security;

create policy "analytics_events_insert_client"
  on public.analytics_events for insert
  with check (
    (auth.uid() = user_id)
    or (
      auth.uid() is null
      and user_id is null
      and nullif(btrim(device_id), '') is not null
    )
  );

create policy "analytics_events_select_own"
  on public.analytics_events for select
  using (auth.uid() = user_id);

create index if not exists idx_analytics_events_occurred_on
  on public.analytics_events(occurred_on desc);

create index if not exists idx_analytics_events_event_name_occurred_on
  on public.analytics_events(event_name, occurred_on desc);

create index if not exists idx_analytics_events_user_occurred_on
  on public.analytics_events(user_id, occurred_on desc)
  where user_id is not null;

create index if not exists idx_analytics_events_guest_device_occurred_on
  on public.analytics_events(device_id, occurred_on desc)
  where user_id is null and device_id is not null;
