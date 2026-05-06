# MoneyThings Add Entry Save Quick Action Dev/Verify

## Summary

This slice continues the MoneyThings One Touch TODO after quick action search. It lets the high-frequency manual add transaction page expose a low-friction `保存为快速动作` entry once the current transaction has enough information.

The implementation is stacked on `codex/moneythings-quick-action-search` and keeps the existing compatibility storage path: production still persists through `TemplateService.createFromTransaction`, so no migration or SaaS sync/payment/entitlement logic changes are required.

## Scope

- Branch: `codex/moneythings-add-entry-save-action`
- Base: `codex/moneythings-quick-action-search`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-add-entry-save-action`
- PR: pending

## Product Behavior

- Manual add transaction now shows `保存为快速动作` after amount, account, and category are complete.
- The action is hidden for split mode and incomplete entries, avoiding broken One Touch seeds.
- The saved seed resolves calculator expressions before creating the quick action.
- Three-level categories remain compatible: `categoryKey` stores the top-level category and `subCategoryKey` stores the selected leaf.
- Notes, account, transfer target, selected time, book id, and tag keys are copied into the seed transaction.
- Production persistence still uses the existing template-backed quick action compatibility layer.

## Implementation Notes

- Added `resolveAddTransactionQuickActionAmount` and `buildAddTransactionQuickActionSeed` as testable helpers for the add-entry quick action seed contract.
- Added `AddTransactionQuickActionCreator` as a lightweight test seam and future compatibility seam; normal runtime still falls back to `TemplateService`.
- Added `AddTransactionScreenKeys.saveQuickActionButton` so UI tests can keep stable anchors.
- Rendered `QuickActionSuggestBar` below the quick field pills when the current entry is eligible.
- Kept transaction saving behavior, continuous entry behavior, amount calculator behavior, category selection, and existing test anchors unchanged.

## Files Changed

- `lib/feature/transactions/add_transaction_screen.dart`
- `test/add_transaction_screen_entry_ux_test.dart`
- `docs/2026-05-06-moneythings-add-entry-save-action-dev-verify.md`
- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/moneythings-entry-system-user-guide.md`

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement/payment/sync behavior.
- Did not add a destructive data migration.

## Validation

- `dart format lib/feature/transactions/add_transaction_screen.dart test/add_transaction_screen_entry_ux_test.dart`
- `flutter test test/add_transaction_screen_entry_ux_test.dart --plain-name "add transaction entry offers save current state as quick action" --timeout=60s`
- `flutter test test/add_transaction_screen_entry_ux_test.dart --plain-name "quick action seed captures amount category account and note" --timeout=60s`
- `flutter test test/add_transaction_screen_entry_ux_test.dart`
- `flutter test test/quick_action_store_service_test.dart test/moneythings_alignment_services_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart test/quick_action_filter_service_test.dart`
- `flutter analyze --no-fatal-infos`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Result

- All targeted tests passed.
- Analyze exited `0` with existing info-level warnings only.
- Restricted-path check returned no files.

## Manual Smoke

Not run in this environment. Recommended smoke:

1. Open the manual add transaction page.
2. Enter `1+2×3`.
3. Choose a custom category such as `餐饮 / 咖啡`.
4. Add an inline note.
5. Confirm `保存为快速动作` appears.
6. Save as a quick action and verify it appears in quick action management.

## Follow-Up

- Next low-risk TODO slice should enhance quick action management editing of core fields such as amount, category, account, mode, and note.
- Cross-device quick action sync remains deferred until the template compatibility layer is intentionally replaced by a cloud quick action source.
