# Android Local Feature Smoke MVP

## Goal

`scripts/run_android_local_feature_smoke.sh` provides a repeatable local Android smoke lane for quick product checks before handing work to CI or staging. It focuses on emulator-friendly flows that can be driven with `adb`:

- build or reuse a debug APK
- install on an adb target
- cold launch the app
- drive onboarding to guest mode
- verify the guest home renders
- collect screenshots, UI XML, crash buffer, alert logs, and a Markdown summary

This lane is intentionally local-only. It does not upload secrets, does not trigger GitHub Actions, and does not use production Supabase or service-role keys.

## Recommended Usage

Fresh emulator run:

```bash
scripts/run_android_local_feature_smoke.sh \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch
```

Reuse an existing APK:

```bash
scripts/run_android_local_feature_smoke.sh \
  --scenario transaction-entry \
  --skip-build \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir /tmp/jive-android-local-feature-smoke
```

Run every local scenario:

```bash
scripts/run_android_local_feature_smoke.sh \
  --scenario all \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch
```

Launch/capture only, without driving onboarding:

```bash
scripts/run_android_local_feature_smoke.sh \
  --skip-build \
  --skip-install \
  --skip-onboarding
```

## Safety Defaults

- The script preserves app data by default.
- App data is reset only when `--fresh-install` is passed.
- Signature-mismatch recovery uninstalls the app only when `--allow-uninstall-on-signature-mismatch` is passed.
- Default dart-defines are fake local smoke values and must not be treated as production connectivity proof.

## Outputs

By default, artifacts are written under:

```text
build/reports/local-android-feature-smoke/<timestamp>/
```

Each run emits:

- `summary.md`
- `launch.*`
- `onboarding_*.*`
- `auth*.*`
- `guest_confirm.*`
- `final_home.*`
- `transaction_entry*.*` when `--scenario transaction-entry` or `--scenario all` is used
- `install.log`
- `flutter-build.log` when building

## Scenarios

The `--scenario` option accepts:

- `guest-home`, the default scenario.
- `transaction-entry`, which runs guest-home first and then verifies the add-transaction screen.
- `all`, currently equivalent to guest-home plus transaction-entry.
- `home`, a compatibility alias for `guest-home`.

### Guest Home

The default scenario covers:

1. Welcome screen opens.
2. User skips welcome.
3. `记一笔` onboarding category grid appears.
4. `餐饮` can be selected.
5. `下一步` advances to category settings.
6. Remaining onboarding steps can be skipped.
7. Login page guest entry can be reached by scrolling.
8. Guest mode confirmation appears.
9. Guest home renders with `访客` and `净资产`.

### Transaction Entry

The transaction-entry scenario starts from the guest home and opens the add-transaction flow. It prefers the `记一笔` entry when present and falls back to the home asset-card `支出` shortcut on the current compact home layout.

It validates:

- Type tabs: `支出`, `收入`, `转账`.
- Category and account anchors: `餐饮`, `现金`.
- Keypad anchors: `再记`, `+ 长按×`, `- 长按÷`.
- Inline note affordance: `展开备注`.
- Long-press operator toggle: long pressing `+ 长按×` shows `当前×`.
- Calculator behavior: entering `1+2×3` shows the result `7.00`.

The scenario intentionally does not tap the save action, so it does not create a real transaction record.

## Implementation Notes

- UI matching parses sanitized `uiautomator` XML and checks decoded `text` and `content-desc` values.
- Matching normalizes whitespace because Flutter semantics may expose `+ 长按×` as `content-desc="+\n长按×"`.
- UI capture retries transient `ERROR: null root node returned by UiTestAutomationBridge` dumps during cold startup.
- Tap coordinates are derived from UI XML bounds rather than screenshots.

## Known Limits

- Physical devices may block adb input injection depending on trust, focus, or OEM restrictions.
- This lane is not a replacement for integration tests or staging backend smoke.
- It validates local startup and UI navigation, not real payments, real cloud sync, or production release signing.
