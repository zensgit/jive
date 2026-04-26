import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  handleDomesticWebhookRequest,
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

Deno.test("handleDomesticWebhookRequest rejects missing webhook token", async () => {
  const response = await handleDomesticWebhookRequest(
    jsonRequest({
      provider: "wechat_pay",
      event_id: "evt_auth",
      event_type: "payment.succeeded",
      order_no: "jive_auth",
      status: "paid",
    }),
    testRuntime(),
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "admin_token_required" });
});

Deno.test("handleDomesticWebhookRequest returns not found for missing orders", async () => {
  const db = new FakeDomesticWebhookDb({ order: null });

  const response = await handleDomesticWebhookRequest(
    jsonRequest({
      provider: "wechat_pay",
      event_id: "evt_missing_order",
      event_type: "payment.succeeded",
      order_no: "jive_missing",
      status: "paid",
    }, { token: "domestic-token" }),
    testRuntime({ db }),
  );

  assertEquals(response.status, 404);
  assertEquals(await response.json(), { error: "payment_order_not_found" });
  assertEquals(db.calls[0].table, "payment_events");
  assertEquals(db.calls[0].operation, "upsert");
});

Deno.test("handleDomesticWebhookRequest makes payment event upsert idempotent", async () => {
  const db = new FakeDomesticWebhookDb({
    order: pendingOrder({ order_no: "jive_duplicate" }),
  });

  const response = await handleDomesticWebhookRequest(
    jsonRequest({
      provider: "wechat_pay",
      event_id: "evt_duplicate",
      event_type: "payment.succeeded",
      order_no: "jive_duplicate",
      provider_trade_no: "wx_trade_duplicate",
      status: "paid",
    }, { token: "domestic-token" }),
    testRuntime({ db }),
  );

  assertEquals(response.status, 200);
  const eventUpsert = db.calls.find((call) =>
    call.table === "payment_events" && call.operation === "upsert"
  );
  assertEquals(eventUpsert?.options, {
    onConflict: "provider,event_id",
    ignoreDuplicates: true,
  });
});

Deno.test("handleDomesticWebhookRequest projects paid orders to subscriptions", async () => {
  const db = new FakeDomesticWebhookDb({
    order: pendingOrder({
      order_no: "jive_paid",
      user_id: "user-paid",
      plan_code: "pro_monthly",
      product_id: "jive_subscriber_monthly",
    }),
  });

  const response = await handleDomesticWebhookRequest(
    jsonRequest({
      provider: "alipay",
      event_id: "evt_paid",
      event_type: "payment.succeeded",
      order_no: "jive_paid",
      provider_trade_no: "ali_trade_paid",
      status: "paid",
      paid_at: "2026-04-26T01:00:00.000Z",
      expires_at: "2026-05-26T01:00:00.000Z",
      payload: { amount_cents: 800 },
    }, { token: "domestic-token" }),
    testRuntime({ db }),
  );

  assertEquals(response.status, 200);
  const body = await response.json();
  assertEquals(body.ok, true);
  assertEquals(body.order_no, "jive_paid");
  assertEquals(body.order_status, "paid");

  const orderUpdate = db.calls.find((call) =>
    call.table === "payment_orders" && call.operation === "update"
  );
  assertEquals(orderUpdate?.payload.status, "paid");
  assertEquals(orderUpdate?.payload.provider_trade_no, "ali_trade_paid");
  assertEquals(orderUpdate?.payload.paid_at, "2026-04-26T01:00:00.000Z");

  const subscriptionInsert = db.calls.find((call) =>
    call.table === "user_subscriptions" && call.operation === "insert"
  );
  assertEquals(subscriptionInsert?.payload.user_id, "user-paid");
  assertEquals(subscriptionInsert?.payload.plan, "subscriber");
  assertEquals(subscriptionInsert?.payload.entitlement_tier, "subscriber");
  assertEquals(subscriptionInsert?.payload.status, "active");
  assertEquals(subscriptionInsert?.payload.platform, "alipay");
  assertEquals(subscriptionInsert?.payload.purchase_token, "ali_trade_paid");
  assertEquals(
    subscriptionInsert?.payload.expires_at,
    "2026-05-26T01:00:00.000Z",
  );
});

Deno.test("handleDomesticWebhookRequest updates existing domestic subscription projection", async () => {
  const db = new FakeDomesticWebhookDb({
    order: pendingOrder({
      order_no: "jive_existing",
      user_id: "user-existing",
      plan_code: "pro_lifetime",
      product_id: "jive_paid_unlock",
    }),
    existingSubscription: { id: 42 },
  });

  const response = await handleDomesticWebhookRequest(
    jsonRequest({
      provider: "wechat_pay",
      event_id: "evt_existing_paid",
      event_type: "payment.succeeded",
      order_no: "jive_existing",
      provider_trade_no: "wx_trade_existing",
      status: "paid",
      paid_at: "2026-04-26T01:00:00.000Z",
      payload: { amount_cents: 2800 },
    }, { token: "domestic-token" }),
    testRuntime({ db }),
  );

  assertEquals(response.status, 200);
  const subscriptionUpdate = db.calls.find((call) =>
    call.table === "user_subscriptions" && call.operation === "update"
  );
  assertEquals(subscriptionUpdate?.filters, [{ column: "id", value: 42 }]);
  assertEquals(subscriptionUpdate?.payload.user_id, "user-existing");
  assertEquals(subscriptionUpdate?.payload.plan, "paid");
  assertEquals(subscriptionUpdate?.payload.entitlement_tier, "paid");
  assertEquals(subscriptionUpdate?.payload.source_order_no, "jive_existing");
});

function jsonRequest(
  body: Record<string, unknown>,
  { token }: { token?: string } = {},
): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (token != null) {
    headers.set("x-domestic-payment-token", token);
  }

  return new Request(
    "https://example.com/functions/v1/domestic-payment-webhook",
    {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    },
  );
}

function testRuntime({
  db = new FakeDomesticWebhookDb(),
}: {
  db?: FakeDomesticWebhookDb;
} = {}) {
  return {
    env: {
      supabaseUrl: "https://example.supabase.co",
      supabaseServiceRoleKey: "service-role",
      domesticPaymentWebhookToken: "domestic-token",
    },
    createClient: () => db.client(),
    now: () => new Date("2026-04-26T01:30:00.000Z"),
    logError: () => {},
  };
}

function pendingOrder(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    order_no: "jive_order",
    user_id: "user-1",
    provider: "wechat_pay",
    plan_code: "pro_lifetime",
    status: "pending",
    product_id: "jive_paid_unlock",
    expires_at: "2026-04-26T02:00:00.000Z",
    ...overrides,
  };
}

type FakeCall = {
  table: string;
  operation: string;
  payload: Record<string, unknown>;
  options?: Record<string, unknown>;
  filters: Array<{ column: string; value: unknown }>;
};

class FakeDomesticWebhookDb {
  calls: FakeCall[] = [];
  order: Record<string, unknown> | null;
  existingSubscription: Record<string, unknown> | null;
  eventUpsertError: unknown | null;
  orderUpdateError: unknown | null;
  subscriptionUpsertError: unknown | null;

  constructor({
    order = pendingOrder(),
    existingSubscription = null,
    eventUpsertError = null,
    orderUpdateError = null,
    subscriptionUpsertError = null,
  }: {
    order?: Record<string, unknown> | null;
    existingSubscription?: Record<string, unknown> | null;
    eventUpsertError?: unknown | null;
    orderUpdateError?: unknown | null;
    subscriptionUpsertError?: unknown | null;
  } = {}) {
    this.order = order;
    this.existingSubscription = existingSubscription;
    this.eventUpsertError = eventUpsertError;
    this.orderUpdateError = orderUpdateError;
    this.subscriptionUpsertError = subscriptionUpsertError;
  }

  client() {
    return {
      from: (table: string) => new FakeQuery(this, table),
    };
  }
}

class FakeQuery {
  private operation = "select";
  private payload: Record<string, unknown> = {};
  private options: Record<string, unknown> | undefined = undefined;
  private filters: Array<{ column: string; value: unknown }> = [];

  constructor(
    private readonly db: FakeDomesticWebhookDb,
    private readonly table: string,
  ) {}

  upsert(
    payload: Record<string, unknown>,
    options?: Record<string, unknown>,
  ): FakeQuery {
    this.operation = "upsert";
    this.payload = payload;
    this.options = options;
    return this;
  }

  insert(payload: Record<string, unknown>): FakeQuery {
    this.operation = "insert";
    this.payload = payload;
    return this;
  }

  update(payload: Record<string, unknown>): FakeQuery {
    this.operation = "update";
    this.payload = payload;
    return this;
  }

  select(): FakeQuery {
    return this;
  }

  eq(column: string, value: unknown): FakeQuery {
    this.filters.push({ column, value });
    return this;
  }

  single(): Promise<
    { data: Record<string, unknown> | null; error: unknown | null }
  > {
    this.recordCall();

    if (this.table === "payment_orders") {
      return Promise.resolve({
        data: this.db.order,
        error: this.db.order == null ? { message: "not found" } : null,
      });
    }

    if (this.table === "user_subscriptions") {
      if (this.operation === "select") {
        return Promise.resolve({
          data: this.db.existingSubscription,
          error: this.db.existingSubscription == null
            ? { message: "not found" }
            : null,
        });
      }
      if (this.db.subscriptionUpsertError != null) {
        return Promise.resolve({
          data: null,
          error: this.db.subscriptionUpsertError,
        });
      }
      return Promise.resolve({
        data: { id: 1, ...this.payload },
        error: null,
      });
    }

    return Promise.resolve({ data: null, error: null });
  }

  then<TResult1 = { error: unknown | null }, TResult2 = never>(
    onfulfilled?:
      | ((value: { error: unknown | null }) => TResult1 | PromiseLike<TResult1>)
      | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): Promise<TResult1 | TResult2> {
    return Promise.resolve(this.result()).then(onfulfilled, onrejected);
  }

  private result(): { error: unknown | null } {
    this.recordCall();

    if (this.table === "payment_events" && this.operation === "upsert") {
      return { error: this.db.eventUpsertError };
    }

    if (this.table === "payment_orders" && this.operation === "update") {
      return { error: this.db.orderUpdateError };
    }

    return { error: null };
  }

  private recordCall() {
    this.db.calls.push({
      table: this.table,
      operation: this.operation,
      payload: this.payload,
      options: this.options,
      filters: [...this.filters],
    });
  }
}
