import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  deriveEntitlementTier,
  deriveWebhookPlan,
  isClaimStale,
  mapGoogleNotificationType,
} from "./index.ts";

Deno.test("mapGoogleNotificationType maps handled RTDN events", () => {
  assertEquals(mapGoogleNotificationType(2), "active");
  assertEquals(mapGoogleNotificationType(5), "grace");
  assertEquals(mapGoogleNotificationType(3), "canceled");
  assertEquals(mapGoogleNotificationType(13), "expired");
});

Deno.test("deriveWebhookPlan preserves paid rows and defaults recurring rows to subscriber", () => {
  assertEquals(deriveWebhookPlan("paid"), "paid");
  assertEquals(deriveWebhookPlan("subscriber"), "subscriber");
  assertEquals(deriveWebhookPlan("free"), "subscriber");
});

Deno.test("deriveEntitlementTier keeps paid tier for paid rows", () => {
  assertEquals(deriveEntitlementTier("paid", "active", null), "paid");
  assertEquals(deriveEntitlementTier("paid", "expired", null), "free");
});

Deno.test("deriveEntitlementTier keeps subscriber during future-dated cancellation", () => {
  const future = new Date(Date.now() + 60_000).toISOString();
  assertEquals(
    deriveEntitlementTier("subscriber", "canceled", future),
    "subscriber",
  );
});

Deno.test("isClaimStale returns false for fresh processing rows", () => {
  const now = "2026-04-09T10:15:00.000Z";
  const fresh = "2026-04-09T10:05:01.000Z";
  assertEquals(isClaimStale(fresh, now), false);
});

Deno.test("isClaimStale returns true for stale or missing processing rows", () => {
  const now = "2026-04-09T10:15:00.000Z";
  const stale = "2026-04-09T09:59:59.000Z";
  assertEquals(isClaimStale(stale, now), true);
  assertEquals(isClaimStale(null, now), true);
});
