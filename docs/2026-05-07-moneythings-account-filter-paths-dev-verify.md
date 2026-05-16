# MoneyThings Account Filter Paths Dev Verify

## Summary

This branch extends the MoneyThings account-group presentation from transaction entry pickers into the shared transaction filter sheet. It keeps account grouping as a view-only layer and does not change transaction account identity or storage.

- Branch: `codex/moneythings-account-filter-paths`
- Base: `codex/moneythings-account-picker-paths`
- PR: #240
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-account-filter-paths`

## Implementation

- `TransactionFilterSheet` now uses `AccountGroupService.displayPath(account)` for account dropdown labels.
- Filter semantics are unchanged: the selected value remains the concrete `JiveAccount.id`.
- Added an `AccountGroupService` regression test for grouped account display paths used by pickers and filters.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not change transaction save/filter identity; account filters still use `accountId`.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/widgets/transaction_filter_sheet.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/widgets/transaction_filter_sheet.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name AccountGroupService`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart test/transaction_entry_widget_regression_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Notes

- Full `flutter analyze --no-fatal-infos` exits successfully with 83 existing info-level findings in unrelated files.
- A first parallel Flutter startup hit a transient Windows plugin symlink `PathExistsException`; the same targeted test was rerun sequentially and passed.
- Manual device smoke was not run in this worktree.

## Manual Smoke Checklist

- Create or use grouped accounts such as `中国银行 / 活期 / CNY`.
- Open a transaction list filter sheet from bills, category transactions, reconciliation, or project detail.
- Confirm the account dropdown shows the grouped account path.
- Select the grouped account and confirm filtering still applies to the concrete child account.
