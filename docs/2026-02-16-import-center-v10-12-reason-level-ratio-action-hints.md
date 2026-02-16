# Jive 导入中心 V10.12（原因级可重试占比 + 重试建议动作）

日期：2026-02-16

## 目标

在 V10.11 基础上继续细化失败处置体验：

1. 失败原因聚合卡从“窗口总占比”下钻到“原因级占比”。
2. 批量重试后不仅给出二次失败摘要，还给出建议动作。
3. 将原因摘要/建议逻辑沉淀为可复用函数并补充测试。

## 本轮实现

### 1) 失败卡支持原因级可重试占比

文件：`lib/feature/import/import_center_screen.dart`

新增：

- `_buildReasonRetryabilitySnapshots(...)`
- `_buildRetryabilitySnapshotForJobs(...)`

效果：

1. 卡片顶部继续展示窗口级：`可重试X / 不可重试Y / 占比Z%`。
2. 每条失败原因行新增自己的占比：
   - `可重试 a 条，不可重试 b 条（占比 c%）`

收益：

1. 用户能快速定位“哪个失败原因最难重试”。
2. 可优先处理高不可重试占比的原因，减少无效点击。

### 2) 二次失败提示增加建议动作

文件：`lib/feature/import/import_center_screen.dart`

在 `_retryResolvedJobs(...)` 完成后提示中新增：

- `二次失败：原因1 ×k，原因2 ×m`
- `建议：<动作建议>`

建议动作由失败原因自动映射，例如：

1. 缺少原始内容 -> `补齐原始导入内容后重试`
2. 解析格式类 -> `检查导入文件格式并更新解析规则`
3. 超时/网络类 -> `检查网络连接后再次重试`
4. 兜底 -> `打开任务详情查看错误并修正源数据`

### 3) 通用分析函数扩展

文件：`lib/feature/import/import_history_analytics.dart`

新增：

- `suggestImportFailureAction(Map<String, int>)`

并将原因摘要排序/归并逻辑做了内部复用，减少 UI 层重复实现。

## 测试更新

### 1) `test/import_center_screen_test.dart`

更新失败聚合测试，校验新增占比文案：

1. 30天窗口存在 `可重试 1 / 不可重试 0 / 占比 0%`
2. 全部窗口存在 `可重试 1 / 不可重试 1 / 占比 50%`

### 2) `test/import_history_analytics_test.dart`

新增：

1. `suggestImportFailureAction returns action by top reason`
   - 覆盖缺失内容、格式错误、网络超时、兜底分支。
2. 既有 `summarizeImportReasonCounts` 测试继续覆盖归并排序逻辑。

## 验证结果

执行日期：2026-02-16

已执行：

1. `dart format lib/feature/import/import_center_screen.dart lib/feature/import/import_history_analytics.dart test/import_history_analytics_test.dart test/import_center_screen_test.dart`
2. `flutter test test/import_history_analytics_test.dart`
3. `flutter test test/import_center_screen_test.dart`
4. `flutter analyze`
5. `flutter test`

结果：

1. analyze 通过。
2. 定向测试通过。
3. 全量测试通过。

## 阶段结论

V10.12 让失败重试闭环从“看得见失败数量”进一步升级为“看得见原因级可执行率 + 拿得到下一步动作建议”，可直接降低失败处置决策成本。
