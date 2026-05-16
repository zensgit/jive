# MoneyThings Widget Quick Action Entry Dev Verify

Date: 2026-05-16

Branch: `codex/moneythings-widget-quick-action`

Base: `origin/main@c9e79ae1`

## Scope

This slice closes the remaining non-migration MoneyThings system-entry TODO for
widgets. The Android Today widget keeps its existing default `+ 记一笔`
behavior, but now supports an optional saved quick-action shortcut.

No migration, Supabase, sync, payment, entitlement, or workflow files were
changed.

## Changes

- Added `HomeWidgetUpdater.setQuickActionShortcut(...)`.
- Persisted optional widget quick-action configuration through
  `SharedPreferences`:
  - `widget_quick_action_id`
  - `widget_quick_action_label`
- Updated `JiveTodayWidget`:
  - If `flutter.widget_quick_action_id` exists, the quick button opens
    `jive://quick-action?id=...`.
  - If it does not exist, the quick button keeps opening
    `jive://transaction/new`.
  - Fallback quick-add links now include `entrySource=deepLink` and the widget
    source label.
- Updated MoneyThings TODO status to mark the widget execution-path item
  complete.

## Behavior

- Configured saved action:

```text
Widget button -> jive://quick-action?id=template:42
  -> QuickActionDeepLinkService
  -> QuickActionService.findActionById
  -> QuickActionExecutor.execute
```

- Default quick-add:

```text
Widget button -> jive://transaction/new?entrySource=deepLink&sourceLabel=来自桌面小组件
  -> QuickActionDeepLinkService
  -> TransactionFormScreen
```

## Verification

Local commands run:

```bash
/Users/chauhua/development/flutter/bin/dart format \
  lib/core/service/home_widget_updater.dart \
  test/widget_data_service_test.dart
git diff --check
/Users/chauhua/development/flutter/bin/flutter test \
  test/widget_data_service_test.dart \
  test/quick_action_deep_link_entry_contract_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Results:

- `dart format`: passed.
- `git diff --check`: passed.
- Restricted path check: passed; no `supabase/migrations`, `lib/core/sync`,
  `.github/workflows`, SaaS payment, SaaS entitlement, or Supabase
  subscription/payment function files were changed.
- Focused Flutter tests: passed, 14 tests.
- `flutter analyze --no-fatal-infos`: passed with existing repo info-level
  analyzer findings.

## Manual Smoke

1. Call `HomeWidgetUpdater.setQuickActionShortcut(actionId: 'template:42', label: '午餐')`.
2. Refresh the Android Today widget.
3. Confirm the widget button label changes to `午餐`.
4. Tap the widget button and confirm Jive opens the matching quick action.
5. Clear the shortcut with `HomeWidgetUpdater.setQuickActionShortcut(actionId: null)`.
6. Confirm the widget button returns to `+ 记一笔` and opens the structured
   transaction editor.
