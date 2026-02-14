# yimu 参考：预算结转 + 月度预算自动复制 + 总预算口径（effectiveAmount）

## 目标
补齐预算在“跨周期”场景下的关键体验：
- 支持月度预算在进入新月份时自动复制上月配置（名称/分类/金额/预警）
- 支持结转（不结转 / 结转正余额 / 结转正负余额）
- 统一预算展示口径：以 `effectiveAmount`（预算有效金额）作为展示与计算基准

## 1) effectiveAmount（预算有效金额）
### 单个预算（总预算/分类预算）
新增字段：
- `JiveBudget.carryoverAmount`：结转调整（可正可负）

计算规则：
- `effectiveAmount = max(0, budget.amount + budget.carryoverAmount)`

说明：
- `budget.amount` 仍是“本期基础预算金额”
- `carryoverAmount` 由“自动复制 + 结转规则”写入，用于本期有效预算的加减调整

### 总预算的 yimu 口径修正（有分类预算时）
当“同一周期 + 同一币种”下存在分类预算时：
- 计算分类预算总和 `categoryBudgetSum`
- 若同一父分类存在父预算，则其子预算视为“子分配”，不叠加进总和（避免重复计入）

总预算有效金额：
- `effectiveAmount = max(totalBudgetEffectiveDirectAmount, categoryBudgetSum)`

总预算是否只统计“已预算分类”的交易：
- 当 `categoryBudgetSum > 0` 且 `totalBudgetEffectiveDirectAmount <= categoryBudgetSum` 时：
  - 认为“总预算由分类预算推导”
  - 总预算仅统计“有预算的分类/子分类”的交易（避免非预算分类干扰总预算）

## 2) 月度预算自动复制（进入新月份）
偏好：
- `budget_monthly_auto_copy_enabled`（默认 true）

触发时机：
- 进入 `预算管理` 页面加载数据时（`BudgetListScreen`）

复制规则：
- 仅复制 `period == monthly` 的预算
- 若本月已存在同一 `(currency + categoryKey)` 的预算，则跳过（避免重复）
- 复制字段：
  - name / amount / currency / categoryKey / alertEnabled / alertThreshold / period

## 3) 结转规则（Copy 时写入 carryoverAmount）
偏好（组合限制：负结转开启时，会自动开启正结转）：
- `budget_carryover_add_enabled`
- `budget_carryover_reduce_enabled`

结转计算：
- `remaining = prevSummary.remainingAmount`
- 若 `remaining > 0` 且开启“结转正余额”：`carryoverAmount = remaining`
- 若 `remaining < 0` 且开启“结转负余额”：`carryoverAmount = remaining`
- 否则：`carryoverAmount = 0`

## UI 改动
- 预算列表卡片与详情展示使用 `summary.effectiveAmount`
- 预算详情在 `carryoverAmount != 0` 时展示“结转调整”
- `预算设置` 新增「周期与结转」分组：
  - 每月自动复制预算
  - 结转正余额
  - 结转负余额

## 代码位置
- 模型：`app/lib/core/database/budget_model.dart`
- Isar 生成：`app/lib/core/database/budget_model.g.dart`
- 预算统计/总预算口径/自动复制：`app/lib/core/service/budget_service.dart`
- 偏好存储：`app/lib/core/service/budget_pref_service.dart`
- 预算列表/详情展示：`app/lib/feature/budget/budget_list_screen.dart`
- 预算设置页：`app/lib/feature/budget/budget_settings_screen.dart`
- 保存支出提示（超支金额口径修正）：`app/lib/feature/transactions/add_transaction_screen.dart`
- 单测：`app/test/budget_service_test.dart`

## 验证
自动化：
- `flutter analyze`
- `flutter test test/budget_service_test.dart`

手动（手机）：
1. 设置 → 预算设置 → 打开「每月自动复制预算」与结转开关
2. 准备“上月月度预算 + 交易”场景（或用测试数据注入）
3. 进入新月份后打开「预算管理」：
   - 若本月预算缺失，应自动出现复制的预算
   - 在预算详情中查看“预算金额/结转调整/有效预算”展示是否符合预期

