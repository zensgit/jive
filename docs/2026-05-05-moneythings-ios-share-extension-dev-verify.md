# MoneyThings iOS Share Extension Development & Verification

Date: 2026-05-05
Branch: `codex/moneythings-ios-share-extension`
Base: `origin/main@0826d970`

## Summary

This slice completes the previously deferred iOS system share entry for the MoneyThings-inspired entry system.

The implementation is intentionally thin: the iOS Share Extension receives shared text or URL content, normalizes it into the existing `jive://transaction/new` deep link, and lets Flutter route it through `QuickActionDeepLinkService` into `TransactionFormScreen`.

Native iOS code still does not create or persist transactions.

## Development

Added `ios/Shared/JiveExternalEntryLinkBuilder.swift`:

- Builds `jive://transaction/new?...` links for external entry sources.
- Builds `jive://quick-action?id=...` links for One Touch quick actions.
- Normalizes transaction type and entry source values.
- Keeps URL construction shared by Shortcuts, Share Extension, and Runner tests.

Updated `ios/Runner/JiveShortcutIntents.swift`:

- `JiveShortcutLinkBuilder` now delegates URL construction to `JiveExternalEntryLinkBuilder`.
- Existing iOS Shortcuts behavior stays unchanged.

Added `ios/JiveShareExtension`:

- `Info.plist` registers a `com.apple.share-services` extension.
- The activation rule supports text and one web URL.
- `ShareViewController` reads the first shared text or URL item.
- It opens `jive://transaction/new?entrySource=shareReceive&sourceLabel=...&rawText=...`.
- After handoff, the extension completes the request.

Updated `ios/Runner.xcodeproj/project.pbxproj`:

- Adds `JiveShareExtension` as a native app extension target.
- Embeds `JiveShareExtension.appex` into Runner via `Embed App Extensions`.
- Adds `JiveExternalEntryLinkBuilder.swift` to both Runner and Share Extension targets.

Updated `ios/RunnerTests/RunnerTests.swift`:

- Keeps existing Shortcuts URL tests.
- Adds coverage for the iOS share-receive deep link shape.

Updated docs:

- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/2026-04-26-moneythings-entry-system-closure-design-verify.md`
- `docs/moneythings-entry-system-user-guide.md`

## Design Notes

The share flow follows the same MoneyThings entry contract already used by Android share, widgets, Shortcuts, and deep links:

`iOS Share Sheet -> JiveShareExtension -> jive://transaction/new -> QuickActionDeepLinkService -> TransactionFormScreen`

The extension passes shared text as `rawText`, not as a forced note. This preserves the existing parser behavior: if the text contains an amount, Jive can infer amount/type; if parsing is incomplete, the editor still keeps the raw text visible for user confirmation.

The extension does not introduce App Group storage, background persistence, or a second transaction API.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No native transaction persistence.
- No dedicated `JiveQuickAction` collection.
- No object-level sharing/RLS changes.

## Verification

Commands run:

```bash
xcodebuild -list -project ios/Runner.xcodeproj

SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
xcrun swiftc -typecheck -parse-as-library -application-extension -sdk "$SDK" -target arm64-apple-ios13.0-simulator ios/Shared/JiveExternalEntryLinkBuilder.swift ios/JiveShareExtension/ShareViewController.swift
xcrun swiftc -typecheck -parse-as-library -sdk "$SDK" -target arm64-apple-ios16.0-simulator ios/Shared/JiveExternalEntryLinkBuilder.swift ios/Runner/JiveShortcutIntents.swift

xcodebuild build -project ios/Runner.xcodeproj -target JiveShareExtension -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO

/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart
git diff --check
git diff --name-only -- supabase/migrations lib/core/sync .github/workflows
```

Results:

- `xcodebuild -list`: passed and lists `Runner`, `RunnerTests`, and `JiveShareExtension`.
- Share Extension Swift typecheck: passed.
- Runner Shortcuts Swift typecheck: passed.
- `xcodebuild build -target JiveShareExtension`: passed.
- `flutter analyze --no-fatal-infos`: passed with existing info-level findings only.
- `flutter test test/moneythings_alignment_services_test.dart`: passed.
- Restricted directory diff: empty.

Attempted full Runner iOS build:

```bash
pod install
xcodebuild build -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

Observed result:

- The dependency graph correctly includes `Runner -> JiveShareExtension`.
- The Share Extension target compiles before Runner.
- The build then fails at existing Runner linking with `ld: framework 'Pods_Runner' not found`.

This matches the local iOS packaging/linking issue already observed in the iOS Shortcuts slice. It is not caused by the new Share Extension source or target.

## Manual Smoke

When iOS simulator packaging is unblocked:

- Install the iOS app.
- From another iOS app, share plain text such as `星巴克 28` to `记到 Jive`.
- Confirm Jive opens the structured transaction editor.
- Confirm source banner shows iOS system share origin.
- Confirm amount/text parsing is consistent with Android share.
- Share a web URL and confirm the URL is preserved as raw text in the editor.
- Save after choosing account/category and confirm the transaction uses the existing save path.
