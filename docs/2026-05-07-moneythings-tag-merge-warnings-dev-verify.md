# MoneyThings Tag Merge Warnings Dev Verify

## Summary

This low-risk stacked slice closes the shared-scene warning gap for tag merges. A merge still uses the existing `TagService.mergeTags` semantics: source-tag transactions and smart rules are reassigned to the target tag, the source tag is deleted, and no migration/sync/payment behavior changes are introduced.

- Branch: `codex/moneythings-tag-merge-warnings`
- Base: `codex/moneythings-tag-archive-warnings`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-tag-merge-warnings`

## Implementation

- `TagManagementScreen` now asks for a second confirmation only when the current tag context inherits shared-scene visibility.
- The confirmation reuses `ObjectSharePolicyService.evaluate(...).warning` and `ObjectSharePolicyService.deletionWarning(...)` so the copy stays aligned with category/tag archive/delete warnings.
- The dialog explains that merge will move transactions and smart rules to the target tag, then delete the source tag.
- Private-scene tag merges keep the existing immediate behavior after target selection.

## Guardrails

- Did not modify `TagService.mergeTags`.
- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not introduce object-level sharing tables, RLS, or permission truth.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/tag/tag_management_screen.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name ObjectSharePolicyService`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/tag/tag_management_screen.dart test/moneythings_alignment_services_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Notes

- `dart format`: passed, 0 files changed after formatting.
- `flutter test ... --plain-name ObjectSharePolicyService`: passed, 6 tests.
- Targeted `flutter analyze --no-fatal-infos`: passed, no issues found.
- `git diff --check`: passed.
- Restricted directory diff check returned no files.

## Manual Smoke Checklist

- In a shared scene, choose merge for a source tag, pick a target tag, and confirm the second dialog explains shared-member impact, transaction migration, smart-rule migration, and source-tag deletion.
- Cancel the second dialog and confirm no merge occurs.
- Confirm the second dialog and verify transactions/rules move to the target tag through the unchanged service behavior.
- Repeat the same merge in a private scene and confirm no extra shared warning appears after target selection.
