# MoneyThings Account Group Paths - Recurring Rules

## Summary

This slice extends the MoneyThings-inspired account group display path rollout
to recurring rule creation and editing. Recurring rules still save concrete
`JiveAccount.id` values; only the account picker labels are more descriptive.

## Changes

- Account and transfer target dropdowns in `RecurringRuleFormScreen` now display
  `AccountGroupService.displayPath(account)`.
- Added a small visible-for-testing label helper so the UI contract can be
  covered without booting the full form and database service.
- Added focused regression tests for custom sub-account groups and broad built-in
  account groups.

## Compatibility

- No migration.
- No sync, payment, entitlement, or workflow changes.
- Recurring rule save semantics are unchanged: rules keep `accountId` and
  `toAccountId`.
- Existing broad groups such as `信用卡账户` keep compact account names.

## Validation

- `dart format lib/feature/recurring/recurring_rule_form_screen.dart test/recurring_rule_form_account_path_test.dart`
- `flutter pub get`
- `flutter analyze --no-fatal-infos lib/feature/recurring/recurring_rule_form_screen.dart test/recurring_rule_form_account_path_test.dart`
- `flutter test test/recurring_rule_form_account_path_test.dart`
- `git diff --check`
- Restricted path check confirms no changes under:
  `supabase/migrations`, `lib/core/sync`, `.github/workflows`

