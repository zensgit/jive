# SaaS Full Billing Smoke Workflow Self-Test Dev Verify

Date: 2026-05-10
Branch: `codex/saas-full-billing-smoke-self-test`

## Goal

Add host-only contract coverage for the `SaaS Full Billing Staging Smoke` workflow so payment staging smoke changes are checked before any real Supabase, Edge Function, payment, device, or secret access.

This slice is intentionally non-destructive:

- No real Supabase project was linked or mutated.
- No Edge Functions were deployed.
- No payment provider was called.
- No staging secrets were read.
- No device or APK install was required.

## Changes

- Added `scripts/test_saas_full_billing_staging_smoke_workflow.sh`.
- Wired the new self-test into `.github/workflows/flutter_ci.yml` under `saas_production_readiness_self_check`.
- Updated `scripts/should_run_saas_wave0_smoke.sh` so full billing workflow/self-test changes trigger Wave0 smoke.
- Updated `scripts/test_saas_wave0_smoke_trigger.sh` with the new trigger paths.

## Contract Coverage

The new self-test verifies:

- Domestic payment E2E remains opt-in.
- Core full-billing smoke secrets are guarded.
- Supabase access token/project ref are required only when syncing runtime secrets or deploying smoke functions.
- Service role key is required and written only for `run_domestic_payment_e2e=true`.
- `DOMESTIC_PAYMENT_WEBHOOK_TOKEN` is synced through Supabase runtime secrets.
- `create-payment-order` and `domestic-payment-webhook` deploy commands remain present.
- `domestic-payment-webhook` keeps `--no-verify-jwt`.
- Full billing smoke invokes `scripts/run_saas_staging_function_smoke.sh --profile full`.
- Report upload remains gated by `scripts/guard_saas_report_artifacts.sh`.
- Function smoke keeps billing auth checks and optional write-path checks.

## Verification

Passed:

```bash
bash -n scripts/run_saas_staging_function_smoke.sh \
  scripts/test_saas_full_billing_staging_smoke_workflow.sh \
  scripts/should_run_saas_wave0_smoke.sh \
  scripts/test_saas_wave0_smoke_trigger.sh
```

Passed:

```bash
scripts/test_saas_full_billing_staging_smoke_workflow.sh --help >/dev/null
scripts/run_saas_staging_function_smoke.sh --help >/dev/null
```

Passed:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); YAML.load_file(".github/workflows/saas_full_billing_staging_smoke.yml"); puts "yaml ok"'
```

Passed:

```bash
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Passed:

```bash
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_production_release_readiness_report.sh
```

Passed:

```bash
scripts/test_saas_report_artifact_guard.sh
scripts/test_release_report_summary_renderer.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
```

Passed with existing info-level lints only:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Passed:

```bash
scripts/run_saas_wave0_smoke.sh
```

Passed:

```bash
git diff --check
```

## Notes

`flutter analyze --no-fatal-infos` reported 83 existing info-level lint messages and no errors or warnings. This change did not touch Dart source.
