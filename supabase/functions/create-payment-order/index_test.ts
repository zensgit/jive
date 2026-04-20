import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  amountCentsForPlan,
  buildMockPaymentOrder,
  parseCreatePaymentOrderRequest,
  resolveMockBaseUrl,
} from "./index.ts";

Deno.test("parseCreatePaymentOrderRequest validates provider and channel", () => {
  assertEquals(
    parseCreatePaymentOrderRequest({
      provider: "wechat_pay",
      product_id: "jive_subscriber_monthly",
      plan_code: "pro_monthly",
      client_channel: "self_hosted_web",
    }),
    {
      provider: "wechat_pay",
      product_id: "jive_subscriber_monthly",
      plan_code: "pro_monthly",
      client_channel: "self_hosted_web",
    },
  );

  assertThrows(
    () =>
      parseCreatePaymentOrderRequest({
        provider: "bank_transfer",
        product_id: "jive_subscriber_monthly",
        plan_code: "pro_monthly",
        client_channel: "self_hosted_web",
      }),
    Error,
    "unsupported_payment_provider",
  );
});

Deno.test("buildMockPaymentOrder creates pending order urls", () => {
  const payload = buildMockPaymentOrder(
    {
      provider: "alipay",
      product_id: "jive_paid_unlock",
      plan_code: "pro_lifetime",
      client_channel: "direct_android",
    },
    "https://api.example.com/functions/v1/create-payment-order",
  );

  assertEquals(payload.status, "pending");
  assertEquals(payload.amount_cents, 2800);
  assertEquals(payload.currency, "CNY");
  assertEquals(payload.redirect_url.includes("/mock-pay/alipay/"), true);
  assertEquals(payload.qr_code_url.includes("/qr.png"), true);
});

Deno.test("amountCentsForPlan exposes stable mock pricing", () => {
  assertEquals(amountCentsForPlan("pro_monthly"), 800);
  assertEquals(amountCentsForPlan("pro_yearly"), 6800);
  assertEquals(amountCentsForPlan("family_monthly"), 1500);
});

Deno.test("resolveMockBaseUrl prefers env override", () => {
  Deno.env.set("DOMESTIC_PAYMENT_MOCK_BASE_URL", "https://pay.example.com/");
  try {
    assertEquals(
      resolveMockBaseUrl("https://api.example.com/functions/v1/create-payment-order"),
      "https://pay.example.com",
    );
  } finally {
    Deno.env.delete("DOMESTIC_PAYMENT_MOCK_BASE_URL");
  }
});
