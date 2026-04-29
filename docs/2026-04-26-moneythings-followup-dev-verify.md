# MoneyThings Alignment Follow-up Development & Verification

Date: 2026-04-26
Branch: `feature/moneythings-followup-todos`
Base: stacked on `feature/moneythings-full-todo` / PR #196

## Summary

This follow-up continues the MoneyThings alignment TODOs with low-risk productization work only. It does not add migrations, does not touch SaaS entitlement/payment/sync, and does not change CI workflows.

Completed in this slice:

- SmartList can now be saved directly from the current transaction list search/filter state.
- Search keyword is preserved when a current view is saved as a SmartList.
- Fixed category/subcategory views are merged into the saved SmartList snapshot, so a category page can be saved even without extra filters.
- Unsupported budget-only filters are not persisted as SmartLists yet, preventing a saved view from restoring different results.
- Scene/book UI now shows first-stage sharing visibility badges.
- Category and tag management now use the active scene/book context when available, and surface inherited shared-scene status plus stronger delete-impact warnings.
- Object sharing deletion-warning behavior is covered by a unit test.

## Development Details

### SmartList Current View Save

- Added a `transaction_save_smart_list_button` action in the transaction list floating toolbar.
- The button is enabled only when the list has a search keyword, supported active filters, or a fixed category/subcategory scope.
- Saving prompts for a view name, captures the current supported filter snapshot, merges fixed category/subcategory scope, and preserves the current search keyword.
- After saving, the snackbar provides a management shortcut into `SmartListScreen` using the captured snapshot and a mounted check.
- `SmartListScreen` now accepts `currentKeyword` so its existing “保存当前筛选” flow does not lose keyword-only views.

Preserved behavior:

- Existing default SmartList restore remains in `CategoryTransactionsScreen`.
- Existing SmartList pin/default/delete behavior remains in `SmartListScreen`.
- No SmartList schema change was introduced.
- Budget inclusion filters remain intentionally excluded from saved SmartLists until the model can restore them losslessly.

### Object Sharing Visibility

- `HomeTopBar` scene switcher shows a sharing badge for shared scenes.
- `BookManagerScreen` shows the same sharing badge in the scene/book list.
- `CategoryManagerScreen` accepts `currentBookId`, falls back to the default book, and shows inherited shared-scene badges on category cards and compact category chips.
- `TagManagementScreen` accepts `currentBookId`, falls back to the default book, and shows compact shared badges on tag chips.

Preserved boundary:

- `ObjectSharePolicyService` remains a UI policy layer only.
- Actual permissions still come from the existing shared ledger/book role model.
- No object-level RLS, migration, or second permission truth was added.

### Delete Risk Copy

- Category delete confirmation now includes `ObjectSharePolicyService.deletionWarning(...)`.
- Tag delete confirmation now includes the same policy warning.
- Shared-scene copy names the shared-member scope, so users understand the impact before deleting categories/tags used in shared contexts.

## Deferred Items

Still intentionally deferred for later TODO slices:

- Widget/AppIntent native action bridge.
- Screenshot import route migration to `TransactionEntryParams`.
- Voice/share external entry unification into `TransactionFormScreen`.
- Full object-level sharing tables/RLS.
- `parentAccountKey` migration for true parent-child accounts.
- Separate `JiveQuickAction` persistent collection.

## Verification

Commands run:

```bash
flutter analyze --no-fatal-infos
flutter test test/moneythings_alignment_services_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart test/transaction_entry_widget_regression_test.dart
```

Results:

- `flutter analyze --no-fatal-infos`: passed with existing info-level lints only.
- Targeted MoneyThings/transaction/category regression tests: passed.

Known residual risk:

- Manual device smoke was not run in this slice.
- `TagManagementScreen` was formatted by `dart format`, so the diff is larger than the functional change. Functional changes are limited to book-context loading, share badge display, and deletion-warning copy.

## Manual Smoke Checklist

Recommended before merging:

- Open transaction list, search or apply a filter, tap the bookmark button, save a view, then reopen it from “我的视图”.
- Open a category/subcategory transaction page without extra filters, save it as a SmartList, then reopen it and confirm the category scope is preserved.
- Long-press the saved SmartList and set it as default; reopen transaction list and confirm it restores.
- In a shared scene, open scene switcher and book manager; confirm sharing badge is visible.
- In a shared scene, open category and tag management; confirm inherited sharing badge is visible.
- Delete a non-system category/tag in a test database and confirm the warning mentions impact scope.
