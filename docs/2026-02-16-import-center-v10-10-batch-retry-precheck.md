# Jive 导入中心 V10.10（失败任务批量重试预检）

日期：2026-02-16

## 背景

在“失败原因聚合 + 一键重试最近N”能力上线后，存在一个稳定性缺口：

1. 同一失败原因下，并非所有任务都可实际重试（例如原文件已不存在且任务未保留 payload）。
2. 弹窗中的可选 N 之前基于“失败任务总数”，用户容易输入一个无法全部执行成功的目标值。
3. 批量重试前缺少“不可重试原因”的透明反馈，运维排查成本较高。

## 本轮目标

1. 在执行批量重试前，逐条预检任务是否可重试。
2. 在重试弹窗中展示“可重试/总数”和不可重试摘要。
3. 执行阶段仅消费可重试任务列表，避免无效重试。
4. 补充对应单元测试并完成全量回归验证。

## 实施计划与落地

### 1) 建立可重试性判定模型

文件：`lib/feature/import/import_history_analytics.dart`

新增：

- `ImportRetryability`：统一表达 `canRetry/source/blockReason`。
- `evaluateImportJobRetryability(...)`：基于 `payloadText/filePath/fileExists` 做可重试性判断。

判定规则：

1. 有 `payloadText`：可重试（source=`payload`）。
2. 无 payload 但原文件存在：可重试（source=`file`）。
3. 仅有文件路径但文件不存在：不可重试（`原文件不存在且无原始文本`）。
4. payload 与文件路径均缺失：不可重试（`原始导入内容缺失`）。

### 2) 批量重试前增加预检分流

文件：`lib/feature/import/import_center_screen.dart`

新增：

- `_ResolvedRetryCandidate`：携带 `job + retryability`。
- `_resolveRetryCandidates(...)`：逐条检查文件存在性并生成预检结果。
- `_summarizeBlockedRetryReasons(...)`：聚合不可重试原因并输出 Top3 摘要。

调整：

1. `_promptBatchRetryByReason(...)` 先预检，再拆分 `retryableJobs` 与 blocked 摘要。
2. 若可重试任务为 0，直接提示并中断执行。
3. `_showRetryCountDialog(...)` 新增 `totalCount/blockedSummary` 参数并显示预检信息。
4. 执行入口改为 `_retryResolvedJobs(retryableJobs, limit: N)`，只针对可重试任务执行。

### 3) 测试补齐

文件：`test/import_history_analytics_test.dart`

新增测试：

- `evaluateImportJobRetryability resolves payload and file fallback`

覆盖四种核心分支：

1. payload 优先可重试。
2. 文件兜底可重试。
3. 文件缺失不可重试。
4. payload + 文件同时缺失不可重试。

## 验证记录

执行日期：2026-02-16

已执行命令：

1. `dart format lib/feature/import/import_center_screen.dart lib/feature/import/import_history_analytics.dart lib/feature/import/import_job_detail_screen.dart test/import_center_screen_test.dart test/import_history_analytics_test.dart test/import_job_detail_screen_test.dart`
2. `flutter analyze`
3. `flutter test test/import_center_screen_test.dart`
4. `flutter test test/import_history_analytics_test.dart`
5. `flutter test test/import_job_detail_screen_test.dart`
6. `flutter test`

结果：

1. `flutter analyze` 通过。
2. 定向测试全部通过。
3. 全量测试通过。

## 阶段结论

V10.10 将“失败原因批量重试”从“按数量触发”升级为“按可重试性触发”，减少无效重试并提升失败任务处置透明度。

## 后续建议

1. 在失败聚合卡中增加“不可重试占比”可视化，提前暴露数据质量问题。
2. 批量重试完成后输出“失败原因二次聚合”，便于判断是否需要改解析策略而非重复重试。
