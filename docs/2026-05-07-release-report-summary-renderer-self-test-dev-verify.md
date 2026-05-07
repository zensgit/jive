# Release Report Summary Renderer Self-Test Dev & Verify

Date: 2026-05-07
Branch: `codex/release-report-summary-self-test`
Base: `origin/main@e9a2e099767bf2a0642a7424804364af9768d1c4`

## Goal

Protect the release report step-summary renderer with a host-only contract test.

`scripts/render_release_report_summary.sh` turns JSON reports under `build/reports` into CI Markdown summaries. It is part of the deployment/release visibility chain, but previously had only historical manual validation. This change adds a repeatable self-test that can run in GitHub Actions without secrets, devices, emulators, Flutter runtime flows, Xcode, or Supabase access.

## Changes

- Added `scripts/test_release_report_summary_renderer.sh`.
- Added `--help` support to `scripts/render_release_report_summary.sh`.
- Added `JIVE_RELEASE_REPORT_DIR` support so tests can render temporary fixtures without writing to `build/reports`.
- Made `scripts/render_release_report_summary.sh` executable because the CI self-check invokes scripts directly.
- Cleaned the default heading from `Release Release Report Summary` to `Release Report Summary`.
- Wired the new self-test into `.github/workflows/flutter_ci.yml` under `release_smoke_script_self_check`.
- Updated `docs/release_report_step_summary_mvp.md`.

## Self-Test Coverage

- Empty report root renders the no-report message.
- Android release candidate report section renders status, mode, artifact, flavor, signing mode, and message.
- iOS release candidate report section renders status, codesign, reason, and recommendation.
- Sync runtime report section renders telemetry/action fields.
- Account book/import/sync report section renders.
- Import column mapping report section renders.
- `GITHUB_STEP_SUMMARY` append works.
- Repeated renders are stable for identical fixture input.

## Local Verification

```bash
for script in scripts/render_release_report_summary.sh scripts/test_release_report_summary_renderer.sh scripts/run_release_smoke.sh scripts/run_release_android_smoke.sh scripts/run_android_local_feature_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/render_release_android_smoke_summary.sh scripts/test_release_android_smoke_artifact_verifier.sh scripts/test_release_android_smoke_summary_renderer.sh scripts/should_run_saas_wave0_smoke.sh scripts/test_saas_wave0_smoke_trigger.sh; do bash -n "$script"; done
```

Result: passed.

```bash
scripts/test_release_report_summary_renderer.sh
```

Result: passed.

```text
[release-report-summary-test] empty report root surfaces no-report message
[release-report-summary-test] all sections and optional fields render
[release-report-summary-test] GITHUB_STEP_SUMMARY append works
[release-report-summary-test] repeated render is stable
[release-report-summary-test] all summary renderer self-tests passed
```

```bash
scripts/render_release_report_summary.sh --help
scripts/test_release_report_summary_renderer.sh --help
```

Result: passed.

```bash
tmp_dir=$(mktemp -d); JIVE_RELEASE_REPORT_DIR="$tmp_dir" scripts/render_release_report_summary.sh release; rm -rf "$tmp_dir"
```

Result: passed and printed:

```text
## Release Report Summary

- No JSON reports found under `build/reports`.
```

```bash
scripts/test_release_android_smoke_artifact_verifier.sh
```

Result: passed.

```bash
scripts/test_release_android_smoke_summary_renderer.sh
```

Result: passed.

```bash
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "workflow yaml parsed"'
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

- The first local self-test attempt exposed that `scripts/render_release_report_summary.sh` was not executable. This PR fixes that file mode so CI and local invocation behave consistently.
- No app feature code, database schema, Supabase function behavior, release signing config, secrets, emulator, or device flow changed.
