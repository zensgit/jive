# MoneyThings Quick Action Search Dev / Verify

## Summary

This slice continues the MoneyThings-style One Touch management work on top of `codex/moneythings-quick-action-custom-icons`.

The goal is small and local: make the quick action management page searchable without changing quick action storage, execution, transaction saving, SaaS sync/payment, or migrations.

PR: #227 (`codex/moneythings-quick-action-search`)

## Design

`TemplateListScreen` now includes a search field above the visible/hidden quick action sections.

Search is intentionally read-only:

- It narrows the already loaded `JiveQuickAction` list in memory.
- It preserves the existing store ordering from `QuickActionStoreService.getRecords()`.
- It keeps the same action card keys and tap/long-press behavior.
- It disables drag handles while a search query is active, so filtering never rewrites the user's global One Touch order by accident.
- Clearing search restores the existing drag-and-drop sections.

`QuickActionFilterService` owns matching as pure Dart logic. It searches:

- name and stable id
- source / template label
- category key, subcategory key, category name, subcategory name
- tag keys and default note
- amount aliases such as `15`, `15.00`, `¥15`
- transaction type aliases: expense / income / transfer plus Chinese labels
- mode aliases: direct / confirm / edit plus Chinese labels
- presentation state: home visible, hidden, pinned

Multi-word queries use AND matching. For example, `咖啡 餐饮` only returns actions that match both tokens.

## Files

- `lib/core/service/quick_action_filter_service.dart`
- `lib/feature/template/template_list_screen.dart`
- `test/quick_action_filter_service_test.dart`
- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/moneythings-entry-system-user-guide.md`

## Boundaries

Unchanged:

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No quick action schema/index changes.
- No transaction save behavior changes.

## Validation

Passed locally:

- `/Users/chauhua/development/flutter/bin/flutter pub get`
- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/quick_action_filter_service.dart lib/feature/template/template_list_screen.dart test/quick_action_filter_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/quick_action_filter_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart test/quick_action_icon_render_test.dart test/quick_action_filter_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart test/quick_action_store_service_test.dart test/quick_action_icon_render_test.dart test/quick_action_filter_service_test.dart`

Notes:

- `flutter analyze --no-fatal-infos` passed with existing info-level lint output in unrelated files.
- The regression bundle passed all 47 tests.
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows` returned no changes.

## Manual Smoke

Recommended manual check after installing this build:

- Open `快速动作`.
- Search by name, such as `咖啡`.
- Search by category, such as `餐饮`.
- Search by mode, such as `轻确认` or `编辑器`.
- Search by amount, such as `15`.
- Confirm drag handles disappear while searching.
- Clear search and confirm drag handles return.
- Tap a filtered action and confirm it still follows direct / confirm / edit behavior.
