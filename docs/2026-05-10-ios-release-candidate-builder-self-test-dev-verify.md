# iOS Release Candidate Builder Self-Test Dev Verify

Date: 2026-05-10
Branch: `codex/ios-release-candidate-self-test`

## Goal

Add host-only fixture coverage for `scripts/build_ios_release_candidate.sh` so the iOS release candidate reporting lane is protected without requiring real Xcode builds, iOS devices, code signing, network access, or Flutter SDK execution.

## Changes

- Added `scripts/test_ios_release_candidate_builder.sh`.
- Added `JIVE_IOS_RELEASE_REPORT_DIR` to `scripts/build_ios_release_candidate.sh`, preserving the existing default report path.
- Improved the successful iOS release candidate Markdown report by including `status` and `message`.
- Wired the self-test into `.github/workflows/flutter_ci.yml` under `release_smoke_script_self_check`.

## Fixture Coverage

The new self-test uses fake `flutter` and `xcodebuild` commands to cover:

- Missing iOS platform fast-fail:
  - `xcodebuild -showdestinations` reports `Any iOS Device` not installed.
  - Script exits `2`.
  - Preflight JSON/Markdown reports `missingPlatform`.
  - `flutter build ios` is not called.
- Build failure:
  - Destinations are available.
  - Fake `flutter build ios` exits non-zero.
  - Blocking release report is written with failure output.
- Successful unsigned build:
  - Fake `flutter build ios` creates `Runner.app`.
  - Script copies `Runner.app` to the artifact directory.
  - JSON report status is `review`.
  - Markdown report includes successful unsigned build status/message.

## Verification

Passed:

```bash
bash -n scripts/build_ios_release_candidate.sh scripts/test_ios_release_candidate_builder.sh .github/workflows/flutter_ci.yml
```

Passed:

```bash
scripts/test_ios_release_candidate_builder.sh --help >/dev/null
scripts/test_ios_release_candidate_builder.sh
```

Passed:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "yaml ok"'
```

Passed:

```bash
scripts/test_ios_release_candidate_builder.sh
scripts/test_release_report_summary_renderer.sh
scripts/test_saas_report_artifact_guard.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Passed:

```bash
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_production_release_readiness_report.sh
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
