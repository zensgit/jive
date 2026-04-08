import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type UserSubscriptionRow = {
  user_id: string;
  plan: "free" | "paid" | "subscriber";
  status:
    | "active"
    | "grace"
    | "pending"
    | "canceled"
    | "expired"
    | "revoked";
  platform: string;
  entitlement_tier: "free" | "paid" | "subscriber";
  expires_at: string | null;
  updated_at: string;
  verification_source: string | null;
};

type AdminUserSummary = {
  user_id: string;
  email: string | null;
  phone: string | null;
  created_at: string | null;
  last_sign_in_at: string | null;
  latest_subscription: UserSubscriptionRow | null;
};

type SetTierRequest = {
  action: "set_tier";
  user_id?: string;
  plan?: "free" | "paid" | "subscriber";
  status?:
    | "active"
    | "grace"
    | "pending"
    | "canceled"
    | "expired"
    | "revoked";
  expires_at?: string | null;
};

type ClearOverrideRequest = {
  action: "clear_override";
  user_id?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

if (import.meta.main) {
  Deno.serve(handleRequest);
}

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const env = readEnv();
    assertAdminAuthorized(req, env);
    const adminClient = createClient(
      env.supabaseUrl,
      env.supabaseServiceRoleKey,
    );

    if (req.method === "GET") {
      return await handleGetRequest(req, adminClient);
    }

    if (req.method === "POST") {
      return await handlePostRequest(req, adminClient);
    }

    return json({ error: "method_not_allowed" }, 405);
  } catch (error) {
    console.error("admin api unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      error instanceof HttpError ? error.status : 500,
    );
  }
}

async function handleGetRequest(
  req: Request,
  adminClient: any,
): Promise<Response> {
  const url = new URL(req.url);
  const action = url.searchParams.get("action") ?? "summary";

  switch (action) {
    case "summary":
      return json(await buildSummary(adminClient), 200);
    case "users":
      return json(await listUsers(adminClient, url), 200);
    case "user":
      return json(await getUserDetail(adminClient, url), 200);
    default:
      throw new HttpError(400, "unsupported_action");
  }
}

async function handlePostRequest(
  req: Request,
  adminClient: any,
): Promise<Response> {
  const body = (await req.json()) as SetTierRequest | ClearOverrideRequest;
  switch (body.action) {
    case "set_tier":
      return json(await setTierOverride(adminClient, body), 200);
    case "clear_override":
      return json(await clearTierOverride(adminClient, body), 200);
    default:
      throw new HttpError(400, "unsupported_action");
  }
}

async function buildSummary(adminClient: any) {
  const users = await listAllAuthUsers(adminClient, 500);
  const subscriptions = await fetchSubscriptions(adminClient);
  const latestByUser = latestSubscriptionByUser(subscriptions);

  let activePaid = 0;
  let activeSubscribers = 0;
  let overrides = 0;
  let expired = 0;

  for (const subscription of latestByUser.values()) {
    if (subscription.platform === "admin_override") {
      overrides += 1;
    }
    if (
      subscription.status === "expired" || subscription.status === "revoked"
    ) {
      expired += 1;
    }
    if (
      (subscription.status === "active" || subscription.status === "grace") &&
      subscription.entitlement_tier === "paid"
    ) {
      activePaid += 1;
    }
    if (
      (subscription.status === "active" || subscription.status === "grace") &&
      subscription.entitlement_tier === "subscriber"
    ) {
      activeSubscribers += 1;
    }
  }

  const recentSignups7d = users.filter((user) => {
    const createdAt = typeof user.created_at === "string"
      ? new Date(user.created_at)
      : null;
    if (createdAt == null || Number.isNaN(createdAt.getTime())) return false;
    return createdAt.getTime() >= Date.now() - 7 * 24 * 60 * 60 * 1000;
  }).length;

  return {
    users: {
      total: users.length,
      recent_signups_7d: recentSignups7d,
    },
    subscriptions: {
      active_paid: activePaid,
      active_subscribers: activeSubscribers,
      expired_or_revoked: expired,
      admin_overrides: overrides,
    },
  };
}

async function listUsers(adminClient: any, url: URL) {
  const limit = clampNumber(url.searchParams.get("limit"), 20, 1, 100);
  const offset = clampNumber(url.searchParams.get("offset"), 0, 0, 10000);
  const query = normalizeQuery(url.searchParams.get("query"));

  const users = await listAllAuthUsers(adminClient, 1000);
  const subscriptions = await fetchSubscriptions(adminClient);
  const latestByUser = latestSubscriptionByUser(subscriptions);

  const filtered = users
    .filter((user) => matchesUserQuery(user, query))
    .sort((a, b) => {
      const left = String(a.created_at ?? "");
      const right = String(b.created_at ?? "");
      return right.localeCompare(left);
    });

  const page = filtered.slice(offset, offset + limit).map((user) =>
    summarizeAuthUser(user, latestByUser)
  );

  return {
    total: filtered.length,
    limit,
    offset,
    users: page,
  };
}

async function getUserDetail(adminClient: any, url: URL) {
  const userId = normalizeQuery(url.searchParams.get("user_id"));
  if (userId == null) {
    throw new HttpError(400, "user_id_required");
  }

  const { data, error } = await adminClient.auth.admin.getUserById(userId);
  if (error != null || data.user == null) {
    throw new HttpError(404, "user_not_found");
  }

  const rows = await fetchSubscriptions(adminClient, userId);
  return {
    user: data.user,
    subscriptions: rows,
  };
}

async function setTierOverride(adminClient: any, body: SetTierRequest) {
  const userId = normalizeQuery(body.user_id);
  if (userId == null) {
    throw new HttpError(400, "user_id_required");
  }

  const plan = body.plan ?? "free";
  const status = body.status ?? (plan == "free" ? "expired" : "active");
  const now = new Date().toISOString();
  const expiresAt = normalizeNullableDate(body.expires_at);

  const payload = {
    user_id: userId,
    plan,
    status,
    platform: "admin_override",
    product_id: null,
    purchase_token: null,
    order_id: null,
    entitlement_tier: plan,
    expires_at: expiresAt,
    last_verified_at: now,
    verification_source: "admin_api",
    receipt_data: {
      source: "admin_api",
      override: true,
    },
    raw_response: {
      source: "admin_api",
      updated_at: now,
    },
    updated_at: now,
  };

  const { data, error } = await adminClient
    .from("user_subscriptions")
    .upsert(payload, {
      onConflict: "user_id,platform",
    })
    .select()
    .single();

  if (error != null) {
    console.error("admin set_tier upsert failed", error);
    throw new HttpError(500, "set_tier_failed");
  }

  return {
    updated: true,
    subscription: data,
  };
}

async function clearTierOverride(adminClient: any, body: ClearOverrideRequest) {
  const userId = normalizeQuery(body.user_id);
  if (userId == null) {
    throw new HttpError(400, "user_id_required");
  }

  const { error } = await adminClient
    .from("user_subscriptions")
    .delete()
    .eq("user_id", userId)
    .eq("platform", "admin_override");

  if (error != null) {
    console.error("admin clear_override failed", error);
    throw new HttpError(500, "clear_override_failed");
  }

  return {
    cleared: true,
    user_id: userId,
  };
}

async function fetchSubscriptions(adminClient: any, userId?: string) {
  let query = adminClient
    .from("user_subscriptions")
    .select(
      "user_id,plan,status,platform,entitlement_tier,expires_at,updated_at,verification_source",
    )
    .order("updated_at", { ascending: false });

  if (userId != null) {
    query = query.eq("user_id", userId);
  }

  const { data, error } = await query;
  if (error != null) {
    console.error("admin fetchSubscriptions failed", error);
    throw new HttpError(500, "subscription_query_failed");
  }

  return ((data ?? []) as UserSubscriptionRow[]);
}

async function listAllAuthUsers(adminClient: any, pageSize: number) {
  const users: any[] = [];
  let page = 1;

  while (true) {
    const { data, error } = await adminClient.auth.admin.listUsers({
      page,
      perPage: pageSize,
    });
    if (error != null) {
      console.error("admin listUsers failed", error);
      throw new HttpError(500, "auth_user_query_failed");
    }

    const batch = Array.isArray(data?.users) ? data.users : [];
    users.push(...batch);
    if (batch.length < pageSize) {
      break;
    }
    page += 1;
  }

  return users;
}

export function latestSubscriptionByUser(
  rows: UserSubscriptionRow[],
): Map<string, UserSubscriptionRow> {
  const latest = new Map<string, UserSubscriptionRow>();
  for (const row of rows) {
    if (!latest.has(row.user_id)) {
      latest.set(row.user_id, row);
    }
  }
  return latest;
}

function summarizeAuthUser(
  user: any,
  latestByUser: Map<string, UserSubscriptionRow>,
): AdminUserSummary {
  return {
    user_id: String(user.id),
    email: typeof user.email === "string" ? user.email : null,
    phone: typeof user.phone === "string" ? user.phone : null,
    created_at: typeof user.created_at === "string" ? user.created_at : null,
    last_sign_in_at: typeof user.last_sign_in_at === "string"
      ? user.last_sign_in_at
      : null,
    latest_subscription: latestByUser.get(String(user.id)) ?? null,
  };
}

function matchesUserQuery(user: any, query: string | null): boolean {
  if (query == null) return true;
  const fields = [
    user.id,
    user.email,
    user.phone,
    user.user_metadata?.display_name,
  ]
    .filter((value) => typeof value === "string")
    .map((value) => String(value).toLowerCase());
  return fields.some((field) => field.includes(query));
}

function clampNumber(
  raw: string | null,
  fallback: number,
  min: number,
  max: number,
): number {
  const parsed = Number(raw);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(Math.max(Math.trunc(parsed), min), max);
}

function normalizeQuery(value: string | null | undefined): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length == 0 ? null : trimmed.toLowerCase();
}

function normalizeNullableDate(
  value: string | null | undefined,
): string | null {
  if (value == null) return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpError(400, "invalid_expires_at");
  }
  return parsed.toISOString();
}

function assertAdminAuthorized(req: Request, env: ReturnType<typeof readEnv>) {
  const authHeader = req.headers.get("Authorization");
  const bearer = authHeader?.replace(/^Bearer\s+/i, "").trim();
  if (env.adminApiToken == null || env.adminApiToken.length === 0) {
    throw new HttpError(503, "admin_api_token_not_configured");
  }
  if (bearer == null || bearer !== env.adminApiToken) {
    throw new HttpError(401, "admin_auth_required");
  }
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
    adminApiToken: Deno.env.get("ADMIN_API_TOKEN"),
  };
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
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
