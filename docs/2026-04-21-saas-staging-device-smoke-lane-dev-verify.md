# SaaS Staging Device Smoke Lane Dev & Verify

Date: 2026-04-21 22:40 CST
Branch: `codex/saas-staging-device-smoke-lane`
Base commit: `01ea299`

## Goal

Turn the manual SaaS staging APK install/launch checks into a repeatable device smoke lane.

This keeps scope intentionally narrow:

- Do not add product features.
- Do not require adb screen tapping.
- Reuse the existing safe APK installer.
- Produce a stable artifact directory for deployment testing.

## Development Changes

Added `scripts/run_saas_staging_device_smoke.sh`.

The script supports:

- `--apk <path>` to install the staging APK before launch.
- `--skip-install` to inspect an already-installed package.
- `--device <serial>`, `--package <id>`, and `--adb <path>` for explicit adb targeting.
- `--allow-uninstall-on-signature-mismatch` and `--backup-before-uninstall <dir>` passthrough to `install_saas_staging_apk.sh`.
- `--seed-home-prefs` to write debug SharedPreferences for staging smoke, skipping onboarding/guided setup/auth gate.
- `--expect <any|welcome|home|auth|guided>` to assert the detected launch state.
- `--out-dir <path>` for deterministic artifact output.

The script captures:

- install log
- package metadata
- activity launch output
- screenshot
- uiautomator XML
- activity dump
- app pid
- app pid logcat
- crash buffer
- detected screen
- summary markdown

It fails if:

- the app process is not alive after launch
- the expected screen does not match the detected screen
- the screen cannot be identified
- app pid logcat contains fatal crash patterns

## Why This Shape

The connected physical Android 16 device blocks adb input injection with `INJECT_EVENTS` permission errors. Because of that, this lane deliberately avoids taps/swipes and validates the stable deployment basics instead:

- installability
- launchability
- UI tree availability
- expected screen state
- no immediate app crash

Interactive flow coverage remains in emulator-based smoke until the physical phone permits adb input injection.

## Physical Device Validation

Command:

```bash
scripts/run_saas_staging_device_smoke.sh \
  --adb /Users/chauhua/Library/Android/sdk/platform-tools/adb \
  --device 531cb562 \
  --apk /tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk \
  --seed-home-prefs \
  --expect home \
  --out-dir /tmp/jive-saas-device-smoke-20260421-physical
```

Result: `PASS`

Device:

- serial: `531cb562`
- model: `25010PN30C`
- Android: `16`
- package: `com.jivemoney.app.dev`

APK:

- path: `/tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk`
- versionCode: `2109612951`
- versionName: `1.1.0-20260421-1311`

Detected screen:

- expected: `home`
- detected: `home`

Artifacts:

- summary: `/tmp/jive-saas-device-smoke-20260421-physical/summary.md`
- screenshot: `/tmp/jive-saas-device-smoke-20260421-physical/launch.png`
- UI tree: `/tmp/jive-saas-device-smoke-20260421-physical/launch.xml`
- app pid logcat: `/tmp/jive-saas-device-smoke-20260421-physical/app-pid-logcat.txt`
- crash buffer: `/tmp/jive-saas-device-smoke-20260421-physical/crash-buffer.txt`
- package metadata: `/tmp/jive-saas-device-smoke-20260421-physical/package-version.txt`

Evidence:

- `detected-screen.txt`: `home`
- `crash-buffer.txt`: `0` bytes
- `app-fatal-log-lines.txt`: `0` bytes
- `summary.md`: `PASS`

## Local Validation

Passed:

```bash
chmod +x scripts/run_saas_staging_device_smoke.sh
bash -n scripts/run_saas_staging_device_smoke.sh
scripts/run_saas_staging_device_smoke.sh --help
git diff --check
```

Not rerun:

- `flutter analyze`
- `flutter test`

Reason: this PR adds a shell smoke wrapper and documentation only; it does not change Dart, Android, iOS, Supabase, or Flutter build inputs.

## Follow-Up

Recommended next deployment-testing step:

- Add a staging sync push/pull runbook or script using a real staging auth user.
- Keep physical-device interaction testing on emulator until the phone allows adb input injection.
