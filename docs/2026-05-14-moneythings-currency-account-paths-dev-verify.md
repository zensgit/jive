# MoneyThings Account Group Paths - Multi-Currency Overview

## Summary

This slice continues the MoneyThings-inspired account group rollout by showing
account group display paths in the multi-currency asset overview. It is a
display-only change: account identity, balances, exchange-rate conversion, and
transaction save semantics are unchanged.

## Changes

- `CurrencyService.calculateMultiCurrencyOverview()` now labels each
  `CurrencyAccountItem` with `AccountGroupService.displayPath(account)`.
- Account groups such as `中国银行 / 活期 / CNY` become visible in currency
  breakdown details, while generic built-in groups such as `信用卡账户` keep the
  original account name.
- Added a focused regression test covering grouped asset accounts and generic
  liability groups.

## Compatibility

- No migration.
- No sync, payment, entitlement, or workflow changes.
- `CurrencyAccountItem.accountId` remains the concrete `JiveAccount.id`.
- Currency totals and conversion logic are unchanged.

## Validation

- `dart format lib/core/service/currency_service.dart test/currency_service_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/currency_service.dart test/currency_service_test.dart`
- `flutter test test/currency_service_test.dart`
- `git diff --check`
- Restricted path check confirms no changes under:
  `supabase/migrations`, `lib/core/sync`, `.github/workflows`

