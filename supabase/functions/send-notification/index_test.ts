import {
  assertEquals,
  assertFalse,
  assertThrows,
} from "jsr:@std/assert@1";
import {
  buildExpiredNoticeJobs,
  buildExpiryReminderJobs,
  buildNotificationPlan,
  buildQueueRows,
  buildSystemNoticeJobs,
  clampPositiveInteger,
  dedupeNotificationJobs,
  distinctUserIds,
  normalizeNotificationAction,
  type SubscriptionRecord,
} from "./logic.ts";

Deno.test("normalizeNotificationAction accepts supported actions", () => {
  assertEquals(normalizeNotificationAction("expiry_reminder"), "expiry_reminder");
  assertEquals(normalizeNotificationAction("expired_notice"), "expired_notice");
  assertEquals(normalizeNotificationAction("system_notice"), "system_notice");
  assertThrows(() => normalizeNotificationAction("unknown"));
});

Deno.test("buildExpiryReminderJobs filters by expiry window and builds stable dedupe keys", () => {
  const now = new Date("2026-04-08T10:00:00.000Z");
  const subscriptions: SubscriptionRecord[] = [
    {
      id: 1,
      user_id: "user-a",
      plan: "subscriber",
      status: "active",
      expires_at: "2026-04-10T10:00:00.000Z",
      entitlement_tier: "subscriber",
    },
    {
      id: 2,
      user_id: "user-b",
      plan: "subscriber",
      status: "active",
      expires_at: "2026-05-10T10:00:00.000Z",
      entitlement_tier: "subscriber",
    },
    {
      id: 3,
      user_id: "user-c",
      plan: "paid",
      status: "expired",
      expires_at: "2026-04-07T10:00:00.000Z",
      entitlement_tier: "free",
    },
  ];

  const jobs = buildExpiryReminderJobs(subscriptions, now, 7);

  assertEquals(jobs.length, 1);
  assertEquals(jobs[0].user_id, "user-a");
  assertEquals(jobs[0].action, "expiry_reminder");
  assertEquals(jobs[0].source_subscription_id, 1);
  assertEquals(jobs[0].dedupe_key, "expiry_reminder:1:2026-04-10T10:00:00.000Z:7");
});

Deno.test("buildExpiredNoticeJobs keeps only already expired subscriptions", () => {
  const now = new Date("2026-04-08T10:00:00.000Z");
  const subscriptions: SubscriptionRecord[] = [
    {
      id: 11,
      user_id: "user-a",
      plan: "subscriber",
      status: "active",
      expires_at: "2026-04-08T09:59:59.000Z",
      entitlement_tier: "subscriber",
    },
    {
      id: 12,
      user_id: "user-b",
      plan: "paid",
      status: "active",
      expires_at: "2026-04-09T10:00:00.000Z",
      entitlement_tier: "paid",
    },
  ];

  const jobs = buildExpiredNoticeJobs(subscriptions, now);

  assertEquals(jobs.length, 1);
  assertEquals(jobs[0].user_id, "user-a");
  assertEquals(jobs[0].action, "expired_notice");
  assertEquals(jobs[0].dedupe_key, "expired_notice:11:2026-04-08T09:59:59.000Z");
});

Deno.test("buildSystemNoticeJobs targets distinct user ids and dedupes repeated requests", () => {
  const now = new Date("2026-04-08T10:00:00.000Z");
  const subscriptions: SubscriptionRecord[] = [
    {
      id: 21,
      user_id: "user-a",
      plan: "subscriber",
      status: "active",
      expires_at: null,
      entitlement_tier: "subscriber",
    },
    {
      id: 22,
      user_id: "user-a",
      plan: "subscriber",
      status: "active",
      expires_at: null,
      entitlement_tier: "subscriber",
    },
    {
      id: 23,
      user_id: "user-b",
      plan: "paid",
      status: "grace",
      expires_at: null,
      entitlement_tier: "paid",
    },
  ];

  const jobs = buildSystemNoticeJobs(
    {
      title: "系统升级",
      body: "今晚 23:00 进行维护",
    },
    now,
    subscriptions,
  );

  assertEquals(distinctUserIds(["user-a", "user-a", "user-b"]).length, 2);
  assertEquals(jobs.length, 2);
  assertEquals(jobs[0].action, "system_notice");
  assertFalse(jobs[0].dedupe_key === jobs[1].dedupe_key);

  const deduped = dedupeNotificationJobs([...jobs, jobs[0]]);
  assertEquals(deduped.length, 2);
});

Deno.test("buildNotificationPlan and buildQueueRows preserve job shape", () => {
  const now = new Date("2026-04-08T10:00:00.000Z");
  const jobs = buildNotificationPlan(
    [
      {
        id: 31,
        user_id: "user-c",
        plan: "subscriber",
        status: "active",
        expires_at: "2026-04-12T10:00:00.000Z",
        entitlement_tier: "subscriber",
      },
    ],
    {
      action: "expiry_reminder",
      now,
      reminderLeadDays: clampPositiveInteger("7", 7),
    },
  );

  const rows = buildQueueRows(jobs);
  assertEquals(rows.length, 1);
  assertEquals(rows[0].user_id, "user-c");
  assertEquals(rows[0].status, "queued");
  assertEquals(rows[0].attempt_count, 0);
  assertEquals(rows[0].source_subscription_id, 31);
});
