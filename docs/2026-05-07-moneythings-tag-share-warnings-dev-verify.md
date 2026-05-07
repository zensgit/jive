# MoneyThings Tag Share Warnings Dev Verify

## Summary

This branch extends the MoneyThings object-sharing first phase from categories to tags and tag groups. It keeps sharing as a user-facing warning layer and does not add object-level permission truth, RLS, migrations, or sync changes.

- Branch: `codex/moneythings-tag-share-warnings`
- Base: `codex/moneythings-category-share-warnings`
- PR: TBD
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-tag-share-warnings`

## Implementation

- `TagEditDialog` now accepts optional `currentBook` context.
- Editing an existing tag in a shared scene asks for confirmation before saving name, icon, color, or group changes.
- `TagGroupDialog` now accepts optional `currentBook` context.
- Editing an existing tag group in a shared scene asks for confirmation before saving name, icon, or color changes.
- Tag management passes `_currentBook` into tag and tag-group edit sheets.
- Archiving/restoring a tag group in a shared scene asks for confirmation before applying the state change.
- Deleting a tag group now includes shared-scene warning copy and the number of tags that will be moved out of the group.
- `ObjectSharePolicyService` test coverage now includes tag-group inherited sharing warnings.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not introduce object-level sharing tables, RLS, or permission truth.
- New tag creation stays non-blocking; warnings are limited to editing existing shared-scene objects or risky group operations.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/tag/tag_edit_dialog.dart lib/feature/tag/tag_group_dialog.dart lib/feature/tag/tag_management_screen.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name ObjectSharePolicyService`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/tag/tag_edit_dialog.dart lib/feature/tag/tag_group_dialog.dart lib/feature/tag/tag_management_screen.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Notes

- Full `flutter analyze --no-fatal-infos` exits successfully with 83 existing info-level findings in unrelated files.
- A first parallel Flutter startup hit a transient Windows plugin symlink `PathExistsException`; the same targeted test was rerun sequentially and passed.
- Manual device smoke was not run in this worktree.

## Manual Smoke Checklist

- Open a shared scene and edit an existing tag; confirm the shared-tag warning appears before save.
- Edit an existing tag group in a shared scene; confirm the shared-group warning appears before save.
- Archive and restore a shared-scene tag group; confirm the warning explains shared-member impact.
- Delete a tag group with tags in a shared scene; confirm the dialog includes shared-member copy and moved-tag count.
- Repeat a private-scene tag edit and confirm the extra shared warning does not appear.
