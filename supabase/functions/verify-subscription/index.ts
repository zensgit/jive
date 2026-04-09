import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type VerifyRequest = {
  platform?: string;
  product_id?: string;
  purchase_token?: string;
  order_id?: string;
  transaction_date_ms?: string;
  receipt_data?: string;
};

type GoogleVerifyRequest = {
  platform: "google_play";
  product_id: string;
  purchase_token: string;
  order_id?: string;
  transaction_date_ms?: string;
};

type AppleVerifyRequest = {
  platform: "apple_app_store";
  product_id: string;
  receipt_data: string;
  order_id?: string;
};

type VerifiedSubscription = {
  plan: "paid" | "subscriber";
  status: "active" | "grace" | "pending" | "canceled" | "expired" | "revoked";
  entitlement_tier: "free" | "paid" | "subscriber";
  product_id: string | null;
  purchase_token: string | null;
  order_id: string | null;
  expires_at: string | null;
  verification_source: string;
  receipt_data: Record<string, unknown>;
  raw_response: Record<string, unknown>;
};

type AppleVerifyReceiptResponse = {
  status?: number;
  environment?: string;
  receipt?: {
    bundle_id?: string;
    in_app?: AppleReceiptTransaction[];
  };
  latest_receipt_info?: AppleReceiptTransaction[];
  latest_expired_receipt_info?: AppleReceiptTransaction[];
  pending_renewal_info?: ApplePendingRenewalInfo[];
  latest_receipt?: string;
};

type AppleReceiptTransaction = {
  product_id?: string;
  transaction_id?: string;
  original_transaction_id?: string;
  purchase_date_ms?: string;
  expires_date_ms?: string;
  cancellation_date_ms?: string;
};

type ApplePendingRenewalInfo = {
  original_transaction_id?: string;
  product_id?: string;
  auto_renew_product_id?: string;
  auto_renew_status?: string;
  expiration_intent?: string;
  grace_period_expires_date_ms?: string;
  is_in_billing_retry_period?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const appleVerifyReceiptProductionUrl =
  "https://buy.itunes.apple.com/verifyReceipt";
const appleVerifyReceiptSandboxUrl =
  "https://sandbox.itunes.apple.com/verifyReceipt";

const subscriptionProducts = new Set([
  "jive_subscriber_monthly",
  "jive_subscriber_yearly",
]);

const supportedProducts = new Set([
  "jive_paid_unlock",
  ...subscriptionProducts,
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

    const parsedBody = parseVerifyRequest((await req.json()) as VerifyRequest);
    if (parsedBody == null) {
      return json({ error: "invalid_payload" }, 400);
    }

    const verified = parsedBody.platform === "google_play"
      ? await verifyGooglePlayPurchase(env, parsedBody)
      : await verifyAppleAppStorePurchase(env, parsedBody);

    const now = new Date().toISOString();
    const payload = {
      user_id: user.id,
      plan: verified.plan,
      status: verified.status,
      platform: parsedBody.platform,
      product_id: verified.product_id ?? parsedBody.product_id,
      purchase_token: verified.purchase_token,
      order_id: parsedBody.order_id ?? verified.order_id,
      entitlement_tier: verified.entitlement_tier,
      expires_at: verified.expires_at,
      last_verified_at: now,
      verification_source: verified.verification_source,
      receipt_data: verified.receipt_data,
      raw_response: verified.raw_response,
      updated_at: now,
    };

    const upsert = adminClient.from("user_subscriptions").upsert(
      payload,
      verified.purchase_token == null
        ? undefined
        : { onConflict: "platform,purchase_token" },
    );

    const { data, error } = await upsert.select().single();

    if (error != null) {
      console.error("verify-subscription upsert failed", error);
      return json({ error: "subscription_upsert_failed" }, 500);
    }

    return json({ verified: true, subscription: data }, 200);
  } catch (error) {
    console.error("verify-subscription unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      500,
    );
  }
}

function parseVerifyRequest(
  body: VerifyRequest,
): GoogleVerifyRequest | AppleVerifyRequest | null {
  const platform = normalizeNonEmptyString(body.platform);
  const productId = normalizeNonEmptyString(body.product_id);
  if (platform == null || productId == null) {
    return null;
  }

  if (platform === "google_play") {
    const purchaseToken = normalizeNonEmptyString(body.purchase_token);
    if (purchaseToken == null) {
      return null;
    }

    return {
      platform,
      product_id: productId,
      purchase_token: purchaseToken,
      order_id: normalizeNonEmptyString(body.order_id) ?? undefined,
      transaction_date_ms: normalizeNonEmptyString(body.transaction_date_ms) ??
        undefined,
    };
  }

  if (platform === "apple_app_store") {
    const receiptData = normalizeNonEmptyString(body.receipt_data);
    if (receiptData == null) {
      return null;
    }

    return {
      platform,
      product_id: productId,
      receipt_data: receiptData,
      order_id: normalizeNonEmptyString(body.order_id) ?? undefined,
    };
  }

  return null;
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
    googleServiceAccountEmail: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_EMAIL"),
    googleServiceAccountPrivateKey: Deno.env.get(
      "GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY",
    )?.replace(/\\n/g, "\n"),
    googlePlayPackageName: Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME"),
    appleAppStoreBundleId: Deno.env.get("APPLE_APP_STORE_BUNDLE_ID"),
    appleAppStoreSharedSecret: Deno.env.get("APPLE_APP_STORE_SHARED_SECRET"),
  };
}

async function verifyGooglePlayPurchase(
  env: ReturnType<typeof readEnv>,
  body: GoogleVerifyRequest,
): Promise<VerifiedSubscription> {
  if (
    env.googleServiceAccountEmail == null ||
    env.googleServiceAccountPrivateKey == null ||
    env.googlePlayPackageName == null
  ) {
    throw new Error("google_play_verification_not_configured");
  }

  const accessToken = await fetchGoogleAccessToken(env);
  const verified = subscriptionProducts.has(body.product_id)
    ? await verifyGoogleSubscription(
      accessToken,
      env.googlePlayPackageName,
      body,
    )
    : await verifyGoogleProduct(accessToken, env.googlePlayPackageName, body);

  return {
    ...verified,
    product_id: body.product_id,
    purchase_token: body.purchase_token,
    verification_source: "google_play_api",
    receipt_data: {
      product_id: body.product_id,
      purchase_token: body.purchase_token,
      order_id: body.order_id ?? null,
      transaction_date_ms: body.transaction_date_ms ?? null,
    },
  };
}

async function verifyAppleAppStorePurchase(
  env: ReturnType<typeof readEnv>,
  body: AppleVerifyRequest,
): Promise<VerifiedSubscription> {
  const sharedSecret = env.appleAppStoreSharedSecret;
  if (subscriptionProducts.has(body.product_id) && sharedSecret == null) {
    throw new Error("apple_app_store_verification_not_configured");
  }

  let response = await postAppleVerifyReceipt(
    appleVerifyReceiptProductionUrl,
    body.receipt_data,
    sharedSecret,
  );
  let status = Number(response.status ?? -1);
  if (status === 21007) {
    response = await postAppleVerifyReceipt(
      appleVerifyReceiptSandboxUrl,
      body.receipt_data,
      sharedSecret,
    );
    status = Number(response.status ?? -1);
  } else if (status === 21008) {
    response = await postAppleVerifyReceipt(
      appleVerifyReceiptProductionUrl,
      body.receipt_data,
      sharedSecret,
    );
    status = Number(response.status ?? -1);
  }

  if (status !== 0 && status !== 21006) {
    throw new Error(`apple_receipt_verify_failed:${status}`);
  }

  const bundleId = normalizeNonEmptyString(response.receipt?.bundle_id);
  if (
    env.appleAppStoreBundleId != null &&
    bundleId != null &&
    bundleId !== env.appleAppStoreBundleId
  ) {
    throw new Error("apple_receipt_bundle_id_mismatch");
  }

  const transaction = pickLatestAppleTransaction(response, body.product_id);
  if (transaction == null) {
    throw new Error("apple_receipt_product_not_found");
  }

  return buildAppleVerifiedSubscription(response, transaction);
}

async function fetchGoogleAccessToken(
  env: ReturnType<typeof readEnv>,
): Promise<string> {
  const jwt = await createGoogleJwt(
    env.googleServiceAccountEmail!,
    env.googleServiceAccountPrivateKey!,
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    throw new Error(`google_access_token_failed:${response.status}`);
  }

  const data = await response.json();
  const accessToken = data.access_token;
  if (typeof accessToken !== "string" || accessToken.length === 0) {
    throw new Error("google_access_token_missing");
  }
  return accessToken;
}

async function verifyGoogleSubscription(
  accessToken: string,
  packageName: string,
  body: GoogleVerifyRequest,
): Promise<
  Omit<
    VerifiedSubscription,
    "product_id" | "purchase_token" | "verification_source" | "receipt_data"
  >
> {
  const endpoint =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${body.purchase_token}`;
  const response = await fetch(endpoint, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) {
    throw new Error(`google_subscription_verify_failed:${response.status}`);
  }

  const data = await response.json();
  const state = String(data.subscriptionState ?? "SUBSCRIPTION_STATE_EXPIRED");
  const lineItem = Array.isArray(data.lineItems) ? data.lineItems[0] : null;
  const expiryTime = lineItem != null && typeof lineItem.expiryTime == "string"
    ? lineItem.expiryTime
    : null;

  const status = mapGoogleSubscriptionStatus(state);
  return {
    plan: "subscriber",
    status,
    entitlement_tier: status === "active" || status === "grace"
      ? "subscriber"
      : "free",
    expires_at: expiryTime,
    order_id: typeof data.latestOrderId == "string" ? data.latestOrderId : null,
    raw_response: asJsonObject(data),
  };
}

async function verifyGoogleProduct(
  accessToken: string,
  packageName: string,
  body: GoogleVerifyRequest,
): Promise<
  Omit<
    VerifiedSubscription,
    "product_id" | "purchase_token" | "verification_source" | "receipt_data"
  >
> {
  const endpoint =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${body.product_id}/tokens/${body.purchase_token}`;
  const response = await fetch(endpoint, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) {
    throw new Error(`google_product_verify_failed:${response.status}`);
  }

  const data = await response.json();
  const purchaseState = Number(data.purchaseState ?? 1);
  const status = purchaseState === 0 ? "active" : "canceled";

  return {
    plan: "paid",
    status,
    entitlement_tier: status === "active" ? "paid" : "free",
    expires_at: null,
    order_id: typeof data.orderId == "string" ? data.orderId : null,
    raw_response: asJsonObject(data),
  };
}

async function postAppleVerifyReceipt(
  url: string,
  receiptData: string,
  sharedSecret?: string,
): Promise<AppleVerifyReceiptResponse> {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receiptData,
      if (sharedSecret != null) password: sharedSecret,
      "exclude-old-transactions": false,
    }),
  });

  if (!response.ok) {
    throw new Error(`apple_verify_receipt_http_failed:${response.status}`);
  }

  return asAppleVerifyReceiptResponse(await response.json());
}

export function pickLatestAppleTransaction(
  response: AppleVerifyReceiptResponse,
  productId: string,
): AppleReceiptTransaction | null {
  const candidates = [
    ...(Array.isArray(response.latest_receipt_info)
      ? response.latest_receipt_info
      : []),
    ...(Array.isArray(response.latest_expired_receipt_info)
      ? response.latest_expired_receipt_info
      : []),
    ...(Array.isArray(response.receipt?.in_app)
      ? response.receipt!.in_app!
      : []),
  ].filter((transaction) =>
    normalizeNonEmptyString(transaction.product_id) === productId
  );

  if (candidates.length === 0) {
    return null;
  }

  candidates.sort((left, right) => {
    return appleTransactionSortKey(right) - appleTransactionSortKey(left);
  });
  return candidates[0];
}

export function buildAppleVerifiedSubscription(
  response: AppleVerifyReceiptResponse,
  transaction: AppleReceiptTransaction,
): VerifiedSubscription {
  const productId = normalizeNonEmptyString(transaction.product_id);
  if (productId == null || !supportedProducts.has(productId)) {
    throw new Error("unsupported_apple_product");
  }

  const plan = subscriptionProducts.has(productId) ? "subscriber" : "paid";
  const renewalInfo = pickApplePendingRenewalInfo(
    response,
    normalizeNonEmptyString(transaction.original_transaction_id),
    productId,
  );
  const status = mapAppleReceiptStatus(plan, transaction, renewalInfo);
  const purchaseToken = normalizeNonEmptyString(
    transaction.original_transaction_id,
  ) ?? normalizeNonEmptyString(transaction.transaction_id);
  const orderId = normalizeNonEmptyString(transaction.transaction_id);

  return {
    plan,
    status,
    entitlement_tier: status === "active" || status === "grace"
      ? plan === "subscriber" ? "subscriber" : "paid"
      : "free",
    product_id: productId,
    purchase_token: purchaseToken,
    order_id: orderId,
    expires_at: parseAppleMsToIso(transaction.expires_date_ms),
    verification_source: "apple_verify_receipt",
    receipt_data: {
      product_id: productId,
      order_id: orderId,
      original_transaction_id: purchaseToken,
      environment: normalizeNonEmptyString(response.environment),
      bundle_id: normalizeNonEmptyString(response.receipt?.bundle_id),
      grace_period_expires_at: parseAppleMsToIso(
        renewalInfo?.grace_period_expires_date_ms,
      ),
    },
    raw_response: asJsonObject(response),
  };
}

function pickApplePendingRenewalInfo(
  response: AppleVerifyReceiptResponse,
  originalTransactionId: string | null,
  productId: string,
): ApplePendingRenewalInfo | null {
  const infos = Array.isArray(response.pending_renewal_info)
    ? response.pending_renewal_info
    : [];
  for (const info of infos) {
    const infoOriginalTransactionId = normalizeNonEmptyString(
      info.original_transaction_id,
    );
    if (
      originalTransactionId != null &&
      infoOriginalTransactionId === originalTransactionId
    ) {
      return info;
    }

    const infoProductId = normalizeNonEmptyString(
      info.auto_renew_product_id ?? info.product_id,
    );
    if (infoProductId === productId) {
      return info;
    }
  }

  return null;
}

export function mapAppleReceiptStatus(
  plan: VerifiedSubscription["plan"],
  transaction: AppleReceiptTransaction,
  renewalInfo: ApplePendingRenewalInfo | null,
  nowMs = Date.now(),
): VerifiedSubscription["status"] {
  if (normalizeNonEmptyString(transaction.cancellation_date_ms) != null) {
    return "revoked";
  }

  if (plan === "paid") {
    return "active";
  }

  const graceMs = parseAppleMs(renewalInfo?.grace_period_expires_date_ms);
  if (graceMs != null && graceMs > nowMs) {
    return "grace";
  }

  const expiryMs = parseAppleMs(transaction.expires_date_ms);
  if (expiryMs != null && expiryMs > nowMs) {
    return "active";
  }

  if (renewalInfo?.is_in_billing_retry_period === "1") {
    return "grace";
  }

  return "expired";
}

function mapGoogleSubscriptionStatus(
  state: string,
): VerifiedSubscription["status"] {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
      return "active";
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
    case "SUBSCRIPTION_STATE_ON_HOLD":
    case "SUBSCRIPTION_STATE_PAUSED":
      return "grace";
    case "SUBSCRIPTION_STATE_PENDING":
      return "pending";
    case "SUBSCRIPTION_STATE_CANCELED":
      return "canceled";
    case "SUBSCRIPTION_STATE_EXPIRED":
      return "expired";
    default:
      return "revoked";
  }
}

function appleTransactionSortKey(transaction: AppleReceiptTransaction): number {
  return parseAppleMs(transaction.expires_date_ms) ??
    parseAppleMs(transaction.purchase_date_ms) ?? 0;
}

function parseAppleMs(value: string | undefined): number | null {
  if (value == null || value.length === 0) {
    return null;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function parseAppleMsToIso(value: string | undefined): string | null {
  const parsed = parseAppleMs(value);
  return parsed == null ? null : new Date(parsed).toISOString();
}

function asAppleVerifyReceiptResponse(
  value: unknown,
): AppleVerifyReceiptResponse {
  return value != null && typeof value === "object"
    ? value as AppleVerifyReceiptResponse
    : {};
}

function asJsonObject(value: unknown): Record<string, unknown> {
  return value != null && typeof value === "object"
    ? value as Record<string, unknown>
    : {};
}

function normalizeNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

async function createGoogleJwt(
  serviceAccountEmail: string,
  privateKeyPem: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: serviceAccountEmail,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaims = base64UrlEncode(JSON.stringify(claims));
  const unsigned = `${encodedHeader}.${encodedClaims}`;

  const privateKey = await importPrivateKey(privateKeyPem);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsigned),
  );

  return `${unsigned}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binary = Uint8Array.from(atob(cleaned), (char) => char.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    binary.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
}

function base64UrlEncode(value: string): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(value));
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  const binary = Array.from(bytes, (byte) => String.fromCharCode(byte)).join(
    "",
  );
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll(
    "=",
    "",
  );
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
