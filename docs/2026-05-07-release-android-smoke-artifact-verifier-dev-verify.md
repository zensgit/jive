# Release Android Smoke Artifact Verifier Dev Verify

- Date: 2026-05-07
- Branch: `codex/release-android-smoke-artifact-verifier`
- Base: `main` @ `6b52e05fa74e6080326c271e63953b1e2578a259`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-release-android-smoke-artifact-verifier`
- Device: Android Emulator `Jive_Staging_API35` / `emulator-5554`
- Package: `com.jivemoney.app.dev`
- Replay artifact dir: `/tmp/jive-release-android-smoke-wrapper-20260507-run1`
- Wrapper artifact dir: `/tmp/jive-release-android-smoke-artifact-verifier-20260507-run1`

## Changes

- Added `scripts/verify_release_android_smoke_artifacts.sh`.
- The verifier checks the local Android smoke artifact contract instead of replaying business logic.
- `scripts/run_release_android_smoke.sh` now runs the verifier after the smoke completes.
- The verifier writes `release_android_smoke_artifact_verification.md` into the artifact directory.
- Updated `docs/release_smoke_lane_mvp.md` and `docs/android_local_feature_smoke_mvp.md` with verifier usage.

## Verifier Contract

Common checks:

- `summary.md` exists and reports `status: passed`.
- Summary contains non-empty `gitCommit`, `device`, `flavor`, `scenario`, `package`, and `apkPath`.
- Summary `apkSha256` is a 64-character hex digest.
- Summary `artifactDir` resolves to the checked directory.
- Summary `finalCrashBytes` is `0`.
- `launch.*` and `final_home.*` key artifacts exist.
- `launch.xml` and `final_home.xml` parse as uiautomator `<hierarchy>` XML.
- `final_home.summary.txt` contains `访客` and `净资产`.
- Final home crash/alert logs are empty.

Scenario checks:

- `saas-gates`: subscription and cloud-sync gate evidence.
- `settings-navigation`: Settings top anchors, language picker, and privacy policy evidence.
- `quick-entry-hub`: quick-entry cards and manual bookkeeping page evidence.
- `transaction-entry`: transaction page anchors, operator toggle, formula, result, and note affordance.
- `all`: all scenario contracts above.

The verifier deliberately avoids brittle checks such as screenshot pixels, bounds, UI row ordering, artifact count, or exact onboarding step count.

## Commands

Static checks:

```bash
for script in scripts/run_release_android_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/run_android_local_feature_smoke.sh; do
  bash -n "$script"
done
scripts/verify_release_android_smoke_artifacts.sh --help
scripts/run_release_android_smoke.sh --help
git diff --check
flutter analyze --no-fatal-infos
```

Verifier replay on existing artifact:

```bash
scripts/verify_release_android_smoke_artifacts.sh /tmp/jive-release-android-smoke-wrapper-20260507-run1
```

Wrapper smoke with automatic verification:

```bash
PATH="/Users/chauhua/development/flutter/bin:/Users/chauhua/Library/Android/sdk/platform-tools:$PATH" \
scripts/run_release_android_smoke.sh \
  --skip-build \
  --apk-path /Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-settings-smoke/build/app/outputs/flutter-apk/app-dev-debug.apk \
  --artifact-dir /tmp/jive-release-android-smoke-artifact-verifier-20260507-run1
```

## Results

Static checks passed:

```text
for script in scripts/run_release_android_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/run_android_local_feature_smoke.sh; do bash -n "$script"; done: passed
scripts/verify_release_android_smoke_artifacts.sh --help: passed
scripts/run_release_android_smoke.sh --help: passed
git diff --check: passed
flutter analyze --no-fatal-infos: passed with 83 existing info-level lints
```

The analyzer infos are the existing project baseline in unrelated Dart files.
This PR changes shell/docs only and does not add Dart analyzer errors or warnings.

Both verifier paths passed.

Replay artifact verification:

```text
artifactDir: /tmp/jive-release-android-smoke-wrapper-20260507-run1
status: passed
scenario: all
failures: 0
warnings: 0
```

Wrapper smoke summary:

```text
status: passed
gitCommit: 6b52e05fa74e6080326c271e63953b1e2578a259
device: emulator-5554
flavor: dev
scenario: all
package: com.jivemoney.app.dev
apkSha256: 2bec6dc5778c3d0f4ba7434ac0533254a980bca51a29d7740bc26528ae22b523
finalCrashBytes: 0
```

Automatic artifact verification:

```text
artifactDir: /tmp/jive-release-android-smoke-artifact-verifier-20260507-run1
status: passed
scenario: all
failures: 0
warnings: 0
```

Representative checked evidence:

```text
summary status: passed
summary apkSha256: 64-char hex digest
launch.xml: parseable uiautomator XML
final_home.xml: parseable uiautomator XML
saas_cloud_sync_gate: 此功能需要订阅版 / 了解订阅版 / 稍后再说
settings_navigation_privacy_policy: Jive 积叶 隐私政策 / 数据存储
quick_entry_hub: 手动记账 / 语音记账 / 对话记账 / 截图识别 / 从模板记 / 从分享记
transaction_entry_expression: 1+2×3 / 7.00 / 展开备注
```

## Notes

- This verifier proves local artifact integrity, not production payment or production Supabase connectivity.
- It is intentionally stricter than a human spot-check but avoids unstable pixel/bounds/artifact-count assertions.
- The wrapper still defaults to fresh install for emulator use; physical devices should pass `--preserve-data` unless data reset is intended.
