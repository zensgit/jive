# MoneyThings Quick Action Drag Ordering Development & Verification

Date: 2026-05-05
Branch: `codex/moneythings-quick-action-dnd`
Base: `origin/codex/moneythings-quick-action-management`
PR: `#223`

## Summary

This stacked slice finishes the low-risk quick action management follow-up from the MoneyThings TODO: drag-and-drop ordering and a broader icon catalog.

The scope stays inside the local quick action presentation layer. Template-backed quick actions keep stable IDs such as `template:<id>`, execution still goes through `QuickActionExecutor`, and transaction saving behavior is unchanged.

## Development

Updated:

- `lib/core/service/quick_action_store_service.dart`
- `lib/feature/template/template_list_screen.dart`
- `test/quick_action_store_service_test.dart`
- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/2026-05-05-moneythings-quick-action-management-dev-verify.md`
- `docs/moneythings-entry-system-user-guide.md`

Added:

- `docs/2026-05-05-moneythings-quick-action-dnd-dev-verify.md`

## Design

### Drag Ordering

`TemplateListScreen` now renders the visible and hidden quick action sections with `ReorderableListView.builder`.

Each card keeps its existing tap and long-press behavior. The drag affordance is isolated to the right-side handle, so normal One Touch execution remains a simple tap.

### Store API

`QuickActionStoreService.reorderActions(...)` accepts an ordered stable ID list plus an optional `showOnHome` scope.

The method:

- syncs template-backed actions before reading records
- only reorders the requested visible or hidden section when `showOnHome` is provided
- ignores stale stable IDs
- appends remaining scoped records so partial reorder payloads do not drop actions
- preserves `showOnHome`, template links, and usage metadata

### Icon Catalog

The style picker now reuses `categoryIconEntries` and `CategoryService.getIcon(...)`, then adds quick-action-specific choices such as credit card, transfer, and payment.

This keeps category, template, and One Touch visual language aligned without adding a new icon source or data migration.

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
/Users/chauhua/development/flutter/bin/dart format lib/core/service/quick_action_store_service.dart lib/feature/template/template_list_screen.dart test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart
```

Results:

- `quick_action_store_service_test`: passed, 11 tests.
- MoneyThings entry regression bundle: passed, 39 tests.
- `flutter analyze --no-fatal-infos`: passed with existing info-level findings only.

## Manual QA Checklist

- Open the quick action management page.
- Drag visible actions by the right-side handle and confirm order persists after reload.
- Drag hidden actions by the right-side handle and confirm they remain hidden.
- Set an action icon to a category-library icon such as movie or travel and confirm it persists.
- Tap a reordered quick action and confirm direct/confirm/edit behavior is unchanged.
- Hide or show an action and confirm drag ordering only affects the current section.

## Follow-Up

- Cross-device quick action sync and conflict handling remain deferred.
- A cloud-backed independent quick action source replacing template compatibility persistence remains deferred.
- Custom user-uploaded quick action icon packs remain deferred.
