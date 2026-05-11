# MoneyThings 三层分类创建契约开发与验证

日期：2026-05-11

## 目标

继续收口 MoneyThings TODO 中“三层分类体验完成”的分类管理切片：不新增交易字段、不做 migration，允许用户在已有二级分类下创建下级分类，并确保交易仍按兼容模型保存。

## 改动

- 分类管理页在添加下级分类时显示完整父路径。
  - 一级下新增：`添加子类 · 出行`
  - 二级下新增：`添加下级分类 · 出行 / 私家车`
- 二级下新增时，输入框文案从“子类名称”切换为“下级分类名称”，降低用户理解成本。
- 新增真实 Isar 服务层回归测试，覆盖：
  - 创建“出行 / 私家车 / 加油”三级分类。
  - 叶子分类 `parentKey` 指向中层分类。
  - `CategoryPathService` 仍解析为完整路径。
  - 交易兼容键仍是 `categoryKey = 顶层`、`subCategoryKey = 叶子`。
  - 同一中层下重复三级名称会被拒绝。

## 未做

- 未新增 `tertiaryCategoryKey`。
- 未修改 `supabase/migrations`。
- 未修改 `lib/core/sync`、SaaS entitlement/payment/sync、`.github/workflows`。
- 未强制迁移旧两层分类。

## 验证

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/category/category_manager_screen.dart test/category_service_three_level_create_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/category/category_manager_screen.dart test/category_service_three_level_create_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/category_service_three_level_create_test.dart`
- `git diff --check`
- 受限目录检查：确认未修改 `supabase/migrations`、`lib/core/sync`、`.github/workflows`

## 结果

- 定向 analyze 通过。
- 三层分类创建服务层测试通过。
- 首次并发执行 test/analyze 时 Flutter Windows plugin symlink 发生一次 `PathExistsException`，改为串行重跑后通过；这是同一 worktree 内 Flutter 命令并发竞争，不是代码失败。

## 后续

- 可继续补分类管理 widget smoke，直接覆盖“长按二级分类 -> 添加下级分类”的弹层文案。
- 可继续把三层路径展示补到更多报表/筛选列表，但交易模型仍保持兼容键。
