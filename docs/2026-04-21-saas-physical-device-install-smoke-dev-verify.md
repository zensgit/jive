# SaaS Staging Physical Device Install Smoke Dev & Verify

Date: 2026-04-21 22:19 CST
Branch: `codex/saas-physical-device-install-smoke`
Base commit: `a03b8b5`

## Goal

Close the next SaaS deployment-readiness gap after staging APK build and emulator smoke:

- Safely install the staging dev APK onto the connected physical Android phone.
- Handle the known debug signing mismatch without silently deleting local app data.
- Record device launch evidence and current limitations.

## Development Changes

Updated `scripts/install_saas_staging_apk.sh`.

- Added `--backup-before-uninstall <dir>`.
- The backup path is only used when `--allow-uninstall-on-signature-mismatch` is also set and `adb install -r` fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- Before uninstalling, the script exports app data via `run-as <package> tar -cf - .`.
- Backup failure or backup verification failure aborts the uninstall.
- Backup success now produces:
  - `<backup>.tar`
  - `<backup>.tar.list`
  - `<backup>.tar.size`
  - `<backup>.tar.sha256` when `shasum` is available
- Added missing-value validation for options that require an argument.
- Default behavior remains data-safe: without the explicit uninstall flag, the script still refuses to uninstall.

## APK Under Test

APK:

`/tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk`

SHA-256:

`b9ed5ddc03733a14c65f1a302ecd5450bea3be4779c55772b9855f2d878fa96a`

Package:

- `com.jivemoney.app.dev`
- `versionCode=2109612951`
- `versionName=1.1.0-20260421-1311`

## Physical Device

- Serial: `531cb562`
- Model: `25010PN30C`
- Android: `16`
- Size: `1440x3200`

## Backup Evidence

Manual preflight backup:

- Directory: `/tmp/jive-physical-backup-20260421-221029`
- Tar: `/tmp/jive-physical-backup-20260421-221029/app-data.tar`
- Size: `138597376`
- SHA-256: `7666fa66b3391b782b3d009f2409b5d5cc8646ab17c78bb65643dc4bd61b4fc9`
- Corrected inventory: `/tmp/jive-physical-backup-20260421-221029/app-data-inventory-corrected.txt`

Scripted pre-uninstall backup:

- Directory: `/tmp/jive-physical-backup-20260421-scripted`
- Tar: `/tmp/jive-physical-backup-20260421-scripted/com.jivemoney.app.dev-appdata-20260421-221441.tar`
- Size: `153879552`
- SHA-256: `9a0242d1feac7bb8fe773eea6425525c82ccb68c49c90686cadb2f6361e09a27`
- Tar list: `/tmp/jive-physical-backup-20260421-scripted/com.jivemoney.app.dev-appdata-20260421-221441.tar.list`

The scripted backup completed before uninstall, and the tar was list-verified before the script proceeded.

## Install Result

Command shape:

```bash
scripts/install_saas_staging_apk.sh \
  --adb /Users/chauhua/Library/Android/sdk/platform-tools/adb \
  --device 531cb562 \
  --apk /tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk \
  --allow-uninstall-on-signature-mismatch \
  --backup-before-uninstall /tmp/jive-physical-backup-20260421-scripted
```

Observed flow:

- Initial `adb install -r` failed with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- Script created and verified app data backup.
- Script uninstalled `com.jivemoney.app.dev`.
- Script installed the staging APK successfully.
- Installed metadata after reinstall:
  - `versionCode=2109612951`
  - `versionName=1.1.0-20260421-1311`
  - `firstInstallTime=2026-04-21 22:14:58`
  - `lastUpdateTime=2026-04-21 22:14:58`

## Physical Device Smoke

Artifacts:

- Launch screenshot: `/tmp/jive-physical-device-qa-24724133714/physical-launch.png`
- Launch UI tree: `/tmp/jive-physical-device-qa-24724133714/physical-launch.xml`
- Home screenshot after seeded debug prefs: `/tmp/jive-physical-device-qa-24724133714/physical-home-seeded.png`
- Home UI tree: `/tmp/jive-physical-device-qa-24724133714/physical-home-seeded.xml`
- Home summary: `/tmp/jive-physical-device-qa-24724133714/physical-home-seeded-summary.txt`
- Package dump: `/tmp/jive-physical-device-qa-24724133714/physical-package-dumpsys-after.txt`
- App PID logcat: `/tmp/jive-physical-device-qa-24724133714/physical-app-pid-logcat.txt`
- Crash buffer: `/tmp/jive-physical-device-qa-24724133714/physical-crash-buffer.txt`

Results:

- Cold launch reached the welcome screen.
- Process stayed alive.
- UI tree was readable.
- After seeding debug SharedPreferences with onboarding/guided-setup/auth-skip completion, the physical device rendered the home screen.
- Home UI tree included:
  - `访客`
  - `净资产`
  - `测试广告`
  - `最近交易`
  - `Home / Stats / Assets` tabs
- App PID logcat captured no crash lines.
- Crash buffer was empty.

## Physical Interaction Limitation

The connected Android 16 phone rejects adb input injection:

```text
java.lang.SecurityException: Injecting input events requires the caller ... to have the INJECT_EVENTS permission.
```

Impact:

- Physical install and launch validation are complete.
- Physical automated tapping is blocked by device security settings, not by the app.
- Interactive flow validation should continue on emulator until the phone enables the vendor setting that permits adb input injection, commonly named "USB debugging (Security settings)" or similar on Xiaomi/HyperOS devices.

## Related Emulator Coverage

The same APK build was already covered by emulator smoke in the previous device-install lane:

- Onboarding quick transaction advanced after category selection.
- Guest auth reached home.
- Subscription screen rendered.
- Cloud sync gate rendered.
- Add transaction page rendered keypad labels `+ 长按×` and `- 长按÷`.
- A basic transaction saved and appeared in recent transactions.
- Final emulator logcat scan had no fatal crash patterns.

Primary emulator artifact directory:

`/tmp/jive-device-qa-24724133714`

## Validation Commands

Passed:

```bash
bash -n scripts/install_saas_staging_apk.sh
scripts/install_saas_staging_apk.sh --help
git diff --check
scripts/install_saas_staging_apk.sh --adb /Users/chauhua/Library/Android/sdk/platform-tools/adb --device 531cb562 --apk /tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk --allow-uninstall-on-signature-mismatch --backup-before-uninstall /tmp/jive-physical-backup-20260421-scripted
```

Not rerun:

- `flutter analyze`
- `flutter test`

Reason: this PR changes only the shell install helper and documentation. The staging APK and Flutter validation were already produced by the successful staging APK workflow for this exact artifact.

## Decision

This closes the physical-device installation blocker for staging debug builds. The remaining phone-side issue is adb input permission, which is an environment/device setting rather than an app regression.
