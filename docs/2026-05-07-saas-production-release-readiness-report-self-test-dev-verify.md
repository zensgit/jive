# SaaS Production Release Readiness Report Self-Test - Dev Verify

Date: 2026-05-07

Branch: `codex/production-release-readiness-self-test`

Base: `28bdf63f85a0ff523d70f86d28fa91eba03dbd3d`

## Scope

This change adds a host-only fixture test for `scripts/report_saas_production_release_readiness.sh`.

The goal is to protect the production release readiness report contract without requiring real GitHub calls, GitHub Actions secrets, Supabase access, APK/AAB builds, or device access.

## Changes

- `scripts/report_saas_production_release_readiness.sh`
  - Added test injection points for the GitHub CLI binary, secret-check script, main SHA, workflow state, and latest CI summary.
  - Kept the default production behavior unchanged.
  - Still prints only redacted secret-check output and never reads or prints secret values.
- `scripts/test_saas_production_release_readiness_report.sh`
  - Added a fixture-based self-test that uses fake secret-check scripts.
  - Covers blocked workflow, missing minimum secrets, dry-run-ready secrets, signed-build-ready secrets, and strict blocked failure behavior.
- `.github/workflows/flutter_ci.yml`
  - Added shell syntax checks and the host-only self-test to the `saas_production_readiness_self_check` job.
- `scripts/should_run_saas_wave0_smoke.sh`
  - Added the readiness reporter and its self-test to the Wave0 trigger path set.
- `scripts/test_saas_wave0_smoke_trigger.sh`
  - Added assertions that both readiness reporter paths trigger Wave0.
- `docs/saas-ops-checklist.md`
  - Added the local no-secret self-test command.

## Validation

### Script Syntax

Command:

```bash
for script in \
  scripts/report_saas_production_release_readiness.sh \
  scripts/test_saas_production_release_readiness_report.sh \
  scripts/check_saas_production_readiness.sh \
  scripts/build_saas_staging_apk.sh \
  scripts/build_release_candidate.sh \
  scripts/should_run_saas_wave0_smoke.sh \
  scripts/test_saas_wave0_smoke_trigger.sh; do
  bash -n "$script"
done
```

Result: passed.

### Production Release Readiness Report Fixture Test

Command:

```bash
scripts/test_saas_production_release_readiness_report.sh
```

Result: passed.

Covered fixtures:

- `blocked-workflow` -> `blocked`
- `missing-secrets` -> `blocked`
- `dry-run-ready` -> `dry-run-ready`
- `signed-build-ready` -> `signed-build-ready`
- `--strict` with blocked status exits non-zero

### Help Output

Commands:

```bash
scripts/report_saas_production_release_readiness.sh --help >/dev/null
scripts/test_saas_production_release_readiness_report.sh --help >/dev/null
```

Result: passed.

### Wave0 Trigger Test

Command:

```bash
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

### Existing Host-Only SaaS/Release Self-Tests

Commands:

```bash
scripts/test_release_report_summary_renderer.sh
scripts/test_saas_report_artifact_guard.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
```

Result: passed.

### Workflow YAML Parse

Command:

```bash
ruby -e 'require "yaml"; %w[.github/workflows/flutter_ci.yml .github/workflows/saas_release_candidate.yml].each { |f| YAML.load_file(f); puts "parsed #{f}" }'
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

- Did not read or print real GitHub Actions secret values.
- Did not deploy Supabase Edge Functions.
- Did not apply database migrations.
- Did not build APK/AAB artifacts.
- Did not run device or emulator tests.

## Outcome

The production release readiness report now has a deterministic local contract test. This reduces the risk of silently breaking the release checklist/report path while keeping the actual production release workflow secret-safe.
