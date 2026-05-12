# MoneyThings Shared Transaction Hint Dev Verify

## Summary

This slice adds a first-stage object-sharing hint to the structured transaction editor. When a transaction is created or edited inside a shared scene/book, the editor shows a non-blocking banner explaining that saving or changing the transaction is visible to shared members.

## Implementation

- Added `ObjectSharePolicyService.transactionPolicy(...)` for transaction-specific shared-scene copy.
- Added `TransactionShareHintBanner` as a small reusable widget.
- Connected `TransactionFormScreen` to resolve the target book from `prefillBookId` or the editing transaction `bookId`.
- The hint is display-only and does not change transaction save behavior.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not add object-level RLS, sharing tables, or new permission truth.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/object_share_policy_service.dart lib/feature/transactions/transaction_form_screen.dart lib/feature/transactions/widgets/transaction_share_hint_banner.dart test/transaction_share_hint_banner_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/object_share_policy_service.dart lib/feature/transactions/transaction_form_screen.dart lib/feature/transactions/widgets/transaction_share_hint_banner.dart test/transaction_share_hint_banner_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_share_hint_banner_test.dart`
- `git diff --check`
- Restricted path check: no changes under `supabase/migrations`, `lib/core/sync`, `.github/workflows`, or SaaS payment/sync/entitlement runtime files.

## Results

- Format passed.
- Targeted analyze passed.
- Shared transaction hint widget tests passed.
- Diff whitespace check passed.
- Restricted path check passed.

## Manual Smoke Suggestion

- Open a structured transaction entry with a shared book prefilled.
- Confirm the banner says the transaction is visible to shared members.
- Save the transaction and confirm the original save semantics are unchanged.
