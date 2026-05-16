# MoneyThings Account Group Collapse Dev / Verify

## Summary

This slice continues the MoneyThings account-group TODO by making the existing account group view usable as a collapsible subaccount surface.

It stays within the first-stage account-group strategy:

- Each child account remains a normal `JiveAccount`.
- Transactions still save to the concrete `accountId`.
- `groupName` only affects presentation, grouped summaries, and local UI preference.
- No migration, sync, payment, entitlement, or workflow files are changed.

## Branch

- Branch: `codex/moneythings-account-group-collapse`
- Base: `codex/moneythings-quick-action-core-edit`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-account-group-collapse`
- PR: #232 (`https://github.com/zensgit/jive/pull/232`)

## Implementation

### Account Group State Helpers

`AccountGroupService` now owns small, testable helpers for account group collapse state:

- `collapseKey(...)` builds a stable key from section scope plus group name.
- `isCollapsed(...)` checks whether a group is currently collapsed.
- `toggledCollapsedKeys(...)` returns the next set without mutating the input set.

The UI passes a scope shaped like `book:<book-id-or-key>::<section-title>`, so the same account group name in another book or broad section does not accidentally reuse the same collapse preference.

### Assets Page UX

`AccountsScreen` now:

- Loads collapsed account group keys from `SharedPreferences`.
- Lets users tap a multi-account group header to collapse or expand it.
- Persists the collapsed keys back to `SharedPreferences`.
- Shows an arrow icon and `已折叠` copy when a group is collapsed.
- Keeps a group-level balance summary visible while collapsed.
- Shows single-account groups exactly as before.

The balance summary uses the group's native currency when all child accounts share one currency. Mixed-currency groups show an approximate total in the current base currency using existing converted balances when available.

## Guardrails

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement, payment, or sync behavior changes.
- No `parentAccountKey` or transaction model migration.
- No change to transaction save semantics.

## Validation

Automated checks run locally:

```bash
/Users/chauhua/development/flutter/bin/dart format lib/core/service/account_group_service.dart lib/feature/accounts/accounts_screen.dart test/moneythings_alignment_services_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name AccountGroupService
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/account_group_service.dart lib/feature/accounts/accounts_screen.dart test/moneythings_alignment_services_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
git diff --check
git diff --name-only -- supabase/migrations lib/core/sync .github/workflows
```

Results:

- AccountGroupService targeted tests: passed.
- Targeted analyze: passed with no issues.
- MoneyThings alignment service tests: passed.
- Transaction/category/widget regression tests: passed.
- Full `flutter analyze --no-fatal-infos`: passed with existing info-level warnings.
- `git diff --check`: passed.
- Restricted path diff check: empty.

## Manual Smoke

Recommended manual verification:

1. Create two accounts with the same meaningful `groupName`, such as `中国银行 / 活期 CNY` and `中国银行 / 定期 USD`.
2. Open the Assets page and confirm `中国银行` appears as a group card.
3. Tap the group header and confirm child accounts hide while the group summary remains visible.
4. Reopen the page and confirm the collapsed state is restored.
5. Expand the group and edit a child account, confirming transactions still point to the child account.

## Next Suggested Slice

The next low-risk MoneyThings TODO should improve Quick Action core editing with inline amount validation and execution-mode preview, so users do not accidentally turn a direct action into a light-confirm action by entering an invalid amount.
