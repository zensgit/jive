# MoneyThings System Entry Shortcuts Smoke Dev Verify

Date: 2026-05-16

Branch: `codex/moneythings-next-status`

Base: `origin/main@4f0ef191`

## Scope

This slice finishes a small system-entry gap from the MoneyThings closure TODO:
iOS already had `RunJiveQuickActionIntent`, but it was not exposed in
`JiveShortcutsProvider.appShortcuts`. The app now surfaces the quick-action
intent alongside transaction entry and scene switching.

No migration, Supabase, sync, entitlement, payment, or workflow files were
changed.

## Changes

- Added an App Shortcut for `RunJiveQuickActionIntent`.
- The shortcut phrase opens `jive://quick-action?id=...` through
  `JiveShortcutLinkBuilder.quickActionURL(actionId:)`.
- Flutter continues to resolve that URL through
  `QuickActionDeepLinkService -> QuickActionService.findActionById ->
  QuickActionExecutor.execute`.
- Updated the MoneyThings closure TODO to mark already merged Waves 1-7
  functionality from code evidence, while keeping Widget saved-action entry and
  Free/Pro/Family shared-ledger limits open.

## Manual Smoke Notes

### iOS Shortcuts / AppIntent

1. Install a debug build on a physical iPhone or simulator with Shortcuts
   available.
2. Open Shortcuts and search for Jive.
3. Confirm three visible actions:
   - `记一笔`
   - `快速动作`
   - `切换场景`
4. Run `快速动作` with an existing action id such as `template:42`.
5. Confirm Jive opens through `jive://quick-action?id=template:42`.
6. Confirm the resulting behavior matches in-app quick action execution:
   - `direct` saves immediately.
   - `confirm` opens the light amount confirmation sheet.
   - `edit` opens the structured transaction editor.

### Android Widget

1. Add the Today Summary widget to the Android launcher.
2. Tap the quick-add button in the widget.
3. Confirm Jive opens `jive://transaction/new` with source copy from the widget.
4. Confirm incomplete entries land in `TransactionFormScreen` with missing
   fields highlighted.

Note: the current Android widget quick-add is a structured editor entry, not a
saved quick-action widget. A future saved-action widget should use
`jive://quick-action?id=...`.

### Deep Link

Run or open the following links from adb, Notes, Safari, or any URL launcher:

```text
jive://quick-action?id=template:42
jive://transaction/new?entrySource=voice&rawText=午餐35元
jive://transaction/new?entrySource=shareReceive&rawText=星巴克28&sourceLabel=来自系统分享
jive://scene/switch?name=旅行
jive://scene/switch?all=true
```

Expected behavior:

- Quick action links execute through `QuickActionExecutor`.
- Transaction links open `TransactionFormScreen`.
- Missing amount/category/account fields are highlighted.
- Scene links switch to the target scene/book or all-scene view.

## Verification

Local commands run for this slice:

```bash
git diff --check
/Users/chauhua/development/flutter/bin/flutter test \
  test/quick_action_deep_link_entry_contract_test.dart \
  test/quick_action_entry_link_builder_test.dart \
  test/quick_action_executor_params_test.dart \
  test/transaction_entry_params_protocol_test.dart \
  test/transaction_source_banner_contract_test.dart
xcrun swiftc -target arm64-apple-ios16.0-simulator \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -typecheck ios/Shared/JiveExternalEntryLinkBuilder.swift \
  ios/Runner/JiveShortcutIntents.swift
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Results:

- `git diff --check`: passed.
- Restricted path check: passed; no `supabase/migrations`, `lib/core/sync`,
  `.github/workflows`, SaaS payment, SaaS entitlement, or SaaS sync files were
  changed.
- Focused Flutter tests: passed, 24 tests.
- Swift typecheck: passed.
- `flutter analyze --no-fatal-infos`: passed with existing repo info-level
  analyzer findings.

## Remaining Open Items

- Android/iOS saved quick-action widget surfaces are still future work if we
  decide to expose user-configurable quick-action slots in widgets.
- Free/Pro/Family shared-ledger entry states and limits remain open because
  they affect SaaS entitlement/business rules and should be implemented in a
  dedicated slice.
- Wave 8 migration decisions remain deferred: synced quick-action persistence,
  `parentAccountKey`, object-level sharing tables/RLS, and audit logs.
