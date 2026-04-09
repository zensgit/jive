# B5.2 Notifications Foundation

This branch adds the minimal SaaS notification backend:

- `supabase/migrations/011_create_notification_queue.sql`
- `supabase/functions/send-notification/index.ts`

## What it does

- Authenticates requests with `NOTIFICATION_ADMIN_TOKEN`
- Builds queue jobs for:
  - `expiry_reminder`
  - `expired_notice`
  - `system_notice`
- Uses `user_subscriptions` as the source of truth for subscription-driven reminders
- Writes deduplicated jobs into `public.notification_queue`

## Expected env vars

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NOTIFICATION_ADMIN_TOKEN`

## Request sketch

```json
{
  "action": "expiry_reminder",
  "reminder_lead_days": 7
}
```

```json
{
  "action": "system_notice",
  "title": "系统维护",
  "body": "今晚 23:00 进行维护",
  "user_ids": ["user-a", "user-b"]
}
```
