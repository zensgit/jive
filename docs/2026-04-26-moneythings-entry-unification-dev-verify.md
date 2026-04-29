# MoneyThings Entry Unification Development & Verification

Date: 2026-04-26
Branch: `feature/moneythings-entry-unification`
Base: stacked on `feature/moneythings-followup-todos` / PR #197

## Summary

This slice continues the MoneyThings TODO plan by moving more non-manual entry flows onto the unified transaction editor contract:

`external source -> TransactionEntryParams -> TransactionFormScreen -> normal transaction repository save`

Completed in this slice:

- Screenshot OCR no longer writes a transaction directly.
- Conversational bookkeeping no longer writes parsed transactions directly.
- `TransactionEntryParams` can carry `bookId` and raw source text.
- `TransactionFormScreen` persists source-specific `source` values and preserves raw text.
- `TransactionFormScreen` can preselect categories by key or display name, which supports parser output such as `餐饮 / 午餐`.
- Tags can now be highlighted as a missing field in the advanced section.

## Design

### Screenshot OCR Entry

Previous behavior:

- Screenshot recognition edited amount, merchant, date, and payment source in `ScreenshotImportScreen`.
- Pressing record created `JiveTransaction` directly with no account/category confirmation.

New behavior:

- Screenshot recognition still lets the user correct amount, merchant, date, and payment source.
- Pressing confirm opens `TransactionFormScreen`.
- The editor receives:
  - `source = ocrScreenshot`
  - amount/date/note prefilled from OCR
  - raw OCR text preserved via `prefillRawText`
  - account and category highlighted as required fields

This keeps the fast OCR flow while preventing incomplete silent saves.

### Conversational Entry

Previous behavior:

- Parsed conversational results were written directly to Isar.
- Category/account matching could be incomplete, but save still proceeded.

New behavior:

- Parsed results are treated as drafts that must be confirmed.
- Single confirmation opens `TransactionFormScreen` for that parsed item.
- Batch confirmation now walks through unsaved parsed items one by one.
- Multi-transaction input keeps each parsed item segment as its own raw text, avoiding repeated full-input raw text on every saved item.
- The editor receives:
  - `source = conversation`
  - amount/type/date/category/subcategory/note/bookId prefilled where available
  - raw conversation text preserved
  - account and category highlighted for user confirmation

This aligns conversational input with the MoneyThings-style transaction editor fallback: fast parsing first, structured confirmation before save.

### TransactionEntryParams Contract

Added optional fields:

- `prefillBookId`
- `prefillRawText`

These are intentionally small extensions to the existing protocol object. No database migration or sync protocol change is required because both values map to existing transaction fields.

### TransactionFormScreen Source Handling

The form now stores source values according to entry origin:

- `manual`
- `quick_action`
- `voice`
- `conversation`
- `auto_draft`
- `ocr_screenshot`
- `share_receive`
- `deep_link`

Edit mode preserves the existing transaction source when available.

Category prefills resolve exact keys first, then use parent plus leaf-name matching as a display-name fallback. This avoids choosing the wrong duplicate category name when parser output is name-based.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync logic changes.
- Existing `AddTransactionScreen` calculator flow is unchanged.
- Existing quick action direct/confirm/edit execution is unchanged.

## Deferred Items

Still intentionally deferred to later slices:

- Native widget/AppIntent bridge.
- Android/iOS system share receiver.
- Voice flow migration out of calculator mode.
- AutoDraft batch-confirm migration to `TransactionFormScreen`.
- Full object-level sharing tables/RLS.
- True `JiveQuickAction` persistent collection.

## Verification

Commands run:

```bash
flutter analyze --no-fatal-infos
flutter test test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart test/speech_intent_parser_test.dart
```

Results:

- `flutter analyze --no-fatal-infos`: passed with existing info-level lints only.
- Targeted MoneyThings/transaction/category/speech parser regression tests: passed.

## Manual Smoke Checklist

Recommended before merge:

- Open screenshot import, recognize a payment screenshot, confirm it opens the transaction editor with amount/date/note prefilled and account/category highlighted.
- Save the screenshot-derived transaction and confirm detail page shows source/raw text as expected.
- Open conversational bookkeeping, parse a sentence, tap confirm on one parsed item, and confirm it opens the transaction editor.
- Try a parsed category such as `餐饮 / 午餐` and confirm the editor resolves it when matching categories exist.
- Use batch confirmation with two parsed items and confirm it walks through unsaved items one by one.
