# MoneyThings Entry System Android Validation

Date: 2026-04-29
Branch: `feature/moneythings-entry-system-closure-docs`
Base stack: `#197 -> #200 -> #201 -> #202 -> #205 -> #206 -> #207 -> #209`

## Summary

This pass validates the current MoneyThings-inspired transaction-entry closure stack from the docs branch head `21bba283`.

Automated validation is green for the targeted entry-system scope. Android device smoke is partially blocked by an installed dev package signed with a different key, so this pass intentionally does not uninstall the existing app because that would clear local dev app data.

## Scope

Covered entry points:

- Manual add transaction calculator and inline note UX.
- Three-level category compatible save path.
- Quick-action and transaction deep-link parsing.
- AI Assistant voice and clipboard-to-editor bridge.
- Android `ACTION_SEND text/plain` share bridge.
- Android Today widget quick-entry manifest/resource wiring.

Out of scope for this pass:

- SaaS entitlement, payment, sync, or migration behavior.
- `.github/workflows`.
- Production signing or store-distributed builds.

## Automated Validation

### Flutter Tests

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart test/speech_intent_parser_test.dart test/add_transaction_screen_entry_ux_test.dart test/transaction_entry_widget_regression_test.dart
```

Result: passed.

Coverage confirmed:

- `QuickActionExecutor` mode inference and deep-link parsing.
- `SpeechEntryParamsBuilder` voice/clipboard/share params.
- Manual entry expression save, inline note, divide-by-zero guard, and operator toggle reset.
- Custom and three-level category compatible transaction save keys.
- Transaction entry widget regression anchors.

### Flutter Analyze

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: passed with info-level findings only.

Notes:

- Analyzer reported 83 existing info-level lint findings.
- No fatal warnings or errors blocked this validation.

### Android Debug Build

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter build apk --debug --flavor dev --no-pub
```

Result: passed.

Output:

```text
build/app/outputs/flutter-apk/app-dev-debug.apk
```

APK size:

```text
242M
```

Generated manifest version:

```text
versionName="1.1.0-20260427-2351"
package="com.jivemoney.app.dev"
```

### Android Manifest Inspection

Command:

```bash
/Users/chauhua/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest print build/app/outputs/flutter-apk/app-dev-debug.apk
```

Result: passed.

Confirmed manifest contracts:

- `MainActivity` handles `jive://auto`.
- `MainActivity` handles `jive://quick-action`.
- `MainActivity` handles `jive://transaction`.
- `MainActivity` handles `android.intent.action.SEND` with `text/plain`.
- `JiveTodayWidget` receiver is present with `android.appwidget.action.APPWIDGET_UPDATE`.

### Static Entry Wiring Check

Command:

```bash
rg -n "ACTION_SEND|widget_quick_add|entrySource|shareReceive|openSpeechResultInEditor|SpeechEntryParamsBuilder|来自桌面小组件|来自系统分享" android lib test docs
```

Result: passed.

Confirmed source contracts:

- Android share text is normalized in `MainActivity`.
- Widget quick-add uses `widget_quick_add`.
- Share links set `entrySource=shareReceive`.
- Widget links carry source label `来自桌面小组件`.
- Share links carry source label `来自系统分享`.
- Voice and clipboard entry use `SpeechEntryParamsBuilder`.

## Android Device Smoke Status

Device:

```text
EP0110MZ0BC110087W    device
```

Install command:

```bash
/Users/chauhua/Library/Android/sdk/platform-tools/adb -s EP0110MZ0BC110087W install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

Result: blocked.

Error:

```text
INSTALL_FAILED_UPDATE_INCOMPATIBLE:
Existing package com.jivemoney.app.dev signatures do not match newer version
```

Installed package observed on device:

```text
package=com.jivemoney.app.dev
versionName=1.1.0-20260419-0411
firstInstallTime=2026-04-19 12:53:09
```

Decision:

- Did not run `adb uninstall com.jivemoney.app.dev`.
- Reason: uninstalling would remove local data for the existing dev app on the phone.

## Pending Manual Device Smoke

After choosing a safe device-data strategy, run:

1. Install the new dev APK.
2. Open `jive://transaction/new?sourceLabel=来自功能验证`.
3. Verify the structured editor opens with a source banner.
4. Share text into Jive from Android:

```text
今天午餐花了 35 元
```

5. Verify the editor opens from system share and parses amount/text into `TransactionEntryParams`.
6. Add the Android Today widget.
7. Tap widget card background and confirm it opens the app.
8. Tap widget `+ 记一笔` and confirm it opens the structured transaction editor with source label `来自桌面小组件`.

## Unblock Options

Option A: clear the existing dev app on the phone.

Use only if losing local dev app data is acceptable:

```bash
/Users/chauhua/Library/Android/sdk/platform-tools/adb -s EP0110MZ0BC110087W uninstall com.jivemoney.app.dev
/Users/chauhua/Library/Android/sdk/platform-tools/adb -s EP0110MZ0BC110087W install build/app/outputs/flutter-apk/app-dev-debug.apk
```

Option B: preserve the current phone state.

- Use a clean Android emulator or spare device.
- Install the new dev APK there.
- Run the same smoke checklist above.

Option C: preserve the installed package and test with the same signing key.

- Locate the keystore used to build the currently installed `20260419-0411` dev package.
- Rebuild this branch using that keystore.
- Install with `adb install -r`.

## Verdict

The current stack is ready from automated and APK-contract validation.

Remaining validation is a device-environment decision, not a code blocker: the phone has an older `com.jivemoney.app.dev` build with a different signature. Once a clean device/emulator or uninstall approval is available, run the pending smoke checklist to close Android manual verification.
