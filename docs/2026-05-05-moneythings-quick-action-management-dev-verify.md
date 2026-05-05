# MoneyThings Quick Action Management Development & Verification

Date: 2026-05-05
Branch: `codex/moneythings-quick-action-management`
Base: `origin/codex/moneythings-quick-action-store`

## Summary

This slice builds on the local `JiveQuickAction` shadow store and turns the old template list into a real quick action management surface.

The scope stays local and non-destructive: existing template-backed quick actions keep stable IDs such as `template:<id>`, execution still goes through `QuickActionExecutor`, and no Supabase migration, sync, workflow, entitlement, or payment code is touched.

## Development

Updated:

- `lib/core/service/quick_action_store_service.dart`
- `lib/core/service/quick_action_service.dart`
- `lib/feature/template/template_list_screen.dart`
- `lib/feature/home/widgets/template_quick_bar.dart`
- `test/quick_action_store_service_test.dart`
- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/2026-05-05-moneythings-quick-action-store-dev-verify.md`
- `docs/moneythings-entry-system-user-guide.md`

Added:

- `docs/2026-05-05-moneythings-quick-action-management-dev-verify.md`

## Design

### Quick Action Management Page

`TemplateListScreen` is now a quick action management page while keeping the existing route/class name for compatibility with home and quick entry navigation.

The page supports:

- visible and hidden sections
- tap to execute through `QuickActionExecutor`
- long press options
- pin/unpin
- show/hide on home and quick entry hub
- icon/color style picker
- manual up/down ordering
- drag-and-drop ordering in the follow-up `codex/moneythings-quick-action-dnd` slice
- delete with template-backed archive semantics

### Store API

`QuickActionStoreService` now exposes management-focused APIs:

- `getRecords({onlyVisible})`
- `updatePresentation(...)`
- `moveAction(...)`
- `deleteAction(...)`

Template-backed records preserve local presentation metadata during `syncFromTemplates()`: icon, color, visibility, pin state, usage count, and last used time.

### Visibility Contract

Home and quick entry hub use `QuickActionService.getActions()`, which returns only `showOnHome == true` records.

The management page uses `QuickActionStoreService.getRecords()`, which returns all active records so hidden actions remain manageable and still resolvable by deep link/shortcuts.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No transaction save behavior changes.
- No object-level sharing permission changes.

## Verification

Commands run:

```bash
/Users/chauhua/development/flutter/bin/dart format lib/core/service/quick_action_store_service.dart lib/core/service/quick_action_service.dart lib/feature/template/template_list_screen.dart lib/feature/home/widgets/template_quick_bar.dart test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart
```

Results:

- `quick_action_store_service_test`: passed, 7 tests.
- MoneyThings entry regression bundle: passed.
- `flutter analyze --no-fatal-infos`: passed with existing info-level findings only.

## Manual QA Checklist

- Open the quick action management page from home quick bar `更多` or quick entry hub.
- Confirm complete actions still execute direct/confirm/edit behavior.
- Hide one action and confirm it disappears from home/quick entry but remains in the hidden section.
- Change icon/color and confirm the card style persists after reload.
- Move an action up/down and confirm ordering persists.
- Delete a template-backed action and confirm it no longer appears in active lists.

## Deferred

- Cross-device quick action sync and conflict handling.
- Cloud-backed independent quick action source replacing template compatibility persistence.
- Custom user-uploaded quick action icon packs.
