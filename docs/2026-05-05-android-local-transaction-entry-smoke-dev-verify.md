# Android Local Transaction Entry Smoke Dev Verify

- Date: 2026-05-05
- Branch: `codex/android-local-smoke-scenarios`
- Base: `main` @ `94dcfc7cc68f1469c654172b32096d2072b42722`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-android-local-smoke-scenarios`
- Device: Android Emulator `Jive_Staging_API35` / `emulator-5554`
- Package: `com.jivemoney.app.dev`
- Artifact dir: `/tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4`

## Changes

- Added `--scenario guest-home|transaction-entry|all` to `scripts/run_android_local_feature_smoke.sh`.
- Added transaction-entry smoke coverage after guest onboarding.
- Added long-press adb support for operator toggles.
- Made UI text matching parse sanitized `uiautomator` XML instead of raw `grep`.
- Normalized whitespace in UI matching so Flutter semantics labels such as `+\n长按×` match `+ 长按×`.
- Added retry handling for transient cold-start UI dumps that return `ERROR: null root node returned by UiTestAutomationBridge`.
- Updated `docs/android_local_feature_smoke_mvp.md`.

## Scenario Design

The transaction-entry scenario keeps the smoke flow local and non-destructive:

- Fresh install and cold launch the dev APK.
- Complete onboarding into guest mode.
- Open the add-transaction page from `记一笔` when available, otherwise from the home `支出` shortcut.
- Verify category/account/keypad anchors.
- Long press `+ 长按×` to switch the plus key to multiplication.
- Enter `1+2×3` and assert the calculated result is `7.00`.
- Do not tap `再记`, so no real transaction is saved.

## Commands

Static checks:

```bash
bash -n scripts/run_android_local_feature_smoke.sh
scripts/run_android_local_feature_smoke.sh --help
```

Full local transaction-entry smoke:

```bash
PATH="/Users/chauhua/development/flutter/bin:/Users/chauhua/Library/Android/sdk/platform-tools:$PATH" \
scripts/run_android_local_feature_smoke.sh \
  --scenario transaction-entry \
  --skip-build \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir /tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4
```

## Results

The full local emulator smoke passed.

Summary:

```text
status: passed
gitCommit: 94dcfc7cc68f1469c654172b32096d2072b42722
device: emulator-5554
flavor: dev
scenario: transaction-entry
package: com.jivemoney.app.dev
apkSha256: a87327d485518afc8ba96eaf9a3b04cb4629b7797db25af3f47f60a9cce668f8
finalCrashBytes: 0
```

Transaction-entry expression evidence:

```text
¥ 1+2×3
¥ 7.00
× 当前×
展开备注
再记
```

Crash/alert evidence:

```text
final_home.crash.log: 0 bytes
final_home.alerts.log: 0 bytes
transaction_entry_expression.crash.log: 0 bytes
transaction_entry_expression.alerts.log: 0 bytes
```

Key artifacts:

```text
/tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4/summary.md
/tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4/final_home.png
/tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4/transaction_entry.png
/tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4/transaction_entry_operator_toggle.png
/tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4/transaction_entry_expression.png
/tmp/jive-android-local-smoke-transaction-entry-20260505-rerun4/transaction_entry_expression.summary.txt
```

## Notes

- Earlier local attempts exposed two runner flake sources: raw XML text matching missed `content-desc="+\n长按×"`, and cold-start `uiautomator` occasionally returned a null root dump.
- Both flake sources were fixed in the runner before the passing run.
- The smoke uses fake local dart-defines and does not validate production Supabase, payments, ads, or release signing.
- No GitHub secrets were read or written.
