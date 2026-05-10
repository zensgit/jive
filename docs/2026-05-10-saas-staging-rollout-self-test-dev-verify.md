# SaaS Staging Rollout Self-Test - Dev Verify

Date: 2026-05-10

Branch: `codex/saas-staging-rollout-self-test`

Base: `1154eb11c0677827e98aa4198d0ebb102cbbb7a2`

## Scope

This change adds a host-only fixture test for `scripts/run_saas_staging_rollout.sh`.

The staging rollout script is the lower-level deploy orchestrator behind the core staging lane. It owns preflight, migration dry-run/apply, secret push, Edge Function deploy, and direct Postgres fallback behavior. The new self-test protects those command shapes without touching real staging infrastructure.

## Changes

- `scripts/test_saas_staging_rollout.sh`
  - Adds a fake Supabase CLI through `SUPABASE_CMD`.
  - Adds a fake `python3` for direct Postgres fallback paths.
  - Uses temporary core/full env fixtures only.
  - Captures stdout, stderr, fake Supabase calls, fake Python calls, and generated secret subset files.
  - Verifies fixture secret values are not printed to stdout, stderr, Supabase logs, or Python logs.
- `.github/workflows/flutter_ci.yml`
  - Adds shell syntax checks, help checks, and execution of the rollout self-test in the host-only SaaS readiness CI job.
- `scripts/should_run_saas_wave0_smoke.sh`
  - Adds the rollout script and self-test paths to the Wave0 trigger set.
- `scripts/test_saas_wave0_smoke_trigger.sh`
  - Adds a trigger assertion for the new self-test path.
- `docs/2026-04-10-saas-staging-apply-runbook.md`
  - Documents the rollout self-test command.
- `docs/2026-04-18-saas-deployment-test-readiness.md`
  - Lists the rollout self-test before real staging secret preparation.

## Fixture Coverage

Covered positive paths:

- `preflight --profile core`
- `preflight --profile full`
- `dry-run --skip-link`
- `apply --skip-link`
- `deploy --profile core`
- `deploy --profile full`
- `dry-run --pg-fallback-only`
- `apply --pg-fallback-only`
- `dry-run --pg-fallback` after fake Supabase CLI failure
- `all --profile core --pg-fallback-only`

Covered negative paths:

- Missing `SUPABASE_ACCESS_TOKEN` blocks dry-run before `db push`.
- Missing `STAGING_DB_URL` blocks fallback-only mode.
- Unknown `--profile` exits non-zero.
- Unknown mode exits non-zero.
- Unknown argument exits non-zero.

Key assertions:

- Core deploy only targets `analytics`, `send-notification`, and `admin`.
- Full deploy targets the full function set.
- `verify-subscription` does not get `--no-verify-jwt`.
- Custom-auth functions get `--no-verify-jwt`.
- `dry-run --skip-link` and `apply --skip-link` do not call `supabase link`.
- Fallback-only paths do not call `supabase link` or `supabase db push`.
- Secret subset files do not include platform default keys:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`

## Validation

### Script Syntax, Help, and Rollout Fixture Test

Command:

```bash
bash -n scripts/run_saas_staging_rollout.sh scripts/test_saas_staging_rollout.sh
scripts/run_saas_staging_rollout.sh --help >/dev/null
scripts/test_saas_staging_rollout.sh --help >/dev/null
scripts/test_saas_staging_rollout.sh
```

Result: passed.

### Adjacent SaaS Self-Tests

Command:

```bash
scripts/test_saas_wave0_smoke_trigger.sh
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_production_release_readiness_report.sh
```

Result: passed.

### Workflow YAML Parse

Command:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "parsed flutter_ci.yml"'
```

Result: passed.

### Flutter Analyze

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: passed with existing info-level lints only. No errors or warnings were reported.

### Full Wave0 SaaS Smoke

Command:

```bash
scripts/run_saas_wave0_smoke.sh
```

Result: passed.

Covered lanes included:

- Sync book scope and tombstone tests
- Subscription webhook Deno tests
- Subscription server-truth analyze and Flutter tests
- Verify-subscription Deno tests
- Create-payment-order Deno tests
- Domestic-payment-webhook Deno tests
- Auth analyze and Flutter tests
- Analytics Deno tests
- Notification Deno tests
- Admin Deno tests

### Diff Hygiene

Command:

```bash
git diff --check
```

Result: passed.

## Non-Goals

- Did not call the real Supabase CLI.
- Did not run `npx`.
- Did not connect to Supabase or Postgres.
- Did not apply migrations.
- Did not push real secrets.
- Did not deploy Edge Functions.
- Did not run Flutter build, adb, emulator, or physical device tests.
- Did not read `/tmp/jive-saas-staging.env` or any real secret store.

## Outcome

The SaaS staging rollout script now has a deterministic local contract test for preflight, migration command shape, deploy command shape, fallback routing, and secret subset safety. This gives us a safer CI guardrail around the staging deploy path while keeping all real infrastructure untouched.
