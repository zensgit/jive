# MoneyThings Entry System Closure Design & Verification

Date: 2026-04-26
Branch: `feature/moneythings-entry-system-closure-docs`
Base: stacked on `feature/moneythings-android-widget-quick-entry` / PR #207

Post-merge status: this stack landed in `main` through PR #196 on 2026-04-29. Main merge commit: `562d3d92b0bffcae53666a7a8a14d153a4c3fcd6`.

## Summary

This document closes the current non-migration MoneyThings borrowing wave.

The product direction is:

`fast external trigger -> unified params -> safe editor or quick executor -> normal transaction save`

The implementation intentionally does not copy MoneyThings data structures. Jive keeps its existing local models and adds protocol/adaptor layers around them.

## Completed Stack

### Base Protocol And Productization

- PR #193: first-stage MoneyThings protocol layer.
- PR #197: SmartList current-view save, scene/share visibility badges, category/tag delete warning copy.
- PR #200: screenshot OCR and conversational bookkeeping now route through `TransactionEntryParams` and `TransactionFormScreen`.
- PR #201: AutoDrafts can open the structured editor while preserving the existing direct confirm path.
- PR #202: category path import/export uses `CategoryPathService` for three-level category compatibility.

### External Entry Closure

- PR #205: AI Assistant voice and clipboard recognition now open `TransactionFormScreen` through `SpeechEntryParamsBuilder`.
- PR #206: Android system text share (`ACTION_SEND text/plain`) normalizes into `jive://transaction/new` and opens the editor.
- PR #207: Android Today widget adds a `+ 记一笔` action that opens the structured editor; existing widget card tap still opens the app.
- PR #209: closure docs and Android validation references.

### Mainline Landing

- PR #209 merged into #207.
- PR #207 merged into #206.
- PR #206 merged into #205.
- PR #205 merged into #202.
- PR #202 merged into #201.
- PR #201 merged into #200.
- PR #200 merged into #197.
- PR #197 merged into #196.
- PR #196 merged into `main`.

## Design

### One Touch / Quick Action

Jive uses the existing `QuickActionService` and `QuickActionExecutor` as the compatibility layer over templates.

The execution modes remain:

- `direct`: complete simple action can be saved directly.
- `confirm`: mostly complete action opens a lightweight confirmation path.
- `edit`: incomplete or complex action opens the full editor with missing-field highlights.

This keeps existing template persistence while allowing Widget, Deep Link, and future App Intent entries to share one execution contract.

### Unified Transaction Editor

External sources now converge on `TransactionEntryParams` before reaching `TransactionFormScreen`.

Covered sources:

- quick action
- deep link
- screenshot OCR
- conversational bookkeeping
- auto draft
- voice
- clipboard/share-like text
- Android system share
- Android widget quick entry
- iOS Shortcuts / Siri App Intent entry

The editor owns final validation and saving. Native/platform code is not allowed to create transactions directly.

### Three-Level Categories

Jive keeps the compatible storage rule:

- `categoryKey = top-level category`
- `subCategoryKey = final selected leaf`

`CategoryPathService` resolves display, import/export, details, filtering, and compatible save keys. No `tertiaryCategoryKey` migration is introduced in this wave.

### Account Groups / Subaccounts

Jive keeps every account as a normal `JiveAccount`.

`AccountGroupService` groups accounts by meaningful `groupName` only at the view/service layer. Transactions still save to a concrete `accountId`.

No `parentAccountKey` migration is introduced in this wave.

### Scenes / SmartList

Jive continues to model scenes as `JiveBook` plus UI/filter preferences.

Delivered behavior:

- home book switcher copy is scene-oriented
- default SmartList can restore the transaction-list view
- current filters/search can be saved as SmartList
- pinned/default SmartList management remains in `SmartListScreen`

### Object Sharing First Stage

Object sharing remains a visibility and warning layer.

Delivered behavior:

- scenes/books/accounts/categories/tags can surface inherited shared-scene state
- category/tag deletion warnings describe shared-scene impact
- permission truth remains the existing shared ledger/book role model

No object-level RLS or second permission truth is introduced in this wave.

## Verification Matrix

Local validation used across the stack. Commands are written in portable form; local runs used the developer machine's Flutter and Android SDK installations.

- `flutter analyze --no-fatal-infos`
- targeted Flutter tests for MoneyThings services, entry UX, category picker, transaction widgets, speech parser, import/export
- `git diff --check`
- restricted directory checks for `supabase/migrations`, `lib/core/sync`, `.github/workflows`, SaaS entitlement/payment/sync logic
- Android `flutter build apk --debug --no-pub` for PR #206 and #207 native changes

GitHub CI status for the final external-entry stack:

- PR #205: `analyze_and_test` passed, `detect_saas_wave0_smoke` passed.
- PR #206: `analyze_and_test` passed, `detect_saas_wave0_smoke` passed.
- PR #207: `analyze_and_test` passed, `detect_saas_wave0_smoke` passed.

GitHub CI status after the stack landed on `main@562d3d92`:

- `analyze_and_test`: passed.
- `detect_saas_wave0_smoke`: passed.
- `saas_wave0_smoke`: passed.
- `android_integration_test`: skipped by workflow conditions.

Fresh-main local post-merge verification:

- `flutter analyze --no-fatal-infos`: passed with existing info-level findings only.
- `flutter test test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart test/import_csv_mapping_service_test.dart test/import_service_test.dart test/speech_intent_parser_test.dart test/auto_draft_service_test.dart`: passed.

Latest Android validation:

- `docs/2026-04-29-moneythings-entry-system-android-validation.md` records the final docs-branch automated validation pass.
- Targeted entry-system tests passed.
- `flutter analyze --no-fatal-infos` passed with info-level findings only.
- `flutter build apk --debug --flavor dev --no-pub` passed.
- APK manifest inspection confirmed `jive://transaction`, `ACTION_SEND text/plain`, and `JiveTodayWidget`.
- Device smoke is pending because the connected phone has an older `com.jivemoney.app.dev` build signed with a different key; the validation pass intentionally did not uninstall it to avoid clearing local dev data.

Android build note:

- `flutter build apk --debug --no-pub` produced flavor APKs under `build/app/outputs/flutter-apk/`.
- Flutter exited non-zero after Gradle because this project generates `app-dev-debug.apk`, `app-auto-debug.apk`, and `app-prod-debug.apk` instead of one default debug APK.
- No Kotlin/resource compile error was reported.

Latest iOS Shortcuts validation:

- `docs/2026-05-05-moneythings-ios-shortcuts-dev-verify.md` records the App Intent bridge implementation and validation.
- `xcrun swiftc -typecheck` passed for `ios/Runner/JiveShortcutIntents.swift`.
- `flutter analyze --no-fatal-infos` passed with existing info-level findings only.
- `flutter test test/moneythings_alignment_services_test.dart` passed.
- Full iOS simulator packaging is still blocked by existing local iOS build environment issues unrelated to this bridge: first a Flutter.framework extended-attribute signing error, then `Library 'isar' not found` while linking.

Latest iOS Share Extension validation:

- `docs/2026-05-05-moneythings-ios-share-extension-dev-verify.md` records the Share Extension implementation and validation.
- `xcodebuild -list` confirms the project now exposes `JiveShareExtension`.
- `xcrun swiftc -typecheck -application-extension` passed for the shared link builder and Share Extension view controller.
- `xcodebuild build -target JiveShareExtension` passed for Debug iPhone simulator.
- Full Runner simulator build reaches the existing Runner link step and still fails with `ld: framework 'Pods_Runner' not found`; the dependency graph confirms `Runner -> JiveShareExtension`.

## Manual Smoke Checklist

- Quick action: run a complete quick action and confirm direct/confirm/edit behavior is preserved.
- Screenshot OCR: recognize a payment screenshot and confirm the structured editor opens with account/category highlighted.
- Conversation: parse one sentence and confirm it opens the editor before save.
- AutoDraft: use both existing confirm and new edit-confirm paths.
- Voice: use AI Assistant voice entry and confirm preview opens the editor.
- Clipboard: use AI Assistant clipboard recognition and confirm it opens the editor.
- Android share: share payment text into Jive and confirm amount is parsed, with account/category highlighted.
- Android widget: tap widget card background to open app, then tap `+ 记一笔` to open editor.
- iOS Shortcuts: run `记一笔` and confirm Jive opens `jive://transaction/new` into the structured editor.
- iOS Shortcuts: run `运行 Jive 快速动作` with `template:<id>` and confirm it follows One Touch direct/confirm/edit behavior.
- iOS share: share `星巴克 28` or a URL to `记到 Jive` and confirm the editor opens with `shareReceive/rawText`.
- Three-level category: save `出行 / 私家车 / 加油` and confirm details/export show the path.
- Account group: confirm grouped accounts display as group/subaccount while transactions still save to child account.
- Shared scene: confirm shared badges and delete warning copy appear on scene/category/tag/account surfaces.

## Explicitly Deferred

These remain intentionally outside the current non-migration wave:

- Cross-device quick action sync, standalone icon/color/order management, and migration from template compatibility source to independent cloud quick action source.
- `parentAccountKey` migration for true parent-child accounts.
- Full object-level sharing table, RLS, offline conflict handling, and audit log.
- E2EE/key-management work.
- SaaS entitlement/payment/sync behavior changes.

## Post-Merge Guidance

The non-migration MoneyThings wave is complete on `main`.

Use `docs/moneythings-entry-system-user-guide.md` for product QA and user-facing behavior checks. Use `docs/2026-05-05-moneythings-postmerge-closure-dev-verify.md` for the post-merge closure validation record.

Future work should start from the explicit deferred list above, not from the old stacked PR queue.
