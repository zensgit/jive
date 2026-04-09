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

type AnalyticsAccumulator = {
  days: number;
  today: string;
  monthlySince: string;
  actorsByDate: Map<string, Set<string>>;
  eventCounts: Map<string, { total: number; actors: Set<string> }>;
  activityByActor: Map<string, Set<string>>;
  authStarted: Set<string>;
  authCompleted: Set<string>;
  purchaseStarted: Set<string>;
  purchaseCompleted: Set<string>;
};

const DEFAULT_SUMMARY_DAYS = 30;
const MIN_SUMMARY_DAYS = 7;
const MAX_SUMMARY_DAYS = 90;
const MAX_SUMMARY_ROWS = 20000;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

class AnalyticsHttpError extends Error {
  constructor(readonly code: string, readonly status: number) {
    super(code);
    this.name = "AnalyticsHttpError";
  }
}

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
    if (error instanceof AnalyticsHttpError) {
      return json({ error: error.code }, error.status);
    }
    console.error("analytics unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      500,
    );
  }
}

export async function handleTrackRequest(
  req: Request,
  anonClient: any,
  adminClient: any,
): Promise<Response> {
  try {
    const body = await parseTrackRequestBody(req);
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
  } catch (error) {
    if (error instanceof AnalyticsHttpError) {
      return json({ error: error.code }, error.status);
    }
    throw error;
  }
}

export async function handleSummaryRequest(
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

  try {
    const url = new URL(req.url);
    const days = parseSummaryDays(url.searchParams.get("days"));
    const now = new Date();
    const { sinceDate, untilDate } = buildSummaryWindow(now, days);
    const summary = await fetchAnalyticsSummary(
      adminClient,
      { sinceDate, untilDate, days, now },
    );
    return json(summary, 200);
  } catch (error) {
    if (error instanceof AnalyticsHttpError) {
      return json({ error: error.code }, error.status);
    }
    throw error;
  }
}

async function fetchAnalyticsSummary(
  adminClient: any,
  options: {
    sinceDate: string;
    untilDate: string;
    days: number;
    now: Date;
    maxRows?: number;
  },
) {
  const { sinceDate, untilDate, days, now, maxRows = MAX_SUMMARY_ROWS } =
    options;
  const pageSize = 1000;
  let from = 0;

  const { count, error: countError } = await adminClient
    .from("analytics_events")
    .select("id", { head: true, count: "exact" })
    .gte("occurred_on", sinceDate)
    .lte("occurred_on", untilDate);

  if (countError != null) {
    console.error("analytics summary count failed", countError);
    throw new AnalyticsHttpError("analytics_summary_fetch_failed", 502);
  }
  if (typeof count === "number" && count > maxRows) {
    throw new AnalyticsHttpError("analytics_summary_window_too_large", 422);
  }

  const accumulator = createAnalyticsAccumulator(now, days);

  while (true) {
    const { data, error } = await adminClient
      .from("analytics_events")
      .select("user_id,device_id,event_name,occurred_on")
      .gte("occurred_on", sinceDate)
      .lte("occurred_on", untilDate)
      .order("occurred_on", { ascending: true })
      .range(from, from + pageSize - 1);

    if (error != null) {
      console.error("analytics summary fetch failed", error);
      throw new AnalyticsHttpError("analytics_summary_fetch_failed", 502);
    }

    const batch = (data ?? []) as AnalyticsRow[];
    for (const row of batch) {
      addAnalyticsRow(accumulator, row);
    }

    if (batch.length < pageSize) {
      break;
    }
    from += pageSize;
  }

  return finalizeAnalyticsAccumulator(accumulator);
}

export async function fetchAnalyticsRows(
  adminClient: any,
  options: {
    sinceDate: string;
    untilDate: string;
    maxRows?: number;
  },
): Promise<AnalyticsRow[]> {
  const { sinceDate, untilDate, maxRows = MAX_SUMMARY_ROWS } = options;
  const rows: AnalyticsRow[] = [];
  const pageSize = 1000;
  let from = 0;

  const { count, error: countError } = await adminClient
    .from("analytics_events")
    .select("id", { head: true, count: "exact" })
    .gte("occurred_on", sinceDate)
    .lte("occurred_on", untilDate);

  if (countError != null) {
    console.error("analytics summary count failed", countError);
    throw new AnalyticsHttpError("analytics_summary_fetch_failed", 502);
  }
  if (typeof count === "number" && count > maxRows) {
    throw new AnalyticsHttpError("analytics_summary_window_too_large", 422);
  }

  while (true) {
    const { data, error } = await adminClient
      .from("analytics_events")
      .select("user_id,device_id,event_name,occurred_on")
      .gte("occurred_on", sinceDate)
      .lte("occurred_on", untilDate)
      .order("occurred_on", { ascending: true })
      .range(from, from + pageSize - 1);

    if (error != null) {
      console.error("analytics summary fetch failed", error);
      throw new AnalyticsHttpError("analytics_summary_fetch_failed", 502);
    }

    const batch = (data ?? []) as AnalyticsRow[];
    rows.push(...batch);
    if (rows.length > maxRows) {
      throw new AnalyticsHttpError("analytics_summary_window_too_large", 422);
    }
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
  const accumulator = createAnalyticsAccumulator(now, days);
  for (const row of rows) {
    addAnalyticsRow(accumulator, row);
  }

  return finalizeAnalyticsAccumulator(accumulator);
}

function createAnalyticsAccumulator(
  now: Date,
  days: number,
): AnalyticsAccumulator {
  const today = toIsoDate(now);
  return {
    days,
    today,
    monthlySince: shiftIsoDate(today, -(days - 1)),
    actorsByDate: new Map<string, Set<string>>(),
    eventCounts: new Map<string, { total: number; actors: Set<string> }>(),
    activityByActor: new Map<string, Set<string>>(),
    authStarted: new Set<string>(),
    authCompleted: new Set<string>(),
    purchaseStarted: new Set<string>(),
    purchaseCompleted: new Set<string>(),
  };
}

function addAnalyticsRow(
  accumulator: AnalyticsAccumulator,
  row: AnalyticsRow,
) {
  if (
    row.occurred_on < accumulator.monthlySince ||
    row.occurred_on > accumulator.today
  ) {
    return;
  }

  const actor = actorKey(row);
  if (actor == null) return;

  if (!accumulator.actorsByDate.has(row.occurred_on)) {
    accumulator.actorsByDate.set(row.occurred_on, new Set<string>());
  }
  accumulator.actorsByDate.get(row.occurred_on)!.add(actor);

  if (!accumulator.activityByActor.has(actor)) {
    accumulator.activityByActor.set(actor, new Set<string>());
  }
  accumulator.activityByActor.get(actor)!.add(row.occurred_on);

  const eventMetric = accumulator.eventCounts.get(row.event_name) ?? {
    total: 0,
    actors: new Set<string>(),
  };
  eventMetric.total += 1;
  eventMetric.actors.add(actor);
  accumulator.eventCounts.set(row.event_name, eventMetric);

  switch (row.event_name) {
    case "auth_screen_viewed":
      accumulator.authStarted.add(actor);
      break;
    case "auth_signed_in":
      accumulator.authCompleted.add(actor);
      break;
    case "subscription_purchase_started":
      accumulator.purchaseStarted.add(actor);
      break;
    case "subscription_purchase_completed":
      accumulator.purchaseCompleted.add(actor);
      break;
  }
}

function finalizeAnalyticsAccumulator(accumulator: AnalyticsAccumulator) {
  const dau = accumulator.actorsByDate.get(accumulator.today)?.size ?? 0;
  const mauActors = new Set<string>();
  for (const set of accumulator.actorsByDate.values()) {
    for (const actor of set) {
      mauActors.add(actor);
    }
  }

  return {
    window_days: accumulator.days,
    as_of: accumulator.today,
    active_users: {
      dau,
      mau: mauActors.size,
    },
    events: Array.from(accumulator.eventCounts.entries())
      .map(([eventName, metric]) => ({
        event_name: eventName,
        total: metric.total,
        unique_actors: metric.actors.size,
      }))
      .sort((a, b) => b.total - a.total),
    conversions: {
      auth_sign_in: conversionMetric(
        accumulator.authStarted,
        accumulator.authCompleted,
      ),
      purchase: conversionMetric(
        accumulator.purchaseStarted,
        accumulator.purchaseCompleted,
      ),
    },
    retention: buildRetention(accumulator.activityByActor),
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

async function parseTrackRequestBody(req: Request): Promise<AnalyticsTrackRequest> {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    throw new AnalyticsHttpError("invalid_json_body", 400);
  }
  if (!isJsonObject(body)) {
    throw new AnalyticsHttpError("invalid_json_body", 400);
  }
  return body as AnalyticsTrackRequest;
}

export function parseSummaryDays(value: string | null): number {
  if (value == null || value.trim().length === 0) {
    return DEFAULT_SUMMARY_DAYS;
  }

  const trimmed = value.trim();
  if (!/^-?\d+$/.test(trimmed)) {
    throw new AnalyticsHttpError("invalid_days", 400);
  }

  const parsed = Number(trimmed);
  if (!Number.isSafeInteger(parsed)) {
    throw new AnalyticsHttpError("invalid_days", 400);
  }

  return Math.min(Math.max(parsed, MIN_SUMMARY_DAYS), MAX_SUMMARY_DAYS);
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

export function buildSummaryWindow(now: Date, days: number) {
  const untilDate = toIsoDate(now);
  return {
    sinceDate: shiftIsoDate(untilDate, -(days - 1)),
    untilDate,
  };
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
