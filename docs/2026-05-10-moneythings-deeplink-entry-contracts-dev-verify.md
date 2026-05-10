# MoneyThings Deep Link Entry Contracts Dev / Verify

## Summary

This branch adds focused contract coverage for the MoneyThings-inspired external
entry protocol. It verifies that quick action links and transaction links keep
using `QuickActionDeepLinkService -> TransactionEntryParams` instead of silently
saving incomplete transactions.

## Branch

- Branch: `codex/moneythings-deeplink-entry-contracts`
- Base: `origin/main@c521cdcb`
- PR: https://github.com/zensgit/jive/pull/273

## Changes

- Added `test/quick_action_deep_link_entry_contract_test.dart`.
- Covered quick action ids from both query and path forms.
- Covered complete expense deep links with account, book, category, tags, date,
  note, and no missing-field highlights.
- Covered incomplete transfer deep links so they highlight only the missing
  target account, not category.
- Covered incomplete share-receive links so raw text remains visible as note and
  raw text while amount remains highlighted.

## Compatibility

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No production behavior change; this is test-only protocol coverage.

## Validation

- `dart format test/quick_action_deep_link_entry_contract_test.dart`
- `flutter test test/quick_action_deep_link_entry_contract_test.dart`
- `flutter analyze --no-fatal-infos lib/feature/quick_entry/quick_action_deep_link_service.dart lib/feature/transactions/transaction_entry_params.dart test/quick_action_deep_link_entry_contract_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`
