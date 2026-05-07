# SaaS Report Artifact Guard Dev & Verify

Date: 2026-05-07
Branch: `codex/saas-report-artifact-guard`
Base: `origin/main@7d08654d7d17faaf9795e8170fa65e8c0d82f8a6`

## Goal

Centralize the SaaS/release report artifact guard and make it self-tested.

The staging, full billing, and release candidate workflows all upload report artifacts after deployment or release checks. Before this change, each workflow carried its own inline guard logic, and only the full billing workflow checked for known secret values inside report files. This change gives those lanes one shared host-only guard script and a fixture-based self-test that runs in CI without secrets or devices.

## Changes

- Added `scripts/guard_saas_report_artifacts.sh`.
- Added `scripts/test_saas_report_artifact_guard.sh`.
- Replaced inline artifact guard logic in:
  - `.github/workflows/saas_core_staging.yml`
  - `.github/workflows/saas_full_billing_staging_smoke.yml`
  - `.github/workflows/saas_release_candidate.yml`
- Wired the self-test into `.github/workflows/flutter_ci.yml` under `release_smoke_script_self_check`.
- Added the guard scripts to the SaaS Wave0 auto-trigger path contract.
- Updated `docs/release_smoke_lane_mvp.md`.
- Changed core staging and release candidate report uploads to require guard success before upload.

## Guard Behavior

Blocked sensitive-looking filenames:

- `*.env`
- `*.pem`
- `*.key`
- `*.keystore`
- `*.jks`
- `*.p12`
- `*.pfx`
- `*secret*`
- `*secrets*`
- `*credential*`
- `*credentials*`
- `*dart-defines*`

Optional secret value scan:

- Each workflow can pass `--secret-env <NAME>`.
- Empty values and values shorter than 8 characters are ignored to avoid noisy placeholder matches.
- If a configured secret value appears in report files, the guard fails and reports the environment variable name plus file path, never the secret value itself.

Upload gating:

- `saas_full_billing_staging_smoke.yml` already uploaded only when its guard succeeded.
- This change applies the same safety semantics to `saas_core_staging.yml` and `saas_release_candidate.yml`.

## Local Verification

```bash
for script in scripts/guard_saas_report_artifacts.sh scripts/test_saas_report_artifact_guard.sh scripts/render_release_report_summary.sh scripts/test_release_report_summary_renderer.sh scripts/run_release_smoke.sh scripts/run_release_android_smoke.sh scripts/run_android_local_feature_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/render_release_android_smoke_summary.sh scripts/test_release_android_smoke_artifact_verifier.sh scripts/test_release_android_smoke_summary_renderer.sh scripts/should_run_saas_wave0_smoke.sh scripts/test_saas_wave0_smoke_trigger.sh; do bash -n "$script"; done
```

Result: passed.

```bash
scripts/test_saas_report_artifact_guard.sh
```

Result: passed.

```text
[saas-report-artifact-guard-test] pass fixture ok: clean-root
[saas-report-artifact-guard-test] pass fixture ok: missing-root
[saas-report-artifact-guard-test] negative fixture ok: blocked-env-file
[saas-report-artifact-guard-test] negative fixture ok: blocked-dart-defines
[saas-report-artifact-guard-test] negative fixture ok: multi-root-blocked
[saas-report-artifact-guard-test] negative fixture ok: leaked-secret-value
[saas-report-artifact-guard-test] pass fixture ok: short-secret-value-ignored
[saas-report-artifact-guard-test] pass fixture ok: unset-secret-env-ignored
[saas-report-artifact-guard-test] all artifact guard self-tests passed
```

```bash
scripts/guard_saas_report_artifacts.sh --help
scripts/test_saas_report_artifact_guard.sh --help
```

Result: passed.

```bash
ruby -e 'require "yaml"; %w[.github/workflows/flutter_ci.yml .github/workflows/saas_core_staging.yml .github/workflows/saas_full_billing_staging_smoke.yml .github/workflows/saas_release_candidate.yml].each { |f| YAML.load_file(f); puts "parsed #{f}" }'
```

Result: passed.

```bash
scripts/test_release_report_summary_renderer.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

```bash
git diff --check
```

Result: passed.

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: passed with 0 errors and 0 warnings. Existing info-level lints remain outside this change.

```bash
bash scripts/run_saas_wave0_smoke.sh
```

Result: passed.

Covered lanes included sync, subscription webhook, trusted subscription client/server tests, verify-subscription, create-payment-order, domestic-payment-webhook, auth, analytics, notification, and admin smoke tests.

## Notes

- No app feature code, database schema, Supabase function behavior, production signing config, real secrets, emulator, or device flow changed.
- This PR intentionally centralizes guard semantics. Future SaaS/report workflows should call `scripts/guard_saas_report_artifacts.sh` instead of duplicating inline `find` / `grep` logic.
