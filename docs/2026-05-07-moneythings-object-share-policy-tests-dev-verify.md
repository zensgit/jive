# MoneyThings Object Share Policy Tests Dev Verify

## Summary

This branch adds service-level regression coverage for the MoneyThings-inspired object sharing warning contract. It is intentionally test-only for product code: object sharing remains a visibility and warning layer, not a new permission source.

- Branch: `codex/moneythings-object-share-policy-tests`
- Base: `origin/main`
- PR: TBD
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-sharing-legacy-tests`

## Implementation

- Added `test/object_share_policy_service_test.dart`.
- Covered `book.sharedLedgerKey` detecting an inherited shared scene even when `book.isShared` is false.
- Covered explicitly shared objects receiving the stable `共享` label and shared-member warning.
- Covered a `JiveSharedLedger` instance marking an object as inherited from a shared scene.
- Covered private-object blocking copy only appearing inside shared scenes.
- Covered empty-impact deletion warnings for both shared and local scopes.

## Guardrails

- Did not modify product object sharing code.
- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not add object-level sharing tables, RLS, or a second permission source.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format test/object_share_policy_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/object_share_policy_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos test/object_share_policy_service_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Notes

- Manual device smoke was not run because this branch is service-test-only.

## Manual Smoke Checklist

- Open a shared scene/book and confirm account/category/tag surfaces show inherited sharing copy.
- Try to use a private object in a shared scene transaction and confirm the blocking copy is shown.
- Delete a shared category or tag with no transactions and confirm the candidate-list warning copy is shown.
- Delete a shared category or tag with transactions and confirm the affected transaction count is shown.
