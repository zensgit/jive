# Release Android Smoke Wrapper Dev Verify

- Date: 2026-05-07
- Branch: `codex/release-android-smoke-wrapper`
- Base: `main` @ `5c95295bc6b84f6442bfe65244403314e8424236`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-release-android-smoke-wrapper`
- Device: Android Emulator `Jive_Staging_API35` / `emulator-5554`
- Package: `com.jivemoney.app.dev`
- Artifact dir: `/tmp/jive-release-android-smoke-wrapper-20260507-run1`

## Changes

- Added `scripts/run_release_android_smoke.sh` as the short pre-deployment Android smoke entry.
- The wrapper defaults to `--scenario all`, `--fresh-install`, `--allow-uninstall-on-signature-mismatch`, and `build/reports/release-android-smoke/<timestamp>/`.
- Extra args are forwarded after defaults so callers can override device, APK, artifact dir, build/install behavior, scenario, or data reset behavior.
- Updated `docs/release_smoke_lane_mvp.md` to mark Settings navigation as covered by the Android local lane.
- Updated `docs/android_local_feature_smoke_mvp.md` to point deployment-test usage at the wrapper.
- Added explicit warning that the default fresh install is intended for emulators; physical devices should use `--preserve-data` unless data reset is acceptable.

## Wrapper Design

The wrapper is intentionally thin. It does not duplicate the real smoke logic; it delegates to `scripts/run_android_local_feature_smoke.sh`.

Default command:

```bash
scripts/run_android_local_feature_smoke.sh \
  --scenario all \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir build/reports/release-android-smoke/<timestamp>
```

Default `all` coverage:

- `guest-home`: cold launch, onboarding, guest home.
- `saas-gates`: subscription page and cloud-sync upgrade gate.
- `settings-navigation`: Settings, language picker, privacy policy, return home.
- `quick-entry-hub`: FAB long-press quick entry and manual bookkeeping entry.
- `transaction-entry`: calculator/note/keypad anchors and `1+2×3=7.00`.

## Commands

Static checks:

```bash
bash -n scripts/run_release_android_smoke.sh scripts/run_android_local_feature_smoke.sh scripts/run_release_smoke.sh
scripts/run_release_android_smoke.sh --help
git diff --check
flutter analyze --no-fatal-infos
```

Wrapper smoke:

```bash
PATH="/Users/chauhua/development/flutter/bin:/Users/chauhua/Library/Android/sdk/platform-tools:$PATH" \
scripts/run_release_android_smoke.sh \
  --skip-build \
  --apk-path /Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-settings-smoke/build/app/outputs/flutter-apk/app-dev-debug.apk \
  --artifact-dir /tmp/jive-release-android-smoke-wrapper-20260507-run1
```

## Results

The local Android emulator wrapper smoke passed.

Static check summary:

```text
bash -n scripts/run_release_android_smoke.sh scripts/run_android_local_feature_smoke.sh scripts/run_release_smoke.sh: passed
scripts/run_release_android_smoke.sh --help: passed
git diff --check: passed
flutter analyze --no-fatal-infos: passed with 83 existing info-level lints
```

The analyzer infos are the existing project baseline in unrelated files. This PR
does not add Dart source changes, analyzer errors, or analyzer warnings.

Smoke summary:

```text
status: passed
gitCommit: 5c95295bc6b84f6442bfe65244403314e8424236
device: emulator-5554
flavor: dev
scenario: all
package: com.jivemoney.app.dev
apkSha256: 2bec6dc5778c3d0f4ba7434ac0533254a980bca51a29d7740bc26528ae22b523
finalCrashBytes: 0
artifactFiles: 171
```

Coverage evidence:

```text
saas_cloud_sync_gate: 此功能需要订阅版 / 了解订阅版 / 稍后再说
settings_navigation_privacy_policy: Jive 积叶 隐私政策 / 数据存储
quick_entry_hub: 手动记账 / 语音记账 / 对话记账 / 截图识别 / 从模板记 / 从分享记
transaction_entry_expression: 1+2×3 / 7.00 / 展开备注
final_home: 访客 / 净资产 / 打开菜单
```

Crash/alert evidence:

```text
final_home.crash.log: 0 bytes
final_home.alerts.log: 0 bytes
saas_cloud_sync_gate.crash.log: 0 bytes
settings_navigation_privacy_policy.alerts.log: 0 bytes
transaction_entry_expression.alerts.log: 0 bytes
```

Key artifacts:

```text
/tmp/jive-release-android-smoke-wrapper-20260507-run1/summary.md
/tmp/jive-release-android-smoke-wrapper-20260507-run1/saas_cloud_sync_gate.png
/tmp/jive-release-android-smoke-wrapper-20260507-run1/settings_navigation_privacy_policy.png
/tmp/jive-release-android-smoke-wrapper-20260507-run1/quick_entry_hub.png
/tmp/jive-release-android-smoke-wrapper-20260507-run1/transaction_entry_expression.png
/tmp/jive-release-android-smoke-wrapper-20260507-run1/final_home.png
```

## Notes

- This is a local pre-deployment smoke wrapper, not a production release proof.
- It does not read GitHub secrets, upload artifacts, run production payments, or prove production Supabase connectivity.
- The default fresh install is appropriate for emulators. On physical devices, use `--preserve-data` unless app data reset is intentional.
