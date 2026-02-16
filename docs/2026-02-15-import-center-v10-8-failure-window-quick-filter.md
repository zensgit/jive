# Import Center V10.8：失败窗口聚合 + 一键过滤

日期：2026-02-15

## 目标
1. 失败原因聚合支持时间窗口（7天 / 30天 / 全部），提高问题定位时效性。
2. 点击聚合原因即可一键应用历史筛选（切到失败任务 + 关键词）。

## 实现内容

### 1) 失败聚合窗口化
- 文件：`lib/feature/import/import_center_screen.dart`
- 新增状态：`_FailureWindow { d7, d30, all }`，默认 `30天`。
- 历史卡片新增窗口切换芯片：`7天 / 30天 / 全部`。
- 聚合调用增加时间边界：
  - `aggregateImportFailureReasons(..., since: failedWindowSince)`。
- 显示窗口内失败任务总数；若窗口内无失败原因，显示空态提示。

### 2) 聚合原因一键过滤
- 文件：`lib/feature/import/import_center_screen.dart`
- 聚合行由纯文本改为可点击按钮。
- 点击后执行：
  - `quick filter => failed`
  - 搜索框填充选中原因并触发筛选。

### 3) 聚合函数增强
- 文件：`lib/feature/import/import_history_analytics.dart`
- `aggregateImportFailureReasons` 新增参数：`DateTime? since`。
- 仅统计 `occurredAt >= since` 的失败任务（若 `since == null` 则全量）。

### 4) 测试补充
- 文件：`test/import_history_analytics_test.dart`
- 新增用例：`aggregateImportFailureReasons supports since time window`
- 覆盖：窗口过滤后仅返回窗口内失败原因。

## 验证
在 `app/` 目录执行：

```bash
flutter analyze
flutter test test/import_history_analytics_test.dart
flutter test test/import_job_detail_screen_test.dart
flutter test
```

结果：全部通过。

## 备注
- 本次改动为运营可观测和排障效率增强，不改变导入去重或写库策略。
