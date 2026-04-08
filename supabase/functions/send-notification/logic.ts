export type NotificationAction =
  | "expiry_reminder"
  | "expired_notice"
  | "system_notice";

export type SubscriptionRecord = {
  id: number;
  user_id: string;
  plan: string;
  status: string;
  expires_at: string | null;
  entitlement_tier?: string | null;
};

export type NotificationJob = {
  user_id: string;
  action: NotificationAction;
  title: string;
  body: string;
  dedupe_key: string;
  payload: Record<string, unknown>;
  queued_at: string;
  source_subscription_id: number | null;
};

export type BuildSystemNoticeInput = {
  user_ids?: string[] | null;
  title?: string | null;
  body?: string | null;
  notice_key?: string | null;
};

export type BuildNotificationPlanInput = {
  action: NotificationAction;
  now: Date;
  reminderLeadDays: number;
  systemNotice?: BuildSystemNoticeInput;
};

const DAY_IN_MS = 24 * 60 * 60 * 1000;

export function normalizeNotificationAction(value: string): NotificationAction {
  if (value === "expiry_reminder" || value === "expired_notice" || value === "system_notice") {
    return value;
  }
  throw new Error(`unsupported_notification_action:${value}`);
}

export function clampPositiveInteger(value: unknown, fallback: number): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    const rounded = Math.floor(value);
    return rounded > 0 ? rounded : fallback;
  }

  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      const rounded = Math.floor(parsed);
      return rounded > 0 ? rounded : fallback;
    }
  }

  return fallback;
}

export function distinctUserIds(userIds: string[]): string[] {
  return Array.from(
    new Set(userIds.map((userId) => userId.trim()).filter((userId) => userId.length > 0)),
  );
}

export function dedupeNotificationJobs(jobs: NotificationJob[]): NotificationJob[] {
  const seen = new Set<string>();
  const deduped: NotificationJob[] = [];

  for (const job of jobs) {
    if (seen.has(job.dedupe_key)) {
      continue;
    }
    seen.add(job.dedupe_key);
    deduped.push(job);
  }

  return deduped;
}

export function buildNotificationPlan(
  subscriptions: SubscriptionRecord[],
  input: BuildNotificationPlanInput,
): NotificationJob[] {
  switch (input.action) {
    case "expiry_reminder":
      return dedupeNotificationJobs(
        buildExpiryReminderJobs(subscriptions, input.now, input.reminderLeadDays),
      );
    case "expired_notice":
      return dedupeNotificationJobs(
        buildExpiredNoticeJobs(subscriptions, input.now),
      );
    case "system_notice":
      return dedupeNotificationJobs(
        buildSystemNoticeJobs(input.systemNotice ?? {}, input.now, subscriptions),
      );
  }
}

export function buildExpiryReminderJobs(
  subscriptions: SubscriptionRecord[],
  now: Date,
  reminderLeadDays: number,
): NotificationJob[] {
  const nowMs = now.getTime();
  const windowEndMs = nowMs + reminderLeadDays * DAY_IN_MS;

  return subscriptions.flatMap((subscription) => {
    if (subscription.expires_at == null) {
      return [];
    }

    const expiresAt = new Date(subscription.expires_at);
    const expiresAtMs = expiresAt.getTime();
    if (Number.isNaN(expiresAtMs)) {
      return [];
    }

    if (expiresAtMs <= nowMs || expiresAtMs > windowEndMs) {
      return [];
    }

    const expiresAtIso = expiresAt.toISOString();
    return [
      createNotificationJob({
        action: "expiry_reminder",
        userId: subscription.user_id,
        sourceSubscriptionId: subscription.id,
        title: "订阅即将到期",
        body: `${planLabel(subscription)} 将在 ${reminderLeadDays} 天内到期，请及时处理。`,
        dedupeKey: `expiry_reminder:${subscription.id}:${expiresAtIso}:${reminderLeadDays}`,
        payload: {
          subscription_id: subscription.id,
          plan: subscription.plan,
          status: subscription.status,
          expires_at: expiresAtIso,
          reminder_lead_days: reminderLeadDays,
        },
        now,
      }),
    ];
  });
}

export function buildExpiredNoticeJobs(
  subscriptions: SubscriptionRecord[],
  now: Date,
): NotificationJob[] {
  const nowMs = now.getTime();

  return subscriptions.flatMap((subscription) => {
    if (subscription.expires_at == null) {
      return [];
    }

    const expiresAt = new Date(subscription.expires_at);
    const expiresAtMs = expiresAt.getTime();
    if (Number.isNaN(expiresAtMs) || expiresAtMs > nowMs) {
      return [];
    }

    const expiresAtIso = expiresAt.toISOString();
    return [
      createNotificationJob({
        action: "expired_notice",
        userId: subscription.user_id,
        sourceSubscriptionId: subscription.id,
        title: "订阅已过期",
        body: `${planLabel(subscription)} 已过期，请尽快续费或恢复订阅。`,
        dedupeKey: `expired_notice:${subscription.id}:${expiresAtIso}`,
        payload: {
          subscription_id: subscription.id,
          plan: subscription.plan,
          status: subscription.status,
          expires_at: expiresAtIso,
        },
        now,
      }),
    ];
  });
}

export function buildSystemNoticeJobs(
  input: BuildSystemNoticeInput,
  now: Date,
  subscriptions: SubscriptionRecord[] = [],
): NotificationJob[] {
  const title = (input.title ?? "系统通知").trim();
  const body = (input.body ?? "你收到一条来自 Jive 的系统通知。").trim();
  const explicitUserIds = distinctUserIds(input.user_ids ?? []);

  const userIds = explicitUserIds.length > 0
    ? explicitUserIds
    : distinctUserIds(subscriptions.map((subscription) => subscription.user_id));
  const noticeKey = buildNoticeKey(
    input.notice_key,
    title,
    body,
    userIds,
  );

  return userIds.map((userId) =>
    createNotificationJob({
      action: "system_notice",
      userId,
      sourceSubscriptionId: null,
      title,
      body,
      dedupeKey: `system_notice:${noticeKey}:${userId}`,
      payload: {
        notice_key: noticeKey,
        target_user_ids: userIds,
        title,
        body,
      },
      now,
    })
  );
}

export function buildQueueRows(jobs: NotificationJob[]) {
  return jobs.map((job) => ({
    user_id: job.user_id,
    source_subscription_id: job.source_subscription_id,
    action: job.action,
    title: job.title,
    body: job.body,
    payload: job.payload,
    dedupe_key: job.dedupe_key,
    status: "queued" as const,
    attempt_count: 0,
    queued_at: job.queued_at,
  }));
}

function createNotificationJob(args: {
  action: NotificationAction;
  userId: string;
  sourceSubscriptionId: number | null;
  title: string;
  body: string;
  dedupeKey: string;
  payload: Record<string, unknown>;
  now: Date;
}): NotificationJob {
  return {
    user_id: args.userId,
    action: args.action,
    title: args.title,
    body: args.body,
    dedupe_key: args.dedupeKey,
    payload: {
      ...args.payload,
      generated_at: args.now.toISOString(),
    },
    queued_at: args.now.toISOString(),
    source_subscription_id: args.sourceSubscriptionId,
  };
}

function planLabel(subscription: SubscriptionRecord): string {
  if (subscription.entitlement_tier === "subscriber" || subscription.plan === "subscriber") {
    return "订阅版";
  }
  if (subscription.entitlement_tier === "paid" || subscription.plan === "paid") {
    return "专业版";
  }
  return "当前订阅";
}

function buildNoticeKey(
  explicitKey: string | null | undefined,
  title: string,
  body: string,
  userIds: string[],
): string {
  const raw = explicitKey?.trim() && explicitKey.trim().length > 0
    ? explicitKey.trim()
    : `${title}|${body}|${userIds.join(",")}`;
  return hashString(raw);
}

function hashString(value: string): string {
  let hash = 0x811c9dc5;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193);
  }
  return (hash >>> 0).toString(36);
}
