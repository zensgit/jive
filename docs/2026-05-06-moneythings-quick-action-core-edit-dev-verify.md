# MoneyThings Quick Action Core Edit Dev/Verify

## Summary

This slice continues the MoneyThings One Touch management work after add-entry quick action save. It adds a low-risk core-field editing path to quick action management so users can refine reusable actions without recreating them.

The implementation remains template-compatible: template-backed quick actions update both the `JiveQuickAction` shadow record and the legacy `JiveTemplate`, so existing deep links and One Touch execution keep the same stable ids.

## Scope

- Branch: `codex/moneythings-quick-action-core-edit`
- Base: `codex/moneythings-add-entry-save-action`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-quick-action-core-edit`
- PR: pending

## Product Behavior

- Long-press a quick action and choose `编辑内容`.
- The edit sheet can update name, transaction type, default amount, account, transfer target, category, and note.
- Clearing default amount turns a complete expense/income action into light-confirm mode when account and category remain present.
- Transfer quick actions still resolve to editor mode for safety.
- Category selection uses `CategoryPathService.visiblePaths`, so three-level category leaves are written back as top-level plus leaf keys.
- Template-backed actions keep the same `template:<id>` stable id after editing.

## Implementation Notes

- Added `QuickActionStoreService.updateCoreFields`.
- `updateCoreFields` updates the active quick action record and mirrors compatible fields back to the legacy template.
- Mode is inferred from edited core fields, matching existing One Touch rules:
  - complete expense/income + amount = `direct`
  - complete expense/income without amount = `confirm`
  - transfer or incomplete action = `edit`
- The management page edit sheet loads current accounts and visible category paths from the existing local Isar store.
- No schema or migration changes were introduced.

## Files Changed

- `lib/core/service/quick_action_store_service.dart`
- `lib/feature/template/template_list_screen.dart`
- `test/quick_action_store_service_test.dart`
- `docs/2026-05-06-moneythings-quick-action-core-edit-dev-verify.md`
- `docs/2026-04-26-moneythings-full-todo-dev-verify.md`
- `docs/moneythings-entry-system-user-guide.md`

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement/payment/sync behavior.
- Did not add a destructive data migration.

## Validation

- `dart format lib/core/service/quick_action_store_service.dart lib/feature/template/template_list_screen.dart test/quick_action_store_service_test.dart`
- `flutter test test/quick_action_store_service_test.dart`
- `flutter test test/add_transaction_screen_entry_ux_test.dart test/quick_action_filter_service_test.dart`
- `flutter analyze --no-fatal-infos`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Result

- Quick action store service tests passed.
- Analyze exited `0` with existing info-level warnings only.
- Restricted-path check returned no files.

## Manual Smoke

Not run in this environment. Recommended smoke:

1. Open quick action management.
2. Long-press an action and choose `编辑内容`.
3. Rename it, change amount, choose an account/category, and save.
4. Confirm the card updates and the action still executes.
5. Clear amount and confirm the mode label changes to `轻确认`.

## Follow-Up

- A later UX polish slice can add richer validation copy and a full-screen editor for dense account/category lists.
- Cross-device quick action sync remains deferred until the template compatibility layer is intentionally replaced by a cloud quick action source.
