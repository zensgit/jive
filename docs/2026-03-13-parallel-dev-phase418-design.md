# Phase418 Design

## Background
- Android emulator lane was blocked by repeated `No space left on device` failures during:
  - `aapt2` download
  - JNI transform extraction
  - native debug symbol strip
  - final APK copy into `build/app/outputs/flutter-apk`

## Design
- Align with Flutter Gradle plugin's own split-per-ABI flow instead of fighting its default ABI injection.
- Route Android E2E smoke through:
  - `GRADLE_OPTS=-Dorg.gradle.project.split-per-abi=true`
  - existing Flutter `target-platform` handling
- Keep debug symbols in the E2E split-per-ABI case to reduce extra native copy pressure.

## Files
- `android/app/build.gradle.kts`
- `scripts/run_android_e2e_smoke.sh`

## Tradeoff
- E2E/debug lanes now prefer smaller ABI-specific artifacts over one fat debug APK.
- This improves host-space survivability but still depends on the host having enough space for one ABI build and final APK copy.
