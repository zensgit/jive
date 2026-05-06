# Android Local Settings Navigation Smoke Dev Verify

- Date: 2026-05-06
- Branch: `codex/android-local-settings-smoke`
- Base: `main` @ `aadd79615549dfde911ebc5d77a83708fb907817`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-settings-smoke`
- Device: Android Emulator `Jive_Staging_API35` / `emulator-5554`
- Package: `com.jivemoney.app.dev`
- Artifact dir: `/tmp/jive-android-local-smoke-settings-navigation-20260506-run1`

## Changes

- Added `--scenario settings-navigation` to `scripts/run_android_local_feature_smoke.sh`.
- Added Settings navigation coverage to the `all` local Android smoke scenario.
- Increased scroll-until-visible retries from three to five swipes for long Settings pages on compact emulator viewports.
- Updated `docs/android_local_feature_smoke_mvp.md` with the new scenario, outputs, safety boundary, and usage notes.

## Scenario Design

`settings-navigation` verifies the Settings route that the host release smoke lane intentionally deferred because desktop integration was unstable.

The scenario remains non-destructive:

- Completes fresh onboarding into guest mode.
- Opens the home menu through the stable `打开菜单` semantics label.
- Opens `设置`.
- Verifies top Settings anchors: `账户与订阅`, `云同步设置`, `外观`.
- Scrolls to `应用语言`, opens the language picker, and verifies `选择语言`, `简体中文`, `English`.
- Closes the language picker without selecting a new language.
- Scrolls to safe Settings anchors: `语音与智能`, `语音设置`, `数据`, `WebDAV 同步`, `导出数据`, `关于`, `隐私政策`.
- Opens the privacy policy page and verifies `Jive 积叶 隐私政策` plus `数据存储`.
- Returns to the guest home and verifies `访客` / `净资产`.

The scenario deliberately avoids:

- Payment purchase actions.
- Cloud sync execution.
- WebDAV backup/restore.
- CSV export file picking.
- System permission panels.
- Mutating language, reminder, theme, or category icon preferences.

## Commands

Static checks:

```bash
bash -n scripts/run_android_local_feature_smoke.sh
scripts/run_android_local_feature_smoke.sh --help
git diff --check
flutter analyze
```

Android emulator smoke:

```bash
PATH="/Users/chauhua/development/flutter/bin:/Users/chauhua/Library/Android/sdk/platform-tools:$PATH" \
scripts/run_android_local_feature_smoke.sh \
  --scenario settings-navigation \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir /tmp/jive-android-local-smoke-settings-navigation-20260506-run1
```

## Results

The local Android emulator smoke passed.

Static check summary:

```text
bash -n scripts/run_android_local_feature_smoke.sh: passed
scripts/run_android_local_feature_smoke.sh --help: passed
git diff --check: passed
flutter analyze: 0 errors, 0 warnings, 83 info
```

The analyzer infos are the existing project baseline in unrelated files, mostly
style/deprecation items such as `curly_braces_in_flow_control_structures`,
`deprecated_member_use`, `use_build_context_synchronously`, and generated-file
ignore comments. This PR did not add analyzer errors or warnings.

Smoke summary:

```text
status: passed
gitCommit: aadd79615549dfde911ebc5d77a83708fb907817
device: emulator-5554
flavor: dev
scenario: settings-navigation
package: com.jivemoney.app.dev
apkSha256: 2bec6dc5778c3d0f4ba7434ac0533254a980bca51a29d7740bc26528ae22b523
finalCrashBytes: 0
```

Settings evidence:

```text
账户与订阅
云同步设置
外观
语言 / 应用语言
选择语言 / 简体中文 / English
语音与智能 / 语音设置
数据 / WebDAV 同步 / 导出数据
关于 / 隐私政策
Jive 积叶 隐私政策
数据存储
```

Crash/alert evidence:

```text
final_home.crash.log: 0 bytes
final_home.alerts.log: 0 bytes
settings_navigation_privacy_policy.crash.log: 0 bytes
settings_navigation_privacy_policy.alerts.log: 0 bytes
```

Key artifacts:

```text
/tmp/jive-android-local-smoke-settings-navigation-20260506-run1/summary.md
/tmp/jive-android-local-smoke-settings-navigation-20260506-run1/settings_navigation_top.png
/tmp/jive-android-local-smoke-settings-navigation-20260506-run1/settings_navigation_language_picker.png
/tmp/jive-android-local-smoke-settings-navigation-20260506-run1/settings_navigation_privacy_policy.png
/tmp/jive-android-local-smoke-settings-navigation-20260506-run1/final_home.png
```

## Notes

- This is local emulator smoke only. It does not prove production payment, production Supabase connectivity, WebDAV connectivity, or release signing.
- The flow validates Settings navigation and safe informational surfaces, not every Settings detail page.
- No GitHub secrets were read or written.
