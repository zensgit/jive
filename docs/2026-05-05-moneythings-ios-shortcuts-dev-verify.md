# MoneyThings iOS Shortcuts Development & Verification

Date: 2026-05-05
Branch: `codex/moneythings-ios-shortcuts-entry`
Base: `origin/main@8c3a0ab`

## Summary

This slice completes the previously deferred iOS App Intent / Shortcut native bridge for the MoneyThings-inspired entry system.

The implementation is intentionally thin: iOS exposes system actions, then hands off to the existing Flutter deep-link protocol. It does not create transactions in native code.

## Development

Added `ios/Runner/JiveShortcutIntents.swift`:

- `JiveShortcutLinkBuilder.transactionURL(...)` builds `jive://transaction/new?...`.
- `JiveShortcutLinkBuilder.quickActionURL(actionId:)` builds `jive://quick-action?id=...`.
- `OpenJiveTransactionIntent` opens Jive's structured transaction editor with optional type, amount, and note.
- `RunJiveQuickActionIntent` opens an existing One Touch quick action by ID, such as `template:42`.
- `JiveShortcutsProvider` makes the `记一笔` shortcut discoverable to Shortcuts / Siri.

Updated `ios/Runner.xcodeproj/project.pbxproj`:

- Adds `JiveShortcutIntents.swift` to the Runner target sources.

Refreshed `ios/Podfile.lock` through `pod install` during iOS validation so the lockfile matches the current Flutter plugin set used by `pubspec.lock`.

Updated `ios/RunnerTests/RunnerTests.swift`:

- Covers transaction deep-link URL construction.
- Covers unknown transaction type fallback to `expense`.
- Covers quick-action link construction.
- Covers blank quick-action ID rejection.

Updated docs:

- `docs/moneythings-entry-system-user-guide.md`
- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/2026-04-26-moneythings-entry-system-closure-design-verify.md`

## Design Notes

The bridge follows the current MoneyThings entry contract:

`iOS system trigger -> App Intent -> jive://... -> QuickActionDeepLinkService -> TransactionFormScreen or QuickActionExecutor`

This preserves the existing rule that native/platform code must not create transactions directly.

The two supported iOS surfaces are:

- `记一笔`: opens the structured transaction editor with optional prefilled fields.
- `运行 Jive 快速动作`: opens a One Touch quick action by ID.

The implementation references Apple's App Intents guidance for exposing small, useful system actions through `AppIntent` and `AppShortcutsProvider`.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No new native transaction persistence path.
- No dedicated `JiveQuickAction` collection.
- No iOS share extension.

## Verification

Commands run:

```bash
/Users/chauhua/development/flutter/bin/flutter pub get
xcrun swiftc -typecheck -parse-as-library -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -target arm64-apple-ios16.0-simulator ios/Runner/JiveShortcutIntents.swift
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart
git diff --check
git diff --name-only -- supabase/migrations lib/core/sync .github/workflows
```

Results:

- `flutter pub get`: passed.
- Swift typecheck: passed.
- `flutter analyze --no-fatal-infos`: passed with existing info-level findings only.
- `flutter test test/moneythings_alignment_services_test.dart`: passed.
- `git diff --check`: passed.
- Restricted directory diff: empty.

Attempted iOS packaging:

```bash
xcodebuild build -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
COPYFILE_DISABLE=1 /Users/chauhua/development/flutter/bin/flutter build ios --simulator --debug --no-codesign
```

Observed blockers:

- Direct `xcodebuild` reached Runner Swift compilation, then failed at link with `framework 'Pods_Runner' not found`.
- Flutter simulator build initially failed while codesigning `Flutter.framework` because the local build copy had macOS extended attributes.
- After clearing build artifacts and using `COPYFILE_DISABLE=1`, Flutter simulator build progressed further but failed with `Library 'isar' not found`.

These blockers are local iOS packaging/linking environment issues. The new App Intent source itself typechecks successfully.

## Manual Smoke

When iOS simulator packaging is unblocked:

- Install the iOS app.
- Open Shortcuts and run Jive `记一笔`.
- Confirm the app opens the structured transaction editor.
- Run `记一笔` with amount and note parameters, then confirm the editor pre-fills them.
- Run `运行 Jive 快速动作` with `template:<id>`.
- Confirm the app follows the same QuickActionExecutor direct / confirm / edit behavior as in-app quick actions.
