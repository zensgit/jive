import {
  assertEquals,
  assertFalse,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  constantTimeEquals,
  corsHeadersForOrigin,
  latestSubscriptionByUser,
  parseAdminRequestBodyText,
  summarizeAnalyticsRows,
  summarizeLatestSubscriptionsFromRows,
  summarizeNotificationQueueRows,
} from "./index.ts";

Deno.test("latestSubscriptionByUser keeps the first row for each user", () => {
  const latest = latestSubscriptionByUser([
    {
      user_id: "user-1",
      plan: "subscriber",
      status: "active",
      platform: "admin_override",
      entitlement_tier: "subscriber",
      expires_at: null,
      updated_at: "2026-04-08T10:00:00.000Z",
      verification_source: "admin_api",
    },
    {
      user_id: "user-1",
      plan: "paid",
      status: "expired",
      platform: "google_play",
      entitlement_tier: "free",
      expires_at: null,
      updated_at: "2026-04-07T10:00:00.000Z",
      verification_source: "google_play_api",
    },
    {
      user_id: "user-2",
      plan: "paid",
      status: "active",
      platform: "google_play",
      entitlement_tier: "paid",
      expires_at: null,
      updated_at: "2026-04-08T09:00:00.000Z",
      verification_source: "google_play_api",
    },
  ]);

  assertEquals(latest.get("user-1")?.platform, "admin_override");
  assertEquals(latest.get("user-2")?.entitlement_tier, "paid");
});

Deno.test("summarizeLatestSubscriptionsFromRows counts only the first row per user", () => {
  const stats = summarizeLatestSubscriptionsFromRows([
    {
      user_id: "user-1",
      plan: "subscriber",
      status: "active",
      platform: "admin_override",
      entitlement_tier: "subscriber",
      expires_at: null,
      updated_at: "2026-04-08T10:00:00.000Z",
      verification_source: "admin_api",
    },
    {
      user_id: "user-1",
      plan: "paid",
      status: "expired",
      platform: "google_play",
      entitlement_tier: "paid",
      expires_at: null,
      updated_at: "2026-04-07T10:00:00.000Z",
      verification_source: "google_play_api",
    },
    {
      user_id: "user-2",
      plan: "paid",
      status: "grace",
      platform: "google_play",
      entitlement_tier: "paid",
      expires_at: null,
      updated_at: "2026-04-08T09:00:00.000Z",
      verification_source: "google_play_api",
    },
    {
      user_id: "user-3",
      plan: "subscriber",
      status: "revoked",
      platform: "app_store",
      entitlement_tier: "subscriber",
      expires_at: null,
      updated_at: "2026-04-08T08:00:00.000Z",
      verification_source: "app_store_api",
    },
  ]);

  assertEquals(stats.admin_overrides, 1);
  assertEquals(stats.active_subscribers, 1);
  assertEquals(stats.active_paid, 1);
  assertEquals(stats.expired_or_revoked, 1);
});

Deno.test("constantTimeEquals matches exact token only", () => {
  assertEquals(constantTimeEquals("secret-token", "secret-token"), true);
  assertFalse(constantTimeEquals("secret-token", "secret-token-x"));
  assertFalse(constantTimeEquals("secret-token", "SECRET-token"));
});

Deno.test("corsHeadersForOrigin only reflects configured origins", () => {
  const allowed = new Set([
    "https://admin.example.com",
    "http://localhost:3000",
  ]);

  assertEquals(
    corsHeadersForOrigin("https://admin.example.com", allowed)[
      "Access-Control-Allow-Origin"
    ],
    "https://admin.example.com",
  );
  assertEquals(
    corsHeadersForOrigin("https://evil.example.com", allowed)[
      "Access-Control-Allow-Origin"
    ],
    undefined,
  );
});

Deno.test("parseAdminRequestBodyText validates supported admin actions", () => {
  assertEquals(
    parseAdminRequestBodyText(
      JSON.stringify({
        action: "set_tier",
        user_id: "user-1",
        plan: "subscriber",
        status: "active",
        expires_at: null,
      }),
    ),
    {
      action: "set_tier",
      user_id: "user-1",
      plan: "subscriber",
      status: "active",
      expires_at: null,
    },
  );

  assertEquals(
    parseAdminRequestBodyText(
      JSON.stringify({
        action: "clear_override",
        user_id: "user-2",
      }),
    ),
    {
      action: "clear_override",
      user_id: "user-2",
    },
  );
});

Deno.test("parseAdminRequestBodyText rejects invalid json and invalid fields", () => {
  assertThrows(
    () => parseAdminRequestBodyText("{"),
    Error,
    "invalid_json_body",
  );
  assertThrows(
    () =>
      parseAdminRequestBodyText(
        JSON.stringify({
          action: "set_tier",
          plan: "enterprise",
        }),
      ),
    Error,
    "invalid_plan",
  );
  assertThrows(
    () =>
      parseAdminRequestBodyText(
        JSON.stringify({
          action: "clear_override",
          user_id: 123,
        }),
      ),
    Error,
    "invalid_request_body",
  );
});

Deno.test("summarizeAnalyticsRows computes activity and conversions", () => {
  const summary = summarizeAnalyticsRows(
    [
      {
        user_id: "user-1",
        device_id: null,
        event_name: "auth_screen_viewed",
        occurred_on: "2026-04-08",
      },
      {
        user_id: "user-1",
        device_id: null,
        event_name: "auth_signed_in",
        occurred_on: "2026-04-08",
      },
      {
        user_id: "user-2",
        device_id: null,
        event_name: "auth_screen_viewed",
        occurred_on: "2026-04-08",
      },
      {
        user_id: "user-2",
        device_id: null,
        event_name: "auth_signed_in",
        occurred_on: "2026-04-08",
      },
      {
        user_id: "user-1",
        device_id: null,
        event_name: "subscription_purchase_started",
        occurred_on: "2026-04-08",
      },
      {
        user_id: "user-1",
        device_id: null,
        event_name: "subscription_purchase_completed",
        occurred_on: "2026-04-08",
      },
      {
        user_id: null,
        device_id: "guest-1",
        event_name: "auth_screen_viewed",
        occurred_on: "2026-04-09",
      },
    ],
    new Date("2026-04-09T12:00:00.000Z"),
    30,
  );

  assertEquals(summary.active_users.dau, 1);
  assertEquals(summary.active_users.mau, 3);
  assertEquals(summary.conversions.auth_sign_in.viewed_or_started, 3);
  assertEquals(summary.conversions.auth_sign_in.completed, 2);
  assertEquals(summary.conversions.auth_sign_in.rate, 0.6667);
  assertEquals(summary.conversions.purchase.rate, 1);
  assertEquals(summary.events[0].event_name, "auth_screen_viewed");
  assertEquals(summary.retention.length, 2);
});

Deno.test("summarizeNotificationQueueRows exposes queue health", () => {
  const summary = summarizeNotificationQueueRows([
    {
      status: "queued",
      queued_at: "2026-04-09T10:00:00.000Z",
      sent_at: null,
      attempt_count: 1,
      action: "expiry_reminder",
      last_error: null,
      updated_at: "2026-04-09T10:00:00.000Z",
    },
    {
      status: "sent",
      queued_at: "2026-04-09T09:00:00.000Z",
      sent_at: "2026-04-09T09:05:00.000Z",
      attempt_count: 0,
      action: "expired_notice",
      last_error: null,
      updated_at: "2026-04-09T09:05:00.000Z",
    },
    {
      status: "failed",
      queued_at: "2026-04-09T08:00:00.000Z",
      sent_at: null,
      attempt_count: 2,
      action: "system_notice",
      last_error: "timeout",
      updated_at: "2026-04-09T08:10:00.000Z",
    },
    {
      status: "canceled",
      queued_at: "2026-04-09T07:00:00.000Z",
      sent_at: null,
      attempt_count: 0,
      action: "system_notice",
      last_error: null,
      updated_at: "2026-04-09T07:30:00.000Z",
    },
  ], new Date("2026-04-09T12:00:00.000Z"));

  assertEquals(summary.total, 4);
  assertEquals(summary.queued, 1);
  assertEquals(summary.sent, 1);
  assertEquals(summary.failed, 1);
  assertEquals(summary.canceled, 1);
  assertEquals(summary.retrying, 1);
  assertEquals(summary.queued_over_1h, 1);
  assertEquals(summary.queued_over_24h, 0);
  assertEquals(summary.oldest_queued_age_minutes, 120);
});
