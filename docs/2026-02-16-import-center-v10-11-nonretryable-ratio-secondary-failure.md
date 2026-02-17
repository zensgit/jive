# Jive 导入中心 V10.11（不可重试占比 + 二次失败聚合）

日期：2026-02-16

## 目标

在 V10.10 的“批量重试预检”基础上，继续提升失败运维可视化与重试反馈闭环：

1. 在失败原因聚合卡中直接展示不可重试占比。
2. 在批量重试完成提示中追加“二次失败原因”摘要。
3. 抽取可复用的原因计数摘要函数并补测。

## 实施内容

### 1) 失败聚合卡增加不可重试占比

文件：`lib/feature/import/import_center_screen.dart`

新增：

- `_FailureRetryabilitySnapshot`：记录窗口内可重试/不可重试计数。
- `_buildFailureRetryabilitySnapshot(DateTime? since)`：基于 `payloadText/filePath/fileExists` 计算可重试性。

界面新增文案：

- `可重试 X 条，不可重试 Y 条（占比 Z%）`

这样用户在点击“重试最近N”前即可判断该窗口失败任务的可处理程度。

### 2) 批量重试结果增加“二次失败原因聚合”

文件：`lib/feature/import/import_center_screen.dart`

改动：

- 在 `_retryResolvedJobs(...)` 中收集重试过程中仍失败的原因计数。
- 完成后提示从：
  - `批量重试完成：目标N 成功A 失败B 新增C`
- 升级为：
  - `批量重试完成：...；二次失败：原因1 ×k，原因2 ×m`

收益：

1. 不再只看到“失败数量”，还能看到“失败类型”。
2. 便于区分“需要继续重试”还是“需要修解析/修数据源”。

### 3) 抽取通用摘要函数

文件：`lib/feature/import/import_history_analytics.dart`

新增函数：

- `summarizeImportReasonCounts(Map<String, int> reasonCounts, {int maxItems = 3})`

能力：

1. 归并空白原因为 `未知原因`。
2. 按次数降序 + 原因字典序排序。
3. 输出 TopN 文本（`原因 ×次数`，逗号连接）。

使用点：

1. 批量重试二次失败摘要。
2. 批量重试预检里的不可重试原因摘要。

## 测试补充

### 新增/更新

1. `test/import_center_screen_test.dart`
   - 更新失败窗口切换用例，断言新增占比文案：
     - 30天窗口：`可重试 1 条，不可重试 0 条（占比 0%）`
     - 全部窗口：`可重试 1 条，不可重试 1 条（占比 50%）`

2. `test/import_history_analytics_test.dart`
   - 新增 `summarizeImportReasonCounts merges and sorts top items`
   - 覆盖：归并、排序、TopN、空输入、`maxItems<=0`。

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
2. 相关定向测试通过。
3. 全量测试通过。

## 阶段结论

V10.11 将失败处理从“重试前后仅看数量”升级为“重试前看可执行率、重试后看失败结构”，进一步缩短失败任务定位与修复路径。

## 下一步建议

1. 将“不可重试占比”下钻到“原因维度占比”（每个失败原因行展示可重试/不可重试）。
2. 对二次失败摘要增加“建议动作标签”（例如：缺失原始内容 -> 建议补源文件；格式错误 -> 建议更新解析规则）。
