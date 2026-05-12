# MoneyThings 分类默认二级策略开发与验证

日期：2026-05-12

## 目标

把分类体验固定为“默认二级，三级自选”：普通用户继续看到一级 / 二级分类作为主路径；只有用户主动在二级分类下添加下级分类时，才进入三层路径能力。

## 改动

- `CategoryPathService` 增加默认交互深度契约：
  - `defaultInteractiveDepth = 2`
  - `defaultInteractivePaths(...)` 只返回一级 / 二级路径
  - `optionalExtendedPaths(...)` 返回三级及更深路径
- 分类管理页保留一级下的系统批量添加二级能力。
- 二级分类下添加下级分类时改为单项手动创建：
  - 不展示系统分类批量入口
  - 不自动批量写入三级分类
  - 文案使用“下级分类”，避免误认为三级是默认结构
- 交易录入页已存在三级路径时继续可选展示，但标签改为“可选三级”。

## 保持不变

- 未新增 `tertiaryCategoryKey`。
- 交易仍保持 `categoryKey = 顶层`、`subCategoryKey = 用户选择的叶子分类`。
- 未修改 `supabase/migrations`。
- 未修改 `lib/core/sync`。
- 未修改 SaaS entitlement/payment/sync 逻辑。
- 未修改 `.github/workflows`。

## 验证

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/category_path_service.dart lib/feature/category/category_create_screen.dart lib/feature/category/category_manager_screen.dart lib/feature/transactions/add_transaction_screen.dart test/moneythings_alignment_services_test.dart test/category_create_screen_two_level_default_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/category_path_service.dart lib/feature/category/category_create_screen.dart lib/feature/category/category_manager_screen.dart lib/feature/transactions/add_transaction_screen.dart test/moneythings_alignment_services_test.dart test/category_create_screen_two_level_default_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --name "CategoryPathService"`
- `/Users/chauhua/development/flutter/bin/flutter test test/category_create_screen_two_level_default_test.dart`
- `git diff --check`
- 受限目录检查：确认未修改 `supabase/migrations`、`lib/core/sync`、`.github/workflows`

## 结果

- 定向 analyze 通过。
- `CategoryPathService` 定向测试通过。
- 分类创建页 widget 测试通过。
- `git diff --check` 通过。
- 受限目录检查为空。
- 首次并行启动多个 Flutter 命令时，Windows plugin symlink 发生一次 `PathExistsException`；改为串行重跑后通过，这是 Flutter 工具启动竞争，不是代码失败。

## 手工 smoke 建议

- 打开分类管理，给一级分类“出行”添加子类，应仍可使用系统分类批量添加。
- 长按二级分类“私家车”并选择“添加下级分类”，应只出现手动输入，不出现系统批量添加入口。
- 创建“出行 / 私家车 / 加油”后，记账页搜索/选择该分类时应显示完整路径，并标记为“可选三级”。
