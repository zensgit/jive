# Android Local Feature Smoke Runner Self-Test Dev/Verify

Date: 2026-05-11

## Goal

Add host-only contract coverage for `scripts/run_android_local_feature_smoke.sh` and wire it into the existing Flutter CI release smoke script self-check. The test validates the runner's orchestration behavior without requiring Flutter build output, Android SDK, adb server, emulator boot, APK install, or a physical device.

## Changes

- Added `scripts/test_android_local_feature_smoke_runner.sh`.
- Added the new self-test to `.github/workflows/flutter_ci.yml` under `release_smoke_script_self_check`.
- Kept the change limited to script/CI validation. No Dart production code, app UI, Supabase schema, Edge Function, payment logic, or runtime Android flow changed.

## Contract Coverage

- `--help` exits successfully without resolving Flutter, adb, or emulator tools.
- Invalid scenarios fail fast during argument parsing before tool resolution.
- A guest-home run with `--skip-build`, `--skip-install`, `--skip-emulator-launch`, and `--skip-onboarding` still launches the app, captures artifacts, and writes a passed summary.
- The transaction-entry scenario can drive the fake UI hierarchy through keypad/operator actions and verify the `1+2×3 = 7.00` anchors.
- Signature mismatch install retry honors `--allow-uninstall-on-signature-mismatch`, uninstalls the package, and retries installation.
- Summary metadata records the effective scenario and artifact directory.

## Verification

Run from `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-feature-smoke-self-test`.

```bash
bash -n scripts/run_android_local_feature_smoke.sh scripts/test_android_local_feature_smoke_runner.sh scripts/run_release_android_smoke.sh scripts/test_release_android_smoke_wrapper.sh
scripts/test_android_local_feature_smoke_runner.sh
```

Result: passed.

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "yaml ok"'
```

Result: passed.

```bash
scripts/test_release_report_summary_renderer.sh
scripts/test_saas_report_artifact_guard.sh
scripts/test_ios_release_candidate_builder.sh
scripts/test_release_android_smoke_wrapper.sh
scripts/test_android_local_feature_smoke_runner.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

```bash
scripts/run_saas_wave0_smoke.sh
```

Result: passed.

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: exit 0. Existing info-level lints remain, with no analyzer errors or warnings.

```bash
git diff --check
```

Result: passed.

## Limitations

- This is a host-only fixture test. It does not build a real APK, start a real emulator, talk to a real adb server, install to a real device, or verify rendered Flutter pixels.
- Real Android release smoke remains covered by the runtime runner, release wrapper, artifact verifier, summary renderer, and staging/device lanes. This PR only makes runner orchestration regressions fail fast in CI.
