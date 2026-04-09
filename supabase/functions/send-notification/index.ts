import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.49.8";
import {
  buildNotificationPlan,
  buildQueueRows,
  clampPositiveInteger,
  normalizeNotificationAction,
  type NotificationJob,
  type SubscriptionRecord,
} from "./logic.ts";

type SendNotificationRequest = {
  action?: string;
  reminder_lead_days?: number | string;
  notice_key?: string;
  title?: string;
  body?: string;
  user_ids?: string[];
  dry_run?: boolean;
  now?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-token",
};

const queueUpsertBatchSize = 500;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const env = readEnv();
    if (!isAuthorized(req, env.notificationAdminToken)) {
      return json({ error: "forbidden" }, 403);
    }

    const body = (await req.json()) as SendNotificationRequest;
    const action = normalizeNotificationAction(body.action ?? "");
    const now = body.now != null ? new Date(body.now) : new Date();
    if (Number.isNaN(now.getTime())) {
      return json({ error: "invalid_now" }, 400);
    }

    const supabase = createClient(env.supabaseUrl, env.supabaseServiceRoleKey);

    const plan = await buildPlan(supabase, {
      action,
      body,
      now,
    });

    if (body.dry_run === true) {
      return json({
        ok: true,
        action,
        dry_run: true,
        matched_subscriptions: plan.matchedSubscriptions,
        recipients: plan.recipients,
        planned: plan.jobs.length,
        queued: 0,
      }, 200);
    }

    if (plan.jobs.length === 0) {
      return json({
        ok: true,
        action,
        dry_run: false,
        matched_subscriptions: plan.matchedSubscriptions,
        recipients: plan.recipients,
        planned: 0,
        queued: 0,
      }, 200);
    }

    const queueRows = buildQueueRows(plan.jobs);
    return json({
      ok: true,
      action,
      dry_run: false,
      matched_subscriptions: plan.matchedSubscriptions,
      recipients: plan.recipients,
      planned: plan.jobs.length,
      queued: await enqueueNotificationJobs(supabase, queueRows),
    }, 200);
  } catch (error) {
    console.error("send-notification unexpected error", error);
    return json(
      { error: error instanceof Error ? error.message : "unknown_error" },
      500,
    );
  }
});

async function buildPlan(
  supabase: SupabaseClient,
  input: {
    action: ReturnType<typeof normalizeNotificationAction>;
    body: SendNotificationRequest;
    now: Date;
  },
): Promise<{
  jobs: NotificationJob[];
  matchedSubscriptions: number;
  recipients: number;
}> {
  switch (input.action) {
    case "expiry_reminder": {
      const leadDays = clampPositiveInteger(input.body.reminder_lead_days, 7);
      const until = new Date(input.now.getTime() + leadDays * 24 * 60 * 60 * 1000);
      const subscriptions = await fetchSubscriptions(supabase, (query) =>
        query
          .not("expires_at", "is", null)
          .gte("expires_at", input.now.toISOString())
          .lte("expires_at", until.toISOString())
          .in("status", ["active", "grace"])
      );
      const jobs = buildNotificationPlan(subscriptions, {
        action: input.action,
        now: input.now,
        reminderLeadDays: leadDays,
      });
      return {
        jobs,
        matchedSubscriptions: subscriptions.length,
        recipients: distinctRecipients(subscriptions),
      };
    }
    case "expired_notice": {
      const subscriptions = await fetchSubscriptions(supabase, (query) =>
        query
          .not("expires_at", "is", null)
          .lte("expires_at", input.now.toISOString())
      );
      const jobs = buildNotificationPlan(subscriptions, {
        action: input.action,
        now: input.now,
        reminderLeadDays: 0,
      });
      return {
        jobs,
        matchedSubscriptions: subscriptions.length,
        recipients: distinctRecipients(subscriptions),
      };
    }
    case "system_notice": {
      let subscriptions: SubscriptionRecord[] = [];
      if (Array.isArray(input.body.user_ids) && input.body.user_ids.length > 0) {
        subscriptions = input.body.user_ids.map((userId, index) => ({
          id: index + 1,
          user_id: userId,
          plan: "subscriber",
          status: "active",
          expires_at: null,
          entitlement_tier: "subscriber",
        }));
      } else {
        const userIds = await fetchActiveNoticeUserIds(supabase);
        subscriptions = userIds.map((userId, index) => ({
          id: index + 1,
          user_id: userId,
          plan: "subscriber",
          status: "active",
          expires_at: null,
          entitlement_tier: "subscriber",
        }));
      }
      const jobs = buildNotificationPlan(subscriptions, {
        action: input.action,
        now: input.now,
        reminderLeadDays: 0,
        systemNotice: {
          user_ids: input.body.user_ids,
          title: input.body.title,
          body: input.body.body,
          notice_key: input.body.notice_key,
        },
      });
      return {
        jobs,
        matchedSubscriptions: subscriptions.length,
        recipients: distinctRecipients(subscriptions),
      };
    }
  }
}

async function fetchSubscriptions(
  supabase: SupabaseClient,
  configureQuery: (query: any) => any,
): Promise<SubscriptionRecord[]> {
  const baseQuery = supabase
    .from("user_subscriptions")
    .select("id,user_id,plan,status,expires_at,entitlement_tier");

  const { data, error } = await configureQuery(baseQuery);

  if (error != null) {
    console.error("send-notification fetch subscriptions failed", error);
    throw new Error("subscription_lookup_failed");
  }

  return (data ?? []) as SubscriptionRecord[];
}

async function fetchActiveNoticeUserIds(
  supabase: SupabaseClient,
): Promise<string[]> {
  const { data, error } = await supabase
    .from("user_subscriptions")
    .select("user_id")
    .in("status", ["active", "grace", "pending"]);

  if (error != null) {
    console.error("send-notification fetch notice users failed", error);
    throw new Error("subscription_lookup_failed");
  }

  return Array.from(
    new Set(
      (data ?? [])
        .map((row: { user_id?: unknown }) => row.user_id)
        .filter((userId: unknown): userId is string =>
          typeof userId === "string" && userId.length > 0
        ),
    ),
  );
}

async function enqueueNotificationJobs(
  supabase: SupabaseClient,
  queueRows: ReturnType<typeof buildQueueRows>,
): Promise<number> {
  let queued = 0;

  for (let index = 0; index < queueRows.length; index += queueUpsertBatchSize) {
    const batch = queueRows.slice(index, index + queueUpsertBatchSize);
    const { data, error } = await supabase
      .from("notification_queue")
      .upsert(batch, {
        onConflict: "dedupe_key",
        ignoreDuplicates: true,
      })
      .select("id");

    if (error != null) {
      console.error("send-notification enqueue failed", error);
      throw new Error("notification_enqueue_failed");
    }

    queued += data?.length ?? 0;
  }

  return queued;
}

function distinctRecipients(subscriptions: SubscriptionRecord[]): number {
  return new Set(subscriptions.map((subscription) => subscription.user_id)).size;
}

function readEnv() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const notificationAdminToken = Deno.env.get("NOTIFICATION_ADMIN_TOKEN");
  if (!supabaseUrl || !supabaseServiceRoleKey || !notificationAdminToken) {
    throw new Error("notification_function_env_missing");
  }

  return {
    supabaseUrl,
    supabaseServiceRoleKey,
    notificationAdminToken,
  };
}

function isAuthorized(req: Request, expectedToken: string): boolean {
  const headerToken = req.headers.get("x-admin-token")?.trim();
  if (headerToken != null && headerToken === expectedToken) {
    return true;
  }

  const authorization = req.headers.get("Authorization");
  if (authorization == null) {
    return false;
  }

  const [scheme, token] = authorization.split(/\s+/, 2);
  if (scheme?.toLowerCase() !== "bearer" || token == null) {
    return false;
  }

  return token.trim() === expectedToken;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
