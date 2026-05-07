# MoneyThings Quick Action Edit Validation Dev / Verify

## Summary

This slice continues the MoneyThings One Touch management work by making quick action content editing safer and more explainable.

Before this change, a non-empty invalid amount could be parsed as `null` and accidentally turn a direct quick action into a light-confirm action. The editor now validates amount input inline and previews the execution mode before saving.

## Branch

- Branch: `codex/moneythings-quick-action-edit-validation`
- Base: `codex/moneythings-quick-action-core-edit`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-quick-action-edit-validation`
- PR: #233 (`https://github.com/zensgit/jive/pull/233`)

## Implementation

### Execution Preview Contract

`QuickActionStoreService` now exposes:

- `previewCoreMode(...)` for the same mode inference used when saving core fields.
- `missingCoreFields(...)` for the fields that explain why the result is direct, confirm, or edit.

These helpers keep the UI preview aligned with persistence behavior and are covered by unit tests.

### Quick Action Editor UX

The `编辑内容` sheet now:

- Validates non-empty amount input inline.
- Requires amount values to parse as numbers greater than zero.
- Keeps an empty amount valid, preserving the intentional light-confirm path.
- Shows `保存后模式：直接保存 / 轻确认 / 进编辑器`.
- Shows missing-field hints such as `待补充：金额`.
- Disables the save button while amount input is invalid.
- Uses `AccountGroupService.displayPath(...)` in account pickers so subaccounts are shown as grouped paths, while still saving the concrete account id.

## Guardrails

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement, payment, or sync behavior changes.
- No quick action schema migration.
- No change to the `QuickActionExecutor` save path.

## Validation

Automated checks run locally:

```bash
/Users/chauhua/development/flutter/bin/dart format lib/core/service/quick_action_store_service.dart lib/feature/template/template_list_screen.dart test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/quick_action_store_service.dart lib/feature/template/template_list_screen.dart test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart test/quick_action_filter_service_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
git diff --check
git diff --name-only -- supabase/migrations lib/core/sync .github/workflows
```

Results:

- QuickActionStoreService tests: passed.
- Targeted analyze: passed with no issues.
- Quick action, transaction entry, category picker, and widget regression tests: passed.
- Full `flutter analyze --no-fatal-infos`: passed with existing info-level warnings.
- `git diff --check`: passed.
- Restricted path diff check: empty.

## Manual Smoke

Recommended manual verification:

1. Open quick action management and long-press a direct action.
2. Choose `编辑内容`.
3. Enter an invalid amount such as `abc` and confirm inline error text appears and `保存内容` is disabled.
4. Clear the amount and confirm preview changes to `轻确认`.
5. Switch to transfer and confirm preview changes to `进编辑器`.
6. If accounts use `groupName`, confirm account pickers show grouped paths such as `中国银行 / 活期 / CNY`.
