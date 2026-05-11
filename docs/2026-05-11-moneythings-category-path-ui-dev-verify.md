# MoneyThings 三层分类选择接入开发与验证

日期：2026-05-11

## 目标

继续执行 MoneyThings 借鉴 TODO 中“三层分类体验完成”的低风险部分：在不新增字段、不做 migration、不改变交易保存语义的前提下，让通用分类网格选择器能够展示并选择三层分类路径。

## 改动

- `CategoryGridPicker` 从只展示一级/二级，升级为展示所选大类下的全部可见后代分类。
- 三层叶子分类显示为“中类 / 小类”，并补充“属于大类”的辅助说明，避免用户只看到孤立叶子。
- 选择任意层级时统一走 `CategoryPathService.toTransactionKeys()`：
  - 顶层分类：`categoryKey = 顶层`，`subCategoryKey = null`
  - 中层分类：`categoryKey = 顶层`，`subCategoryKey = 中层`
  - 小类叶子：`categoryKey = 顶层`，`subCategoryKey = 叶子`
- 保留旧两层分类显示与选择行为。

## 未做

- 未新增 `tertiaryCategoryKey`。
- 未修改 `supabase/migrations`。
- 未修改 `lib/core/sync`、SaaS entitlement/payment/sync、`.github/workflows`。
- 未强制迁移旧分类。

## 验证

- `dart format lib/core/design_system/category_grid_picker.dart test/category_grid_picker_three_level_test.dart`
- `flutter analyze --no-fatal-infos lib/core/design_system/category_grid_picker.dart test/category_grid_picker_three_level_test.dart`
- `flutter test test/category_grid_picker_three_level_test.dart`
- `git diff --check`
- 受限目录检查：确认未修改 `supabase/migrations`、`lib/core/sync`、`.github/workflows`

## 结果

- 定向 analyze 通过。
- 三层分类 picker widget tests 通过。
- 首次并发执行 test/analyze 时 Flutter Windows plugin symlink 发生一次 `PathExistsException`，改为串行重跑后通过；这是同一 worktree 内 Flutter 命令并发竞争，不是代码失败。

## 后续

- 分类管理页“创建第三层分类”的编辑入口可作为下一支独立 PR 推进。
- 统计、筛选、导入导出已由 `CategoryPathService` 作为统一解析器承接，后续只需补更多场景测试。
