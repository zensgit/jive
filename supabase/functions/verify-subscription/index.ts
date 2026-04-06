import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type VerifyRequest = {
  platform?: string;
  product_id?: string;
  purchase_token?: string;
  order_id?: string;
  transaction_date_ms?: string;
};

type VerifiedSubscription = {
  plan: "paid" | "subscriber";
  status: "active" | "grace" | "pending" | "canceled" | "expired" | "revoked";
  entitlement_tier: "free" | "paid" | "subscriber";
  expires_at: string | null;
  order_id: string | null;
  raw_response: Record<string, unknown>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const subscriptionProducts = new Set([
  "jive_subscriber_monthly",
  "jive_subscriber_yearly",
]);

Deno.serve(async (req) => {
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

    const body = (await req.json()) as VerifyRequest;
    if (
      body.platform !== "google_play" ||
      body.product_id == null ||
      body.product_id.length === 0 ||
      body.purchase_token == null ||
      body.purchase_token.length === 0
    ) {
      return json({ error: "invalid_payload" }, 400);
    }

    if (
      env.googleServiceAccountEmail == null ||
      env.googleServiceAccountPrivateKey == null ||
      env.googlePlayPackageName == null
    ) {
      return json({ error: "google_play_verification_not_configured" }, 503);
    }

    const accessToken = await fetchGoogleAccessToken(env);
    const verified = subscriptionProducts.has(body.product_id)
      ? await verifyGoogleSubscription(accessToken, env.googlePlayPackageName, body)
      : await verifyGoogleProduct(accessToken, env.googlePlayPackageName, body);

    const now = new Date().toISOString();
    const payload = {
      user_id: user.id,
      plan: verified.plan,
      status: verified.status,
      platform: "google_play",
      product_id: body.product_id,
      purchase_token: body.purchase_token,
      order_id: body.order_id ?? verified.order_id,
      entitlement_tier: verified.entitlement_tier,
      expires_at: verified.expires_at,
      last_verified_at: now,
      verification_source: "google_play_api",
      receipt_data: {
        product_id: body.product_id,
        purchase_token: body.purchase_token,
        order_id: body.order_id,
        transaction_date_ms: body.transaction_date_ms,
      },
      raw_response: verified.raw_response,
      updated_at: now,
    };

    const { data, error } = await adminClient
      .from("user_subscriptions")
      .upsert(payload, { onConflict: "platform,purchase_token" })
      .select()
      .single();

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
});

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
  body: VerifyRequest,
): Promise<VerifiedSubscription> {
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
  const expiryTime =
    lineItem != null && typeof lineItem.expiryTime == "string"
      ? lineItem.expiryTime
      : null;

  const status = mapSubscriptionStatus(state);
  return {
    plan: "subscriber",
    status,
    entitlement_tier:
      status === "active" || status === "grace" ? "subscriber" : "free",
    expires_at: expiryTime,
    order_id: typeof data.latestOrderId == "string" ? data.latestOrderId : null,
    raw_response: data,
  };
}

async function verifyGoogleProduct(
  accessToken: string,
  packageName: string,
  body: VerifyRequest,
): Promise<VerifiedSubscription> {
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
    raw_response: data,
  };
}

function mapSubscriptionStatus(state: string): VerifiedSubscription["status"] {
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
