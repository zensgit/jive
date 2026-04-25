# Domestic Payment E2E Smoke Dev Verify

Date: 2026-04-26

## Summary

Added an explicit opt-in domestic payment happy-path smoke to `scripts/run_saas_staging_function_smoke.sh`.

The default function smoke behavior is unchanged. The new path only runs when `--run-domestic-payment-e2e` is passed with `--profile full`.

## Scope

- Creates a temporary Supabase Auth user through the Admin API.
- Signs in that temporary user to obtain a real user access token.
- Calls `create-payment-order` to create a staging domestic payment order.
- Posts a paid event to `domestic-payment-webhook`.
- Reads `user_subscriptions` with the service role key and verifies the projected entitlement matches the temporary order.
- Cleans up the temporary `payment_events`, `user_subscriptions`, `payment_orders`, and auth user.

## Safety Boundaries

- The E2E path is off by default.
- `--run-domestic-payment-e2e` is rejected unless `--profile full` is used.
- `SUPABASE_SERVICE_ROLE_KEY` is required only for the explicit E2E path.
- Logs print status codes and response shapes only. Tokens, passwords, API keys, and JWTs are never printed.
- Cleanup is registered with a shell trap so partial failures still attempt to remove temporary staging data.

## Validation

```bash
bash -n scripts/run_saas_staging_function_smoke.sh
```

Passed.

```bash
scripts/run_saas_staging_function_smoke.sh --help | sed -n '1,80p'
```

Passed. Help now documents `--run-domestic-payment-e2e` and the conditional `SUPABASE_SERVICE_ROLE_KEY` requirement.

```bash
scripts/run_saas_staging_function_smoke.sh \
  --profile core \
  --run-domestic-payment-e2e \
  --env-file /tmp/does-not-matter
```

Passed. The script exits with code `1` and reports:

```text
[saas-function-smoke] ERROR: --run-domestic-payment-e2e requires --profile full
```

Fake-curl full-profile validation passed:

```text
[saas-function-smoke] PASS: verify-subscription requires a real user session -> HTTP 401
[saas-function-smoke] PASS: analytics rejects missing admin token -> HTTP 401
[saas-function-smoke] PASS: analytics summary accepts admin token -> HTTP 200
[saas-function-smoke] PASS: admin rejects anon token -> HTTP 401
[saas-function-smoke] PASS: admin summary accepts admin token -> HTTP 200
[saas-function-smoke] PASS: send-notification dry run accepts notification token -> HTTP 200
[saas-function-smoke] PASS: subscription-webhook accepts Google test notification -> HTTP 200
[saas-function-smoke] PASS: create-payment-order requires a real user session -> HTTP 401
[saas-function-smoke] PASS: domestic-payment-webhook rejects missing token -> HTTP 401 error=admin_token_required
[saas-function-smoke] PASS: domestic-payment-webhook accepts token and checks order existence -> HTTP 404 error=payment_order_not_found
[saas-function-smoke] PASS: domestic E2E creates temporary auth user -> HTTP 201
[saas-function-smoke] PASS: domestic E2E signs in temporary user -> HTTP 200
[saas-function-smoke] PASS: domestic E2E creates payment order -> HTTP 201
[saas-function-smoke] PASS: domestic E2E posts paid webhook -> HTTP 200
[saas-function-smoke] PASS: domestic E2E reads projected subscription -> HTTP 200
[saas-function-smoke] PASS: domestic E2E subscription projection matches temporary order
[saas-function-smoke] function smoke passed
[saas-function-smoke] cleanup: payment event -> HTTP 204
[saas-function-smoke] cleanup: subscription projection -> HTTP 204
[saas-function-smoke] cleanup: payment order -> HTTP 204
[saas-function-smoke] cleanup: auth user -> HTTP 204
```

```bash
npx -y deno-bin@2.2.7 check \
  supabase/functions/create-payment-order/index.ts \
  supabase/functions/create-payment-order/index_test.ts \
  supabase/functions/domestic-payment-webhook/index.ts \
  supabase/functions/domestic-payment-webhook/index_test.ts
```

Passed.

```bash
npx -y deno-bin@2.2.7 test --allow-env \
  supabase/functions/create-payment-order/index_test.ts \
  supabase/functions/domestic-payment-webhook/index_test.ts
```

Passed: `10 passed | 0 failed`.

## Live Staging Status

Live staging E2E was not run locally because `/tmp/jive-saas-staging.env` is not present in this machine. The new command to run once a full staging env file is available:

```bash
scripts/run_saas_staging_function_smoke.sh \
  --profile full \
  --run-domestic-payment-e2e \
  --env-file /tmp/jive-saas-staging.env
```

This command requires the full function set to already be deployed, including `create-payment-order` and `domestic-payment-webhook`.

## Follow-Up

- If this should run from GitHub Actions, add a separate full-billing staging workflow/input rather than wiring it into the existing core-only staging lane.
- The existing `SaaS Core Staging` workflow intentionally runs `--profile core`, so this E2E path should stay out of that lane unless the lane is expanded beyond core functions.
