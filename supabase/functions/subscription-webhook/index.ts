import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type SubscriptionStatus =
  | "active"
  | "grace"
  | "pending"
  | "canceled"
  | "expired"
  | "revoked";

type EntitlementTier = "free" | "paid" | "subscriber";

type PubSubPushPayload = {
  message: {
    data: string;
    messageId: string;
    publishTime: string | null;
    attributes: Record<string, string>;
  };
  subscription: string | null;
};

type DeveloperNotification = {
  version?: string;
  packageName?: string;
  eventTimeMillis?: string;
  subscriptionNotification?: {
    version?: string;
    notificationType?: number;
    purchaseToken?: string;
    subscriptionId?: string;
  };
  testNotification?: Record<string, unknown>;
};

type AppleAppStoreServerNotificationV2Request = {
  signedPayload: string;
};

type UserSubscriptionRow = {
  id: number;
  plan: string;
  product_id: string | null;
  order_id: string | null;
  expires_at: string | null;
  receipt_data: Record<string, unknown> | null;
  raw_response: Record<string, unknown> | null;
};

type GoogleSubscriptionLookup = {
  productId: string | null;
  orderId: string | null;
  expiresAt: string | null;
  rawResponse: Record<string, unknown>;
};

type IdempotencyClaim =
  | { state: "claimed" }
  | { state: "duplicate" }
  | { state: "in_progress" };

type WebhookEnv = ReturnType<typeof readEnv>;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-jive-signature, x-signature, x-hub-signature-256",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const handledGoogleNotificationTypes = new Set([1, 2, 3, 4, 5, 6, 7, 12, 13]);
const processingClaimTtlMs = 15 * 60 * 1000;

let cachedEnv: WebhookEnv | null = null;
let cachedAdminClient: ReturnType<typeof createClient> | null = null;

if (import.meta.main) {
  Deno.serve(handleRequest);
}

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const env = getEnv();
    const adminClient = getAdminClient(env);
    const rawBody = await req.text();
    await validateIncomingRequest(req, rawBody, env);

    const body = parseJson<unknown>(rawBody);
    if (looksLikeAppleAppStoreServerNotificationV2(body)) {
      return await handleAppleAppStoreServerNotificationV2(body);
    }

    return await handleGooglePlayRtdn(body, env, adminClient);
  } catch (error) {
    console.error("subscription-webhook unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      error instanceof HttpError ? error.status : 500,
    );
  }
}

async function handleGooglePlayRtdn(
  body: unknown,
  env: WebhookEnv,
  adminClient: ReturnType<typeof createClient>,
): Promise<Response> {
  const pushPayload = parsePubSubPushPayload(body);
  const notificationId = pushPayload.message.messageId;
  const claim = await claimNotification(
    adminClient,
    notificationId,
    "google_play",
    "google_pubsub_push",
    asJsonObject(body),
  );

  if (claim.state === "duplicate") {
    return json({
      received: true,
      duplicate: true,
      notification_id: notificationId,
    });
  }

  if (claim.state === "in_progress") {
    return json({
      received: true,
      duplicate: true,
      notification_id: notificationId,
      status: "processing",
    }, 202);
  }

  try {
    const developerNotification = decodeDeveloperNotification(
      pushPayload.message.data,
    );

    if (
      env.googlePlayPackageName != null &&
      developerNotification.packageName != null &&
      developerNotification.packageName !== env.googlePlayPackageName
    ) {
      throw new HttpError(400, "unexpected_package_name");
    }

    if (developerNotification.testNotification != null) {
      await markNotificationProcessed(adminClient, notificationId);
      return json({
        received: true,
        provider: "google_play",
        notification_id: notificationId,
        test: true,
      });
    }

    const subscriptionNotification = developerNotification.subscriptionNotification;
    if (subscriptionNotification == null) {
      await markNotificationProcessed(adminClient, notificationId);
      return json({
        received: true,
        provider: "google_play",
        notification_id: notificationId,
        ignored: true,
        reason: "unsupported_notification_kind",
      }, 202);
    }

    const notificationType = Number(subscriptionNotification.notificationType);
    const purchaseToken = subscriptionNotification.purchaseToken?.trim();
    if (!Number.isInteger(notificationType) || purchaseToken == null || purchaseToken.length === 0) {
      throw new HttpError(400, "invalid_subscription_notification");
    }

    if (!handledGoogleNotificationTypes.has(notificationType)) {
      await markNotificationProcessed(adminClient, notificationId);
      return json({
        received: true,
        provider: "google_play",
        notification_id: notificationId,
        ignored: true,
        reason: "unsupported_notification_type",
        notification_type: notificationType,
      }, 202);
    }

    const subscription = await findSubscriptionByPurchaseToken(
      adminClient,
      purchaseToken,
    );
    if (subscription == null) {
      throw new HttpError(404, "subscription_not_found");
    }

    let googleLookup: GoogleSubscriptionLookup | null = null;
    try {
      googleLookup = await maybeFetchGoogleSubscription(env, purchaseToken);
    } catch (error) {
      console.error("subscription-webhook google lookup failed", error);
    }

    const status = mapGoogleNotificationType(notificationType);
    const expiresAt = googleLookup?.expiresAt ?? subscription.expires_at ?? null;
    const now = new Date().toISOString();
    const receiptData = mergeJsonObject(subscription.receipt_data, {
      last_webhook: {
        provider: "google_play",
        notification_id: notificationId,
        notification_type: notificationType,
        notification_name: googleNotificationTypeName(notificationType),
        purchase_token: purchaseToken,
        event_time_millis: developerNotification.eventTimeMillis ?? null,
        pubsub_publish_time: pushPayload.message.publishTime,
        received_at: now,
      },
    });
    const rawResponse = mergeJsonObject(subscription.raw_response, {
      google_rtdn: {
        developer_notification: developerNotification,
        pubsub_message: pushPayload.message,
        google_api: googleLookup?.rawResponse ?? null,
      },
    });

    const nextPlan = deriveWebhookPlan(subscription.plan);
    const { data, error } = await adminClient
      .from("user_subscriptions")
      .update({
        plan: nextPlan,
        status,
        product_id:
          googleLookup?.productId ??
            subscriptionNotification.subscriptionId ??
            subscription.product_id,
        order_id: googleLookup?.orderId ?? subscription.order_id,
        entitlement_tier: deriveEntitlementTier(nextPlan, status, expiresAt),
        expires_at: expiresAt,
        last_verified_at: now,
        verification_source: googleLookup == null
          ? "google_rtdn"
          : "google_rtdn_api",
        receipt_data: receiptData,
        raw_response: rawResponse,
        updated_at: now,
      })
      .eq("id", subscription.id)
      .select()
      .single();

    if (error != null) {
      console.error("subscription-webhook update failed", error);
      throw new HttpError(500, "subscription_update_failed");
    }

    await markNotificationProcessed(adminClient, notificationId);
    return json({
      received: true,
      provider: "google_play",
      duplicate: false,
      notification_id: notificationId,
      notification_type: notificationType,
      subscription: data,
    });
  } catch (error) {
    await markNotificationFailed(
      adminClient,
      notificationId,
      error instanceof Error ? error.message : "unknown_error",
    );
    throw error;
  }
}

async function handleAppleAppStoreServerNotificationV2(
  _body: AppleAppStoreServerNotificationV2Request,
): Promise<Response> {
  // TODO: Verify the signedPayload JWS with Apple's App Store Server API keys.
  // TODO: Decode notificationUUID and use it for the idempotency table.
  // TODO: Map notificationType/subtype into user_subscriptions updates.
  console.warn("subscription-webhook apple handler is not implemented");

  return json({
    received: true,
    provider: "apple_app_store",
    handled: false,
    reason: "not_implemented",
  }, 202);
}

function readEnv() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseServiceRoleKey) {
    throw new Error("supabase_function_env_missing");
  }

  return {
    supabaseUrl,
    supabaseServiceRoleKey,
    googleServiceAccountEmail: Deno.env.get("GOOGLE_SERVICE_ACCOUNT_EMAIL"),
    googleServiceAccountPrivateKey: Deno.env.get(
      "GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY",
    )?.replace(/\\n/g, "\n"),
    googlePlayPackageName: Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME"),
    webhookBearerToken: Deno.env.get("PUBSUB_BEARER_TOKEN"),
    webhookHmacSecret: Deno.env.get("WEBHOOK_HMAC_SECRET"),
  };
}

function getEnv(): WebhookEnv {
  cachedEnv ??= readEnv();
  return cachedEnv;
}

function getAdminClient(env: WebhookEnv): ReturnType<typeof createClient> {
  cachedAdminClient ??= createClient(
    env.supabaseUrl,
    env.supabaseServiceRoleKey,
  );
  return cachedAdminClient;
}

async function validateIncomingRequest(
  req: Request,
  rawBody: string,
  env: ReturnType<typeof readEnv>,
): Promise<void> {
  if (env.webhookBearerToken == null && env.webhookHmacSecret == null) {
    throw new HttpError(503, "subscription_webhook_auth_not_configured");
  }

  const authorization = req.headers.get("authorization");
  const bearerToken = authorization?.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length).trim()
    : null;
  if (
    env.webhookBearerToken != null &&
    bearerToken != null &&
    timingSafeEqual(bearerToken, env.webhookBearerToken)
  ) {
    return;
  }

  if (env.webhookHmacSecret != null) {
    const signature = extractSignature(req.headers);
    if (signature != null) {
      const expected = await signHmacSha256(env.webhookHmacSecret, rawBody);
      if (timingSafeEqual(signature.toLowerCase(), expected)) {
        return;
      }
    }
  }

  throw new HttpError(401, "invalid_webhook_signature");
}

function parsePubSubPushPayload(body: unknown): PubSubPushPayload {
  const root = asRecord(body);
  const message = asRecord(root.message);
  const data = message.data;
  const messageId = message.messageId;

  if (typeof data !== "string" || data.length === 0) {
    throw new HttpError(400, "missing_pubsub_data");
  }

  if (typeof messageId !== "string" || messageId.length === 0) {
    throw new HttpError(400, "missing_pubsub_message_id");
  }

  return {
    message: {
      data,
      messageId,
      publishTime: typeof message.publishTime === "string"
        ? message.publishTime
        : null,
      attributes: stringRecord(message.attributes),
    },
    subscription: typeof root.subscription === "string" ? root.subscription : null,
  };
}

function decodeDeveloperNotification(data: string): DeveloperNotification {
  const decoded = decodeBase64(data);
  return parseJson<DeveloperNotification>(decoded);
}

async function findSubscriptionByPurchaseToken(
  adminClient: ReturnType<typeof createClient>,
  purchaseToken: string,
): Promise<UserSubscriptionRow | null> {
  const { data, error } = await adminClient
    .from("user_subscriptions")
    .select("id, plan, product_id, order_id, expires_at, receipt_data, raw_response")
    .eq("platform", "google_play")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();

  if (error != null) {
    console.error("subscription-webhook select failed", error);
    throw new HttpError(500, "subscription_lookup_failed");
  }

  return data as UserSubscriptionRow | null;
}

async function maybeFetchGoogleSubscription(
  env: ReturnType<typeof readEnv>,
  purchaseToken: string,
): Promise<GoogleSubscriptionLookup | null> {
  if (
    env.googleServiceAccountEmail == null ||
    env.googleServiceAccountPrivateKey == null ||
    env.googlePlayPackageName == null
  ) {
    return null;
  }

  const accessToken = await fetchGoogleAccessToken(env);
  const endpoint =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${env.googlePlayPackageName}/purchases/subscriptionsv2/tokens/${purchaseToken}`;
  const response = await fetch(endpoint, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    throw new Error(`google_subscription_lookup_failed:${response.status}`);
  }

  const data = asJsonObject(await response.json());
  const lineItem = Array.isArray(data.lineItems) ? data.lineItems[0] : null;
  const lineItemRecord = isRecord(lineItem) ? lineItem : null;

  return {
    productId: lineItemRecord != null && typeof lineItemRecord.productId === "string"
      ? lineItemRecord.productId
      : null,
    orderId: typeof data.latestOrderId === "string" ? data.latestOrderId : null,
    expiresAt: lineItemRecord != null && typeof lineItemRecord.expiryTime === "string"
      ? lineItemRecord.expiryTime
      : null,
    rawResponse: data,
  };
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

  const data = asRecord(await response.json());
  const accessToken = data.access_token;
  if (typeof accessToken !== "string" || accessToken.length === 0) {
    throw new Error("google_access_token_missing");
  }

  return accessToken;
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

async function claimNotification(
  adminClient: ReturnType<typeof createClient>,
  notificationId: string,
  provider: "google_play" | "apple_app_store",
  source: string,
  payload: Record<string, unknown>,
): Promise<IdempotencyClaim> {
  const now = new Date().toISOString();
  const { error } = await adminClient
    .from("subscription_webhook_notifications")
    .insert({
      notification_id: notificationId,
      provider,
      source,
      status: "processing",
      payload,
      last_error: null,
      processed_at: null,
      updated_at: now,
    });

  if (error == null) {
    return { state: "claimed" };
  }

  if (error.code !== "23505") {
    console.error("subscription-webhook idempotency insert failed", error);
    throw new HttpError(500, "webhook_idempotency_claim_failed");
  }

  const { data, error: existingError } = await adminClient
    .from("subscription_webhook_notifications")
    .select("status, updated_at")
    .eq("notification_id", notificationId)
    .maybeSingle();

  if (existingError != null) {
    console.error("subscription-webhook idempotency fetch failed", existingError);
    throw new HttpError(500, "webhook_idempotency_lookup_failed");
  }

  const existingStatus = data?.status;
  const updatedAt = typeof data?.updated_at === "string" ? data.updated_at : null;
  if (existingStatus === "processed") {
    return { state: "duplicate" };
  }

  if (
    existingStatus === "processing" &&
    !isClaimStale(updatedAt, now)
  ) {
    return { state: "in_progress" };
  }

  const { error: retryError } = await adminClient
    .from("subscription_webhook_notifications")
    .update({
      provider,
      source,
      status: "processing",
      payload,
      last_error: null,
      processed_at: null,
      updated_at: now,
    })
    .eq("notification_id", notificationId);

  if (retryError != null) {
    console.error("subscription-webhook idempotency retry failed", retryError);
    throw new HttpError(500, "webhook_idempotency_retry_failed");
  }

  return { state: "claimed" };
}

async function markNotificationProcessed(
  adminClient: ReturnType<typeof createClient>,
  notificationId: string,
): Promise<void> {
  const now = new Date().toISOString();
  const { error } = await adminClient
    .from("subscription_webhook_notifications")
    .update({
      status: "processed",
      last_error: null,
      processed_at: now,
      updated_at: now,
    })
    .eq("notification_id", notificationId);

  if (error != null) {
    console.error("subscription-webhook processed mark failed", error);
    throw new HttpError(500, "webhook_processed_mark_failed");
  }
}

async function markNotificationFailed(
  adminClient: ReturnType<typeof createClient>,
  notificationId: string,
  errorMessage: string,
): Promise<void> {
  const { error } = await adminClient
    .from("subscription_webhook_notifications")
    .update({
      status: "failed",
      last_error: errorMessage,
      updated_at: new Date().toISOString(),
    })
    .eq("notification_id", notificationId);

  if (error != null) {
    console.error("subscription-webhook failed mark failed", error);
  }
}

export function mapGoogleNotificationType(notificationType: number): SubscriptionStatus {
  switch (notificationType) {
    case 1:
    case 2:
    case 4:
    case 7:
      return "active";
    case 5:
    case 6:
      return "grace";
    case 3:
      return "canceled";
    case 12:
      return "revoked";
    case 13:
      return "expired";
    default:
      return "pending";
  }
}

function googleNotificationTypeName(notificationType: number): string {
  switch (notificationType) {
    case 1:
      return "recovered";
    case 2:
      return "renewed";
    case 3:
      return "canceled";
    case 4:
      return "purchased";
    case 5:
      return "on_hold";
    case 6:
      return "in_grace";
    case 7:
      return "restarted";
    case 12:
      return "revoked";
    case 13:
      return "expired";
    default:
      return "unknown";
  }
}

export function deriveEntitlementTier(
  plan: string,
  status: SubscriptionStatus,
  expiresAt: string | null,
): EntitlementTier {
  if (plan === "paid") {
    return status === "active" || status === "grace" ? "paid" : "free";
  }

  if (status === "active" || status === "grace") {
    return "subscriber";
  }

  if (status === "canceled" && expiresAt != null) {
    const expiry = Date.parse(expiresAt);
    if (!Number.isNaN(expiry) && expiry > Date.now()) {
      return "subscriber";
    }
  }

  return "free";
}

export function deriveWebhookPlan(currentPlan: string): EntitlementTier {
  return currentPlan === "paid" ? "paid" : "subscriber";
}

export function isClaimStale(updatedAt: string | null, nowIso: string): boolean {
  if (updatedAt == null) {
    return true;
  }

  const updatedAtMs = Date.parse(updatedAt);
  const nowMs = Date.parse(nowIso);
  if (Number.isNaN(updatedAtMs) || Number.isNaN(nowMs)) {
    return true;
  }

  return nowMs - updatedAtMs >= processingClaimTtlMs;
}

function looksLikeAppleAppStoreServerNotificationV2(
  value: unknown,
): value is AppleAppStoreServerNotificationV2Request {
  return isRecord(value) && typeof value.signedPayload === "string";
}

function parseJson<T>(value: string): T {
  try {
    return JSON.parse(value) as T;
  } catch {
    throw new HttpError(400, "invalid_json");
  }
}

function decodeBase64(value: string): string {
  const normalized = normalizeBase64(value);
  const binary = atob(normalized);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

function normalizeBase64(value: string): string {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padding = (4 - (normalized.length % 4)) % 4;
  return `${normalized}${"=".repeat(padding)}`;
}

function extractSignature(headers: Headers): string | null {
  const raw = headers.get("x-jive-signature") ??
    headers.get("x-signature") ??
    headers.get("x-hub-signature-256");
  if (raw == null || raw.length === 0) {
    return null;
  }

  return raw.startsWith("sha256=") ? raw.slice("sha256=".length) : raw;
}

async function signHmacSha256(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(payload),
  );

  return bytesToHex(new Uint8Array(signature));
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join(
    "",
  );
}

function timingSafeEqual(left: string, right: string): boolean {
  const leftBytes = new TextEncoder().encode(left);
  const rightBytes = new TextEncoder().encode(right);
  if (leftBytes.length !== rightBytes.length) {
    return false;
  }

  let diff = 0;
  for (let index = 0; index < leftBytes.length; index += 1) {
    diff |= leftBytes[index] ^ rightBytes[index];
  }

  return diff === 0;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asRecord(value: unknown): Record<string, unknown> {
  if (!isRecord(value)) {
    throw new HttpError(400, "invalid_payload");
  }

  return value;
}

function asJsonObject(value: unknown): Record<string, unknown> {
  return isRecord(value) ? value : {};
}

function stringRecord(value: unknown): Record<string, string> {
  if (!isRecord(value)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(value).filter((entry): entry is [string, string] =>
      typeof entry[1] === "string"
    ),
  );
}

function mergeJsonObject(
  base: Record<string, unknown> | null,
  extra: Record<string, unknown>,
): Record<string, unknown> {
  return { ...(base ?? {}), ...extra };
}

function base64UrlEncode(value: string): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(value));
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  const binary = Array.from(bytes, (byte) => String.fromCharCode(byte)).join("");
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

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}
