# MoneyThings Account Filter Paths Dev Verify

## Summary

This slice restacks the low-risk account filter path behavior from the old stacked queue directly onto `main`. Transaction filter sheets now show MoneyThings-style account group paths while still filtering by the concrete child `accountId`.

## Implementation

- `TransactionFilterSheet` now labels account dropdown options with `AccountGroupService.displayPath(account)`.
- Added `transactionFilterAccountLabel(...)` as the filter-sheet binding point for tests.
- Added a focused regression test covering:
  - grouped child account label, for example `中国银行 / 活期 / CNY`
  - unchanged concrete account identity
  - broad legacy groups such as `资金账户` remaining plain account names

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement/payment/sync logic.
- Did not change transaction filtering identity; selected values remain concrete `JiveAccount.id`.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/widgets/transaction_filter_sheet.dart test/transaction_filter_sheet_account_path_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/widgets/transaction_filter_sheet.dart lib/core/service/account_group_service.dart test/transaction_filter_sheet_account_path_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_filter_sheet_account_path_test.dart`
- `git diff --check`
- Restricted path check: no changes under `supabase/migrations`, `lib/core/sync`, `.github/workflows`, or SaaS payment/sync/entitlement runtime files.

## Results

- Format passed.
- Targeted analyze passed.
- Account filter label tests passed.
- Diff whitespace check passed.
- Restricted path check passed.

## Manual Smoke Suggestion

- Create grouped accounts such as `中国银行 / 活期 / CNY`.
- Open any transaction filter sheet.
- Confirm the account dropdown shows grouped paths.
- Select a grouped child account and confirm filtering still targets that concrete account.
