# MoneyThings SmartList Stale Default Dev Verify

## Summary

This branch continues the MoneyThings SmartList TODO by clearing stale default-view preferences when the saved SmartList record no longer exists. It keeps SmartList storage and filter behavior unchanged while making default-view restore safer.

- Branch: `codex/moneythings-smartlist-stale-default`
- Base: `origin/main`
- PR: TBD
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-smartlist-stale-default`

## Implementation

- Updated `SmartListService.getDefaultView()`:
  - Reads the stored default SmartList id as before.
  - Returns the matching `JiveSmartList` when it exists.
  - Clears `jive.default_smart_list_id` when the stored id points to a deleted/missing SmartList.
- Added `test/smart_list_service_regression_test.dart` covering:
  - Default view restore and delete cleanup.
  - Stale default id cleanup.
  - Pinned-first ordering.
  - Filter snapshot round-trip behavior.
  - First-value restoration for comma-separated category/tag fields.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not change SmartList schema.
- Did not change transaction query semantics.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/smart_list_service.dart test/smart_list_service_regression_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/smart_list_service_regression_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/smart_list_service.dart test/smart_list_service_regression_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Manual Smoke Checklist

- Set a SmartList as default.
- Delete that SmartList.
- Reopen the transaction list and confirm no stale default filter is applied.
- Confirm existing SmartLists still sort with pinned views first.
