# MoneyThings Category Hidden Paths Dev Verify

## Summary

This branch continues the MoneyThings three-level category TODO by preserving full category paths when a visible leaf belongs to a hidden parent. The selected transaction category remains the visible leaf, but display/search paths can still show the full hierarchy for context.

- Branch: `codex/moneythings-category-hidden-paths`
- Base: `origin/main`
- PR: TBD
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-category-hidden-paths`

## Implementation

- Updated `CategoryPathService.visiblePaths()` so it filters selectable leaves by `isIncome` and `!isHidden`, but resolves each leaf path against the full category tree.
- Preserved the compatible storage rule:
  - `categoryKey = top-level category`
  - `subCategoryKey = selected leaf`
- Added regression coverage for a hidden top-level parent with visible descendants, e.g. `出行 / 私家车 / 加油`.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not add `tertiaryCategoryKey`.
- Did not force any category migration.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/category_path_service.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name CategoryPathService`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/category_path_service.dart test/moneythings_alignment_services_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Manual Smoke Checklist

- Create or seed a hidden parent category with visible child/leaf descendants.
- Open Add Transaction category search/picker.
- Confirm the visible leaf can be selected.
- Confirm the path displays with its hidden parent context, for example `出行 / 私家车 / 加油`.
