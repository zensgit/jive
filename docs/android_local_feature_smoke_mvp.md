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
  --scenario quick-entry-hub \
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
- `quick_entry*.*` when `--scenario quick-entry-hub` or `--scenario all` is used
- `saas_*.*` when `--scenario saas-gates` or `--scenario all` is used
- `install.log`
- `flutter-build.log` when building

## Scenarios

The `--scenario` option accepts:

- `guest-home`, the default scenario.
- `transaction-entry`, which runs guest-home first and then verifies the add-transaction screen.
- `quick-entry-hub`, which runs guest-home first and then verifies the long-press quick-entry hub.
- `saas-gates`, which runs guest-home first and then verifies Settings subscription and cloud-sync gate entry points.
- `all`, currently equivalent to guest-home plus saas-gates, quick-entry-hub, and transaction-entry.
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

### Quick Entry Hub

The quick-entry-hub scenario starts from the guest home and long-presses the home FAB. The FAB exposes a stable Android semantics label, `新增记账，长按打开快记中心`, so the smoke runner does not depend on screenshot coordinates.

It validates:

- Quick-entry hub entry cards: `手动记账`, `语音记账`, `对话记账`, `截图识别`, `从模板记`, `从分享记`.
- Subscriber-only voice entry remains visibly locked for the free guest account.
- Tapping `手动记账` opens the calculator-based add-transaction page.
- Manual flow anchors are present: `支出`, `收入`, `转账`, `餐饮`, `现金`, `再记`.

The scenario does not save a transaction. It backs out to the guest home after the manual page opens.

### SaaS Gates

The saas-gates scenario starts from the guest home, opens Settings through the stable `打开菜单` semantics label, and verifies the visible SaaS entry points without using real payments or real cloud sync.

It validates:

- Settings anchors: `账户与订阅`, `云同步设置`, `外观`.
- Subscription page anchors: `升级方案`, `当前方案`, `云同步与多设备使用`, `恢复购买`.
- Free-tier cloud-sync gate: `此功能需要订阅版`, `了解订阅版`, `稍后再说`.
- The cloud-sync upgrade prompt can navigate to the subscription page.

Use `--fresh-install` for this scenario when validating the free-tier gate, otherwise preserved local entitlement state may bypass the upgrade prompt.

## Implementation Notes

- UI matching parses sanitized `uiautomator` XML and checks decoded `text` and `content-desc` values.
- Matching normalizes whitespace because Flutter semantics may expose `+ 长按×` as `content-desc="+\n长按×"`.
- UI capture retries transient `ERROR: null root node returned by UiTestAutomationBridge` dumps during cold startup.
- Tap coordinates are derived from UI XML bounds rather than screenshots.
- Long-press coordinates prefer `long-clickable=true` nodes when available.
- Onboarding is advanced as a small state machine so transient empty launch XML or reordered onboarding pages do not strand the smoke before guest mode.

## Known Limits

- Physical devices may block adb input injection depending on trust, focus, or OEM restrictions.
- This lane is not a replacement for integration tests or staging backend smoke.
- It validates local startup and UI navigation, not real payments, real cloud sync, or production release signing.
