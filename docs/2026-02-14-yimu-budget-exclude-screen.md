# yimu 参考：预算排除管理页（Jive 实现）

## 目标
对齐 yimu 的 `BudgetHideActivity` 交互，让用户能在一个入口集中管理「不计入预算」的分类，而不必逐个进入「编辑分类」。

## 入口
- `预算管理` 顶部新增入口：`预算排除`（图标 `block`）

## 交互
- 页面标题：`预算排除`
- 右上角：`新增`
  - 打开 `选择要排除的分类`
  - 选择一级或二级分类后，立即设置该分类为 `不计入预算`
- 列表展示当前已排除的分类
  - 点击：进入 `编辑分类`（可继续调整图标/颜色/层级/不计入预算开关等）
  - 右侧 `X`：快速取消排除（恢复计入预算）
  - 长按：弹出操作面板（编辑/取消不计入预算）

## 数据与统计规则
该页面只是对 `JiveCategory.excludeFromBudget` 的“集中编辑”：
- 不改变已有的「账单维度不计入预算（JiveTransaction.excludeFromBudget）」能力
- 预算统计规则见：`app/docs/2026-02-14-yimu-budget-category-exclude.md`

## 相关代码位置
- 入口：`app/lib/feature/budget/budget_list_screen.dart`
- 页面实现：`app/lib/feature/budget/budget_exclude_screen.dart`
- 服务方法：`app/lib/core/service/category_service.dart`（`setCategoryExcludeFromBudget`）

