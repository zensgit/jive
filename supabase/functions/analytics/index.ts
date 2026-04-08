import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type AnalyticsTrackRequest = {
  event_name?: string;
  event_group?: string;
  occurred_at?: string;
  device_id?: string;
  session_id?: string;
  platform?: string;
  app_version?: string;
  properties?: Record<string, unknown>;
};

type AnalyticsRow = {
  user_id: string | null;
  device_id: string | null;
  event_name: string;
  occurred_on: string;
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

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
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
    const anonClient = createClient(env.supabaseUrl, env.supabaseAnonKey, {
      global: {
        headers: {
          Authorization: req.headers.get("Authorization") ?? "",
        },
      },
    });
    const adminClient = createClient(
      env.supabaseUrl,
      env.supabaseServiceRoleKey,
    );

    if (req.method === "POST") {
      return await handleTrackRequest(req, anonClient, adminClient);
    }

    if (req.method === "GET") {
      return await handleSummaryRequest(req, adminClient, env);
    }

    return json({ error: "method_not_allowed" }, 405);
  } catch (error) {
    console.error("analytics unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      500,
    );
  }
}

async function handleTrackRequest(
  req: Request,
  anonClient: any,
  adminClient: any,
): Promise<Response> {
  const body = (await req.json()) as AnalyticsTrackRequest;
  const eventName = normalizeAnalyticsToken(body.event_name);
  if (eventName == null) {
    return json({ error: "invalid_event_name" }, 400);
  }

  const eventGroup = normalizeAnalyticsToken(body.event_group) ?? "app";
  const occurredAt = parseOccurredAt(body.occurred_at);
  if (occurredAt == null) {
    return json({ error: "invalid_occurred_at" }, 400);
  }

  const {
    data: { user },
  } = await anonClient.auth.getUser();

  const deviceId = normalizeOptionalText(body.device_id);
  if (user == null && deviceId == null) {
    return json({ error: "device_id_required_for_guest_event" }, 400);
  }

  const payload = {
    user_id: user?.id ?? null,
    device_id: deviceId,
    session_id: normalizeOptionalText(body.session_id),
    event_name: eventName,
    event_group: eventGroup,
    platform: normalizeOptionalText(body.platform),
    app_version: normalizeOptionalText(body.app_version),
    properties: isJsonObject(body.properties) ? body.properties : {},
    occurred_at: occurredAt.toISOString(),
    occurred_on: occurredAt.toISOString().slice(0, 10),
  };

  const { error } = await adminClient.from("analytics_events").insert(payload);
  if (error != null) {
    console.error("analytics track insert failed", error);
    return json({ error: "analytics_insert_failed" }, 500);
  }

  return json({ accepted: true }, 202);
}

async function handleSummaryRequest(
  req: Request,
  adminClient: any,
  env: ReturnType<typeof readEnv>,
): Promise<Response> {
  const authHeader = req.headers.get("Authorization");
  const bearerToken = authHeader?.replace(/^Bearer\s+/i, "").trim();
  if (env.analyticsAdminToken == null || env.analyticsAdminToken.length === 0) {
    return json({ error: "analytics_admin_token_not_configured" }, 503);
  }
  if (bearerToken == null || bearerToken !== env.analyticsAdminToken) {
    return json({ error: "admin_auth_required" }, 401);
  }

  const url = new URL(req.url);
  const requestedDays = Number(url.searchParams.get("days") ?? "30");
  const days = Number.isFinite(requestedDays)
    ? Math.min(Math.max(Math.trunc(requestedDays), 7), 90)
    : 30;
  const now = new Date();
  const since = new Date(Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate() - Math.max(days, 30),
  ));
  const rows = await fetchAnalyticsRows(
    adminClient,
    since.toISOString().slice(0, 10),
  );
  const summary = summarizeAnalyticsRows(rows, now, days);
  return json(summary, 200);
}

async function fetchAnalyticsRows(
  adminClient: any,
  sinceDate: string,
): Promise<AnalyticsRow[]> {
  const rows: AnalyticsRow[] = [];
  const pageSize = 1000;
  let from = 0;

  while (true) {
    const { data, error } = await adminClient
      .from("analytics_events")
      .select("user_id,device_id,event_name,occurred_on")
      .gte("occurred_on", sinceDate)
      .order("occurred_on", { ascending: true })
      .range(from, from + pageSize - 1);

    if (error != null) {
      console.error("analytics summary fetch failed", error);
      throw new Error("analytics_summary_fetch_failed");
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
  const mauActors = new Set<string>();
  for (const set of actorsByDate.values()) {
    for (const actor of set) {
      mauActors.add(actor);
    }
  }

  return {
    window_days: days,
    as_of: today,
    active_users: {
      dau,
      mau: mauActors.size,
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

export function normalizeAnalyticsToken(value?: string): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase().replace(/[^a-z0-9_]+/g, "_")
    .replace(/^_+|_+$/g, "");
  if (normalized.length === 0 || normalized.length > 64) {
    return null;
  }
  return normalized;
}

function normalizeOptionalText(value?: string): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function parseOccurredAt(value?: string): Date | null {
  if (value == null) return new Date();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function isJsonObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value != null && !Array.isArray(value);
}

function toIsoDate(value: Date): string {
  return value.toISOString().slice(0, 10);
}

function shiftIsoDate(value: string, days: number): string {
  const parsed = new Date(`${value}T00:00:00.000Z`);
  parsed.setUTCDate(parsed.getUTCDate() + days);
  return toIsoDate(parsed);
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
    analyticsAdminToken: Deno.env.get("ANALYTICS_ADMIN_TOKEN"),
  };
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}
