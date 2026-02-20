# Jive 预算分析下一步：节奏预测（Pacing Insight）

## 背景
当前预算管理已有「总预算 + 趋势图 + 分类预算」。
下一步目标是补齐“分析层”：让用户在当期中途也能快速判断是否会超支，并给出可执行的日均建议。

## 本次交付
### 1) BudgetService 新增节奏分析模型
- 新增 `BudgetPacingInsight`，统一承载：
  - `totalDays / elapsedDays / remainingDays`
  - `expectedUsedByNow`（按均匀节奏应使用）
  - `paceDelta`（当前比均匀节奏超前/落后）
  - `projectedUsedAmount / projectedRemainingAmount / projectedUsedPercent`
  - `suggestedDailyLimit`
  - `projectedStatus`（normal / warning / exceeded）
- 新增方法：`BudgetService.buildBudgetPacingInsight(summary, referenceDate)`
  - 支持未来周期（`elapsedDays = 0`）
  - 支持已结束周期（`remainingDays = 0`）
  - 复用已有预算预警规则判定预测状态

### 2) 月度预算管理页接入分析卡片
- 在 `预算管理 -> 总预算` 卡片内新增“节奏分析”区块：
  - 预计月末状态（超支 / 预警 / 正常）
  - 进度偏差（相对均匀节奏）
  - 建议日均（按剩余额度与剩余天数）
- 参考日期策略：
  - 未来月份：按“未开始”处理（不错误地算作已过 1 天）
  - 历史月份：按周期末
  - 当前月份：按今天

## 变更文件
- `lib/core/service/budget_service.dart`
- `lib/feature/budget/budget_manager_screen.dart`
- `test/budget_service_test.dart`

## 自动化验证
已执行并通过：
- `flutter analyze --no-fatal-infos`
- `flutter test test/budget_service_test.dart`
- `flutter test`

## 手工验证建议（Android 真机）
1. 打开 `预算管理`，确认总预算卡片出现“节奏分析”区块。
2. 切换到未来月份，确认文案为“周期未开始”，建议日均正常显示。
3. 在当月注入几笔高额支出后返回预算管理，确认提示变为“预计超支/预警”。
4. 切换到历史月份，确认预测按该月最终数据稳定显示。
