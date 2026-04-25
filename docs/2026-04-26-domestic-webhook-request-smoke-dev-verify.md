# Domestic Payment Webhook Request Smoke Dev & Verify

Date: 2026-04-26 02:20 CST
Branch: `codex/domestic-webhook-request-tests`
Base commit: `e92e7fa7`

## Goal

Harden the domestic payment webhook path before production payment work continues.

This closes two small but important reliability gaps:

- `domestic-payment-webhook` only had parser/projection unit tests, not request-level handler tests.
- `run_saas_staging_function_smoke.sh` treated HTTP `404` as sufficient proof that the deployed domestic webhook had executed the "order not found" business path. A missing function route can also return `404`, so status-only validation could create a false positive.

## Development Changes

Updated `supabase/functions/domestic-payment-webhook/index.ts`.

- Kept the production `handleRequest(req)` entrypoint unchanged for runtime callers.
- Added exported `handleDomesticWebhookRequest(req, runtime)` for request-level tests.
- Added injectable runtime dependencies for env, Supabase client factory, clock, and error logging.
- Kept production behavior on the default path: env still comes from `Deno.env`, Supabase still uses `createClient`, and errors still log through `console.error`.

Updated `supabase/functions/domestic-payment-webhook/index_test.ts`.

- Added request-level coverage for missing webhook token.
- Added request-level coverage for missing order after a valid token.
- Added request-level coverage that event upsert uses `onConflict: "provider,event_id"` with `ignoreDuplicates: true`.
- Added request-level coverage that paid domestic payment events project to `user_subscriptions`.

Updated `scripts/run_saas_staging_function_smoke.sh`.

- Added `expect_json_error`.
- Domestic webhook missing-token smoke now requires HTTP `401` plus JSON `{"error":"admin_token_required"}`.
- Domestic webhook missing-order smoke now requires HTTP `404` plus JSON `{"error":"payment_order_not_found"}`.
- This prevents a missing deployed function route from passing as a valid missing-order business response.

## Validation

Passed:

```bash
npx -y deno-bin@2.2.7 fmt supabase/functions/domestic-payment-webhook/index.ts supabase/functions/domestic-payment-webhook/index_test.ts
npx -y deno-bin@2.2.7 check supabase/functions/domestic-payment-webhook/index.ts supabase/functions/domestic-payment-webhook/index_test.ts
npx -y deno-bin@2.2.7 test --allow-env supabase/functions/domestic-payment-webhook/index_test.ts
npx -y deno-bin@2.2.7 lint supabase/functions/domestic-payment-webhook/index.ts supabase/functions/domestic-payment-webhook/index_test.ts
bash -n scripts/run_saas_staging_function_smoke.sh
git diff --check
bash scripts/run_saas_wave0_smoke.sh
```

Domestic webhook targeted result:

```text
6 passed | 0 failed
```

Wave0 result:

```text
[saas-wave0-smoke] Wave 0 SaaS smoke completed
```

## Function Smoke Body Check Validation

Positive fake-curl validation passed:

```bash
PATH="<fake-curl-dir>:$PATH" \
  scripts/run_saas_staging_function_smoke.sh \
  --profile full \
  --env-file "<temp>/staging.env" \
  --functions-url https://functions.example.com/functions/v1
```

Result:

```text
[saas-function-smoke] PASS: domestic-payment-webhook rejects missing token -> HTTP 401 error=admin_token_required
[saas-function-smoke] PASS: domestic-payment-webhook accepts token and checks order existence -> HTTP 404 error=payment_order_not_found
[saas-function-smoke] function smoke passed
```

Negative fake-curl validation passed:

- fake endpoint returned HTTP `404` with `{"error":"function_not_found"}`;
- script failed as expected instead of accepting the status-only match.

Result:

```text
[saas-function-smoke] WARN: domestic-payment-webhook accepts token and checks order existence expected HTTP 404 with error=payment_order_not_found but got 404
[saas-function-smoke] ERROR: function smoke found 1 issue(s)
negative body-check smoke failed as expected
```

## Not Rerun

- Live staging `run_saas_staging_function_smoke.sh` was not rerun because this change does not deploy functions or change staging configuration, and local `/tmp/jive-saas-staging.env` is not required for the fake-curl body-check validation.
- `flutter analyze` and full `flutter test` were not run separately because `bash scripts/run_saas_wave0_smoke.sh` covers the SaaS-targeted Flutter analyze/tests and all relevant Deno function checks.

## Follow-Up

Before real domestic merchant onboarding, replace the shared `DOMESTIC_PAYMENT_WEBHOOK_TOKEN` staging auth with provider signature verification for WeChat Pay and Alipay webhooks.
