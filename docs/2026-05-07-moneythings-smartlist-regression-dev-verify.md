# MoneyThings SmartList Regression Dev Verify

## Summary

This branch continues the MoneyThings TODO closure by locking the existing SmartList default-view and saved-filter contract with focused service tests. It does not change SmartList product behavior; it makes the current behavior safer to evolve.

- Branch: `codex/moneythings-smartlist-regression`
- Base: `origin/main`
- PR: https://github.com/zensgit/jive/pull/256
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-smartlist-regression`

## Implementation

- Added `test/smart_list_service_regression_test.dart`.
- Covered default SmartList persistence through `SharedPreferences`.
- Covered default-view cleanup when the saved view is deleted.
- Covered `getAll()` ordering: pinned views first, then `sortOrder`.
- Covered `fromFilterState()` snapshot behavior for category, tag, account, book, transaction type, amount floor, keyword, and custom date range.
- Covered `buildFilterState()` restoration behavior, including first-value selection for comma-separated category/tag fields.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not introduce SmartList schema changes.
- Did not introduce scene or object-level sharing migrations.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format test/smart_list_service_regression_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/smart_list_service_regression_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos test/smart_list_service_regression_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Manual Smoke Checklist

- Save a filtered transaction-list view as SmartList.
- Set it as default from SmartList management.
- Reopen the transaction list and confirm the default view restores.
- Delete the default SmartList and confirm no stale default view is applied.
