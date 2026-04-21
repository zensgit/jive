# SaaS Staging Migration Apply Dev & Verify

Date: 2026-04-21
Branch under test: `main`
Commit under test: `cac77753e3d8dfb10515c6d2bfd7c76bfe39b0e9`

## Goal

Apply the single pending staging database migration found by the previous safe staging dry-run:

```text
013_create_domestic_payment_orders.sql
```

This was intentionally scoped to database migration alignment only. It did not deploy Edge Functions, did not run deployed function smoke, and did not build an APK.

## Apply Run

Workflow run: https://github.com/zensgit/jive/actions/runs/24721665717

Inputs:

```text
workflow: saas_core_staging.yml
ref: main
run_local_smoke: true
apply_migrations: true
deploy_functions: false
run_function_smoke: false
build_apk: false
```

Result:

```text
core_staging: passed
duration: 2m18s
```

Safety boundary:

- `Guard deploy secrets`: skipped as expected.
- Edge Functions deploy: skipped.
- Deployed Functions smoke: skipped.
- Staging APK build: skipped.
- Artifact upload warning was expected because APK/report generation was intentionally skipped.

Readiness summary:

```text
failures=0
warnings=0
profile=core
strict=1
online=1
```

Local SaaS Wave0 smoke completed before apply.

Migration dry-run before apply reported:

```text
Would push these migrations:
  • 013_create_domestic_payment_orders.sql
```

Apply step reported:

```text
Applying migration 013_create_domestic_payment_orders.sql...
Finished supabase db push.
```

## Post-Apply Verification Run

Workflow run: https://github.com/zensgit/jive/actions/runs/24721782306

Inputs:

```text
workflow: saas_core_staging.yml
ref: main
run_local_smoke: false
apply_migrations: false
deploy_functions: false
run_function_smoke: false
build_apk: false
```

Result:

```text
core_staging: passed
duration: 32s
```

The follow-up dry-run reported:

```text
DRY RUN: migrations will *not* be pushed to the database.
Connecting to remote database...
Remote database is up to date.
```

This confirms the staging database has no pending migrations after applying `013_create_domestic_payment_orders.sql`.

## Commands Used

```bash
gh workflow run saas_core_staging.yml \
  --ref main \
  -f run_local_smoke=true \
  -f apply_migrations=true \
  -f deploy_functions=false \
  -f run_function_smoke=false \
  -f build_apk=false
```

```bash
gh run watch 24721665717 --interval 15
```

```bash
gh workflow run saas_core_staging.yml \
  --ref main \
  -f run_local_smoke=false \
  -f apply_migrations=false \
  -f deploy_functions=false \
  -f run_function_smoke=false \
  -f build_apk=false
```

```bash
gh run watch 24721782306 --interval 15
```

## Outcome

Staging database schema is now aligned with the current domestic payment migration set.

The next staging step can move from schema alignment to Edge Function rollout:

```text
run_local_smoke: true
apply_migrations: false
deploy_functions: true
run_function_smoke: false
build_apk: false
```

After Edge Functions deploy succeeds, run deployed function smoke separately:

```text
run_local_smoke: false
apply_migrations: false
deploy_functions: true
run_function_smoke: true
build_apk: false
```

Keep the function smoke as a separate step so deployment failures and runtime/API failures remain easy to distinguish.
