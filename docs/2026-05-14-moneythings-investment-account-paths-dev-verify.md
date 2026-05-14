# MoneyThings Account Group Paths - Investment

## Summary

This slice extends the MoneyThings-inspired account group display path rollout
to the investment screen. Investment holdings and buy/sell dialogs now show
sub-account context without changing how holdings reference accounts.

## Changes

- Investment account labels now use `AccountGroupService.displayPath(account)`.
- The buy/sell dialog account dropdown shows grouped account paths.
- Holding rows that call the investment account label helper now show the same
  grouped path.
- Added a focused label contract test for grouped accounts and existing fallback
  labels.

## Compatibility

- No migration.
- No sync, payment, entitlement, or workflow changes.
- Investment records still keep their existing concrete `accountId` references.
- Existing fallback labels remain unchanged: `未关联账户` and `账户 #id`.

## Validation

- `dart format lib/feature/investment/investment_screen.dart test/investment_account_path_test.dart`
- `flutter pub get`
- `flutter analyze --no-fatal-infos lib/feature/investment/investment_screen.dart test/investment_account_path_test.dart`
- `flutter test test/investment_account_path_test.dart`
- `git diff --check`
- Restricted path check confirms no changes under:
  `supabase/migrations`, `lib/core/sync`, `.github/workflows`

