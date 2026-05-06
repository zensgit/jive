# Android Local SaaS And Quick Entry Smoke Dev Verify

- Date: 2026-05-06
- Branch: `codex/android-local-saas-entry-smoke`
- Base: `main` @ `7d37a8934a0c69e16c29b02e7e6b0b673825dda0`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-saas-entry-smoke`
- Device: Android Emulator `Jive_Staging_API35` / `emulator-5554`
- Package: `com.jivemoney.app.dev`
- SaaS artifact dir: `/tmp/jive-android-local-smoke-saas-gates-20260506-run8`
- Quick-entry artifact dir: `/tmp/jive-android-local-smoke-quick-entry-hub-20260506-run5`

## Changes

- Added `--scenario quick-entry-hub` to `scripts/run_android_local_feature_smoke.sh`.
- Added `--scenario saas-gates` to `scripts/run_android_local_feature_smoke.sh`.
- Added stable semantics for the home settings menu and home FAB.
- Added stable semantics for quick-entry hub cards.
- Added long-clickable node preference for adb long-press coordinate selection.
- Hardened onboarding navigation into a state-machine style loop.
- Added reusable scroll-until-visible text lookup for subscription page assertions.
- Updated `docs/android_local_feature_smoke_mvp.md`.

## Scenario Design

`quick-entry-hub` verifies the MoneyThings-style quick entry doorway without creating records:

- Complete fresh onboarding into guest mode.
- Long-press the home FAB via `新增记账，长按打开快记中心`.
- Verify all six quick-entry cards.
- Tap `手动记账`.
- Verify the add-transaction page opens.
- Back out to guest home without saving.

`saas-gates` verifies the free-tier SaaS entry chain without using production services:

- Complete fresh onboarding into guest mode.
- Open the home menu via `打开菜单`.
- Open Settings.
- Verify subscription and cloud-sync entry points.
- Open the subscription page and scroll to subscriber feature copy and restore purchase action.
- Tap the cloud-sync gated entry and verify the subscriber upgrade prompt.
- Follow `了解订阅版` back to the subscription page.
- Back out to guest home.

## Commands

Static checks:

```bash
bash -n scripts/run_android_local_feature_smoke.sh
scripts/run_android_local_feature_smoke.sh --help
/Users/chauhua/development/flutter/bin/dart format \
  lib/feature/home/main_screen.dart \
  lib/feature/home/widgets/home_top_bar.dart \
  lib/feature/quick_entry/quick_entry_hub_sheet.dart
git diff --check
flutter analyze
```

Quick-entry hub smoke:

```bash
PATH="/Users/chauhua/development/flutter/bin:/Users/chauhua/Library/Android/sdk/platform-tools:$PATH" \
scripts/run_android_local_feature_smoke.sh \
  --scenario quick-entry-hub \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir /tmp/jive-android-local-smoke-quick-entry-hub-20260506-run5
```

SaaS gates smoke:

```bash
PATH="/Users/chauhua/development/flutter/bin:/Users/chauhua/Library/Android/sdk/platform-tools:$PATH" \
scripts/run_android_local_feature_smoke.sh \
  --scenario saas-gates \
  --skip-build \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir /tmp/jive-android-local-smoke-saas-gates-20260506-run8
```

## Results

Both local Android emulator smokes passed.

Static check summary:

```text
bash -n scripts/run_android_local_feature_smoke.sh: passed
scripts/run_android_local_feature_smoke.sh --help: passed
dart format: passed
git diff --check: passed
flutter analyze: 0 errors, 0 warnings, 83 info
```

The analyzer infos are the existing project baseline in unrelated files, mostly
style/deprecation items such as `curly_braces_in_flow_control_structures`,
`deprecated_member_use`, `use_build_context_synchronously`, and generated-file
ignore comments. This PR did not add analyzer errors or warnings.

Quick-entry summary:

```text
status: passed
gitCommit: 7d37a8934a0c69e16c29b02e7e6b0b673825dda0
device: emulator-5554
flavor: dev
scenario: quick-entry-hub
package: com.jivemoney.app.dev
apkSha256: ff0f9f1fb8dc7eb20dcbfeca8eb402059b1e5dc7f884fb567b79019143932ab4
finalCrashBytes: 0
```

Quick-entry evidence:

```text
手动记账
语音记账
对话记账
截图识别
从模板记
从分享记
支出 / 收入 / 转账
餐饮 / 现金 / 再记
```

SaaS gates summary:

```text
status: passed
gitCommit: 7d37a8934a0c69e16c29b02e7e6b0b673825dda0
device: emulator-5554
flavor: dev
scenario: saas-gates
package: com.jivemoney.app.dev
apkSha256: ff0f9f1fb8dc7eb20dcbfeca8eb402059b1e5dc7f884fb567b79019143932ab4
finalCrashBytes: 0
```

SaaS gate evidence:

```text
账户与订阅
云同步设置
升级方案
当前方案
云同步与多设备使用
恢复购买
此功能需要订阅版
了解订阅版
稍后再说
```

Crash/alert evidence:

```text
quick_entry_hub final_home.crash.log: 0 bytes
quick_entry_hub final_home.alerts.log: 0 bytes
quick_entry_manual_transaction.crash.log: 0 bytes
quick_entry_manual_transaction.alerts.log: 0 bytes
saas_gates final_home.crash.log: 0 bytes
saas_gates final_home.alerts.log: 0 bytes
saas_cloud_sync_gate.crash.log: 0 bytes
saas_cloud_sync_gate.alerts.log: 0 bytes
```

Key artifacts:

```text
/tmp/jive-android-local-smoke-quick-entry-hub-20260506-run5/summary.md
/tmp/jive-android-local-smoke-quick-entry-hub-20260506-run5/quick_entry_hub.png
/tmp/jive-android-local-smoke-quick-entry-hub-20260506-run5/quick_entry_manual_transaction.png
/tmp/jive-android-local-smoke-saas-gates-20260506-run8/summary.md
/tmp/jive-android-local-smoke-saas-gates-20260506-run8/saas_settings.png
/tmp/jive-android-local-smoke-saas-gates-20260506-run8/saas_cloud_sync_gate.png
```

## Notes

- This is local emulator smoke only. It does not prove production payment, production Supabase connectivity, or release signing.
- `saas-gates` should be run with `--fresh-install` when validating free-tier behavior.
- The smoke runner now uses text semantics where possible and only falls back to XML-derived bounds.
- No GitHub secrets were read or written.
