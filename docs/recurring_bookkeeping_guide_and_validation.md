# 周期记账 使用说明与回归验证

## 1. 功能概览

周期记账用于按固定频率自动生成交易，支持两种落地模式：

- `生成草稿`：到期时写入自动草稿，待用户确认后入账。
- `自动入账`：到期时直接生成交易记录。

支持频率：

- 按日（`day`）
- 按周（`week`）
- 按月（`month`）
- 按年（`year`）

本轮（2026-02-12）补充能力：

- 新建规则保存后自动执行一次，并回传执行结果。
- 编辑规则保存后自动执行一次，并回传执行结果。
- 列表页保留“立即执行一次”入口，支持手动触发补执行。
- 预算管理页保留超时/失败兜底态与重试入口，避免长期无反馈加载。

## 2. 入口与页面

- 调试菜单入口：`周期记账`
- 页面：
  - `周期记账` 列表页（规则总览、启停、编辑、删除、立即执行）
  - `新建周期规则` 表单页（规则创建与编辑）
  - `预算管理` 页面（预算汇总、失败兜底、重试）

## 3. 数据结构与执行链路

### 3.1 规则模型

文件：`lib/core/database/recurring_rule_model.dart`

核心字段：

- 规则基础：`name`、`type`、`amount`
- 账户分类：`accountId`、`toAccountId`、`categoryKey`、`subCategoryKey`
- 标签项目：`tagKeys`、`projectId`
- 执行模式：`commitMode`（`draft` / `commit`）
- 周期信息：`intervalType`、`intervalValue`、`dayOfMonth`、`dayOfWeek`
- 生命周期：`startDate`、`endDate`、`nextRunAt`、`lastRunAt`、`isActive`

### 3.2 执行服务

文件：`lib/core/service/recurring_service.dart`

执行要点：

- 只处理启用规则（`isActive=true`）。
- 从 `nextRunAt` 开始循环补齐到当前时间，支持跨多次周期补账。
- 使用 `recurringKey` 去重，避免重复写入。
- 草稿模式写 `JiveAutoDraft`，自动入账模式写 `JiveTransaction`。
- 自动入账成功后更新标签使用时间（`TagService.markTagsUsed`）。

### 3.3 触发时机

- `lib/main.dart`
  - App 首次初始化完成后执行一次 `_processRecurringRules()`。
  - App 回到前台（`resumed`）时再次执行。
- `lib/feature/recurring/recurring_rule_form_screen.dart`
  - 新建规则保存成功后自动执行一次 `processDueRules()`。
  - 编辑规则保存成功后自动执行一次 `processDueRules()`。
- `lib/feature/recurring/recurring_rule_list_screen.dart`
  - 点击右上角“立即执行一次”按钮时手动执行。

### 3.4 保存结果回传与提示

- `RecurringRuleFormScreen` 保存后返回 `RecurringRuleSaveResult`：
  - `saved`
  - `generatedDrafts`
  - `committedTransactions`
  - `processingError`
- `RecurringRuleListScreen` 统一根据回传结果展示提示：
  - `规则已保存，当前没有到期规则`
  - `规则已保存并执行：草稿 X 笔，入账 Y 笔`
  - `规则已保存，但自动执行失败：...`

## 4. 手动测试用例

### 4.1 新建后自动执行

1. 打开 `周期记账` 页面，点击 `新建规则`。
2. 新建一条起始时间为过去的规则并保存。

期望：

- 返回列表后出现“已保存并执行”的结果提示。
- 若规则到期，草稿或交易数据产生；未到期则提示“当前没有到期规则”。

### 4.2 编辑后自动执行

1. 在列表页编辑已有规则并保存。

期望：

- 返回列表后出现“已保存并执行”或“当前没有到期规则”的结果提示。
- 列表摘要与开关状态正常。

### 4.3 列表手动执行

1. 在列表页点击右上角“立即执行一次”。

期望：

- 显示“执行完成/当前没有到期规则/执行失败”提示。
- 列表刷新，无重复写入。

### 4.4 草稿模式去重

1. 创建 `生成草稿` 规则，起始时间设为过去。
2. 连续触发执行两次。

期望：

- 同一 occurrence 只生成一次草稿（`recurringKey` 防重生效）。

### 4.5 自动入账模式去重

1. 创建 `自动入账` 规则，起始时间设为过去。
2. 连续触发执行两次。

期望：

- 同一 occurrence 只入账一次（`recurringKey` 防重生效）。

### 4.6 预算页失败兜底与重试

1. 打开 `预算管理` 页面。
2. 在异常数据场景下观察失败态并点击 `重试`。

期望：

- 页面不会长期停留在无反馈 spinner。
- 失败态可见，且可通过重试恢复加载。

## 5. 自动化回归

### 5.1 ADB 冒烟脚本

脚本：`scripts/verify_dev_flow.sh`

示例命令：

```bash
bash scripts/verify_dev_flow.sh com.jivemoney.app.dev
```

脚本覆盖：

- 首页可见性
- 调试菜单打开
- 周期记账列表/新建页可达
- 预算页加载后不会长期停在 spinner

### 5.2 单元测试覆盖（新增）

- `test/recurring_service_test.dart`
  - 草稿模式去重
  - 入账模式去重
  - 按月 31 号跨月补齐
  - 停用规则不执行
- `test/budget_service_test.dart`
  - 预算汇总 smoke
  - 分类预算过滤
  - 周期日期边界计算

## 6. 本次验证结果（2026-02-12）

已执行并通过：

- `flutter test`：全部通过
- `flutter build apk --debug`：构建成功
- `flutter build apk --debug --flavor dev -t lib/main.dart`：构建成功
- `adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk`：安装成功
- `bash scripts/verify_dev_flow.sh com.jivemoney.app.dev`：`PASS`

静态检查：

- `flutter analyze --no-fatal-infos ...` 已执行。
- 当前保留 `recurring_rule_form_screen.dart` 的 9 条 info 级弃用提示（`DropdownButtonFormField.value` / `RadioListTile` 新 API 迁移），不影响本轮功能与构建。

验证产物目录：

- `/tmp/jive-verify-20260212-005901`

## 7. 已知约束

- 周期规则时间计算以本地时间为准。
- 如果规则名称/分类后续变更，历史已生成交易不会自动回滚。
- 历史补齐量过大时，执行耗时会增加，建议配合起止日期控制。
- 表单页组件 API 仍有弃用项，后续可单独做 Flutter 新 API 迁移。
