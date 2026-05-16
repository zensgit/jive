# MoneyThings Form Book Context Dev Verify

## Summary

This branch gives `TransactionFormScreen` the same book/share context discipline as the calculator entry page. Structured entries from share, deep link, voice, quick action, OCR, conversation, and AutoDraft can now preserve the incoming `prefillBookId`, show where the transaction will be saved, and ask before saving into a shared scene.

- Branch: `codex/moneythings-form-book-context`
- Base: `origin/main`
- PR: https://github.com/zensgit/jive/pull/255
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-form-book-context`

## Implementation

- Added test-only `isar` and `transactionSaver` injections to `TransactionFormScreen`, matching the existing low-risk test pattern used by other screens while leaving production persistence unchanged.
- Loaded `JiveBook` context in `TransactionFormScreen` from `prefillBookId` or the edited transaction's `bookId`.
- Added a lightweight book context banner:
  - Local book: `将保存到账本「...」`
  - Shared scene/book: `将保存到共享场景「...」`
- Added a pre-save shared-scene confirmation for new structured-form transactions.
- Canceling the confirmation keeps the form open and saves nothing.
- Continuing preserves the existing form save path and writes the selected `bookId`.
- Added widget regression tests for shared and local book contexts.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not introduce object-level sharing tables, RLS, or a second permission truth.
- Did not force transactions without `prefillBookId` into a default book, preserving existing external-entry semantics.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/transactions/transaction_form_screen.dart test/transaction_form_screen_book_context_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_form_screen_book_context_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/transactions/transaction_form_screen.dart test/transaction_form_screen_book_context_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Manual Smoke Checklist

- Open `jive://transaction/new?amount=15&type=expense&bookId=<localBookId>` and confirm the form shows the local book banner.
- Open `jive://transaction/new?amount=15&type=expense&bookId=<sharedBookId>` and confirm the form shows the shared scene banner.
- Save in a shared scene and confirm `保存到共享场景？` appears before saving.
- Tap `取消` and confirm no transaction is saved.
- Tap `继续保存` and confirm the transaction is saved with the incoming `bookId`.
