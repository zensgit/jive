import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type DomesticWebhookRequest = {
  provider?: string;
  event_id?: string;
  event_type?: string;
  order_no?: string;
  provider_trade_no?: string;
  status?: string;
  paid_at?: string | null;
  expires_at?: string | null;
  payload?: Record<string, unknown>;
};

type ParsedDomesticWebhookRequest = {
  provider: "wechat_pay" | "alipay";
  event_id: string;
  event_type: string;
  order_no: string;
  provider_trade_no: string | null;
  status: "pending" | "paid" | "failed" | "expired" | "closed";
  paid_at: string | null;
  expires_at: string | null;
  payload: Record<string, unknown>;
};

type SubscriptionProjection = {
  plan: "paid" | "subscriber";
  entitlement_tier: "paid" | "subscriber";
  status: "active" | "expired";
  expires_at: string | null;
};

type DomesticWebhookQueryResult = {
  error: unknown | null;
};

type DomesticWebhookSingleResult = {
  data: Record<string, unknown> | null;
  error: unknown | null;
};

type DomesticWebhookQuery = {
  upsert(
    payload: Record<string, unknown>,
    options?: Record<string, unknown>,
  ): DomesticWebhookQuery;
  update(payload: Record<string, unknown>): DomesticWebhookQuery;
  select(columns?: string): DomesticWebhookQuery;
  eq(column: string, value: unknown): DomesticWebhookQuery;
  single(): Promise<DomesticWebhookSingleResult>;
  then<TResult1 = DomesticWebhookQueryResult, TResult2 = never>(
    onfulfilled?:
      | ((
        value: DomesticWebhookQueryResult,
      ) => TResult1 | PromiseLike<TResult1>)
      | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): Promise<TResult1 | TResult2>;
};

type DomesticWebhookSupabaseClient = {
  from(table: string): DomesticWebhookQuery;
};

type DomesticWebhookRuntime = {
  env?: ReturnType<typeof readEnv>;
  createClient?: (
    supabaseUrl: string,
    supabaseServiceRoleKey: string,
  ) => DomesticWebhookSupabaseClient;
  now?: () => Date;
  logError?: (message?: unknown, ...optionalParams: unknown[]) => void;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-domestic-payment-token",
};

const supportedProviders = new Set(["wechat_pay", "alipay"]);
const supportedStatuses = new Set([
  "pending",
  "paid",
  "failed",
  "expired",
  "closed",
]);

if (import.meta.main) {
  Deno.serve(handleRequest);
}

export function handleRequest(req: Request): Promise<Response> {
  return handleDomesticWebhookRequest(req);
}

export async function handleDomesticWebhookRequest(
  req: Request,
  runtime: DomesticWebhookRuntime = {},
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const logError = runtime.logError ?? console.error;

  try {
    const env = runtime.env ?? readEnv();
    assertWebhookAuthorized(req, env);

    const parsedBody = parseDomesticWebhookRequest(
      (await req.json()) as DomesticWebhookRequest,
    );

    const createSupabaseClient = runtime.createClient ??
      ((supabaseUrl: string, supabaseServiceRoleKey: string) =>
        createClient(
          supabaseUrl,
          supabaseServiceRoleKey,
        ) as unknown as DomesticWebhookSupabaseClient);

    const adminClient = createSupabaseClient(
      env.supabaseUrl,
      env.supabaseServiceRoleKey,
    );

    const { error: eventError } = await adminClient.from("payment_events")
      .upsert({
        provider: parsedBody.provider,
        event_id: parsedBody.event_id,
        event_type: parsedBody.event_type,
        order_no: parsedBody.order_no,
        provider_trade_no: parsedBody.provider_trade_no,
        payload: parsedBody.payload,
      }, {
        onConflict: "provider,event_id",
        ignoreDuplicates: true,
      });
    if (eventError != null) {
      logError("domestic-payment-webhook event upsert failed", eventError);
      return json({ error: "payment_event_upsert_failed" }, 500);
    }

    const { data: order, error: orderError } = await adminClient.from(
      "payment_orders",
    ).select().eq("order_no", parsedBody.order_no).single();
    if (orderError != null || order == null) {
      return json({ error: "payment_order_not_found" }, 404);
    }

    const now = (runtime.now?.() ?? new Date()).toISOString();
    const updatedOrder = {
      status: parsedBody.status,
      provider_trade_no: parsedBody.provider_trade_no,
      paid_at: parsedBody.status === "paid" ? parsedBody.paid_at ?? now : null,
      expires_at: parsedBody.expires_at ?? order.expires_at,
      raw_response: parsedBody.payload,
      updated_at: now,
    };

    const { error: updateOrderError } = await adminClient.from("payment_orders")
      .update(updatedOrder).eq("order_no", parsedBody.order_no);
    if (updateOrderError != null) {
      logError(
        "domestic-payment-webhook order update failed",
        updateOrderError,
      );
      return json({ error: "payment_order_update_failed" }, 500);
    }

    let subscription: unknown = null;
    if (parsedBody.status === "paid") {
      const projected = projectSubscriptionFromOrder({
        planCode: String(order.plan_code),
        explicitExpiresAt: parsedBody.expires_at,
        paidAt: parsedBody.paid_at ?? now,
      });
      const purchaseToken = parsedBody.provider_trade_no ?? parsedBody.order_no;
      const payload = {
        user_id: String(order.user_id),
        plan: projected.plan,
        status: projected.status,
        platform: parsedBody.provider,
        product_id: order.product_id == null ? null : String(order.product_id),
        purchase_token: purchaseToken,
        order_id: parsedBody.provider_trade_no ?? parsedBody.order_no,
        entitlement_tier: projected.entitlement_tier,
        expires_at: projected.expires_at,
        last_verified_at: now,
        verification_source: `${parsedBody.provider}_webhook`,
        source_order_no: parsedBody.order_no,
        provider_trade_no: parsedBody.provider_trade_no,
        receipt_data: {
          source: "domestic_payment_webhook",
          event_id: parsedBody.event_id,
        },
        raw_response: parsedBody.payload,
        updated_at: now,
      };

      const { data, error } = await adminClient.from("user_subscriptions")
        .upsert(payload, {
          onConflict: "platform,purchase_token",
        }).select().single();
      if (error != null) {
        logError(
          "domestic-payment-webhook subscription upsert failed",
          error,
        );
        return json({ error: "subscription_upsert_failed" }, 500);
      }
      subscription = data;
    }

    await adminClient.from("payment_events").update({
      processed_at: now,
    }).eq("provider", parsedBody.provider).eq("event_id", parsedBody.event_id);

    return json(
      {
        ok: true,
        order_no: parsedBody.order_no,
        order_status: parsedBody.status,
        subscription,
      },
      200,
    );
  } catch (error) {
    logError("domestic-payment-webhook unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      error instanceof HttpError ? error.status : 500,
    );
  }
}

export function parseDomesticWebhookRequest(
  body: DomesticWebhookRequest,
): ParsedDomesticWebhookRequest {
  const provider = normalizeNonEmptyString(body.provider);
  const eventId = normalizeNonEmptyString(body.event_id);
  const eventType = normalizeNonEmptyString(body.event_type);
  const orderNo = normalizeNonEmptyString(body.order_no);
  const status = normalizeNonEmptyString(body.status);

  if (
    provider == null || eventId == null || eventType == null ||
    orderNo == null || status == null
  ) {
    throw new HttpError(400, "invalid_domestic_webhook_request");
  }
  if (!supportedProviders.has(provider)) {
    throw new HttpError(400, "unsupported_payment_provider");
  }
  if (!supportedStatuses.has(status)) {
    throw new HttpError(400, "unsupported_payment_status");
  }

  return {
    provider: provider as ParsedDomesticWebhookRequest["provider"],
    event_id: eventId,
    event_type: eventType,
    order_no: orderNo,
    provider_trade_no: normalizeNonEmptyString(body.provider_trade_no),
    status: status as ParsedDomesticWebhookRequest["status"],
    paid_at: normalizeNullableDateString(body.paid_at),
    expires_at: normalizeNullableDateString(body.expires_at),
    payload: body.payload == null ? {} : body.payload,
  };
}

export function projectSubscriptionFromOrder({
  planCode,
  explicitExpiresAt,
  paidAt,
}: {
  planCode: string;
  explicitExpiresAt: string | null;
  paidAt: string;
}): SubscriptionProjection {
  if (planCode === "pro_lifetime") {
    return {
      plan: "paid",
      entitlement_tier: "paid",
      status: "active",
      expires_at: null,
    };
  }

  if (explicitExpiresAt != null) {
    return {
      plan: "subscriber",
      entitlement_tier: "subscriber",
      status: "active",
      expires_at: explicitExpiresAt,
    };
  }

  const paidDate = new Date(paidAt);
  const expiresDate = new Date(paidDate);
  if (planCode.endsWith("_yearly")) {
    expiresDate.setUTCFullYear(expiresDate.getUTCFullYear() + 1);
  } else {
    expiresDate.setUTCMonth(expiresDate.getUTCMonth() + 1);
  }

  return {
    plan: "subscriber",
    entitlement_tier: "subscriber",
    status: "active",
    expires_at: expiresDate.toISOString(),
  };
}

function assertWebhookAuthorized(
  req: Request,
  env: ReturnType<typeof readEnv>,
) {
  const provided = normalizeWebhookToken(req);
  if (provided == null || provided !== env.domesticPaymentWebhookToken) {
    throw new HttpError(401, "admin_token_required");
  }
}

function normalizeWebhookToken(req: Request): string | null {
  const header = req.headers.get("x-domestic-payment-token");
  if (header != null && header.trim().length > 0) {
    return header.trim();
  }

  const authorization = req.headers.get("Authorization");
  if (authorization == null) return null;
  const prefix = "Bearer ";
  if (!authorization.startsWith(prefix)) return null;
  const token = authorization.slice(prefix.length).trim();
  return token.length === 0 ? null : token;
}

function readEnv() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const domesticPaymentWebhookToken = Deno.env.get(
    "DOMESTIC_PAYMENT_WEBHOOK_TOKEN",
  );
  if (!supabaseUrl || !supabaseServiceRoleKey || !domesticPaymentWebhookToken) {
    throw new Error("domestic_payment_env_missing");
  }

  return {
    supabaseUrl,
    supabaseServiceRoleKey,
    domesticPaymentWebhookToken,
  };
}

function normalizeNonEmptyString(
  value: string | undefined | null,
): string | null {
  if (typeof value != "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function normalizeNullableDateString(
  value: string | null | undefined,
): string | null {
  const normalized = normalizeNonEmptyString(value);
  return normalized == null ? null : normalized;
}

class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
