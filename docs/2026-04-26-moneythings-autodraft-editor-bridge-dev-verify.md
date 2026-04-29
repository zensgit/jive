# MoneyThings AutoDraft Editor Bridge Development & Verification

Date: 2026-04-26
Branch: `feature/moneythings-autodraft-editor-bridge`
Base: stacked on `feature/moneythings-entry-unification` / PR #200

## Summary

This slice continues the MoneyThings TODO plan by adding an editor fallback for automatic drafts:

`auto draft -> TransactionEntryParams -> TransactionFormScreen -> discard original draft after save`

The existing fast path remains unchanged:

`auto draft -> review sheet -> AutoDraftService.confirmDraft()`

This intentionally avoids rewriting batch confirmation or the service-level transfer guards.

## Design

### AutoDraftEntryParamsBuilder

Added `AutoDraftEntryParamsBuilder` as the protocol adapter between `JiveAutoDraft` and the unified transaction editor.

It maps:

- amount, type, account, transfer target, date, tags, raw text
- category keys when present
- category names as fallback when keys are missing
- missing-field highlights for amount, account, category, and transfer target
- transfer service charge from `metadataJson.transferServiceCharge`

Type inference now uses shared `AutoDraftTypeHints`, so the editor path follows the same income/transfer keyword rules as the existing confirm path.

The builder does not write data and does not replace `AutoDraftService`.

### Auto Draft Screen

Each draft card now offers three actions:

- `删除`: discard the draft
- `编辑确认`: open the unified transaction editor
- `确认`: keep the existing review/confirm sheet and `AutoDraftService.confirmDraft()`

When `编辑确认` saves successfully, the original draft is discarded. If the editor is cancelled or validation fails, the draft remains in the pending list.

### Transfer Fee Preservation

`TransactionEntryParams` now supports:

- `prefillExchangeFee`
- `prefillExchangeFeeType`

`TransactionFormScreen` writes those fields only for transfer transactions. This keeps imported transfer drafts with a service fee from losing that fee when the user chooses the structured editor path.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync logic changes.
- Existing `确认` and `全部确认` behavior is unchanged.
- Transfer account safety remains enforced by the existing confirm path.

## Deferred Items

Still deferred to later slices:

- Replacing AutoDraft batch confirmation with a full editor walk-through.
- Native widget/AppIntent bridge.
- Android/iOS system share receiver.
- Voice flow migration out of calculator mode.
- Full object-level sharing tables/RLS.
- True `JiveQuickAction` persistent collection.

## Verification

Commands run:

```bash
flutter analyze --no-fatal-infos
flutter test test/moneythings_alignment_services_test.dart test/auto_draft_service_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart
```

Results:

- `flutter analyze --no-fatal-infos`: passed with existing info-level lints only.
- MoneyThings protocol tests: passed.
- AutoDraft service tests: passed, including transfer target and service fee preservation.
- Transaction/category regression tests: passed.

## Manual Smoke Checklist

- Open `待确认自动记账` with a normal expense draft.
- Tap `编辑确认`, confirm the editor opens with amount/account/category/raw text prefilled.
- Save from the editor and confirm the original draft disappears.
- Open a transfer draft with a missing target account and confirm the editor highlights the transfer target.
- Use the existing `确认` button and confirm the original AutoDraft review sheet still works.
- Use `全部确认` and confirm the original batch-confirm behavior still works.
