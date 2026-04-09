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

type AnalyticsRow = {
  user_id: string | null;
  device_id: string | null;
  event_name: string;
  occurred_on: string;
};

type NotificationQueueRow = {
  status: "queued" | "sent" | "failed" | "canceled" | string;
  queued_at: string;
  sent_at: string | null;
  attempt_count: number;
  action: string;
  last_error: string | null;
  updated_at: string;
};

type ConversionMetric = {
  viewed_or_started: number;
  completed: number;
  rate: number;
};

type RetentionMetric = {
  cohort_date: string;
  cohort_size: number;
  retained_d1: number;
  retained_d7: number;
  retained_d30: number;
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
      return json(await buildSummary(adminClient, url), 200, corsHeaders);
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

async function buildSummary(adminClient: SupabaseClient, url: URL) {
  const days = clampNumber(url.searchParams.get("days"), 30, 7, 90);
  const now = new Date();
  const [userStats, subscriptionStats, analyticsRows, notificationRows] =
    await Promise.all([
      summarizeAuthUsers(adminClient, 500),
      summarizeLatestSubscriptions(adminClient, 500),
      fetchAnalyticsRows(adminClient, days),
      fetchNotificationQueueRows(adminClient, now, days),
    ]);

  return {
    users: {
      total: userStats.total,
      recent_signups_7d: userStats.recentSignups7d,
    },
    subscriptions: subscriptionStats,
    analytics: summarizeAnalyticsRows(analyticsRows, now, days),
    notifications: {
      queue: summarizeNotificationQueueRows(notificationRows, now),
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

async function summarizeLatestSubscriptions(
  adminClient: SupabaseClient,
  pageSize: number,
) {
  let from = 0;
  let activePaid = 0;
  let activeSubscribers = 0;
  let overrides = 0;
  let expired = 0;
  const seenUsers = new Set<string>();

  while (true) {
    const { data, error } = await adminClient
      .from("user_subscriptions")
      .select(
        "user_id,plan,status,platform,entitlement_tier,expires_at,updated_at,verification_source",
      )
      .order("updated_at", { ascending: false })
      .range(from, from + pageSize - 1);

    if (error != null) {
      console.error("admin summarizeLatestSubscriptions failed", error);
      throw new HttpError(500, "subscription_query_failed");
    }

    const batch = (data ?? []) as UserSubscriptionRow[];
    const batchStats = summarizeLatestSubscriptionsFromRows(
      batch,
      seenUsers,
    );
    activePaid += batchStats.active_paid;
    activeSubscribers += batchStats.active_subscribers;
    overrides += batchStats.admin_overrides;
    expired += batchStats.expired_or_revoked;

    if (batch.length < pageSize) {
      break;
    }
    from += pageSize;
  }

  return {
    active_paid: activePaid,
    active_subscribers: activeSubscribers,
    expired_or_revoked: expired,
    admin_overrides: overrides,
  };
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

export function summarizeLatestSubscriptionsFromRows(
  rows: UserSubscriptionRow[],
  seenUsers = new Set<string>(),
) {
  let activePaid = 0;
  let activeSubscribers = 0;
  let overrides = 0;
  let expired = 0;

  for (const row of rows) {
    if (seenUsers.has(row.user_id)) {
      continue;
    }
    seenUsers.add(row.user_id);

    if (row.platform === "admin_override") {
      overrides += 1;
    }
    if (row.status === "expired" || row.status === "revoked") {
      expired += 1;
    }
    if (
      (row.status === "active" || row.status === "grace") &&
      row.entitlement_tier === "paid"
    ) {
      activePaid += 1;
    }
    if (
      (row.status === "active" || row.status === "grace") &&
      row.entitlement_tier === "subscriber"
    ) {
      activeSubscribers += 1;
    }
  }

  return {
    active_paid: activePaid,
    active_subscribers: activeSubscribers,
    expired_or_revoked: expired,
    admin_overrides: overrides,
  };
}

async function fetchAnalyticsRows(
  adminClient: SupabaseClient,
  days: number,
): Promise<AnalyticsRow[]> {
  const rows: AnalyticsRow[] = [];
  const pageSize = 1000;
  let from = 0;
  const sinceDate = shiftIsoDate(toIsoDate(new Date()), -(days - 1));

  while (true) {
    const { data, error } = await adminClient
      .from("analytics_events")
      .select("user_id,device_id,event_name,occurred_on")
      .gte("occurred_on", sinceDate)
      .order("occurred_on", { ascending: true })
      .range(from, from + pageSize - 1);

    if (error != null) {
      console.error("admin analytics fetch failed", error);
      throw new HttpError(500, "analytics_query_failed");
    }

    const batch = (data ?? []) as AnalyticsRow[];
    rows.push(...batch);
    if (batch.length < pageSize) {
      break;
    }
    from += pageSize;
  }

  return rows;
}

async function fetchNotificationQueueRows(
  adminClient: SupabaseClient,
  now: Date,
  days: number,
): Promise<NotificationQueueRow[]> {
  const rows: NotificationQueueRow[] = [];
  const pageSize = 1000;
  let from = 0;
  const sinceQueuedAt = new Date(now);
  sinceQueuedAt.setUTCDate(sinceQueuedAt.getUTCDate() - (days - 1));

  while (true) {
    const { data, error } = await adminClient
      .from("notification_queue")
      .select(
        "status,queued_at,sent_at,attempt_count,action,last_error,updated_at",
      )
      .gte("queued_at", sinceQueuedAt.toISOString())
      .order("updated_at", { ascending: false })
      .range(from, from + pageSize - 1);

    if (error != null) {
      console.error("admin notification queue fetch failed", error);
      throw new HttpError(500, "notification_queue_query_failed");
    }

    const batch = (data ?? []) as NotificationQueueRow[];
    rows.push(...batch);
    if (batch.length < pageSize) {
      break;
    }
    from += pageSize;
  }

  return rows;
}

export function summarizeAnalyticsRows(
  rows: AnalyticsRow[],
  now: Date = new Date(),
  days = 30,
) {
  const today = toIsoDate(now);
  const monthlySince = shiftIsoDate(today, -(days - 1));
  const actorsByDate = new Map<string, Set<string>>();
  const eventCounts = new Map<string, { total: number; actors: Set<string> }>();
  const activityByActor = new Map<string, Set<string>>();
  const authStarted = new Set<string>();
  const authCompleted = new Set<string>();
  const purchaseStarted = new Set<string>();
  const purchaseCompleted = new Set<string>();

  for (const row of rows) {
    if (row.occurred_on < monthlySince || row.occurred_on > today) continue;
    const actor = actorKey(row);
    if (actor == null) continue;

    if (!actorsByDate.has(row.occurred_on)) {
      actorsByDate.set(row.occurred_on, new Set<string>());
    }
    actorsByDate.get(row.occurred_on)!.add(actor);

    if (!activityByActor.has(actor)) {
      activityByActor.set(actor, new Set<string>());
    }
    activityByActor.get(actor)!.add(row.occurred_on);

    const eventMetric = eventCounts.get(row.event_name) ?? {
      total: 0,
      actors: new Set<string>(),
    };
    eventMetric.total += 1;
    eventMetric.actors.add(actor);
    eventCounts.set(row.event_name, eventMetric);

    switch (row.event_name) {
      case "auth_screen_viewed":
        authStarted.add(actor);
        break;
      case "auth_signed_in":
        authCompleted.add(actor);
        break;
      case "subscription_purchase_started":
        purchaseStarted.add(actor);
        break;
      case "subscription_purchase_completed":
        purchaseCompleted.add(actor);
        break;
    }
  }

  const dau = actorsByDate.get(today)?.size ?? 0;

  return {
    window_days: days,
    as_of: today,
    active_users: {
      dau,
      mau: activityByActor.size,
    },
    events: Array.from(eventCounts.entries())
      .map(([eventName, metric]) => ({
        event_name: eventName,
        total: metric.total,
        unique_actors: metric.actors.size,
      }))
      .sort((a, b) => b.total - a.total),
    conversions: {
      auth_sign_in: conversionMetric(authStarted, authCompleted),
      purchase: conversionMetric(purchaseStarted, purchaseCompleted),
    },
    retention: buildRetention(activityByActor),
  };
}

export function summarizeNotificationQueueRows(
  rows: NotificationQueueRow[],
  now: Date = new Date(),
) {
  const nowMs = now.getTime();
  const totals = {
    queued: 0,
    sent: 0,
    failed: 0,
    canceled: 0,
  };
  let retrying = 0;
  let queuedOver1h = 0;
  let queuedOver24h = 0;
  let oldestQueuedMs: number | null = null;

  for (const row of rows) {
    if (row.status in totals) {
      totals[row.status as keyof typeof totals] += 1;
    }

    if (row.status !== "queued") {
      continue;
    }

    if (row.attempt_count > 0) {
      retrying += 1;
    }

    const queuedAt = Date.parse(row.queued_at);
    if (Number.isNaN(queuedAt)) {
      continue;
    }

    if (oldestQueuedMs == null || queuedAt < oldestQueuedMs) {
      oldestQueuedMs = queuedAt;
    }

    const ageMinutes = Math.floor((nowMs - queuedAt) / 60000);
    if (ageMinutes >= 60) {
      queuedOver1h += 1;
    }
    if (ageMinutes >= 60 * 24) {
      queuedOver24h += 1;
    }
  }

  const total = rows.length;
  const delivered = totals.sent;

  return {
    total,
    by_status: totals,
    queued: totals.queued,
    sent: totals.sent,
    failed: totals.failed,
    canceled: totals.canceled,
    retrying,
    delivery_rate: total === 0 ? 0 : Number((delivered / total).toFixed(4)),
    queued_over_1h: queuedOver1h,
    queued_over_24h: queuedOver24h,
    oldest_queued_at: oldestQueuedMs == null
      ? null
      : new Date(oldestQueuedMs).toISOString(),
    oldest_queued_age_minutes: oldestQueuedMs == null
      ? null
      : Math.floor((nowMs - oldestQueuedMs) / 60000),
  };
}

function buildRetention(
  activityByActor: Map<string, Set<string>>,
): RetentionMetric[] {
  const cohorts = new Map<string, {
    size: number;
    d1: number;
    d7: number;
    d30: number;
  }>();

  for (const dates of activityByActor.values()) {
    const orderedDates = Array.from(dates).sort();
    if (orderedDates.length === 0) continue;
    const firstSeen = orderedDates[0];
    const cohort = cohorts.get(firstSeen) ?? { size: 0, d1: 0, d7: 0, d30: 0 };
    const activity = new Set(orderedDates);

    cohort.size += 1;
    if (activity.has(shiftIsoDate(firstSeen, 1))) cohort.d1 += 1;
    if (activity.has(shiftIsoDate(firstSeen, 7))) cohort.d7 += 1;
    if (activity.has(shiftIsoDate(firstSeen, 30))) cohort.d30 += 1;
    cohorts.set(firstSeen, cohort);
  }

  return Array.from(cohorts.entries())
    .map(([cohortDate, metric]) => ({
      cohort_date: cohortDate,
      cohort_size: metric.size,
      retained_d1: metric.d1,
      retained_d7: metric.d7,
      retained_d30: metric.d30,
    }))
    .sort((a, b) => a.cohort_date.localeCompare(b.cohort_date));
}

function conversionMetric(
  started: Set<string>,
  completed: Set<string>,
): ConversionMetric {
  const base = started.size;
  const completedFromStarted =
    Array.from(completed).filter((actor) => started.has(actor)).length;
  return {
    viewed_or_started: base,
    completed: completedFromStarted,
    rate: base === 0 ? 0 : Number((completedFromStarted / base).toFixed(4)),
  };
}

function actorKey(row: AnalyticsRow): string | null {
  if (row.user_id != null && row.user_id.length > 0) {
    return `user:${row.user_id}`;
  }
  if (row.device_id != null && row.device_id.length > 0) {
    return `guest:${row.device_id}`;
  }
  return null;
}

function toIsoDate(value: Date): string {
  return value.toISOString().slice(0, 10);
}

function shiftIsoDate(value: string, days: number): string {
  const parsed = new Date(`${value}T00:00:00.000Z`);
  parsed.setUTCDate(parsed.getUTCDate() + days);
  return toIsoDate(parsed);
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
