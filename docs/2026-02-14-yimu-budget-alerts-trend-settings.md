# yimu 参考：预算提醒 + 趋势图 + 预算设置（保存前提示/趋势图开关/下拉预算排除）

## 目标
在 Jive 已有预算能力基础上，补齐 yimu `BudgetManagerActivity` 的关键体验：
- 保存支出时，若会触发预算预警或超支，在保存前弹窗提示确认（可关闭）
- 预算详情中展示近 14 天支出趋势（每日/累计切换）
- 提供「预算设置」用于统一管理相关偏好（默认开启）

## 1) 保存支出时预算预警/超支提示
### 触发条件
- 仅在 `expense` 且 `excludeFromBudget=false` 时评估
- `BudgetPrefService.getBudgetSaveAlertEnabled()==true` 时启用

### 提示策略（减少打扰）
仅在状态“变差”时提示：
- `normal -> warning/exceeded`
- `warning -> exceeded`

以下情况不提示：
- 预算仍保持 `warning`（例如 85% -> 90%）
- 编辑交易导致预算使用降低（`deltaAmount <= 0`）
- 交易不在预算日期范围内

### 统计口径
- 仍沿用既有口径：
  - 账单维度：`JiveTransaction.excludeFromBudget=true` 不计入预算
  - 分类维度：`JiveCategory.excludeFromBudget=true` **仅对总预算** 生效；分类预算不应用此过滤

### 弹窗交互
- 列出最多 4 个受影响预算（按“超支优先、使用率更高优先”排序）
- 支持勾选「不再提示预算提醒」，会自动关闭该功能开关
- 弹窗内提示可在「设置 → 预算设置」中调整

## 2) 预算详情支出趋势图
### 数据
- `BudgetService.getBudgetDailySpendingTrend(budget, days: 14)`
  - 返回最近 14 天（或预算有效日期内）的每日支出（包含 0）
  - 支持切换「每日」与「累计」两种展示

### UI
- 使用 `fl_chart` 折线图
- 「累计」模式下额外展示「剩余预算」折线（支出累计/剩余预算双线对比）
- 颜色：
  - 分类预算优先使用分类颜色
  - 总预算使用 `JiveTheme.primaryGreen`

### 开关
- `BudgetPrefService.getBudgetTrendChartEnabled()==true` 时显示
- 关闭后，预算详情不显示趋势图区域

## 3) 预算设置
### 入口
- `设置 → 预算 → 预算设置`
- `预算管理` 页 AppBar 的 `设置` 图标

### 开关项（默认均为 true）
- 保存支出时提示预算预警/超支：`budget_save_alert_enabled`
- 预算详情显示支出趋势图：`budget_trend_chart_enabled`
- 预算管理下拉打开预算排除：`budget_pull_to_exclude_enabled`

备注：在“保存支出提示弹窗”中勾选「不再提示预算提醒」会写入 `budget_save_alert_enabled=false`。

## 代码位置
- 偏好存储：`app/lib/core/service/budget_pref_service.dart`
- 预算统计/趋势/影响评估：`app/lib/core/service/budget_service.dart`
- 保存支出前提示：`app/lib/feature/transactions/add_transaction_screen.dart`
- 趋势图 + 下拉预算排除开关：`app/lib/feature/budget/budget_list_screen.dart`
- 预算设置页：`app/lib/feature/budget/budget_settings_screen.dart`
- 设置入口：`app/lib/feature/settings/settings_screen.dart`
- 单测：`app/test/budget_service_test.dart`

## 验证
### 自动化
- `flutter analyze`
- `flutter test`

### 手动（手机）
1. 预算管理 → 点开某预算 → 详情中应看到「支出趋势」及「每日/累计」切换
2. 设置 → 预算设置 → 关闭「预算详情显示支出趋势图」→ 返回预算详情确认趋势图隐藏
3. 新建/编辑支出交易：准备一笔预算接近阈值的场景，再保存一笔支出触发弹窗；勾选「不再提示预算提醒」后再次保存确认不再弹
4. 预算管理下拉打开预算排除：开关开/关分别验证是否还能下拉直接进入「预算排除」
