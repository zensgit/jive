# Release Android Smoke Summary Renderer Self-Test Dev Verify

- Date: 2026-05-07
- Branch: `codex/release-smoke-renderer-self-test`
- Base: `main` @ `2f5caa31213c00ba0882fe665635626985fe5949`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-release-smoke-renderer-self-test`
- Retained fixture root: `/tmp/jive-release-android-smoke-summary-test.r89pD1`

## Changes

- Added `scripts/test_release_android_smoke_summary_renderer.sh`.
- The self-test creates minimal local smoke summary fixtures and validates `scripts/render_release_android_smoke_summary.sh` without adb, emulator, APK build, uploads, or secrets.
- `scripts/run_release_smoke.sh` now runs the summary renderer self-test after the artifact verifier self-test.
- `.github/workflows/flutter_ci.yml` now runs the summary renderer self-test in the lightweight `release_smoke_script_self_check` job.
- Updated `docs/release_smoke_lane_mvp.md` with the host-only renderer self-test command.

## Fixture Coverage

- Passed smoke + passed verification generates `overallStatus: passed`.
- Passed smoke + missing verification generates `verificationStatus: missing` and `overallStatus: missing`.
- Failed smoke summary generates `overallStatus: failed` even when verification is passed.
- Repeated rendering keeps `artifactFiles` stable because `latest.md` is excluded from the count.
- `JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR` can point at a temporary report directory.
- Report dir equal to artifact dir does not fail.

## Commands

Static checks:

```bash
for script in scripts/run_release_smoke.sh scripts/run_release_android_smoke.sh scripts/run_android_local_feature_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/render_release_android_smoke_summary.sh scripts/test_release_android_smoke_artifact_verifier.sh scripts/test_release_android_smoke_summary_renderer.sh; do
  bash -n "$script"
done
```

Self-tests:

```bash
scripts/test_release_android_smoke_summary_renderer.sh
scripts/test_release_android_smoke_summary_renderer.sh --keep-fixtures
tmp_report=$(mktemp -d /tmp/jive-summary-renderer-report.XXXXXX)
JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR="$tmp_report" scripts/test_release_android_smoke_summary_renderer.sh
test -f "$tmp_report/latest.md"
```

Full CI self-check local reproduction:

```bash
scripts/verify_release_android_smoke_artifacts.sh --help >/dev/null
scripts/render_release_android_smoke_summary.sh --help >/dev/null
scripts/test_release_android_smoke_artifact_verifier.sh --help >/dev/null
scripts/test_release_android_smoke_summary_renderer.sh --help >/dev/null
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
```

Additional checks:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "workflow yaml parsed"'
git diff --check
flutter analyze --no-fatal-infos
```

## Results

Summary renderer self-test passed:

```text
[release-android-smoke-summary-test] pass fixture ok: passed smoke with passed verification
[release-android-smoke-summary-test] pass fixture ok: missing verification is surfaced
[release-android-smoke-summary-test] pass fixture ok: failed smoke status wins
[release-android-smoke-summary-test] pass fixture ok: same-path report dir
[release-android-smoke-summary-test] all summary renderer self-tests passed
```

Retained fixture evidence:

```text
passed-with-verification: overallStatus passed, verificationStatus passed, artifactFiles 9
missing-verification: overallStatus missing, verificationStatus missing, artifactFiles 8
failed-smoke: overallStatus failed, verificationStatus passed, artifactFiles 9
same-path: overallStatus passed, verificationStatus passed, artifactFiles 9
```

External report directory override passed:

```text
JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR=<tmp> scripts/test_release_android_smoke_summary_renderer.sh: passed
<tmp>/latest.md exists
```

Full CI self-check local reproduction passed:

```text
[release-android-smoke-verifier-test] all verifier self-tests passed
[release-android-smoke-summary-test] all summary renderer self-tests passed
```

Additional checks passed:

```text
workflow yaml parsed
git diff --check: passed
flutter analyze --no-fatal-infos: passed with 83 existing info-level lints
```

The analyzer infos are the existing project baseline in unrelated Dart files.
This PR changes shell/workflow/docs only and does not add Dart analyzer errors or warnings.

## Notes

- This self-test protects the summary renderer contract itself.
- It does not replace `scripts/run_release_android_smoke.sh`, which remains the real device/emulator pre-deployment smoke.
- The self-test writes renderer reports to temporary directories by default and supports `JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR` for explicit report isolation.
