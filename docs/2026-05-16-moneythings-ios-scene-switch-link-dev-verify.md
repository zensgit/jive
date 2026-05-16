# MoneyThings iOS Scene Switch Link Development And Verification

Date: 2026-05-16
Branch: `codex/moneythings-ios-scene-switch-link`

## Development

- Added `JiveExternalEntryLinkBuilder.sceneSwitchURL(...)` so iOS entry surfaces
  can generate `jive://scene/switch` links using the same Flutter parser added
  for MoneyThings-style system entry linkage.
- Added `JiveShortcutLinkBuilder.sceneSwitchURL(...)` as the Shortcuts-facing
  wrapper.
- Added `SwitchJiveSceneIntent`, which opens a named scene when provided and
  falls back to `all=true` for the "all scenes" view.
- Added a second App Shortcut suggestion for switching scenes.
- Added iOS unit coverage for scene switching by visible scene name, all-scenes
  fallback, and numeric book id.

## Verification

Commands run:

```sh
git diff --check
/Users/chauhua/development/flutter/bin/flutter pub get
cd ios && pod install
xcodebuildmcp test_sim -only-testing:RunnerTests
xattr -cr build/xcode-derived-data
xattr -cr /Users/chauhua/development/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework /Users/chauhua/development/flutter/bin/cache/artifacts/engine/ios-profile/Flutter.xcframework /Users/chauhua/development/flutter/bin/cache/artifacts/engine/ios-release/Flutter.xcframework
xattr -cr /Users/chauhua/.pub-cache/hosted/pub.dev build/xcode-derived-data
xcrun swiftc -target arm64-apple-ios16.0-simulator -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -typecheck ios/Shared/JiveExternalEntryLinkBuilder.swift ios/Runner/JiveShortcutIntents.swift
```

Targeted checks to run in a clean iOS-capable environment:

```sh
xcodebuild test -project ios/Runner.xcodeproj -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected behavior:

- `JiveShortcutLinkBuilder.sceneSwitchURL(sceneName: "旅行")` builds
  `jive://scene/switch?name=旅行`.
- `JiveExternalEntryLinkBuilder.sceneSwitchURL()` builds an all-scenes switch
  link with `all=true`.
- `SwitchJiveSceneIntent` opens the same URL contract consumed by Flutter's
  `QuickActionDeepLinkService`.

Actual result:

- `git diff --check`: passed.
- `flutter pub get`: passed.
- `pod install`: passed, with the existing CocoaPods base-configuration warning.
- `xcrun swiftc -typecheck` for the changed Swift builder/intent files: passed.
- XcodeBuildMCP `RunnerTests` discovered the expected 8 tests, including the 3
  new scene-switch tests, but the simulator build was blocked by local build
  artifact signing issues: generated Pod/Flutter frameworks repeatedly failed
  CodeSign with `resource fork, Finder information, or similar detritus not
  allowed`. This is an environment/cache xattr issue, not a Swift source error.
