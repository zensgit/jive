# MoneyThings Entry System Closure Design & Verification

Date: 2026-04-26
Branch: `feature/moneythings-entry-system-closure-docs`
Base: stacked on `feature/moneythings-android-widget-quick-entry` / PR #207

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

Local validation used across the stack:

- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos`
- targeted Flutter tests for MoneyThings services, entry UX, category picker, transaction widgets, speech parser, import/export
- `git diff --check`
- restricted directory checks for `supabase/migrations`, `lib/core/sync`, `.github/workflows`, SaaS entitlement/payment/sync logic
- Android `flutter build apk --debug --no-pub` for PR #206 and #207 native changes

GitHub CI status for the final external-entry stack:

- PR #205: `analyze_and_test` passed, `detect_saas_wave0_smoke` passed.
- PR #206: `analyze_and_test` passed, `detect_saas_wave0_smoke` passed.
- PR #207: `analyze_and_test` passed, `detect_saas_wave0_smoke` passed.

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

## Manual Smoke Checklist

- Quick action: run a complete quick action and confirm direct/confirm/edit behavior is preserved.
- Screenshot OCR: recognize a payment screenshot and confirm the structured editor opens with account/category highlighted.
- Conversation: parse one sentence and confirm it opens the editor before save.
- AutoDraft: use both existing confirm and new edit-confirm paths.
- Voice: use AI Assistant voice entry and confirm preview opens the editor.
- Clipboard: use AI Assistant clipboard recognition and confirm it opens the editor.
- Android share: share payment text into Jive and confirm amount is parsed, with account/category highlighted.
- Android widget: tap widget card background to open app, then tap `+ 记一笔` to open editor.
- Three-level category: save `出行 / 私家车 / 加油` and confirm details/export show the path.
- Account group: confirm grouped accounts display as group/subaccount while transactions still save to child account.
- Shared scene: confirm shared badges and delete warning copy appear on scene/category/tag/account surfaces.

## Explicitly Deferred

These remain intentionally outside the current non-migration wave:

- iOS App Intent / Shortcut native bridge.
- iOS system share extension.
- Dedicated `JiveQuickAction` collection replacing template compatibility persistence.
- `parentAccountKey` migration for true parent-child accounts.
- Full object-level sharing table, RLS, offline conflict handling, and audit log.
- E2EE/key-management work.
- SaaS entitlement/payment/sync behavior changes.

## Merge Guidance

Merge the external-entry closure stack in order:

- #205
- #206
- #207
- this docs-only PR

Earlier MoneyThings stack PRs should remain in their existing order:

- #197
- #200
- #201
- #202

After the stack lands, update any central TODO page to mark the current non-migration MoneyThings wave as complete and keep the deferred items as a separate post-Beta track.
