# MoneyThings Quick Action Store Development & Verification

Date: 2026-05-05
Branch: `codex/moneythings-quick-action-store`
Base: `origin/main@15f43e84`

## Summary

This slice moves Jive's MoneyThings-style One Touch layer from a purely runtime template adapter to a dedicated local `JiveQuickAction` shadow store.

The design remains conservative: existing `JiveTemplate` records are still the compatibility source, old IDs such as `template:42` keep working, and no Supabase migration, SaaS entitlement/payment/sync logic, or workflow file is changed.

## Development

Added:

- `lib/core/database/quick_action_model.dart`
- `lib/core/database/quick_action_model.g.dart`
- `lib/core/service/quick_action_store_service.dart`
- `test/quick_action_store_service_test.dart`
- `docs/2026-05-05-moneythings-quick-action-store-dev-verify.md`

Updated:

- `lib/core/service/database_service.dart`
- `lib/core/service/quick_action_service.dart`
- `lib/feature/home/main_screen.dart`
- `lib/feature/home/widgets/template_quick_bar.dart`
- `lib/feature/quick_entry/quick_entry_hub_sheet.dart`
- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/2026-04-26-moneythings-entry-system-closure-design-verify.md`
- `docs/moneythings-entry-system-user-guide.md`

## Design

### Persistent Quick Action Shadow Store

`JiveQuickAction` is a local Isar collection for MoneyThings-style One Touch actions. Template-backed records use stable IDs like `template:<id>` and record:

- execution mode: `direct / confirm / edit`
- default transaction fields: amount, account, transfer account, category path, note, tags
- home/UI metadata: icon, color, pinned state, sort order, usage count, last used time
- compatibility metadata: `source=template`, `legacyTemplateId`

### Compatibility Rules

- Existing templates are backfilled into `JiveQuickAction` through `QuickActionStoreService.syncFromTemplates()`.
- Removed templates archive their template-backed quick action record instead of hard deleting it.
- `QuickActionService.findActionById()` resolves both persistent IDs and legacy numeric template IDs.
- `QuickActionService.markUsed()` updates both the quick action record and the legacy template when possible.
- `QuickActionService.saveTransaction()` keeps existing transaction save behavior and still records the legacy template ID in `quickActionId`.

### UI Entry Changes

- Home quick bar now loads `QuickActionService.getActions(limit: 5)` instead of sorting templates directly.
- Quick entry hub now uses the same quick action list as the home quick bar.
- Deep links resolve through `QuickActionService.findActionById()` before entering `QuickActionExecutor`.
- Follow-up `codex/moneythings-quick-action-management` adds local management for visibility, pinning, style, ordering, and delete/archive behavior.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No transaction model foreign-key change.
- No object-level sharing permission change.

## Verification

Commands run:

```bash
/Users/chauhua/development/flutter/bin/dart run build_runner build --delete-conflicting-outputs
/Users/chauhua/development/flutter/bin/dart format lib/core/database/quick_action_model.dart lib/core/service/database_service.dart lib/core/service/quick_action_service.dart lib/core/service/quick_action_store_service.dart lib/feature/home/main_screen.dart lib/feature/home/widgets/template_quick_bar.dart lib/feature/quick_entry/quick_entry_hub_sheet.dart test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_store_service_test.dart test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Results:

- `build_runner`: passed, generated `quick_action_model.g.dart`.
- `quick_action_store_service_test`: passed, 5 tests.
- MoneyThings entry regression bundle: passed.
- `flutter analyze --no-fatal-infos`: passed with existing info-level findings only.

## Manual QA Checklist

- Create or keep an existing template such as `早餐 ¥15`.
- Confirm the home quick bar shows it as a quick action.
- Tap it and confirm direct/confirm/edit behavior still follows `QuickActionExecutor`.
- Open `jive://quick-action?id=template:<id>` and confirm the same behavior.
- Delete the template and confirm the quick action no longer appears in the active list.

## Deferred

- Cross-device quick action sync and conflict handling.
- Cross-device quick action presentation sync.
- Richer icon catalog and drag-and-drop ordering.
- Migration from template compatibility source to independent cloud quick action source.
