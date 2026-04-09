import { assertEquals } from "jsr:@std/assert@1";

import {
  buildAppleVerifiedSubscription,
  mapAppleReceiptStatus,
  pickLatestAppleTransaction,
} from "./index.ts";

Deno.test("pickLatestAppleTransaction prefers the newest matching receipt", () => {
  const transaction = pickLatestAppleTransaction(
    {
      latest_receipt_info: [
        {
          product_id: "jive_subscriber_monthly",
          original_transaction_id: "orig-old",
          transaction_id: "txn-old",
          expires_date_ms: "1775600000000",
        },
        {
          product_id: "jive_subscriber_monthly",
          original_transaction_id: "orig-new",
          transaction_id: "txn-new",
          expires_date_ms: "1775700000000",
        },
      ],
    },
    "jive_subscriber_monthly",
  );

  assertEquals(transaction?.transaction_id, "txn-new");
});

Deno.test("buildAppleVerifiedSubscription maps an active subscriber receipt", () => {
  const verified = buildAppleVerifiedSubscription(
    {
      environment: "Sandbox",
      receipt: { bundle_id: "app.zens.jive" },
      pending_renewal_info: [
        {
          original_transaction_id: "orig-sub",
          auto_renew_product_id: "jive_subscriber_yearly",
          auto_renew_status: "1",
        },
      ],
    },
    {
      product_id: "jive_subscriber_yearly",
      original_transaction_id: "orig-sub",
      transaction_id: "txn-sub",
      expires_date_ms: "1775800000000",
    },
  );

  assertEquals(verified.plan, "subscriber");
  assertEquals(verified.status, "active");
  assertEquals(verified.entitlement_tier, "subscriber");
  assertEquals(verified.purchase_token, "orig-sub");
  assertEquals(verified.order_id, "txn-sub");
  assertEquals(verified.product_id, "jive_subscriber_yearly");
  assertEquals(verified.receipt_data["environment"], "Sandbox");
});

Deno.test("mapAppleReceiptStatus treats active grace window as grace", () => {
  const status = mapAppleReceiptStatus(
    "subscriber",
    {
      product_id: "jive_subscriber_monthly",
      original_transaction_id: "orig-grace",
      transaction_id: "txn-grace",
      expires_date_ms: "1712000000000",
    },
    {
      original_transaction_id: "orig-grace",
      grace_period_expires_date_ms: "1712100000000",
      is_in_billing_retry_period: "1",
    },
    1712050000000,
  );

  assertEquals(status, "grace");
});

Deno.test("buildAppleVerifiedSubscription maps one-time unlock as paid", () => {
  const verified = buildAppleVerifiedSubscription(
    {
      environment: "Production",
      receipt: { bundle_id: "app.zens.jive" },
    },
    {
      product_id: "jive_paid_unlock",
      original_transaction_id: "orig-paid",
      transaction_id: "txn-paid",
      purchase_date_ms: "1711000000000",
    },
  );

  assertEquals(verified.plan, "paid");
  assertEquals(verified.status, "active");
  assertEquals(verified.entitlement_tier, "paid");
  assertEquals(verified.purchase_token, "orig-paid");
  assertEquals(verified.order_id, "txn-paid");
}
