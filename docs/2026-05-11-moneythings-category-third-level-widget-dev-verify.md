# MoneyThings Category Third-Level Widget Dev Verify

Date: 2026-05-11

## Summary

This slice adds a widget smoke test for the three-level category creation path in category management.

The smoke covers the user-facing flow:

- Search a second-level category.
- Open its action menu.
- Choose `添加下级分类`.
- Verify the create screen receives the full parent path title: `添加下级分类 · 出行 / 私家车`.
- Verify the create screen input contract uses `下级分类名称`.

## Design

- `CategoryManagerScreenKeys.subCategory(...)` provides a stable widget anchor for category chips.
- `CategoryManagerScreen.initialCategories` and `bootstrapDefaults` are test-only hooks so the widget smoke can run from a deterministic category snapshot instead of waiting on full Isar bootstrap.
- Production behavior remains unchanged: by default the screen still initializes from Isar and bootstraps default categories.
- The existing three-level service test remains the storage/compatibility guard for `categoryKey = top-level` and `subCategoryKey = leaf`.

## Files

- `lib/feature/category/category_manager_screen.dart`
- `test/category_manager_three_level_widget_smoke_test.dart`

## Validation

- `dart format lib/feature/category/category_manager_screen.dart test/category_manager_three_level_widget_smoke_test.dart`
- `flutter test test/category_manager_three_level_widget_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/feature/category/category_manager_screen.dart test/category_manager_three_level_widget_smoke_test.dart`
- `flutter test test/category_service_three_level_create_test.dart`
- `git diff --check`
- Restricted path check: no changes under `supabase/migrations`, `lib/core/sync`, `.github/workflows`, SaaS payment/subscription/webhook paths.

All commands above passed locally.

## Notes

- No migration was added.
- No transaction save model was changed.
- No SaaS entitlement, payment, sync, or workflow logic was changed.
