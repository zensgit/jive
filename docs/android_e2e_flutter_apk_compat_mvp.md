# Android E2E Flutter APK Compatibility

## Goal
- Keep Android emulator E2E on single-ABI debug artifacts.
- Preserve compatibility with `flutter test` APK discovery, which still expects the legacy non-ABI filename.
- Prevent `adb shell` preflight calls from hanging the lane indefinitely.

## Changes
- `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`
  - Keep `split-per-abi` enabled for Android E2E.
  - Add variant-specific compatibility tasks such as `app:linkFlutterApkDevDebug`.
  - After split-per-ABI build output is produced, create a compatibility symlink like `app-dev-debug.apk -> app-arm64-v8a-dev-debug.apk` in `build/app/outputs/flutter-apk`.
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
  - Wrap `adb` calls in a bounded timeout.
  - Recover with `adb reconnect` instead of `adb kill-server`, to avoid breaking emulator registration.

## Expected Effect
- `flutter test -d emulator-5554 --flavor dev` can keep using the legacy APK lookup path.
- Android E2E lane stays on smaller single-ABI APKs.
- Device preflight no longer blocks forever on a hung `adb shell getprop sys.boot_completed`.

## Scope
- Android emulator `integration_test` lane only.
- No change to release signing or release packaging.
