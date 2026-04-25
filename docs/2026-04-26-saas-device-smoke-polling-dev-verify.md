# SaaS Device Smoke Polling Dev & Verify

Date: 2026-04-26 01:20 CST
Branch: `codex/saas-device-smoke-polling`
Base commit: `e82163f1`

## Goal

Reduce false negatives in the SaaS staging device smoke lane when a fresh debug build needs more than the old fixed 12 seconds to leave the splash screen.

This follows the deployment-test completion report recommendation in `docs/2026-04-22-saas-staging-deployment-test-completion.md`.

## Development Changes

Updated `scripts/run_saas_staging_device_smoke.sh`.

Changes:

- Changed the default launch wait budget from `12` seconds to `45` seconds.
- Added `--poll-interval-seconds <n>` and `JIVE_SAAS_DEVICE_SMOKE_POLL_INTERVAL_SECONDS`.
- Replaced the single fixed post-launch sleep with UI polling until a recognizable screen appears or the wait budget expires.
- Added positive integer validation for `--wait-seconds` and `--poll-interval-seconds`.
- Added `screen-poll-log.tsv` to record each poll attempt.
- Added `waitSeconds`, `pollIntervalSeconds`, and `screenPollLog` to the generated summary.
- Kept existing screen detection states unchanged: `welcome`, `home`, `auth`, `guided`, and `unknown`.

## Why This Shape

The staging completion run showed that the first launch of a fresh debug APK can still be on splash after 12 seconds, while the app becomes healthy shortly afterward. A fixed sleep therefore made the smoke lane sensitive to machine/emulator timing rather than app correctness.

Polling the UI tree is safer because:

- fast launches still finish quickly;
- slow first launches get the full wait budget;
- artifacts show the exact detection timeline;
- the script remains tap-free, so it still works on physical devices that block adb input injection.

## Emulator Validation

Command:

```bash
scripts/run_saas_staging_device_smoke.sh \
  --adb /Users/chauhua/Library/Android/sdk/platform-tools/adb \
  --device emulator-5554 \
  --skip-install \
  --package com.jivemoney.app.dev \
  --seed-home-prefs \
  --expect home \
  --wait-seconds 45 \
  --poll-interval-seconds 2 \
  --out-dir /tmp/jive-saas-device-smoke-polling-20260426
```

Result: `PASS`

Device:

- serial: `emulator-5554`
- model: `sdk_gphone64_arm64`
- Android: `15`
- resolution: `1080x2400`

Package:

- package: `com.jivemoney.app.dev`
- activity: `com.jivemoney.app.dev/com.jive.app.MainActivity`
- versionCode: `2109614529`
- versionName: `1.1.0-20260422-1529`
- install mode: `--skip-install`

Detected screen:

- expected: `home`
- detected: `home`
- detected after: `17s`

Poll log:

```text
elapsed_seconds	detected_screen
4	unknown
8	unknown
12	unknown
17	home
```

Artifacts:

- summary: `/tmp/jive-saas-device-smoke-polling-20260426/summary.md`
- poll log: `/tmp/jive-saas-device-smoke-polling-20260426/screen-poll-log.tsv`
- screenshot: `/tmp/jive-saas-device-smoke-polling-20260426/launch.png`
- UI tree: `/tmp/jive-saas-device-smoke-polling-20260426/launch.xml`
- app pid logcat: `/tmp/jive-saas-device-smoke-polling-20260426/app-pid-logcat.txt`
- crash buffer: `/tmp/jive-saas-device-smoke-polling-20260426/crash-buffer.txt`

Evidence:

- `summary.md`: `PASS`
- `detected-screen.txt`: `home`
- `crash-buffer.txt`: `0` bytes
- `app-fatal-log-lines.txt`: `0` bytes

## Local Validation

Passed:

```bash
bash -n scripts/run_saas_staging_device_smoke.sh
scripts/run_saas_staging_device_smoke.sh --help
git diff --check
scripts/run_saas_staging_device_smoke.sh --adb /Users/chauhua/Library/Android/sdk/platform-tools/adb --device emulator-5554 --skip-install --package com.jivemoney.app.dev --seed-home-prefs --expect home --wait-seconds 45 --poll-interval-seconds 2 --out-dir /tmp/jive-saas-device-smoke-polling-20260426
```

Not rerun:

- `shellcheck`
- `flutter analyze`
- `flutter test`

Reason: `shellcheck` is not installed locally; this PR changes only a shell staging smoke script and documentation. It does not change Dart, Flutter build inputs, Android app code, Supabase migrations, or Edge Functions.

## Follow-Up

No follow-up is required for the staging deployment-test lane. If future APKs still need longer first-launch time, raise `--wait-seconds` in the workflow invocation without changing script code.
