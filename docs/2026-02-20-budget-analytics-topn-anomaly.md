# Jive 预算分析深化（二期）：Top 分类贡献 + 异常支出日提示

## 目标
在已上线的预算节奏分析基础上，补齐两类“可行动洞察”：
- 分类贡献：本期哪几类支出占比最高。
- 异常日提示：明显高于预算节奏/历史均值的支出日。

## 实现内容

### 1) 服务层能力（BudgetService）
新增 `BudgetService` 能力：
- `getBudgetCategoryContributions(...)`
  - 聚合预算周期内支出，输出 TopN 分类贡献（金额 + 占比）。
  - 复用总预算已有口径（预算排除、仅预算分类等）保证一致性。
- `detectBudgetSpendingAnomaliesFromDaily(...)`
  - 基于日级支出识别异常日。
  - 阈值为 `max(日均支出 * 2.0, 日预算 * 1.8, 1)`，避免低金额噪声。

新增数据类型：
- `BudgetCategoryContribution`
- `BudgetSpendingAnomalyDay`

### 2) 月度预算管理页接入（BudgetManagerScreen）
在总预算卡片新增两段信息：
- `分类支出贡献 TopN`
- `异常支出日`

并沿用已有节奏分析区块，形成“三层洞察”：
1. 预计月末状态
2. 主要贡献分类
3. 异常支出日期

### 3) 自动化验证脚本增强
更新 `scripts/verify_dev_flow.sh` 的日期范围步骤：
- 日历选择改为“按日历单元格坐标”而非纯文本匹配，降低误点概率。
- 兼容“日期选择器未自动关闭”的场景。
- 在 `com.jivemoney.app.dev` 实机回归通过。

## 变更文件
- `lib/core/service/budget_service.dart`
- `lib/feature/budget/budget_manager_screen.dart`
- `test/budget_service_test.dart`
- `scripts/verify_dev_flow.sh`

## 验证结果

### 静态与单测
- `flutter analyze --no-fatal-infos` ✅
- `flutter test test/budget_service_test.dart` ✅
- `flutter test` ✅

### ADB 真机（开发包）
- 安装并运行：`flutter run --flavor dev -d EP0110MZ0BC110087W --debug --no-resident` ✅
- 回归脚本：`bash scripts/verify_dev_flow.sh com.jivemoney.app.dev` ✅
- 结果产物：`/tmp/jive-verify-20260220-232237`
- 关键 UI 断言：预算页出现
  - `按当前节奏预计月末剩余`
  - `进度偏差`
  - `建议日均`
