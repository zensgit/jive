# Jive 导入中心 V10.13（一键重试可重试 + 可点击建议动作）

日期：2026-02-16

## 目标

执行上一轮规划的 `1+2`：

1. 在失败原因行提供“仅重试可重试任务”的一键入口（无需输入 N）。
2. 将批量重试后的“建议动作”从纯文本升级为可点击操作。

## 实施内容

### 1) 失败原因行新增一键重试入口

文件：`lib/feature/import/import_center_screen.dart`

改动：

1. 每条失败原因行由单按钮升级为双按钮：
   - `重试可重试`
   - `重试最近N`
2. 新增 `_retryAllRetryableByReason(reason)`：
   - 复用预检逻辑筛出可重试任务。
   - 无可重试任务时直接提示。
   - 通过 `_confirmRetryAllDialog(...)` 确认后，直接重试全部可重试任务。

结果：

- 用户可一键处置该原因下全部可重试任务，不再每次输入 N。

### 2) 建议动作升级为可点击

文件：

- `lib/feature/import/import_history_analytics.dart`
- `lib/feature/import/import_center_screen.dart`

改动：

1. 新增结构化建议模型：
   - `ImportFailureActionKind`
   - `ImportFailureActionSuggestion`
   - `deriveImportFailureActionSuggestion(...)`
2. 保留原文本建议函数 `suggestImportFailureAction(...)`（向后兼容）。
3. `_showMessage(...)` 支持 `SnackBarAction`。
4. 批量重试完成后：
   - 仍展示“二次失败摘要 + 文本建议”。
   - 追加可点击 action（根据建议类型触发）：
     - `筛选失败任务`
     - `配置规则模板`
     - `刷新任务`
5. 新增 `_handleFailureActionSuggestion(...)` 执行动作映射。

## 测试更新

### 1) `test/import_history_analytics_test.dart`

新增：

- `deriveImportFailureActionSuggestion maps action label and kind`

覆盖：

1. 缺失内容 -> `filterFailedJobs` + `筛选失败任务`
2. 格式问题 -> `openRuleTemplate` + `配置规则模板`
3. 网络超时 -> `refreshJobs` + `刷新任务`
4. 空输入 -> `none`

### 2) `test/import_center_screen_test.dart`

新增：

- `tap retry-all-retryable shows unsupported message in debug mode`

覆盖：

1. 新按钮 `重试可重试` 存在且可点击。
2. debug 模式下链路可达并给出预期提示。

并更新既有用例断言，确认界面包含 `重试可重试` 入口。

## 验证结果

执行日期：2026-02-16

已执行：

1. `dart format lib/feature/import/import_center_screen.dart lib/feature/import/import_history_analytics.dart test/import_center_screen_test.dart test/import_history_analytics_test.dart`
2. `flutter test test/import_history_analytics_test.dart`
3. `flutter test test/import_center_screen_test.dart`
4. `flutter analyze`
5. `flutter test`

结果：

1. analyze 通过。
2. 定向测试通过。
3. 全量测试通过。

## 阶段结论

V10.13 实现了“失败原因 -> 一键重试可执行集合 -> 重试后可点击建议动作”的闭环，进一步降低了失败任务批处理和后续处置成本。
