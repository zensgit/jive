# Release Android Smoke Summary Index Dev Verify

- Date: 2026-05-07
- Branch: `codex/release-smoke-summary-index`
- Base: `main` @ `ee36d0720bffe2cdb9ff4967010d196a1007fa7a`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-release-smoke-summary-index`
- Device: Android Emulator `Jive_Staging_API35` / `emulator-5554`
- Package: `com.jivemoney.app.dev`
- APK: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-settings-smoke/build/app/outputs/flutter-apk/app-dev-debug.apk`
- Artifact dir: `/tmp/jive-release-android-smoke-summary-index-20260507-run1`

## Changes

- Added `scripts/render_release_android_smoke_summary.sh`.
- `scripts/run_release_android_smoke.sh` now runs three post-smoke steps:
  - local Android smoke runner
  - artifact verifier
  - one-page summary index renderer
- The renderer writes:
  - `<artifact-dir>/latest.md`
  - `build/reports/release-android-smoke/latest.md`
- Updated release smoke docs to describe the generated `latest.md` report.

## Summary Contract

`latest.md` summarizes the already-generated runner and verifier reports:

- smoke status and message
- artifact verification status, failures, and warnings
- scenario, flavor, package, device, emulator, and git commit
- APK SHA-256
- final crash bytes
- stable artifact file count, excluding `latest.md` itself
- key report paths and scenario coverage

The renderer does not run adb, build APKs, upload artifacts, or read secrets.

## Commands

Static checks:

```bash
for script in scripts/run_release_android_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/render_release_android_smoke_summary.sh scripts/run_android_local_feature_smoke.sh; do
  bash -n "$script"
done
scripts/render_release_android_smoke_summary.sh --help
scripts/run_release_android_smoke.sh --help
git diff --check
flutter analyze --no-fatal-infos
```

Renderer replay on existing artifact:

```bash
scripts/render_release_android_smoke_summary.sh /tmp/jive-release-android-smoke-artifact-verifier-20260507-run1
```

Same-path output guard:

```bash
tmpdir=$(mktemp -d /tmp/jive-release-smoke-summary-same-path.XXXXXX)
cp /tmp/jive-release-android-smoke-summary-index-20260507-run1/summary.md "$tmpdir/summary.md"
cp /tmp/jive-release-android-smoke-summary-index-20260507-run1/release_android_smoke_artifact_verification.md "$tmpdir/release_android_smoke_artifact_verification.md"
JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR="$tmpdir" \
  scripts/render_release_android_smoke_summary.sh "$tmpdir"
```

Wrapper smoke with automatic verification and summary index:

```bash
PATH="/Users/chauhua/development/flutter/bin:/Users/chauhua/Library/Android/sdk/platform-tools:$PATH" \
scripts/run_release_android_smoke.sh \
  --skip-build \
  --apk-path /Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-settings-smoke/build/app/outputs/flutter-apk/app-dev-debug.apk \
  --artifact-dir /tmp/jive-release-android-smoke-summary-index-20260507-run1
```

Post-run summary inspection:

```bash
sed -n '1,140p' /tmp/jive-release-android-smoke-summary-index-20260507-run1/latest.md
sed -n '1,60p' /tmp/jive-release-android-smoke-summary-index-20260507-run1/release_android_smoke_artifact_verification.md
sed -n '1,40p' /tmp/jive-release-android-smoke-summary-index-20260507-run1/summary.md
```

## Results

Static checks passed:

```text
for script in scripts/run_release_android_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/render_release_android_smoke_summary.sh scripts/run_android_local_feature_smoke.sh; do bash -n "$script"; done: passed
scripts/render_release_android_smoke_summary.sh --help: passed
scripts/run_release_android_smoke.sh --help: passed
git diff --check: passed
flutter analyze --no-fatal-infos: passed with 83 existing info-level lints
```

The analyzer infos are the existing project baseline in unrelated Dart files.
This PR changes shell/docs only and does not add Dart analyzer errors or warnings.

Renderer replay passed and wrote:

```text
/tmp/jive-release-android-smoke-artifact-verifier-20260507-run1/latest.md
build/reports/release-android-smoke/latest.md
```

Same-path output guard passed: renderer does not fail when `<artifact-dir>/latest.md`
and `build/reports/release-android-smoke/latest.md` resolve to the same file.

Wrapper smoke passed and wrote:

```text
/tmp/jive-release-android-smoke-summary-index-20260507-run1/summary.md
/tmp/jive-release-android-smoke-summary-index-20260507-run1/release_android_smoke_artifact_verification.md
/tmp/jive-release-android-smoke-summary-index-20260507-run1/latest.md
build/reports/release-android-smoke/latest.md
```

Latest summary:

```text
overallStatus: passed
smokeStatus: passed
verificationStatus: passed
verificationFailures: 0
verificationWarnings: 0
scenario: all
package: com.jivemoney.app.dev
device: emulator-5554
gitCommit: ee36d0720bffe2cdb9ff4967010d196a1007fa7a
apkSha256: 2bec6dc5778c3d0f4ba7434ac0533254a980bca51a29d7740bc26528ae22b523
finalCrashBytes: 0
artifactFiles: 172
```

Artifact verifier:

```text
status: passed
scenario: all
failures: 0
warnings: 0
```

Covered flow:

```text
guest-home
saas-gates
settings-navigation
quick-entry-hub
transaction-entry
```

## Notes

- This PR changes shell/docs only.
- This summary proves local pre-deployment smoke evidence is easy to inspect; it does not prove production payment, production Supabase connectivity, or store receipt validation.
- The stable `artifactFiles` count intentionally excludes `latest.md` so repeated rendering does not change the number.
