import {
  createClient,
  type SupabaseClient,
  type User,
} from "https://esm.sh/@supabase/supabase-js@2.49.8";

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
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Vary": "Origin",
};

if (import.meta.main) {
  Deno.serve(handleRequest);
}

export async function handleRequest(req: Request): Promise<Response> {
  const runtimeCorsHeaders = corsHeadersForOrigin(
    req.headers.get("Origin"),
    readAllowedOriginsFromEnv(),
  );

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 204,
      headers: runtimeCorsHeaders,
    });
  }

  try {
    const env = readEnv();
    assertAdminAuthorized(req, env);
    const adminClient = createClient(
      env.supabaseUrl,
      env.supabaseServiceRoleKey,
    );

    if (req.method === "GET") {
      return await handleGetRequest(req, adminClient, runtimeCorsHeaders);
    }

    if (req.method === "POST") {
      return await handlePostRequest(req, adminClient, runtimeCorsHeaders);
    }

    return json({ error: "method_not_allowed" }, 405, runtimeCorsHeaders);
  } catch (error) {
    console.error("admin api unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      error instanceof HttpError ? error.status : 500,
      runtimeCorsHeaders,
    );
  }
}

async function handleGetRequest(
  req: Request,
  adminClient: SupabaseClient,
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const url = new URL(req.url);
  const action = url.searchParams.get("action") ?? "summary";

  switch (action) {
    case "summary":
      return json(await buildSummary(adminClient), 200, corsHeaders);
    case "users":
      return json(await listUsers(adminClient, url), 200, corsHeaders);
    case "user":
      return json(await getUserDetail(adminClient, url), 200, corsHeaders);
    default:
      throw new HttpError(400, "unsupported_action");
  }
}

async function handlePostRequest(
  req: Request,
  adminClient: SupabaseClient,
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const body = await parseAdminRequestBody(req);
  switch (body.action) {
    case "set_tier":
      return json(await setTierOverride(adminClient, body), 200, corsHeaders);
    case "clear_override":
      return json(
        await clearTierOverride(adminClient, body),
        200,
        corsHeaders,
      );
    default:
      throw new HttpError(400, "unsupported_action");
  }
}

async function buildSummary(adminClient: SupabaseClient) {
  const userStats = await summarizeAuthUsers(adminClient, 500);
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

  return {
    users: {
      total: userStats.total,
      recent_signups_7d: userStats.recentSignups7d,
    },
    subscriptions: {
      active_paid: activePaid,
      active_subscribers: activeSubscribers,
      expired_or_revoked: expired,
      admin_overrides: overrides,
    },
  };
}

async function listUsers(adminClient: SupabaseClient, url: URL) {
  const limit = clampNumber(url.searchParams.get("limit"), 20, 1, 100);
  const offset = clampNumber(url.searchParams.get("offset"), 0, 0, 10000);
  const query = normalizeQuery(url.searchParams.get("query"));

  const scanned = await collectFilteredAuthUsers(adminClient, {
    limit,
    offset,
    query,
  });
  const pageUserIds = scanned.users.map((user) => String(user.id));
  const latestByUser = latestSubscriptionByUser(
    pageUserIds.length === 0
      ? []
      : await fetchSubscriptionsForUserIds(adminClient, pageUserIds),
  );
  const page = scanned.users.map((user) => summarizeAuthUser(user, latestByUser));

  return {
    total: scanned.total,
    limit,
    offset,
    users: page,
  };
}

async function getUserDetail(adminClient: SupabaseClient, url: URL) {
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

async function setTierOverride(
  adminClient: SupabaseClient,
  body: SetTierRequest,
) {
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

async function clearTierOverride(
  adminClient: SupabaseClient,
  body: ClearOverrideRequest,
) {
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

async function fetchSubscriptions(adminClient: SupabaseClient, userId?: string) {
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

async function listAllAuthUsers(adminClient: SupabaseClient, pageSize: number) {
  const users: User[] = [];
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

async function summarizeAuthUsers(adminClient: SupabaseClient, pageSize: number) {
  let total = 0;
  let recentSignups7d = 0;
  let page = 1;
  const recentThreshold = Date.now() - 7 * 24 * 60 * 60 * 1000;

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
    total += batch.length;

    for (const user of batch) {
      const createdAt = typeof user.created_at === "string"
        ? new Date(user.created_at)
        : null;
      if (createdAt == null || Number.isNaN(createdAt.getTime())) continue;
      if (createdAt.getTime() >= recentThreshold) {
        recentSignups7d += 1;
      }
    }

    if (batch.length < pageSize) {
      break;
    }
    page += 1;
  }

  return {
    total,
    recentSignups7d,
  };
}

async function collectFilteredAuthUsers(
  adminClient: SupabaseClient,
  options: {
    limit: number;
    offset: number;
    query: string | null;
  },
) {
  const keptUsers: User[] = [];
  const maxKept = options.limit + options.offset;
  let total = 0;
  let page = 1;

  while (true) {
    const { data, error } = await adminClient.auth.admin.listUsers({
      page,
      perPage: 200,
    });
    if (error != null) {
      console.error("admin listUsers failed", error);
      throw new HttpError(500, "auth_user_query_failed");
    }

    const batch = Array.isArray(data?.users) ? data.users : [];
    for (const user of batch) {
      if (!matchesUserQuery(user, options.query)) continue;
      total += 1;
      if (maxKept === 0) continue;
      keptUsers.push(user);
      keptUsers.sort(compareUsersByCreatedAtDesc);
      if (keptUsers.length > maxKept) {
        keptUsers.pop();
      }
    }

    if (batch.length < 200) {
      break;
    }
    page += 1;
  }

  return {
    total,
    users: keptUsers.slice(options.offset, options.offset + options.limit),
  };
}

async function fetchSubscriptionsForUserIds(
  adminClient: SupabaseClient,
  userIds: string[],
) {
  const { data, error } = await adminClient
    .from("user_subscriptions")
    .select(
      "user_id,plan,status,platform,entitlement_tier,expires_at,updated_at,verification_source",
    )
    .in("user_id", userIds)
    .order("updated_at", { ascending: false });

  if (error != null) {
    console.error("admin fetchSubscriptionsForUserIds failed", error);
    throw new HttpError(500, "subscription_query_failed");
  }

  return ((data ?? []) as UserSubscriptionRow[]);
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
  user: User,
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

function matchesUserQuery(user: User, query: string | null): boolean {
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

function compareUsersByCreatedAtDesc(left: User, right: User): number {
  const leftCreatedAt = typeof left?.created_at === "string"
    ? left.created_at
    : "";
  const rightCreatedAt = typeof right?.created_at === "string"
    ? right.created_at
    : "";
  return rightCreatedAt.localeCompare(leftCreatedAt);
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

function normalizeOptionalString(value: unknown): string | undefined {
  if (value == null) return undefined;
  if (typeof value !== "string") {
    throw new HttpError(400, "invalid_request_body");
  }
  return value;
}

function normalizeOptionalNullableString(
  value: unknown,
): string | null | undefined {
  if (value === null) return null;
  return normalizeOptionalString(value);
}

function parsePlan(value: unknown): SetTierRequest["plan"] | undefined {
  if (value == null) return undefined;
  if (value === "free" || value === "paid" || value === "subscriber") {
    return value;
  }
  throw new HttpError(400, "invalid_plan");
}

function parseStatus(value: unknown): SetTierRequest["status"] | undefined {
  if (value == null) return undefined;
  if (
    value === "active" || value === "grace" || value === "pending" ||
    value === "canceled" || value === "expired" || value === "revoked"
  ) {
    return value;
  }
  throw new HttpError(400, "invalid_status");
}

export function parseAdminRequestBodyText(
  raw: string,
): SetTierRequest | ClearOverrideRequest {
  const trimmed = raw.trim();
  if (trimmed.length === 0) {
    throw new HttpError(400, "request_body_required");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(trimmed);
  } catch {
    throw new HttpError(400, "invalid_json_body");
  }

  if (parsed == null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new HttpError(400, "invalid_request_body");
  }

  const body = parsed as Record<string, unknown>;
  const action = body.action;
  if (action === "set_tier") {
    return {
      action,
      user_id: normalizeOptionalString(body.user_id),
      plan: parsePlan(body.plan),
      status: parseStatus(body.status),
      expires_at: normalizeOptionalNullableString(body.expires_at),
    };
  }
  if (action === "clear_override") {
    return {
      action,
      user_id: normalizeOptionalString(body.user_id),
    };
  }

  throw new HttpError(400, "unsupported_action");
}

async function parseAdminRequestBody(req: Request) {
  return parseAdminRequestBodyText(await req.text());
}

function assertAdminAuthorized(req: Request, env: ReturnType<typeof readEnv>) {
  const authHeader = req.headers.get("Authorization");
  const bearer = authHeader?.replace(/^Bearer\s+/i, "").trim();
  if (env.adminApiToken == null || env.adminApiToken.length === 0) {
    throw new HttpError(503, "admin_api_token_not_configured");
  }
  if (bearer == null || !constantTimeEquals(bearer, env.adminApiToken)) {
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
    allowedOrigins: readAllowedOriginsFromEnv(),
  };
}

function readAllowedOriginsFromEnv(): Set<string> {
  return parseAllowedOrigins(Deno.env.get("ADMIN_API_ALLOWED_ORIGINS"));
}

function parseAllowedOrigins(raw: string | undefined): Set<string> {
  return new Set(
    (raw ?? "")
      .split(",")
      .map((origin) => origin.trim())
      .filter((origin) => origin.length > 0 && origin !== "*"),
  );
}

export function corsHeadersForOrigin(
  origin: string | null,
  allowedOrigins: Set<string>,
): Record<string, string> {
  const headers: Record<string, string> = {
    ...corsHeaders,
  };
  if (origin != null && allowedOrigins.has(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

export function constantTimeEquals(left: string, right: string): boolean {
  const encoder = new TextEncoder();
  const leftBytes = encoder.encode(left);
  const rightBytes = encoder.encode(right);
  if (leftBytes.length !== rightBytes.length) {
    return false;
  }

  let diff = 0;
  for (let index = 0; index < leftBytes.length; index += 1) {
    diff |= leftBytes[index] ^ rightBytes[index];
  }

  return diff === 0;
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

function json(
  payload: unknown,
  status = 200,
  responseCorsHeaders: Record<string, string> = corsHeaders,
): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...responseCorsHeaders,
      "Content-Type": "application/json",
    },
  });
}
