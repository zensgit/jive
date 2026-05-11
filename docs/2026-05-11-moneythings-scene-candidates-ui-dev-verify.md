# MoneyThings Scene Candidates UI Dev Verify

Date: 2026-05-11

## Summary

This slice connects `SceneCandidateService` to the high-frequency transaction entry UI without changing transaction persistence semantics.

The entry screen now uses the current scene/book context to order category and account candidates:

- Scene template category keys are promoted in the parent category row.
- Current book accounts are promoted before default-book accounts.
- Default-book accounts remain available as fallback.
- Existing transaction saving still writes concrete `accountId`, `categoryKey`, and `subCategoryKey`.

## Design

- `AddTransactionScreen` loads books before accounts so account candidate ordering can see the active book.
- `SceneCandidateService.categoryCandidates(...)` is used to order parent category candidates when the active book name matches a scene template, such as `旅行出差`.
- `SceneCandidateService.accountCandidates(...)` is used to order account candidates by current book, then default-book fallback.
- Non-matching accounts are appended after scene/default candidates to preserve existing picker reachability.
- Switching books refreshes account and category candidates while preserving selected keys when possible.
- Test-only `initialCurrentBook` lets widget tests verify the UI contract without forcing production route changes.

## Files

- `lib/feature/transactions/add_transaction_screen.dart`
- `test/add_transaction_screen_entry_ux_test.dart`

## Validation

- `dart format lib/feature/transactions/add_transaction_screen.dart test/add_transaction_screen_entry_ux_test.dart`
- `flutter analyze --no-fatal-infos lib/feature/transactions/add_transaction_screen.dart test/add_transaction_screen_entry_ux_test.dart`
- `flutter test test/add_transaction_screen_entry_ux_test.dart --name "scene"`
- `flutter test test/add_transaction_screen_entry_ux_test.dart`
- `git diff --check`
- Restricted path check: no changes under `supabase/migrations`, `lib/core/sync`, `.github/workflows`, SaaS payment/subscription/webhook paths.

All commands above passed locally.

## Notes

- No database migration was added.
- No SaaS entitlement, payment, sync, or workflow logic was changed.
- This is candidate ordering only; save semantics remain unchanged.
