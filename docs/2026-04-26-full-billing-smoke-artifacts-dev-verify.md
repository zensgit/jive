# Full Billing Smoke Artifacts Dev Verify

Date: 2026-04-26
Branch: `codex/full-billing-smoke-artifacts`

## Summary

Improved the manual `SaaS Full Billing Staging Smoke` workflow so a successful or failed run leaves a compact, auditable evidence bundle instead of requiring maintainers to inspect raw Actions logs.

This is a deployment-test reliability change only. It does not change Dart app code, Supabase SQL schema, Edge Function behavior, payment projection logic, or staging data writes.

## Design

The workflow now prepares a temporary report directory at:

```text
$RUNNER_TEMP/saas-full-billing-staging-smoke
```

The directory contains:

- `metadata.md`: repository, run id, run attempt, ref, SHA, and the workflow inputs used for the run.
- `smoke.log`: stdout/stderr from `scripts/run_saas_staging_function_smoke.sh`, captured with `tee` while preserving `pipefail`.
- `summary.md`: a GitHub Step Summary friendly report with PASS/FAIL/SKIPPED status and the last 120 log lines.

The workflow appends `summary.md` to `$GITHUB_STEP_SUMMARY`, then uploads the report directory as:

```text
saas-full-billing-smoke-${{ github.run_id }}
```

## Safety Boundary

Before upload, `Guard full billing smoke artifacts` checks:

- no sensitive-looking file names are present, including `.env`, `.pem`, `.key`, `*secret*`, `*credential*`, and `*dart-defines*`;
- report files do not contain exact configured secret values for anon key, access token, service role key, admin tokens, notification token, Pub/Sub token, or domestic webhook token.

The upload step runs only when the artifact guard succeeds. If the guard fails, the workflow fails and the report artifact is not uploaded.

Supabase project URL / functions URL / project ref are not treated as secret values for this artifact guard because the smoke log intentionally records the deployed Functions base URL for traceability.

## Validation

Local workflow syntax:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/saas_full_billing_staging_smoke.yml"); puts "yaml ok"'
```

Result:

```text
yaml ok
```

Branch live validation:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref codex/full-billing-smoke-artifacts \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=false
```

Result:

- Run ID: `24958622844`
- URL: `https://github.com/zensgit/jive/actions/runs/24958622844`
- Head SHA: `5c25b92baaf45227388e9b47b24cc1b10fbda729`
- Conclusion: `success`
- Step Summary generation: passed
- Artifact guard: passed
- Artifact upload: passed
- Artifact name: `saas-full-billing-smoke-24958622844`

Downloaded artifact contents:

```text
metadata.md
smoke.log
summary.md
```

`summary.md` recorded:

```text
- status: PASS
- smokeOutcome: success
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
[saas-function-smoke] function smoke passed
```

PR CI:

- `analyze_and_test`: passed
- `detect_saas_wave0_smoke`: passed
- `saas_wave0_smoke`: skipped as expected for this workflow/docs-only change
- `android_integration_test`: skipped as expected

Post-merge main validation:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref main \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=false
```

Result:

- Run ID: `24958762851`
- URL: `https://github.com/zensgit/jive/actions/runs/24958762851`
- Head SHA: `d69e9611de4e41185fe896c5d2afa6255edc8f4d`
- Conclusion: `success`
- Step Summary generation: passed
- Artifact guard: passed
- Artifact upload: passed
- Artifact name: `saas-full-billing-smoke-24958762851`

Downloaded artifact contents:

```text
metadata.md
smoke.log
summary.md
```

`summary.md` recorded `status: PASS`, `smokeOutcome: success`, and the same full-profile non-writing function smoke pass set as the branch run.

Post-merge main domestic payment E2E validation:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref main \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=true
```

Result:

- Run ID: `24958852162`
- URL: `https://github.com/zensgit/jive/actions/runs/24958852162`
- Head SHA: `d6e922a0ef45aace7b7fa58f602ff5b88f91ea52`
- Conclusion: `success`
- Step Summary generation: passed
- Artifact guard: passed
- Artifact upload: passed
- Artifact name: `saas-full-billing-smoke-24958852162`

Downloaded artifact contents:

```text
metadata.md
smoke.log
summary.md
```

`summary.md` recorded the full non-writing smoke pass set plus:

```text
[saas-function-smoke] domestic payment E2E smoke enabled; creating temporary staging user/order
[saas-function-smoke] PASS: domestic E2E creates temporary auth user -> HTTP 200
[saas-function-smoke] PASS: domestic E2E signs in temporary user -> HTTP 200
[saas-function-smoke] PASS: domestic E2E creates payment order -> HTTP 201
[saas-function-smoke] PASS: domestic E2E posts paid webhook -> HTTP 200
[saas-function-smoke] PASS: domestic E2E reads projected subscription -> HTTP 200
[saas-function-smoke] PASS: domestic E2E subscription projection matches temporary order
[saas-function-smoke] cleanup: payment event -> HTTP 204
[saas-function-smoke] cleanup: subscription projection -> HTTP 204
[saas-function-smoke] cleanup: payment order -> HTTP 204
[saas-function-smoke] cleanup: auth user -> HTTP 200
```

## Deferred

- No change to the existing core staging workflow; it already has its own report upload path.
- No new production payment provider integration.
- No new database migration or Supabase Function API.
