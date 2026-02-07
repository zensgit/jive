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

## 2. 入口与页面

- 调试菜单入口：`周期记账`
- 页面：
  - `周期记账` 列表页（规则总览、启停、编辑、删除）
  - `新建周期规则` 表单页（规则创建与编辑）

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

文件：`lib/main.dart`

- App 首次初始化完成后执行一次 `_processRecurringRules()`。
- App 回到前台（`resumed`）时再次执行。

## 4. 手动测试用例

### 4.1 规则创建

1. 打开 `周期记账` 页面，点 `新建规则`。
2. 选择类型、金额、账户、分类、周期。
3. 保存后返回列表。

期望：

- 列表出现新规则。
- 显示正确的类型/金额/周期/模式摘要。

### 4.2 规则启停

1. 在列表页切换规则开关。

期望：

- 开关状态即时更新。
- 停用后不再生成新草稿/交易。

### 4.3 草稿模式

1. 新建 `生成草稿` 规则，起始时间设置为过去。
2. 回首页或重进 App，触发周期处理。
3. 进入自动草稿页查看。

期望：

- 出现对应草稿。
- 不重复生成相同 occurrence（由 `recurringKey` 防重）。

### 4.4 自动入账模式

1. 新建 `自动入账` 规则，起始时间设置为过去。
2. 回首页触发处理，查看交易列表。

期望：

- 自动生成交易。
- 标签规则正常挂载，且标签使用时间被刷新。

## 5. 自动化 adb 回归

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

## 6. 本次验证结果（2026-02-07）

已执行并通过：

- `flutter test`：全部通过
- `flutter build apk --debug --flavor dev -t lib/main.dart`：构建成功
- `adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk`：安装成功
- `bash scripts/verify_dev_flow.sh com.jivemoney.app.dev`：`PASS`

验证产物目录：

- `/tmp/jive-verify-20260207-212940`

## 7. 已知约束

- 周期规则时间计算以本地时间为准。
- 如果规则名称/分类被后续删除，历史已生成交易不会自动回滚。
- 大量历史补齐时会在启动阶段执行，建议配合规则范围（起止日期）控制数据量。
