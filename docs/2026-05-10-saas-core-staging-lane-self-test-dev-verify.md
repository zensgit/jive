# SaaS Core Staging Lane Self-Test - Dev Verify

Date: 2026-05-10

Branch: `codex/saas-core-lane-self-test`

Base: `e6d2cbeacf5fcfa224c8ae22599f713a471dd181`

## Scope

This change adds a host-only fixture test for `scripts/run_saas_core_staging_lane.sh`.

The core staging lane is the one-command entrypoint for staging readiness, local smoke, migration preview/apply, function deploy/smoke, optional sync smoke, and APK build. The new self-test protects the lane's orchestration and safety switches without touching real staging infrastructure.

## Changes

- `scripts/test_saas_core_staging_lane.sh`
  - Adds fake `gh`, `npx`, and `flutter` binaries.
  - Verifies the all-skipped host-only lane completes with:
    - `--skip-local-smoke`
    - `--skip-dry-run`
    - `--skip-apply`
    - `--skip-deploy`
    - `--skip-function-smoke`
    - `--skip-apk`
    - `--skip-online-readiness`
  - Covers parsing for:
    - `--project-ref`
    - `--db-password`
    - `--access-token`
    - `--db-url`
    - `--functions-url`
    - `--pg-fallback`
    - `--pg-lock-timeout`
    - `--pg-statement-timeout`
  - Verifies missing `SUPABASE_ACCESS_TOKEN` blocks before rollout when a deploy-required path is enabled.
  - Verifies unknown arguments fail before initialization.
  - Checks fixture secret values are not printed to stdout or stderr.
- `.github/workflows/flutter_ci.yml`
  - Adds shell syntax checks, help checks, and execution of the new self-test in the host-only SaaS readiness CI job.
- `scripts/should_run_saas_wave0_smoke.sh`
  - Adds the new self-test path to the Wave0 trigger set.
- `scripts/test_saas_wave0_smoke_trigger.sh`
  - Adds a trigger assertion for the new self-test path.
- `docs/2026-04-10-saas-staging-apply-runbook.md`
  - Documents the core staging lane self-test command.
- `docs/2026-04-18-saas-deployment-test-readiness.md`
  - Lists the core lane self-test next to the deployment readiness self-test before real staging secret preparation.

## Validation

### Script Syntax, Help, and Core Lane Fixture Test

Command:

```bash
bash -n \
  scripts/run_saas_core_staging_lane.sh \
  scripts/test_saas_core_staging_lane.sh \
  scripts/check_saas_deployment_readiness.sh \
  scripts/test_saas_deployment_readiness.sh \
  scripts/should_run_saas_wave0_smoke.sh \
  scripts/test_saas_wave0_smoke_trigger.sh

scripts/run_saas_core_staging_lane.sh --help >/dev/null
scripts/test_saas_core_staging_lane.sh --help >/dev/null
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

### Adjacent SaaS Readiness Regression Self-Tests

Command:

```bash
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

- Did not run real staging migrations.
- Did not deploy Supabase Edge Functions.
- Did not run deployed Function smoke.
- Did not run staging sync smoke against Supabase.
- Did not build APK/AAB artifacts.
- Did not call real GitHub or Supabase CLIs from the new self-test.
- Did not read, print, or upload real secrets.
- Did not run a device or emulator.

## Outcome

The SaaS core staging lane now has a deterministic local contract test. Future edits to lane argument parsing, skip flags, readiness sequencing, and deploy-required guardrails can be reviewed and CI-validated without risking staging side effects.
