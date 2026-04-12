import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type CreatePaymentOrderRequest = {
  provider?: string;
  product_id?: string;
  plan_code?: string;
  client_channel?: string;
};

type ParsedCreatePaymentOrderRequest = {
  provider: "wechat_pay" | "alipay";
  product_id: string;
  plan_code:
    | "pro_lifetime"
    | "pro_monthly"
    | "pro_yearly"
    | "family_monthly"
    | "family_yearly"
    | "custom";
  client_channel:
    | "auto"
    | "self_hosted_web"
    | "direct_android"
    | "desktop_web"
    | "app_store"
    | "google_play";
};

type MockOrderPayload = {
  order_no: string;
  provider: ParsedCreatePaymentOrderRequest["provider"];
  product_id: string;
  plan_code: ParsedCreatePaymentOrderRequest["plan_code"];
  client_channel: ParsedCreatePaymentOrderRequest["client_channel"];
  status: "pending";
  amount_cents: number;
  currency: "CNY";
  redirect_url: string;
  qr_code_url: string;
  expires_at: string;
  raw_request: Record<string, unknown>;
  raw_response: Record<string, unknown>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const supportedProviders = new Set(["wechat_pay", "alipay"]);
const supportedPlanCodes = new Set([
  "pro_lifetime",
  "pro_monthly",
  "pro_yearly",
  "family_monthly",
  "family_yearly",
  "custom",
]);
const supportedChannels = new Set([
  "auto",
  "self_hosted_web",
  "direct_android",
  "desktop_web",
  "app_store",
  "google_play",
]);

if (import.meta.main) {
  Deno.serve(handleRequest);
}

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const env = readEnv();
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "missing_authorization" }, 401);
    }

    const userClient = createClient(env.supabaseUrl, env.supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });
    const adminClient = createClient(
      env.supabaseUrl,
      env.supabaseServiceRoleKey,
    );

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError != null || user == null) {
      return json({ error: "auth_required" }, 401);
    }

    const parsedBody = parseCreatePaymentOrderRequest(
      (await req.json()) as CreatePaymentOrderRequest,
    );
    const order = buildMockPaymentOrder(parsedBody, req.url);

    const { data, error } = await adminClient.from("payment_orders").insert({
      order_no: order.order_no,
      user_id: user.id,
      provider: order.provider,
      plan_code: order.plan_code,
      status: order.status,
      amount_cents: order.amount_cents,
      currency: order.currency,
      product_id: order.product_id,
      client_channel: order.client_channel,
      redirect_url: order.redirect_url,
      qr_code_url: order.qr_code_url,
      expires_at: order.expires_at,
      raw_request: order.raw_request,
      raw_response: order.raw_response,
      updated_at: new Date().toISOString(),
    }).select().single();

    if (error != null) {
      console.error("create-payment-order insert failed", error);
      return json({ error: "payment_order_insert_failed" }, 500);
    }

    return json(
      {
        order: {
          order_no: data.order_no,
          provider: data.provider,
          product_id: data.product_id,
          plan_code: data.plan_code,
          status: data.status,
          amount_cents: data.amount_cents,
          currency: data.currency,
          redirect_url: data.redirect_url,
          qr_code_url: data.qr_code_url,
          expires_at: data.expires_at,
        },
      },
      201,
    );
  } catch (error) {
    console.error("create-payment-order unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      error instanceof HttpError ? error.status : 500,
    );
  }
}

export function parseCreatePaymentOrderRequest(
  body: CreatePaymentOrderRequest,
): ParsedCreatePaymentOrderRequest {
  const provider = normalizeNonEmptyString(body.provider);
  const productId = normalizeNonEmptyString(body.product_id);
  const planCode = normalizeNonEmptyString(body.plan_code);
  const clientChannel = normalizeNonEmptyString(body.client_channel);

  if (
    provider == null || productId == null || planCode == null ||
    clientChannel == null
  ) {
    throw new HttpError(400, "invalid_payment_order_request");
  }
  if (!supportedProviders.has(provider)) {
    throw new HttpError(400, "unsupported_payment_provider");
  }
  if (!supportedPlanCodes.has(planCode)) {
    throw new HttpError(400, "unsupported_plan_code");
  }
  if (!supportedChannels.has(clientChannel)) {
    throw new HttpError(400, "unsupported_client_channel");
  }

  return {
    provider: provider as ParsedCreatePaymentOrderRequest["provider"],
    product_id: productId,
    plan_code: planCode as ParsedCreatePaymentOrderRequest["plan_code"],
    client_channel:
      clientChannel as ParsedCreatePaymentOrderRequest["client_channel"],
  };
}

export function buildMockPaymentOrder(
  body: ParsedCreatePaymentOrderRequest,
  requestUrl: string,
): MockOrderPayload {
  const orderNo = `jive_${Date.now()}_${crypto.randomUUID().replaceAll("-", "").slice(0, 12)}`;
  const amountCents = amountCentsForPlan(body.plan_code);
  const baseUrl = resolveMockBaseUrl(requestUrl);
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
  const redirectUrl =
    `${baseUrl}/mock-pay/${body.provider}/${orderNo}?channel=${body.client_channel}`;
  const qrCodeUrl =
    `${baseUrl}/mock-pay/${body.provider}/${orderNo}/qr.png?channel=${body.client_channel}`;

  return {
    order_no: orderNo,
    provider: body.provider,
    product_id: body.product_id,
    plan_code: body.plan_code,
    client_channel: body.client_channel,
    status: "pending",
    amount_cents: amountCents,
    currency: "CNY",
    redirect_url: redirectUrl,
    qr_code_url: qrCodeUrl,
    expires_at: expiresAt,
    raw_request: { ...body },
    raw_response: {
      mode: "mock",
      redirect_url: redirectUrl,
      qr_code_url: qrCodeUrl,
    },
  };
}

export function amountCentsForPlan(
  planCode: ParsedCreatePaymentOrderRequest["plan_code"],
): number {
  switch (planCode) {
    case "pro_lifetime":
      return 2800;
    case "pro_monthly":
      return 800;
    case "pro_yearly":
      return 6800;
    case "family_monthly":
      return 1500;
    case "family_yearly":
      return 12800;
    case "custom":
      return 100;
  }
}

export function resolveMockBaseUrl(requestUrl: string): string {
  const configured = Deno.env.get("DOMESTIC_PAYMENT_MOCK_BASE_URL");
  if (configured != null && configured.trim().length > 0) {
    return configured.trim().replaceAll(RegExp(r"/+$"), "");
  }

  const url = new URL(requestUrl);
  return `${url.protocol}//${url.host}`;
}

function readEnv() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
    throw new Error("supabase_function_env_missing");
  }

  return {
    supabaseUrl,
    supabaseAnonKey,
    supabaseServiceRoleKey,
  };
}

function normalizeNonEmptyString(value: string | undefined): string | null {
  if (typeof value != "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
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
