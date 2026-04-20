# SaaS Core Staging Safe Run Dev & Verify

Date: 2026-04-20
Branch under test: `main`
Commit under test: `899c3c5cc551878dc017f929601acb735c41426f`
Workflow run: https://github.com/zensgit/jive/actions/runs/24675515286

## Goal

Verify the SaaS core staging lane after the CI Node 24 workflow cleanup, without applying database migrations or deploying Edge Functions.

This run was intended as a deployment-preflight check:

- Confirm core staging GitHub secrets are present.
- Confirm strict SaaS readiness passes.
- Confirm the local SaaS Wave0 smoke lane passes in GitHub Actions.
- Confirm remote migration dry-run can connect and report pending migrations.
- Confirm a staging dev debug APK can be built with client-safe Supabase dart-defines.
- Confirm uploaded staging build reports can be downloaded and inspected.

## Workflow Inputs

```text
workflow: saas_core_staging.yml
ref: main
run_local_smoke: true
apply_migrations: false
deploy_functions: false
run_function_smoke: false
build_apk: true
```

## Safety Boundary

This run did not apply remote database migrations and did not deploy Edge Functions.

The workflow skipped:

- `Guard deploy secrets`, because deploy/function-smoke inputs were false.
- Migration apply.
- Edge Function deploy.
- Deployed Functions smoke.

The run did execute:

- Core secrets guard.
- Strict readiness with online checks.
- Local SaaS Wave0 smoke.
- Supabase migration dry-run.
- Staging dev debug APK build.
- Staging report artifact upload.

## Results

GitHub Actions completed successfully.

```text
core_staging: passed
duration: 9m16s
```

Step summary:

```text
Guard core staging secrets: passed
Setup Java: passed
Setup Flutter: passed
Setup Node: passed
Create staging env file: passed
Guard deploy secrets: skipped as expected
Run core staging lane: passed
Upload SaaS staging reports: passed
```

Readiness summary:

```text
failures=0
warnings=0
profile=core
strict=1
online=1
```

Online readiness confirmed:

- Main Flutter CI was green at `899c3c5cc551878dc017f929601acb735c41426f`.
- Supabase CLI was reachable through `npx`.
- Core env keys were present in the generated staging env file.
- Service role was present for server-side staging checks but was not passed to the Flutter client build.

## SaaS Wave0 Smoke

The local SaaS Wave0 smoke lane completed successfully in the staging workflow.

Covered areas included:

- Sync smoke.
- Subscription webhook smoke.
- Client/server-truth billing analyze and tests.
- Verify-subscription smoke.
- Create-payment-order smoke.
- Domestic-payment-webhook smoke.
- Auth analyze and tests.
- Analytics smoke.
- Notification smoke.
- Admin smoke.

## Migration Dry-Run

The Supabase migration dry-run connected to the remote database and completed without applying changes.

Dry-run reported one pending migration:

```text
013_create_domestic_payment_orders.sql
```

This means the staging database is not yet fully aligned with the current SaaS/domestic-payment code. The next write-capable staging step should apply this migration intentionally before deploying or exercising domestic payment order creation against staging.

## APK Build

The staging dev debug APK was built successfully.

Downloaded artifact report:

```text
artifactName: app-dev-debug.apk
artifactBytes: 253777249
sha256: 3a106f8465141adde9348a5d3df64705a021f061c2b2d5c55fda87ac09d1acff
supabaseUrlConfigured: true
supabaseAnonKeyConfigured: true
serviceRolePassedToClient: false
```

Local artifact verification after downloading the GitHub Actions artifact:

```text
sha256: 3a106f8465141adde9348a5d3df64705a021f061c2b2d5c55fda87ac09d1acff
size: 242M
```

Downloaded local artifact path:

```text
/tmp/jive-saas-staging-run-24675515286/saas-staging-reports-24675515286/saas-staging/20260420-153756-dev-debug/app-dev-debug.apk
```

Downloaded report paths:

```text
/tmp/jive-saas-staging-run-24675515286/saas-staging-reports-24675515286/reports/saas-staging/latest.md
/tmp/jive-saas-staging-run-24675515286/saas-staging-reports-24675515286/reports/saas-staging/saas-staging-build.json
```

## Commands Used

```bash
gh workflow run saas_core_staging.yml \
  --ref main \
  -f run_local_smoke=true \
  -f apply_migrations=false \
  -f deploy_functions=false \
  -f run_function_smoke=false \
  -f build_apk=true
```

```bash
gh run watch 24675515286 --interval 15
```

```bash
gh run download 24675515286 -D /tmp/jive-saas-staging-run-24675515286
```

```bash
shasum -a 256 /tmp/jive-saas-staging-run-24675515286/saas-staging-reports-24675515286/saas-staging/20260420-153756-dev-debug/app-dev-debug.apk
```

## Recommendation

The staging preflight lane is healthy. The next step is a controlled write-capable staging run:

```text
run_local_smoke: true
apply_migrations: true
deploy_functions: false
run_function_smoke: false
build_apk: false
```

After migration apply succeeds, run another dry-run or staging lane to confirm there are no pending migrations. Then deploy Edge Functions and run deployed function smoke in a separate step.

Recommended sequence:

1. Apply pending migration only.
2. Re-run dry-run to confirm no pending migrations.
3. Deploy Edge Functions.
4. Run deployed function smoke.
5. Build release candidate artifact.
