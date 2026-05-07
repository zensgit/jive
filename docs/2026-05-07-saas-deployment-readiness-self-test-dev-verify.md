# SaaS Deployment Readiness Self-Test - Dev Verify

Date: 2026-05-07

Branch: `codex/saas-deployment-readiness-self-test`

Base: `df8a89ad38bb4d0cc926a337f8abc8b1ee76acb9`

## Scope

This change adds a host-only fixture test for `scripts/check_saas_deployment_readiness.sh`.

The readiness script is the preflight gate for staging deployment lanes. The new self-test protects its expected behavior without requiring GitHub, Supabase, Flutter, devices, network access, or real secrets.

## Changes

- `scripts/test_saas_deployment_readiness.sh`
  - Adds fake `gh`, `npx`, and `flutter` binaries in a temporary `PATH`.
  - Creates temporary core and full staging env files.
  - Verifies strict core readiness succeeds.
  - Verifies strict full readiness succeeds when billing provider keys are present.
  - Verifies strict full readiness fails when billing provider keys are missing.
  - Verifies non-strict missing env file produces a warning but exits successfully.
  - Verifies `--online` uses fake GitHub and Supabase CLI probes.
  - Verifies an invalid profile exits with code 2.
  - Checks that fixture secret values are not printed to stdout or stderr.
- `.github/workflows/flutter_ci.yml`
  - Adds syntax checks, help checks, and execution of the deployment readiness self-test.
- `scripts/should_run_saas_wave0_smoke.sh`
  - Adds the new self-test path to the Wave0 trigger set.
- `scripts/test_saas_wave0_smoke_trigger.sh`
  - Adds a trigger assertion for the new self-test path.
- `docs/2026-04-10-saas-staging-apply-runbook.md`
  - Documents the local no-secret readiness gate contract test.
- `docs/2026-04-18-saas-deployment-test-readiness.md`
  - Adds the self-test command before real staging secret preparation.

## Validation

### Script Syntax, Help, and Fixture Test

Command:

```bash
bash -n \
  scripts/check_saas_deployment_readiness.sh \
  scripts/test_saas_deployment_readiness.sh \
  scripts/should_run_saas_wave0_smoke.sh \
  scripts/test_saas_wave0_smoke_trigger.sh

scripts/check_saas_deployment_readiness.sh --help >/dev/null
scripts/test_saas_deployment_readiness.sh --help >/dev/null
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

### Production Release Report Regression Self-Test

Command:

```bash
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

- Did not call real GitHub APIs from the new deployment readiness self-test.
- Did not call real Supabase CLI from the new deployment readiness self-test.
- Did not read, print, or upload real secrets.
- Did not deploy Edge Functions.
- Did not apply migrations.
- Did not build APK/AAB artifacts.
- Did not run a physical device or emulator.

## Outcome

The staging deployment readiness preflight now has a deterministic local contract test. This makes future edits to profile handling, strict mode, required env keys, online checks, and Wave0 trigger wiring safer to review and merge.
