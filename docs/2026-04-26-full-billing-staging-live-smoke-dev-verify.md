# Full Billing Staging Live Smoke Dev Verify

Date: 2026-04-26

## Summary

Started live validation of the `SaaS Full Billing Staging Smoke` workflow and hardened the workflow after the first run exposed a missing domestic webhook token secret.

## Initial Live Run

Command:

```bash
gh workflow run 'SaaS Full Billing Staging Smoke' \
  --repo zensgit/jive \
  --ref main \
  -f run_domestic_payment_e2e=false
```

Result:

- Run ID: `24958067699`
- URL: `https://github.com/zensgit/jive/actions/runs/24958067699`
- Head SHA: `515c7a4ac348862f6e8c36d9e13d317f9cffa831`
- Input: `run_domestic_payment_e2e=false`
- Conclusion: `failure`
- Failed step: `Guard full billing smoke secrets`
- Missing secret: `STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN`

No staging data was written. The workflow stopped before creating the temporary env file or calling any Edge Function.

## Configuration Fix

Created `STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN` as a GitHub Actions secret with a newly generated random value.

The secret value was not printed or stored in this document.

## Workflow Hardening

Updated `.github/workflows/saas_full_billing_staging_smoke.yml` so the workflow can optionally sync the GitHub Actions domestic webhook token into Supabase Edge Function runtime secrets before running smoke.

New input:

- `sync_domestic_payment_secret`
- Default: `true`
- Effect: runs `supabase secrets set DOMESTIC_PAYMENT_WEBHOOK_TOKEN=...` with `STAGING_SUPABASE_ACCESS_TOKEN` and `STAGING_PROJECT_REF`

This prevents drift where GitHub Actions has a domestic webhook token but the deployed Supabase function still has an old or missing runtime secret.

## Branch Live Run After Token Sync

Command:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref codex/sync-domestic-webhook-secret-before-smoke \
  -f sync_domestic_payment_secret=true \
  -f run_domestic_payment_e2e=false
```

Result:

- Run ID: `24958141758`
- URL: `https://github.com/zensgit/jive/actions/runs/24958141758`
- Head SHA: `8502b8283e18ec0b59e90bc5a69bbe36ccdb1e85`
- Input: `sync_domestic_payment_secret=true`
- Input: `run_domestic_payment_e2e=false`
- Conclusion: `failure`
- Passed: `Guard full billing smoke secrets`
- Passed: `Sync domestic payment webhook runtime secret`
- Passed: `verify-subscription`
- Passed: `analytics`
- Passed: `admin`
- Passed: `send-notification`
- Passed: `subscription-webhook`
- Failed: `create-payment-order` returned route-level `404`
- Failed: `domestic-payment-webhook` returned route-level `404`

Diagnosis: staging has the core and subscription webhook functions deployed, but the domestic payment smoke functions were not deployed on this project.

## Payment Function Deploy Hardening

Updated `.github/workflows/saas_full_billing_staging_smoke.yml` again so the workflow can optionally deploy the two payment smoke functions before running smoke.

New input:

- `deploy_payment_smoke_functions`
- Default: `true`
- Effect: deploys `create-payment-order` and `domestic-payment-webhook`
- Authentication: uses `STAGING_SUPABASE_ACCESS_TOKEN` and `STAGING_PROJECT_REF`
- JWT mode: deploys `domestic-payment-webhook` with `--no-verify-jwt`

## Branch Live Run After Payment Function Deploy

Command:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref codex/sync-domestic-webhook-secret-before-smoke \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=false
```

Result:

- Run ID: `24958170192`
- URL: `https://github.com/zensgit/jive/actions/runs/24958170192`
- Head SHA: `bcf2cafe23a13259e427b3fee9738819aae000e1`
- Conclusion: `success`
- Passed: secret guard
- Passed: domestic webhook runtime secret sync
- Passed: payment smoke function deploy
- Passed: full billing function smoke

## Branch Domestic Payment E2E Run

Command:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref codex/sync-domestic-webhook-secret-before-smoke \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=true
```

Result:

- Run ID: `24958180734`
- URL: `https://github.com/zensgit/jive/actions/runs/24958180734`
- Head SHA: `bcf2cafe23a13259e427b3fee9738819aae000e1`
- Conclusion: `failure`
- Passed: secret guard
- Passed: domestic webhook runtime secret sync
- Passed: payment smoke function deploy
- Passed: temporary auth user creation
- Passed: temporary auth user sign-in
- Passed: payment order creation
- Failed: paid webhook returned HTTP `500`
- Cleanup: payment event, subscription projection, payment order, and auth user cleanup all completed

Diagnosis: the paid webhook reached the deployed function and failed during subscription projection. The function used `upsert(..., { onConflict: "platform,purchase_token" })`, but the current schema has `idx_user_subscriptions_platform_token_unique` as a partial unique index. That conflict target is not reliable through PostgREST upsert.

## Domestic Webhook Projection Fix

Updated `supabase/functions/domestic-payment-webhook/index.ts` to avoid the partial-index upsert path.

New behavior:

- Looks up an existing subscription projection by `source_order_no`.
- Updates the existing projection when found.
- Inserts a projection when no existing row is found.
- Preserves webhook replay behavior without relying on `onConflict: "platform,purchase_token"`.

Added unit coverage for updating an existing domestic subscription projection.

## Final Branch Domestic Payment E2E Run

Command:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref codex/sync-domestic-webhook-secret-before-smoke \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=true
```

Result:

- Run ID: `24958256145`
- URL: `https://github.com/zensgit/jive/actions/runs/24958256145`
- Head SHA: `8b4bf0a51aea3d6b59e7c2e411849b1a785e5f97`
- Conclusion: `success`
- Passed: secret guard
- Passed: domestic webhook runtime secret sync
- Passed: payment smoke function deploy
- Passed: full billing function smoke
- Passed: temporary auth user creation
- Passed: temporary auth user sign-in
- Passed: payment order creation
- Passed: paid webhook
- Passed: projected subscription readback
- Passed: subscription projection matched the temporary order
- Cleanup: payment event `204`
- Cleanup: subscription projection `204`
- Cleanup: payment order `204`
- Cleanup: auth user `200`

Key log lines:

```text
[saas-function-smoke] PASS: domestic E2E posts paid webhook -> HTTP 200
[saas-function-smoke] PASS: domestic E2E reads projected subscription -> HTTP 200
[saas-function-smoke] PASS: domestic E2E subscription projection matches temporary order
[saas-function-smoke] function smoke passed
```

## Post-Merge Main Domestic Payment E2E Run

Command:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref main \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=true
```

Result:

- Run ID: `24958349070`
- URL: `https://github.com/zensgit/jive/actions/runs/24958349070`
- Head SHA: `7c073af3ac2b00ab2105f6a2e931c5a12f2ebd21`
- Conclusion: `success`
- Passed: secret guard
- Passed: domestic webhook runtime secret sync
- Passed: payment smoke function deploy
- Passed: full billing function smoke
- Passed: temporary auth user creation
- Passed: temporary auth user sign-in
- Passed: payment order creation
- Passed: paid webhook
- Passed: projected subscription readback
- Passed: subscription projection matched the temporary order
- Cleanup: payment event `204`
- Cleanup: subscription projection `204`
- Cleanup: payment order `204`
- Cleanup: auth user `200`

Key log lines:

```text
[saas-function-smoke] PASS: domestic E2E posts paid webhook -> HTTP 200
[saas-function-smoke] PASS: domestic E2E reads projected subscription -> HTTP 200
[saas-function-smoke] PASS: domestic E2E subscription projection matches temporary order
[saas-function-smoke] function smoke passed
```

## Validation

```bash
for f in scripts/run_saas_staging_function_smoke.sh scripts/check_saas_github_secrets.sh scripts/push_saas_github_secrets.sh; do
  bash -n "$f"
done
```

Passed.

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/saas_full_billing_staging_smoke.yml"); puts "yaml ok"'
```

Passed.

```bash
npx -y deno-bin@2.2.7 check \
  supabase/functions/domestic-payment-webhook/index.ts \
  supabase/functions/domestic-payment-webhook/index_test.ts
```

Passed.

```bash
npx -y deno-bin@2.2.7 test --allow-env \
  supabase/functions/domestic-payment-webhook/index_test.ts
```

Passed: `7 passed | 0 failed`.

## Next Live Runs

Run non-writing smoke first:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref main \
  -f deploy_payment_smoke_functions=true \
  -f sync_domestic_payment_secret=true \
  -f run_domestic_payment_e2e=false
```

If that passes, run the temporary write-path E2E:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref main \
  -f deploy_payment_smoke_functions=true \
  -f sync_domestic_payment_secret=true \
  -f run_domestic_payment_e2e=true
```
