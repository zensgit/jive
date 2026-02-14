# 2026-02-14 参考 yimu 6.2.5：不计入预算（账单维度）

本次阅读参考代码：`references/yimu_apk_6_2_5_jadx/`，其中在新增账单与筛选里存在“预算计入/排除”能力：

- 新增账单：`不计入预算`
- 搜索/筛选：`不计入预算` / `仅计入预算`

为了让预算统计更贴近真实使用场景（例如：报销/代付/临时垫付不希望占用预算），本次先落地最小闭环：

1. **账单可标记为“不计入预算”**
2. **预算统计会忽略这些账单**

## 实现内容

### 1) 数据模型

在交易模型新增字段：

- `lib/core/database/transaction_model.dart`
  - `bool excludeFromBudget = false;`

说明：

- 默认 `false`（计入预算）
- 目前仅对 `type == expense` 的交易生效（收入/转账不参与预算统计）

### 2) 预算统计忽略

- `lib/core/service/budget_service.dart`
  - 预算使用计算的交易查询增加过滤：`excludeFromBudget == false`

### 3) 记账 UI：不计入预算开关

- `lib/feature/transactions/add_transaction_screen.dart`
  - 在“支出”类型下，新增 `FilterChip`：`不计入预算`
  - 编辑已有账单时会回显
  - 切换到“收入/转账”会自动重置为 `false`

## 验证

自动化测试已覆盖：

- `test/budget_service_test.dart`
  - `excludeFromBudget=true` 的支出不会计入预算已用金额

建议手工验证：

1. 新建一笔支出，勾选 `不计入预算`
2. 打开 `预算管理`，确认该笔支出不影响预算已用金额

## 后续可继续完善（对照 yimu）

- 交易筛选里增加“预算计入条件”：`不计入预算` / `仅计入预算`
- 分类层级“分类不计入预算”（预算排除分类）
- 预算设置页补齐解释与入口（如 yimu 的“预算设置/预算说明/预算排除”）

