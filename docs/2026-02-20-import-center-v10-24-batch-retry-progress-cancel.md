# Jive 导入中心 V10.24（批量重试进度可视化 + 可取消）

日期：2026-02-20

## 背景

当前批量重试在任务数较多时，用户只能等待最终结果，缺少执行进度和中断能力。
这会带来两个问题：

1. 无法判断当前重试是否在推进。
2. 当用户发现筛选范围过大时，无法及时停止。

## 本次改动

### 1) 新增批量重试执行器（可复用）

新增文件：
- `lib/feature/import/import_batch_retry_runner.dart`

新增能力：
- 统一批量重试循环执行。
- 暴露进度回调：`processed/total/success/failed/inserted`。
- 支持取消信号（`shouldCancel`）。
- 输出汇总结果（含 `secondaryFailureReasons`）。

### 2) 导入中心接入进度与取消

改动文件：
- `lib/feature/import/import_center_screen.dart`

接入点：
- `_retryResolvedJobs(...)` 改为使用 `ImportBatchRetryRunner`。
- 新增页面状态：
  - `_isBatchRetryRunning`
  - `_batchRetryCancelRequested`
  - `_batchRetryProgress`
- 失败聚合卡片新增执行面板：
  - 进度文案（已处理/成功/失败/新增）
  - 线性进度条
  - 「停止重试」按钮（点击后进入“停止中...”）
- 批量重试完成文案升级：
  - 正常完成：`批量重试完成：目标X 已处理Y ...`
  - 用户中断：`批量重试已取消：目标X 已处理Y ...`

## 测试

新增测试：
- `test/import_batch_retry_runner_test.dart`
  - 用例1：成功/失败/异常混合时汇总正确。
  - 用例2：取消信号触发后停止后续重试。

回归执行：

```bash
flutter analyze --no-fatal-infos
flutter test test/import_batch_retry_runner_test.dart test/import_center_screen_test.dart
flutter test
```

结果：全部通过。

## 结论

V10.24 将批量重试从“黑盒等待”升级为“可观测、可中断”的执行模式，降低误操作成本，提升失败任务治理的可控性。
