import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  parseDomesticWebhookRequest,
  projectSubscriptionFromOrder,
} from "./index.ts";

Deno.test("parseDomesticWebhookRequest validates provider and status", () => {
  assertEquals(
    parseDomesticWebhookRequest({
      provider: "wechat_pay",
      event_id: "evt_1",
      event_type: "payment.succeeded",
      order_no: "jive_123",
      provider_trade_no: "wx_trade_1",
      status: "paid",
      payload: { amount_cents: 800 },
    }),
    {
      provider: "wechat_pay",
      event_id: "evt_1",
      event_type: "payment.succeeded",
      order_no: "jive_123",
      provider_trade_no: "wx_trade_1",
      status: "paid",
      paid_at: null,
      expires_at: null,
      payload: { amount_cents: 800 },
    },
  );

  assertThrows(
    () =>
      parseDomesticWebhookRequest({
        provider: "wechat_pay",
        event_id: "evt_1",
        event_type: "payment.succeeded",
        order_no: "jive_123",
        status: "settled",
      }),
    Error,
    "unsupported_payment_status",
  );
});

Deno.test("projectSubscriptionFromOrder maps lifetime and subscription plans", () => {
  assertEquals(
    projectSubscriptionFromOrder({
      planCode: "pro_lifetime",
      explicitExpiresAt: null,
      paidAt: "2026-04-12T15:00:00.000Z",
    }),
    {
      plan: "paid",
      entitlement_tier: "paid",
      status: "active",
      expires_at: null,
    },
  );

  const monthly = projectSubscriptionFromOrder({
    planCode: "pro_monthly",
    explicitExpiresAt: null,
    paidAt: "2026-04-12T15:00:00.000Z",
  });
  assertEquals(monthly.plan, "subscriber");
  assertEquals(monthly.entitlement_tier, "subscriber");
  assertEquals(monthly.status, "active");
  assertEquals(monthly.expires_at != null, true);
});
