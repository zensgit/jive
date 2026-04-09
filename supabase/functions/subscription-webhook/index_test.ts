import { assertEquals } from "jsr:@std/assert@1";

import {
  buildAppleSubscriptionUpdate,
  decodeJwsPayload,
  deriveEntitlementTier,
  deriveWebhookPlan,
  isClaimStale,
  mapAppleNotificationType,
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

Deno.test("decodeJwsPayload decodes the payload segment from a JWS", () => {
  const payload = {
    notificationType: "SUBSCRIBED",
    notificationUUID: "test-notification",
  };

  assertEquals(decodeJwsPayload(buildUnsignedJws(payload)), payload);
});

Deno.test("mapAppleNotificationType covers the supported subscription lifecycle states", () => {
  assertEquals(mapAppleNotificationType("DID_RENEW"), "active");
  assertEquals(
    mapAppleNotificationType(
      "DID_CHANGE_RENEWAL_STATUS",
      "AUTO_RENEW_DISABLED",
    ),
    "canceled",
  );
  assertEquals(
    mapAppleNotificationType("DID_FAIL_TO_RENEW", "GRACE_PERIOD", {
      isInBillingRetryPeriod: true,
    }),
    "grace",
  );
  assertEquals(mapAppleNotificationType("EXPIRED"), "expired");
  assertEquals(mapAppleNotificationType("REVOKE"), "revoked");
  assertEquals(mapAppleNotificationType("CONSUMPTION_REQUEST"), null);
});

Deno.test("buildAppleSubscriptionUpdate derives subscriber payload from Apple renewal data", () => {
  const update = buildAppleSubscriptionUpdate(
    {
      notificationType: "DID_FAIL_TO_RENEW",
      subtype: "GRACE_PERIOD",
    },
    {
      originalTransactionId: "orig-123",
      transactionId: "txn-456",
      productId: "jive_subscriber_monthly",
      expiresDate: 1_775_692_800_000,
      appAccountToken: "8f39c97d-5fd3-4422-9478-95f74d715967",
    },
    null,
  );

  assertEquals(update, {
    plan: "subscriber",
    status: "grace",
    entitlementTier: "subscriber",
    productId: "jive_subscriber_monthly",
    purchaseToken: "orig-123",
    orderId: "txn-456",
    expiresAt: "2026-04-09T00:00:00.000Z",
    notificationType: "DID_FAIL_TO_RENEW",
    notificationSubtype: "GRACE_PERIOD",
    originalTransactionId: "orig-123",
    transactionId: "txn-456",
    appAccountToken: "8f39c97d-5fd3-4422-9478-95f74d715967",
  });
});

Deno.test("buildAppleSubscriptionUpdate ignores unsupported products", () => {
  assertEquals(
    buildAppleSubscriptionUpdate(
      {
        notificationType: "SUBSCRIBED",
      },
      {
        originalTransactionId: "orig-789",
        transactionId: "txn-789",
        productId: "unknown_product",
      },
      null,
    ),
    null,
  );
});

function buildUnsignedJws(payload: unknown): string {
  return `${base64UrlEncode({ alg: "none" })}.${
    base64UrlEncode(payload)
  }.signature`;
}

function base64UrlEncode(payload: unknown): string {
  const json = JSON.stringify(payload);
  const bytes = new TextEncoder().encode(json);
  const binary = Array.from(bytes, (byte) => String.fromCharCode(byte)).join(
    "",
  );
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll(
    "=",
    "",
  );
}
