# MoneyThings Bank Account Group Default Dev Verify

## Summary

This slice connects the existing account-group view layer to account creation. When users create bank asset accounts from bank-backed templates, Jive now defaults `groupName` to the selected bank name, so accounts such as `中国银行 / 活期 / CNY` and `中国银行 / 定期 / USD` naturally appear as one account group.

## Implementation

- Added `AccountService.defaultGroupNameForCreation(...)`.
- Bank-backed asset templates use the selected bank name as the default account group.
- Liability credit cards still stay under the credit account group by default.
- `AccountsScreen` uses the helper when building the new account draft.
- Transactions still save to the concrete child `accountId`.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not add `parentAccountKey` or any account schema migration.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/account_service.dart lib/feature/accounts/accounts_screen.dart test/account_creation_group_name_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/account_service.dart lib/feature/accounts/accounts_screen.dart test/account_creation_group_name_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/account_creation_group_name_test.dart`
- `git diff --check`
- Restricted path check: no changes under `supabase/migrations`, `lib/core/sync`, `.github/workflows`, or SaaS payment/sync/entitlement runtime files.

## Results

- Format passed.
- Targeted analyze passed.
- Account creation group-name tests passed.
- Diff whitespace check passed.
- Restricted path check passed.

## Manual Smoke Suggestion

- Create `中国银行` bank asset accounts using `银行卡活期` and `外币/定期`.
- Open the assets/account screen and confirm they appear as one `中国银行` group.
- Save transactions against each child account and confirm the stored account remains the selected child account.
