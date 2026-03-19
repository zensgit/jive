# Phase419 Design

## Background
- Phase418 solved host disk exhaustion by moving Android E2E to single-ABI debug builds.
- After that, Android `flutter test` still failed because Flutter tool was looking for the legacy file name `app-dev-debug.apk`, while Gradle only emitted `app-arm64-v8a-dev-debug.apk`.
- Separately, `adb shell getprop sys.boot_completed` could hang long enough to stall the whole smoke script.

## Design
- Keep the Flutter Gradle plugin on `split-per-abi=true`.
- Add a compatibility layer in `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`:
  - for each Android variant, finalize `assemble<Variant>` with a small task that links the split-per-ABI output back to the legacy Flutter lookup name.
- Harden `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`:
  - wrap `adb` commands in a timeout
  - use `adb reconnect` recovery instead of `adb kill-server`
  - keep the rest of the smoke lane unchanged

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/android_e2e_flutter_apk_compat_mvp.md`

## Tradeoff
- The lane keeps single-ABI output size benefits and avoids duplicating the full APK by using a symlink.
- The compatibility layer is debug-lane specific behavior, but it is still extra Gradle wiring that should stay scoped to Android E2E usage.
