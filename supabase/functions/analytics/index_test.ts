import {
  assertEquals,
  assertRejects,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildSummaryWindow,
  fetchAnalyticsRows,
  handleSummaryRequest,
  handleTrackRequest,
  normalizeAnalyticsToken,
  parseSummaryDays,
  summarizeAnalyticsRows,
} from "./index.ts";

Deno.test("normalizeAnalyticsToken normalizes and bounds values", () => {
  assertEquals(normalizeAnalyticsToken(" Auth Signed In "), "auth_signed_in");
  assertEquals(normalizeAnalyticsToken(""), null);
  assertEquals(normalizeAnalyticsToken(undefined), null);
  assertEquals(normalizeAnalyticsToken("x".repeat(65)), null);
});

Deno.test("parseSummaryDays defaults, clamps valid integers, and rejects malformed values", () => {
  assertEquals(parseSummaryDays(null), 30);
  assertEquals(parseSummaryDays(""), 30);
  assertEquals(parseSummaryDays("5"), 7);
  assertEquals(parseSummaryDays("120"), 90);
  assertEquals(parseSummaryDays("15"), 15);
  assertThrows(() => parseSummaryDays("7.5"));
  assertThrows(() => parseSummaryDays("abc"));
});

Deno.test("buildSummaryWindow honors requested window without forcing 30 days", () => {
  assertEquals(
    buildSummaryWindow(new Date("2026-04-08T12:00:00.000Z"), 7),
    {
      sinceDate: "2026-04-02",
      untilDate: "2026-04-08",
    },
  );
});

Deno.test("summarizeAnalyticsRows computes active users, conversions, and retention", () => {
  const summary = summarizeAnalyticsRows(
    [
      {
        user_id: "user-1",
        device_id: null,
        event_name: "auth_screen_viewed",
        occurred_on: "2026-04-01",
      },
      {
        user_id: "user-1",
        device_id: null,
        event_name: "auth_signed_in",
        occurred_on: "2026-04-01",
      },
      {
        user_id: "user-1",
        device_id: null,
        event_name: "app_opened",
        occurred_on: "2026-04-02",
      },
      {
        user_id: null,
        device_id: "guest-a",
        event_name: "subscription_purchase_started",
        occurred_on: "2026-04-01",
      },
      {
        user_id: null,
        device_id: "guest-a",
        event_name: "subscription_purchase_completed",
        occurred_on: "2026-04-01",
      },
      {
        user_id: null,
        device_id: "guest-a",
        event_name: "app_opened",
        occurred_on: "2026-04-08",
      },
    ],
    new Date("2026-04-08T12:00:00.000Z"),
    30,
  );

  assertEquals(summary.active_users.dau, 1);
  assertEquals(summary.active_users.mau, 2);
  assertEquals(summary.conversions.auth_sign_in, {
    viewed_or_started: 1,
    completed: 1,
    rate: 1,
  });
  assertEquals(summary.conversions.purchase, {
    viewed_or_started: 1,
    completed: 1,
    rate: 1,
  });
  assertEquals(summary.retention, [
    {
      cohort_date: "2026-04-01",
      cohort_size: 2,
      retained_d1: 1,
      retained_d7: 1,
      retained_d30: 0,
    },
  ]);
});

Deno.test("handleTrackRequest returns 400 for malformed json body", async () => {
  const response = await handleTrackRequest(
    new Request("https://example.com/analytics", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{bad json",
    }),
    { auth: { getUser: async () => ({ data: { user: null } }) } },
    {},
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), { error: "invalid_json_body" });
});

Deno.test("handleSummaryRequest returns 400 for malformed days query", async () => {
  const response = await handleSummaryRequest(
    new Request("https://example.com/analytics?days=abc", {
      method: "GET",
      headers: { Authorization: "Bearer admin-token" },
    }),
    {},
    {
      supabaseUrl: "https://example.supabase.co",
      supabaseAnonKey: "anon",
      supabaseServiceRoleKey: "service",
      analyticsAdminToken: "admin-token",
    },
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), { error: "invalid_days" });
});

Deno.test("fetchAnalyticsRows constrains the date window and fails early on oversized result sets", async () => {
  const calls: Array<Record<string, unknown>> = [];
  const responses = [
    { count: 20001, error: null },
  ];
  const adminClient = createAdminClientStub(calls, responses);

  await assertRejects(
    () =>
      fetchAnalyticsRows(adminClient, {
        sinceDate: "2026-04-02",
        untilDate: "2026-04-08",
        maxRows: 20000,
      }),
    Error,
    "analytics_summary_window_too_large",
  );

  assertEquals(calls, [
    {
      table: "analytics_events",
      columns: "id",
      options: { head: true, count: "exact" },
      gte: ["occurred_on", "2026-04-02"],
      lte: ["occurred_on", "2026-04-08"],
    },
  ]);
});

function createAdminClientStub(
  calls: Array<Record<string, unknown>>,
  responses: Array<Record<string, unknown>>,
) {
  return {
    from(table: string) {
      const state: Record<string, unknown> = { table };
      const builder = {
        select(columns: string, options?: Record<string, unknown>) {
          state.columns = columns;
          if (options != null) {
            state.options = options;
          }
          return builder;
        },
        gte(column: string, value: string) {
          state.gte = [column, value];
          return builder;
        },
        lte(column: string, value: string) {
          state.lte = [column, value];
          return builder;
        },
        order(column: string, options: Record<string, unknown>) {
          state.order = [column, options];
          return builder;
        },
        range(from: number, to: number) {
          state.range = [from, to];
          calls.push({ ...state });
          return Promise.resolve(responses.shift() ?? { data: [], error: null });
        },
        then(
          onFulfilled?: (value: unknown) => unknown,
          onRejected?: (reason: unknown) => unknown,
        ) {
          calls.push({ ...state });
          return Promise.resolve(responses.shift() ?? { data: [], error: null })
            .then(onFulfilled, onRejected);
        },
      };
      return builder;
    },
  };
}
