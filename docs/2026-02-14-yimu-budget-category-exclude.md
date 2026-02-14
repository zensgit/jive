# yimu 参考：预算排除（分类维度）

## 背景
在 `references/yimu_apk_6_2_5_jadx` 中，yimu 提供了 **预算排除**（`BudgetHideActivity`）能力：允许把某些一级/二级分类加入“预算排除”列表，使这些分类的支出不参与预算统计。

Jive 之前已支持 **账单维度**的“不计入预算”（`JiveTransaction.excludeFromBudget`）。
本次在此基础上补齐 **分类维度**的“预算排除”。

## 本次实现
### 1) 分类新增字段：不计入预算
- `JiveCategory.excludeFromBudget: bool`（默认 `false`）
- 对系统分类额外提供覆盖字段，避免系统分类迁移/重建导致设置丢失：
  - `JiveCategoryOverride.excludeFromBudgetOverride: bool?`

### 2) 分类编辑页提供开关
入口：`分类管理 -> 编辑分类`

- 支出分类新增开关：`不计入预算`
- 语义：
  - 一级分类：该一级分类及其子类相关支出将不计入总预算
  - 二级分类：该二级分类相关支出将不计入总预算

### 3) 预算统计逻辑支持分类排除
仅对 **总预算（`budget.categoryKey == null`）** 生效：
- 先按“支出 + 时间区间 + 账单不计入预算=false”取交易
- 再基于 `excludeFromBudget=true` 的分类集合，过滤掉：
  - `tx.categoryKey` 在排除集合中的交易
  - `tx.subCategoryKey` 在排除集合中的交易

备注：分类预算（`budget.categoryKey != null`）当前不应用此过滤，避免未来支持分类预算后出现“预算本身选了某分类但统计为 0”的意外体验。

### 4) 备份/恢复支持
`DataBackupService` 已包含新字段的导入导出，避免用户导出/导入后丢失设置。

## 与“账单维度不计入预算”的关系
预算统计会同时满足两条规则：
- `JiveTransaction.excludeFromBudget == true` 的账单不计入预算
- 所属分类（`categoryKey/subCategoryKey`）被标记 `excludeFromBudget == true` 的账单不计入预算

## 验证点（单测）
新增用例覆盖：
1. 一级分类被排除后，该分类下的交易不计入总预算
2. 仅二级分类被排除时，只排除该二级分类的交易，父级下其它二级分类仍计入

## 相关代码位置
- 分类模型：`app/lib/core/database/category_model.dart`
- 分类覆盖与应用逻辑：`app/lib/core/service/category_service.dart`
- 分类编辑页开关：`app/lib/feature/category/category_edit_dialog.dart`
- 预算统计过滤：`app/lib/core/service/budget_service.dart`
- 备份恢复：`app/lib/core/service/data_backup_service.dart`
- 单测：`app/test/budget_service_test.dart`

