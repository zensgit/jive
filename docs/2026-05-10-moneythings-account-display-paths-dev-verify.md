# MoneyThings Account Display Paths Dev Verify

## Summary

This branch continues the MoneyThings account-group TODO by making grouped account display paths less repetitive. It keeps account groups as a view-layer feature: transactions still save to the concrete `JiveAccount.id`, and no parent account migration is introduced.

- Branch: `codex/moneythings-account-display-paths`
- Base: `origin/main`
- PR: https://github.com/zensgit/jive/pull/260
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-account-display-paths`

## Implementation

- Updated `AccountGroupService.displayPath()` to avoid repeating subtype/currency when the account name already contains them.
- Preserved broad legacy group handling: group names such as `资金账户` still do not become MoneyThings-style subaccount groups.
- Added regression coverage for:
  - `中国银行 / 活期 CNY` instead of `中国银行 / 活期 CNY / 活期 CNY`
  - `中国银行 / 定期 / USD` when only currency is missing from the account name

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not add `parentAccountKey`.
- Did not change transaction `accountId` semantics.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/account_group_service.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name AccountGroupService`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/account_group_service.dart test/moneythings_alignment_services_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Manual Smoke Checklist

- Create grouped accounts such as `中国银行 / 活期 CNY / 定期 USD`.
- Open the accounts screen and confirm child account subtitles do not repeat subtype/currency.
- Create a transaction with a grouped child account and confirm it still saves to the child account.
