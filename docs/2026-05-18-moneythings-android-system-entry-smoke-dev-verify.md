# MoneyThings Android System Entry Smoke Dev Verify

Date: 2026-05-18

Branch: `codex/android-moneythings-system-entry-smoke`

Base: local branch from the merged SaaS cleanup documentation state.

## Scope

This slice records Android device smoke evidence for the MoneyThings system
entry work. It does not change runtime code.

No migrations, sync internals, SaaS entitlement/payment/sync logic, Supabase
functions, or GitHub workflow files were changed.

## Device

- Serial: `EP0110MZ0BC110087W`
- Model: `P0110`
- Android version: `16`
- Existing Jive packages before smoke:
  - `com.jivemoney.app.dev`
  - `com.jivemoney.app.auto`

## Build And Install

Commands run:

```bash
/Users/chauhua/development/flutter/bin/flutter build apk --debug --flavor dev
/Users/chauhua/development/flutter/bin/flutter build apk --debug --flavor prod
/Users/chauhua/Library/Android/sdk/platform-tools/adb \
  -s EP0110MZ0BC110087W install -r build/app/outputs/flutter-apk/app-prod-debug.apk
```

Results:

- `dev` debug APK built successfully.
- Installing `app-dev-debug.apk` over existing `com.jivemoney.app.dev` failed
  with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` because the existing dev package
  had a different signature.
- The existing dev package was not uninstalled to avoid deleting local dev data.
- `prod` debug APK built successfully.
- `app-prod-debug.apk` installed successfully as temporary package
  `com.jivemoney.app`.

## Smoke Results

### `jive://transaction/new`

Command shape:

```bash
adb -s EP0110MZ0BC110087W shell \
  "am start -W -a android.intent.action.VIEW \
   -d 'jive://transaction/new?entrySource=widget&sourceLabel=...&highlight=amount,category,account' \
   -p com.jivemoney.app"
```

Result:

- First launch was gated by onboarding.
- After tapping through onboarding skip steps, the same transaction deep link
  opened the structured editor.
- UI evidence from `uiautomator`:
  - title: `快速记录`
  - source copy: `来自桌面小组件`
  - missing fields: `分类 待补全 未选择`, `账户 待补全 未选择`
  - action buttons: `保存并新建`, `确认入账`
- Screenshot captured to:
  `/tmp/jive-moneythings-android-transaction-new.png`

Status: pass for Android deep-link routing into structured transaction entry.

### `jive://scene/switch`

Command shape:

```bash
adb -s EP0110MZ0BC110087W shell \
  "am start -W -a android.intent.action.VIEW \
   -d 'jive://scene/switch?sceneName=%E6%97%85%E8%A1%8C' \
   -p com.jivemoney.app"
```

Result:

- App cold-launched successfully.
- No crash was observed in the filtered logcat tail.
- The clean temporary install had no seeded `旅行` scene, so semantic scene
  switching could not be verified.

Status: partial. Android route launch is healthy; semantic validation requires
seeded scene data.

### `jive://quick-action`

Command shape:

```bash
adb -s EP0110MZ0BC110087W shell \
  "am start -W -a android.intent.action.VIEW \
   -d 'jive://quick-action?id=template%3A42' \
   -p com.jivemoney.app"
```

Result:

- App cold-launched successfully.
- No crash was observed in the filtered logcat tail.
- The clean temporary install had no template `42`, so executor behavior for a
  configured saved quick action could not be verified.

Status: partial. Android route launch is healthy; full quick-action execution
requires a seeded quick action.

## Cleanup

Command run:

```bash
/Users/chauhua/Library/Android/sdk/platform-tools/adb \
  -s EP0110MZ0BC110087W uninstall com.jivemoney.app
```

Result:

- Temporary `com.jivemoney.app` package was uninstalled.
- Existing `com.jivemoney.app.dev` and `com.jivemoney.app.auto` remained
  installed.

## Remaining Android Smoke

- Add or seed a saved quick action, then rerun
  `jive://quick-action?id=<existing-id>` to validate executor behavior.
- Add the actual Android home widget and tap the widget button, rather than
  only exercising the equivalent deep link.
- Seed or create a `旅行` scene, then rerun `jive://scene/switch?sceneName=旅行`
  to validate visible scene switching.
