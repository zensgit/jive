# MoneyThings SmartList Regression Tests Dev Verify

## Summary

This branch adds service-level regression coverage for the MoneyThings-inspired SmartList saved-view contract. It is intentionally test-only for product code: SmartList behavior remains unchanged.

- Branch: `codex/moneythings-smartlist-regression-tests`
- Base: `origin/main`
- PR: #248
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-smartlist-regression-tests`

## Implementation

- Added `test/smart_list_service_test.dart`.
- Covered `SmartListService.fromFilterState` and `buildFilterState` round-trip behavior.
- Covered `describeSummary` for category, tag, type, amount, custom date, and keyword labels.
- Covered `getAll` ordering: pinned views first, then `sortOrder`.
- Covered `getPinned` filtering and sorting.
- Covered `setDefaultView`, `getDefaultView`, and `delete` clearing the default-view preference.

## Guardrails

- Did not modify product SmartList code.
- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not change transaction filter persistence semantics.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format test/smart_list_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/smart_list_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos test/smart_list_service_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Notes

- Manual device smoke was not run because this branch is service-test-only.

## Manual Smoke Checklist

- Save a SmartList from the transaction list filters.
- Pin the SmartList and confirm it appears before non-pinned views.
- Set the SmartList as default and reopen the transaction list.
- Delete the default SmartList and confirm no default view remains selected.
