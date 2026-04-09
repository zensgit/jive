import {
  assertEquals,
  assertFalse,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  constantTimeEquals,
  corsHeadersForOrigin,
  latestSubscriptionByUser,
  parseAdminRequestBodyText,
  summarizeLatestSubscriptionsFromRows,
} from "./index.ts";

Deno.test("latestSubscriptionByUser keeps the first row for each user", () => {
  const latest = latestSubscriptionByUser([
    {
      user_id: "user-1",
      plan: "subscriber",
      status: "active",
      platform: "admin_override",
      entitlement_tier: "subscriber",
      expires_at: null,
      updated_at: "2026-04-08T10:00:00.000Z",
      verification_source: "admin_api",
    },
    {
      user_id: "user-1",
      plan: "paid",
      status: "expired",
      platform: "google_play",
      entitlement_tier: "free",
      expires_at: null,
      updated_at: "2026-04-07T10:00:00.000Z",
      verification_source: "google_play_api",
    },
    {
      user_id: "user-2",
      plan: "paid",
      status: "active",
      platform: "google_play",
      entitlement_tier: "paid",
      expires_at: null,
      updated_at: "2026-04-08T09:00:00.000Z",
      verification_source: "google_play_api",
    },
  ]);

  assertEquals(latest.get("user-1")?.platform, "admin_override");
  assertEquals(latest.get("user-2")?.entitlement_tier, "paid");
});

Deno.test("summarizeLatestSubscriptionsFromRows counts only the first row per user", () => {
  const stats = summarizeLatestSubscriptionsFromRows([
    {
      user_id: "user-1",
      plan: "subscriber",
      status: "active",
      platform: "admin_override",
      entitlement_tier: "subscriber",
      expires_at: null,
      updated_at: "2026-04-08T10:00:00.000Z",
      verification_source: "admin_api",
    },
    {
      user_id: "user-1",
      plan: "paid",
      status: "expired",
      platform: "google_play",
      entitlement_tier: "paid",
      expires_at: null,
      updated_at: "2026-04-07T10:00:00.000Z",
      verification_source: "google_play_api",
    },
    {
      user_id: "user-2",
      plan: "paid",
      status: "grace",
      platform: "google_play",
      entitlement_tier: "paid",
      expires_at: null,
      updated_at: "2026-04-08T09:00:00.000Z",
      verification_source: "google_play_api",
    },
    {
      user_id: "user-3",
      plan: "subscriber",
      status: "revoked",
      platform: "app_store",
      entitlement_tier: "subscriber",
      expires_at: null,
      updated_at: "2026-04-08T08:00:00.000Z",
      verification_source: "app_store_api",
    },
  ]);

  assertEquals(stats.admin_overrides, 1);
  assertEquals(stats.active_subscribers, 1);
  assertEquals(stats.active_paid, 1);
  assertEquals(stats.expired_or_revoked, 1);
});

Deno.test("constantTimeEquals matches exact token only", () => {
  assertEquals(constantTimeEquals("secret-token", "secret-token"), true);
  assertFalse(constantTimeEquals("secret-token", "secret-token-x"));
  assertFalse(constantTimeEquals("secret-token", "SECRET-token"));
});

Deno.test("corsHeadersForOrigin only reflects configured origins", () => {
  const allowed = new Set([
    "https://admin.example.com",
    "http://localhost:3000",
  ]);

  assertEquals(
    corsHeadersForOrigin("https://admin.example.com", allowed)[
      "Access-Control-Allow-Origin"
    ],
    "https://admin.example.com",
  );
  assertEquals(
    corsHeadersForOrigin("https://evil.example.com", allowed)[
      "Access-Control-Allow-Origin"
    ],
    undefined,
  );
});

Deno.test("parseAdminRequestBodyText validates supported admin actions", () => {
  assertEquals(
    parseAdminRequestBodyText(
      JSON.stringify({
        action: "set_tier",
        user_id: "user-1",
        plan: "subscriber",
        status: "active",
        expires_at: null,
      }),
    ),
    {
      action: "set_tier",
      user_id: "user-1",
      plan: "subscriber",
      status: "active",
      expires_at: null,
    },
  );

  assertEquals(
    parseAdminRequestBodyText(
      JSON.stringify({
        action: "clear_override",
        user_id: "user-2",
      }),
    ),
    {
      action: "clear_override",
      user_id: "user-2",
    },
  );
});

Deno.test("parseAdminRequestBodyText rejects invalid json and invalid fields", () => {
  assertThrows(
    () => parseAdminRequestBodyText("{"),
    Error,
    "invalid_json_body",
  );
  assertThrows(
    () =>
      parseAdminRequestBodyText(
        JSON.stringify({
          action: "set_tier",
          plan: "enterprise",
        }),
      ),
    Error,
    "invalid_plan",
  );
  assertThrows(
    () =>
      parseAdminRequestBodyText(
        JSON.stringify({
          action: "clear_override",
          user_id: 123,
        }),
      ),
    Error,
    "invalid_request_body",
  );
});
