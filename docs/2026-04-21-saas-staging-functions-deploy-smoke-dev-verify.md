# SaaS Staging Functions Deploy + Smoke Development Verification

Date: 2026-04-21

## Summary

This round completed the first deployed Supabase Edge Functions validation for the SaaS core staging lane.

The work intentionally stayed inside the core staging boundary:

- Deployed only the core Edge Functions: `analytics`, `send-notification`, and `admin`.
- Did not apply database migrations.
- Did not build an APK in the deploy/smoke runs.
- Added a small CI/script fix so core deployed function smoke only probes the functions deployed by the core profile.

## Repository State

- Base before this round: `db1a104b` (`docs: record saas staging migration apply (#174)`)
- Script fix merged: `f01f0367` (`ci: scope staging function smoke by profile (#175)`)
- Current target branch after merge: `main`

## Development Change

PR: https://github.com/zensgit/jive/pull/175

Files changed:

- `scripts/run_saas_staging_function_smoke.sh`
- `scripts/run_saas_core_staging_lane.sh`

What changed:

- Added `--profile full|core` and `--core-only` to `run_saas_staging_function_smoke.sh`.
- Kept `full` as the default profile, preserving the existing full smoke coverage.
- Made `core` smoke check only:
  - `analytics`
  - `admin`
  - `send-notification`
- Kept billing/webhook/domestic-payment smoke in the `full` profile.
- Updated `run_saas_core_staging_lane.sh` to pass `--profile core` when running deployed function smoke.

Why:

The core deployment profile only deploys `analytics`, `send-notification`, and `admin`. Before PR #175, the deployed function smoke also probed full-profile endpoints such as `verify-subscription`, `subscription-webhook`, and domestic payment endpoints. That made core staging validation depend on functions outside the deployment scope and could create false failures.

## Local Verification

Commands run:

```bash
bash -n scripts/run_saas_staging_function_smoke.sh scripts/run_saas_core_staging_lane.sh scripts/run_saas_staging_rollout.sh
scripts/run_saas_staging_function_smoke.sh --help
```

Additional local mock verification:

- `--profile core` passed against a local mock HTTP server without `PUBSUB_BEARER_TOKEN`.
- The mock returned success only for `analytics`, `admin`, and `send-notification`, confirming core smoke did not call billing/webhook endpoints.
- `--profile full` still fails fast when `PUBSUB_BEARER_TOKEN` is missing.

Key local smoke output:

```text
[saas-function-smoke] profile: core
[saas-function-smoke] billing and webhook smoke skipped for core profile
[saas-function-smoke] PASS: analytics rejects missing admin token -> HTTP 401
[saas-function-smoke] PASS: analytics summary accepts admin token -> HTTP 200
[saas-function-smoke] PASS: admin rejects anon token -> HTTP 401
[saas-function-smoke] PASS: admin summary accepts admin token -> HTTP 200
[saas-function-smoke] PASS: send-notification dry run accepts notification token -> HTTP 200
[saas-function-smoke] function smoke passed
```

## CI Verification

PR #175 CI:

- Run: https://github.com/zensgit/jive/actions/runs/24723410177
- Result: success
- `analyze_and_test`: passed
- `detect_saas_wave0_smoke`: passed
- `saas_wave0_smoke`: passed
- `android_integration_test`: skipped by workflow rules

Post-merge main CI:

- Run: https://github.com/zensgit/jive/actions/runs/24723560869
- Result: success
- Head SHA: `f01f03673295f894d656cba501218400df1b2efe`
- `analyze_and_test`: passed
- `detect_saas_wave0_smoke`: passed
- `saas_wave0_smoke`: passed
- `android_integration_test`: skipped by workflow rules

## Staging Deploy-Only Verification

Run: https://github.com/zensgit/jive/actions/runs/24723093828

Inputs:

```text
run_local_smoke=true
apply_migrations=false
deploy_functions=true
run_function_smoke=false
build_apk=false
```

Result: success

Confirmed behavior:

- Strict readiness passed.
- Local Wave0 SaaS smoke passed.
- Migration dry-run reported the remote database was up to date.
- Migration apply was skipped.
- Core staging secrets were pushed to Supabase.
- Deployed only:
  - `analytics`
  - `send-notification`
  - `admin`
- Deployed function smoke was skipped.
- APK build was skipped.

Relevant log evidence:

```text
[saas-core-lane] previewing staging migrations
Remote database is up to date.
[saas-core-lane] skipping migration apply
[saas-core-lane] deploying staging Edge Functions
[saas-staging-rollout] deploying function analytics
Deployed Functions on project ***: analytics
[saas-staging-rollout] deploying function send-notification
Deployed Functions on project ***: send-notification
[saas-staging-rollout] deploying function admin
Deployed Functions on project ***: admin
[saas-core-lane] skipping deployed Functions smoke
[saas-core-lane] skipping staging APK build
[saas-core-lane] core staging lane completed
```

## Staging Deployed Function Smoke Verification

Run: https://github.com/zensgit/jive/actions/runs/24723677365

Inputs:

```text
run_local_smoke=false
apply_migrations=false
deploy_functions=true
run_function_smoke=true
build_apk=false
```

Result: success

Confirmed behavior:

- Strict readiness passed.
- Main CI was green at `f01f03673295f894d656cba501218400df1b2efe`.
- Local Wave0 SaaS smoke was intentionally skipped for this run.
- Migration dry-run reported the remote database was up to date.
- Migration apply was skipped.
- Re-deployed only:
  - `analytics`
  - `send-notification`
  - `admin`
- Ran deployed function smoke with `profile: core`.
- Billing/webhook smoke was intentionally skipped for the core profile.
- APK build was skipped.

Relevant log evidence:

```text
[saas-readiness] summary: failures=0 warnings=0 profile=core strict=1 online=1 run_smoke=0
[saas-core-lane] skipping local Wave0 SaaS smoke
[saas-core-lane] previewing staging migrations
Remote database is up to date.
[saas-core-lane] skipping migration apply
[saas-core-lane] deploying staging Edge Functions
[saas-staging-rollout] deploying function analytics
Deployed Functions on project ***: analytics
[saas-staging-rollout] deploying function send-notification
Deployed Functions on project ***: send-notification
[saas-staging-rollout] deploying function admin
Deployed Functions on project ***: admin
[saas-core-lane] running deployed Functions smoke
[saas-function-smoke] profile: core
[saas-function-smoke] billing and webhook smoke skipped for core profile
[saas-function-smoke] PASS: analytics rejects missing admin token -> HTTP 401
[saas-function-smoke] PASS: analytics summary accepts admin token -> HTTP 200
[saas-function-smoke] PASS: admin rejects anon token -> HTTP 401
[saas-function-smoke] PASS: admin summary accepts admin token -> HTTP 200
[saas-function-smoke] PASS: send-notification dry run accepts notification token -> HTTP 200
[saas-function-smoke] function smoke passed
[saas-core-lane] skipping staging APK build
[saas-core-lane] core staging lane completed
```

## Expected Warning

Both deploy/smoke runs can show this warning when `build_apk=false` and no staging report artifact is produced:

```text
No files were found with the provided path: build/reports/saas-staging
```

This is expected for these scoped runs and did not affect the job conclusion.

## Current Staging Readiness

Completed:

- GitHub Actions secrets are sufficient for the core staging lane.
- Staging database migrations are aligned.
- Core Edge Functions deploy successfully.
- Deployed core Edge Functions pass runtime smoke checks.
- Main CI is green after the smoke profile fix.

Not covered by this core-profile run:

- Full billing function smoke for `verify-subscription`.
- Full Google/Apple subscription webhook smoke.
- Domestic payment function smoke.
- APK install/device verification from a freshly built staging artifact.

## Recommended Next Step

Build a fresh staging APK from current `main` with `build_apk=true` and no database/function mutations:

```bash
gh workflow run saas_core_staging.yml \
  --ref main \
  -f run_local_smoke=false \
  -f apply_migrations=false \
  -f deploy_functions=false \
  -f run_function_smoke=false \
  -f build_apk=true
```

That gives the next deploy-test artifact using the now-validated staging backend. After the APK is built, install it on the test phone and verify login/sync/analytics-visible flows against staging.
