# Android E2E Single-ABI Space Mode

## Goal
- Reduce Android emulator E2E build disk pressure on macOS host machines with limited free space.
- Keep the optimization scoped to Android E2E/debug lanes instead of changing release packaging.

## Changes
- `android/app/build.gradle.kts`
  - Detect Gradle property `split-per-abi=true`.
  - When enabled, keep JNI debug symbols for `.so` files to avoid extra strip/copy churn in E2E builds.
- `scripts/run_android_e2e_smoke.sh`
  - Inject `-Dorg.gradle.project.split-per-abi=true` through `GRADLE_OPTS`.

## Expected Effect
- Flutter Gradle plugin switches from fat APK mode to split-per-ABI mode.
- Android E2E build emits ABI-specific APKs, reducing final artifact size.
- Host-side build no longer needs to package all Flutter debug ABIs into one APK for emulator smoke runs.

## Scope
- Intended for `integration_test` and Android emulator smoke lanes.
- Does not change release signing or release artifact strategy.
