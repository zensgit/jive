# MoneyThings Account Group Contracts Dev / Verify

## Summary

This branch adds focused contract coverage for the MoneyThings-inspired
account-group/subaccount view layer. It keeps the first-stage approach explicit:
accounts are only grouped for presentation, while each transaction still points
to a concrete `JiveAccount.id`.

## Branch

- Branch: `codex/moneythings-account-group-contracts`
- Base: `origin/main@c521cdcb`
- PR: https://github.com/zensgit/jive/pull/275

## Changes

- Added `test/account_group_service_contract_test.dart`.
- Fixed `AccountGroupService` to treat the legacy broad group name `信用账户`
  like other built-in broad groups, avoiding false subaccount grouping for old
  credit-account data.
- Covered custom `groupName` aggregation without changing account ids.
- Covered ordering, multi-currency `currencies`, and group opening balance
  summaries.
- Covered broad legacy group names such as `资金账户` and `信用账户` so they do
  not become false subaccount groups.
- Covered grouped display paths and archived account filtering.

## Compatibility

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- Production behavior change is limited to account group presentation: legacy
  `信用账户` values no longer create a synthetic account group.

## Validation

- `dart format lib/core/service/account_group_service.dart test/account_group_service_contract_test.dart`
- `flutter test test/account_group_service_contract_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/account_group_service.dart test/account_group_service_contract_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`
