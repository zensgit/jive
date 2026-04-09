# B5.4 Ops Overview

This stacked task turns the existing admin API `summary` endpoint into a
practical SaaS ops overview.

## What changed

- `GET /functions/admin?action=summary` now includes:
  - `users`
  - `subscriptions`
  - `analytics`
  - `notifications.queue`
- The summary is intentionally compact and reviewable:
  - `analytics` reuses the same daily activity, conversion, and retention shape
    as the dedicated analytics function
  - `notifications.queue` reports queue backlog, retry pressure, failure counts,
    and stale queued items

## Why this is useful

- Ops can inspect product health from one endpoint instead of jumping between
  analytics, notifications, and admin tools.
- The response is stable enough to back a future admin dashboard without
  changing the backend contract again.

## Verification

- `deno test supabase/functions/admin/index_test.ts`
- `deno check supabase/functions/admin/index.ts`
