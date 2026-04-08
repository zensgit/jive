import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import { latestSubscriptionByUser } from "./index.ts";

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
