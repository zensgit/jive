-- B5.3: admin API support for manual subscription overrides.
-- Run this after migrations 001-009.

alter table public.user_subscriptions
  drop constraint if exists user_subscriptions_platform_check;

alter table public.user_subscriptions
  add constraint user_subscriptions_platform_check
  check (
    platform in ('google_play', 'apple_app_store', 'admin_override')
  );

create unique index if not exists idx_user_subscriptions_admin_override_unique
  on public.user_subscriptions(user_id, platform)
  where platform = 'admin_override';
