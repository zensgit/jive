# Release Android Smoke Wrapper Self-Test Dev/Verify

Date: 2026-05-11

## Goal

Add a host-only contract test for `scripts/run_release_android_smoke.sh` and wire it into the existing Flutter CI release smoke script self-check. The intent is to catch wrapper regressions without requiring Flutter, Android SDK, adb, an emulator, or a physical device.

## Changes

- Added `scripts/test_release_android_smoke_wrapper.sh`.
- Added the wrapper self-test to `.github/workflows/flutter_ci.yml` under `release_smoke_script_self_check`.
- Kept the change limited to CI/script validation; no Dart production code, Supabase schema, Edge Function, or app behavior changed.

## Contract Coverage

- `--help` exits successfully without requiring downstream Android tooling.
- Default wrapper invocation delegates to `run_android_local_feature_smoke.sh` with `--scenario all`, `--fresh-install`, `--allow-uninstall-on-signature-mismatch`, and the generated default artifact directory.
- `JIVE_RELEASE_ANDROID_SMOKE_SCENARIO` and `JIVE_RELEASE_ANDROID_SMOKE_ARTIFACT_DIR` override the default scenario and artifact directory.
- CLI `--artifact-dir` is appended after defaults and is the effective directory used by verification and summary rendering.
- Pass-through CLI `--scenario` can override the default scenario by appearing later in the delegated argument list.
- The verifier and renderer consume the final effective artifact directory and produce the expected marker outputs.

## Verification

Run from `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-release-android-smoke-wrapper-self-test`.

```bash
bash -n scripts/run_release_android_smoke.sh scripts/test_release_android_smoke_wrapper.sh
scripts/test_release_android_smoke_wrapper.sh
```

Result: passed.

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "yaml ok"'
```

Result: passed.

```bash
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
scripts/test_release_report_summary_renderer.sh
scripts/test_saas_report_artifact_guard.sh
scripts/test_ios_release_candidate_builder.sh
```

Result: passed.

```bash
scripts/test_saas_wave0_smoke_trigger.sh
scripts/test_saas_staging_apk_builder.sh
scripts/test_saas_staging_apk_installer.sh
scripts/test_saas_staging_device_smoke.sh
```

Result: passed.

```bash
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
scripts/test_saas_deployment_readiness.sh
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

- This is a host-only wrapper test. It does not build an APK, launch an emulator, connect adb, install to a device, or exercise real app UI.
- Real release Android smoke remains covered by the runtime scripts and staging/device lanes; this PR only makes the wrapper contract fail fast in CI.
