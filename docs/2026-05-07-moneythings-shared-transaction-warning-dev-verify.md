# MoneyThings Shared Transaction Warning Dev Verify

## Summary

This branch adds the first transaction-level sharing safety prompt inspired by MoneyThings object visibility. When a user manually creates a transaction inside a shared scene/book, Jive asks for confirmation before saving so the user understands other members can see the transaction.

- Branch: `codex/moneythings-shared-transaction-warning`
- Base: `origin/main`
- PR: #251
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-shared-transaction-warning`

## Implementation

- Added a stable `AddTransactionScreenKeys.sharedSceneSaveDialog` test anchor.
- Added a save-time guard in `AddTransactionScreen` for new transactions in shared books.
- The guard treats both `book.isShared == true` and non-empty `book.sharedLedgerKey` as shared-scene signals.
- Canceling the dialog keeps the user on the transaction page and does not call the saver.
- Continuing the dialog preserves the existing save path and keeps `bookId` on the saved transaction.
- Added a test-only `initialBooks` injection path so transaction entry widget tests can validate book/share context without using production services.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not introduce object-level sharing tables, RLS, or a second permission truth.
- Did not change existing transaction persistence semantics beyond the pre-save confirmation gate.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/transactions/add_transaction_screen.dart test/add_transaction_screen_entry_ux_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/add_transaction_screen_entry_ux_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/transactions/add_transaction_screen.dart test/add_transaction_screen_entry_ux_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Manual Smoke Checklist

- Open a local book and create a manual expense; confirm no shared warning appears.
- Open a shared book/scene and create a manual expense; confirm Jive shows `保存到共享场景？`.
- Tap `取消`; confirm no transaction is saved and the entry page stays open.
- Tap `继续保存`; confirm the transaction saves with the shared book selected.
- In split mode, confirm continuing the warning still saves all split rows with the shared `bookId`.
