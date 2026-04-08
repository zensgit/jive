import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import { normalizeAnalyticsToken, summarizeAnalyticsRows } from "./index.ts";

Deno.test("normalizeAnalyticsToken normalizes and bounds values", () => {
  assertEquals(normalizeAnalyticsToken(" Auth Signed In "), "auth_signed_in");
  assertEquals(normalizeAnalyticsToken(""), null);
  assertEquals(normalizeAnalyticsToken(undefined), null);
  assertEquals(normalizeAnalyticsToken("x".repeat(65)), null);
});

Deno.test("summarizeAnalyticsRows computes active users, conversions, and retention", () => {
  const summary = summarizeAnalyticsRows(
    [
      {
        user_id: "user-1",
        device_id: null,
        event_name: "auth_screen_viewed",
        occurred_on: "2026-04-01",
      },
      {
        user_id: "user-1",
        device_id: null,
        event_name: "auth_signed_in",
        occurred_on: "2026-04-01",
      },
      {
        user_id: "user-1",
        device_id: null,
        event_name: "app_opened",
        occurred_on: "2026-04-02",
      },
      {
        user_id: null,
        device_id: "guest-a",
        event_name: "subscription_purchase_started",
        occurred_on: "2026-04-01",
      },
      {
        user_id: null,
        device_id: "guest-a",
        event_name: "subscription_purchase_completed",
        occurred_on: "2026-04-01",
      },
      {
        user_id: null,
        device_id: "guest-a",
        event_name: "app_opened",
        occurred_on: "2026-04-08",
      },
    ],
    new Date("2026-04-08T12:00:00.000Z"),
    30,
  );

  assertEquals(summary.active_users.dau, 1);
  assertEquals(summary.active_users.mau, 2);
  assertEquals(summary.conversions.auth_sign_in, {
    viewed_or_started: 1,
    completed: 1,
    rate: 1,
  });
  assertEquals(summary.conversions.purchase, {
    viewed_or_started: 1,
    completed: 1,
    rate: 1,
  });
  assertEquals(summary.retention, [
    {
      cohort_date: "2026-04-01",
      cohort_size: 2,
      retained_d1: 1,
      retained_d7: 1,
      retained_d30: 0,
    },
  ]);
});
