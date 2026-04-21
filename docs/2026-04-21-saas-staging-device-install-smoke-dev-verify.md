# SaaS Staging Device Install + Smoke Verification

Date: 2026-04-21

## Summary

This round completed device-side validation for the SaaS staging APK built from current `main`, and added a safer reusable install helper for future staging APK tests.

Changes made:

- Added `scripts/install_saas_staging_apk.sh`.
- Validated the staging APK on the Android emulator.
- Confirmed the physical Android phone is blocked by a signature mismatch, without deleting its local app data.
- Captured screenshots, UI trees, and logcat evidence under `/tmp/jive-device-qa-24724133714`.

## Source State

- Branch at start: `main`
- Source commit for APK: `8ce14ee7a7aa5bba156520f443af3029a35e3610`
- Current report branch: `codex/saas-staging-device-install-smoke`
- APK build run: https://github.com/zensgit/jive/actions/runs/24724133714
- APK file used:

```text
/tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk
```

APK metadata:

```text
package: com.jivemoney.app.dev
versionName: 1.1.0-20260421-1311
versionCode: 2109612951
sha256: b9ed5ddc03733a14c65f1a302ecd5450bea3be4779c55772b9855f2d878fa96a
size: 253777249 bytes
```

## Install Helper

New file:

- `scripts/install_saas_staging_apk.sh`

Purpose:

- Find `adb` from `PATH`, `ADB`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, or the default macOS Android SDK path.
- Install a staging APK to a selected adb device.
- Print device metadata and installed package version metadata.
- Detect `INSTALL_FAILED_UPDATE_INCOMPATIBLE` and fail safely by default.
- Only uninstall an existing app when `--allow-uninstall-on-signature-mismatch` is explicitly passed.

Validation:

```bash
bash -n scripts/install_saas_staging_apk.sh
scripts/install_saas_staging_apk.sh --help
```

Successful emulator install command:

```bash
scripts/install_saas_staging_apk.sh \
  --device emulator-5554 \
  --apk /tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk
```

Successful emulator install output:

```text
[saas-apk-install] device=emulator-5554 model=sdk_gphone64_arm64 android=15 Physical size: 1080x2400
Performing Streamed Install
Success
[saas-apk-install] installed package metadata:
    versionCode=2109612951 minSdk=24 targetSdk=36
    versionName=1.1.0-20260421-1311
    lastUpdateTime=2026-04-21 21:43:11
      firstInstallTime=2026-04-21 21:35:25
```

## Device Matrix

Devices detected:

```text
531cb562       physical phone, model=25010PN30C, Android 16, 1440x3200
emulator-5554  emulator, model=sdk_gphone64_arm64, Android 15, 1080x2400
```

Physical phone result:

- Existing `com.jivemoney.app.dev` version: `1.1.0-20260420-2110`
- Safe install result: blocked by signature mismatch.
- No uninstall was performed.
- Local app data was preserved.

Physical phone safe-failure evidence:

```text
adb: failed to install ... app-dev-debug.apk: Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package com.jivemoney.app.dev signatures do not match newer version; ignoring!]
[saas-apk-install] ERROR: signature mismatch for com.jivemoney.app.dev. Re-run with --allow-uninstall-on-signature-mismatch only if deleting local app data is acceptable.
```

Physical phone data check:

```text
/data/user/0/com.jivemoney.app.dev
app_flutter
databases
files
shared_prefs
```

This confirms the existing physical-phone install has local data. Keeping the safe default was the right behavior.

## Emulator Smoke Verification

Emulator install:

- Previous emulator install also had a signature mismatch.
- The emulator package was uninstalled and the new staging APK was installed.
- This was safe because the emulator is the disposable test target for this run.

Installed version:

```text
versionCode=2109612951
versionName=1.1.0-20260421-1311
```

Launch command:

```bash
adb -s emulator-5554 shell am start -n com.jivemoney.app.dev/com.jive.app.MainActivity
```

Launch result:

- App process started.
- Foreground activity resolved as `com.jivemoney.app.dev/com.jive.app.MainActivity`.
- Android reported the activity as fully drawn in about 12 seconds.
- No `FATAL EXCEPTION`, `E/flutter`, ANR, crash, or native fatal signal was found in logcat.

## Flow Checks

### 1. First Launch / Onboarding

Result: passed

Observed:

- Welcome screen rendered.
- Onboarding advanced from welcome to quick transaction entry.
- Category grid rendered with updated category labels including `餐饮`, `宠物`, `出差`, `护肤`, `金融`, and others.

Artifacts:

- `/tmp/jive-device-qa-24724133714/emulator-launch-25s.png`
- `/tmp/jive-device-qa-24724133714/emulator-after-skip.png`

### 2. Onboarding Quick Transaction Next Button

Result: passed

Steps:

- Entered amount `12.34`.
- Selected category `餐饮`.
- Tapped `下一步`.

Observed:

- The flow advanced to the `设分类` step.
- The previous "category selected but next cannot advance" risk did not reproduce on the emulator.

Artifact:

- `/tmp/jive-device-qa-24724133714/emulator-onboarding-add-next.png`

### 3. Guest Mode

Result: passed

Observed:

- Auth screen rendered.
- The guest mode button was reachable after scrolling.
- Guest confirmation dialog rendered.
- `进入游客模式` entered the app successfully.

Artifacts:

- `/tmp/jive-device-qa-24724133714/emulator-auth-scrolled.xml`
- `/tmp/jive-device-qa-24724133714/emulator-main-home.png`

### 4. Home Screen

Result: passed

Observed:

- Home rendered for `访客`.
- Net worth card rendered.
- Quick action tiles rendered.
- Recent transactions section rendered.
- Bottom navigation rendered.

Artifact:

- `/tmp/jive-device-qa-24724133714/emulator-main-home.png`

### 5. Subscription Screen

Result: passed

Observed:

- Settings opened from the home menu.
- `账户与订阅 当前：免费版` was visible.
- Subscription screen opened.
- Free and pro plan content rendered.

Artifact:

- `/tmp/jive-device-qa-24724133714/emulator-subscription.png`

### 6. Cloud Sync Gate

Result: passed

Observed:

- `云同步设置` entry opened the subscription gate in guest/free mode.
- The gate displayed `此功能需要订阅版`.
- The app did not crash.

Artifact:

- `/tmp/jive-device-qa-24724133714/emulator-sync-settings.png`

### 7. Main Add Transaction

Result: passed

Observed:

- New add-transaction page opened from `记一笔`.
- Amount keypad rendered.
- `+ 长按×` and `- 长按÷` labels were visible.
- Entered `12.34`.
- Confirmed the transaction.
- Home returned and recent transactions showed `今天 -12.34`.

Artifact:

- `/tmp/jive-device-qa-24724133714/emulator-final-home-with-transaction.png`

## Logcat Check

Final logcat scan:

```bash
rg -n "FATAL EXCEPTION|E/flutter|Unhandled Exception|ANR in|CRASH|Fatal signal" \
  /tmp/jive-device-qa-24724133714/emulator-final-logcat.txt
```

Result:

```text
no matches
```

## Known Limitation

Physical phone installation was not completed because the existing app was signed with a different certificate. The safe helper intentionally stopped before uninstalling.

To install on the physical phone, first decide whether deleting the existing `com.jivemoney.app.dev` local data is acceptable. If yes:

```bash
scripts/install_saas_staging_apk.sh \
  --device 531cb562 \
  --apk /tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk \
  --allow-uninstall-on-signature-mismatch
```

## Result

The staging APK is installable and usable on a clean Android emulator. Core app launch, onboarding, guest mode, subscription gate, sync gate, and a basic local transaction flow passed. The only blocker for physical-phone testing is the expected signature mismatch with the already-installed dev package.
