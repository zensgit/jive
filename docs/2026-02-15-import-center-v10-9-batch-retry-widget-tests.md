# Import Center V10.9：失败聚合 Widget 测试 + 按原因批量重试

日期：2026-02-15

## 目标
1. 为失败聚合卡片补 widget test，覆盖窗口切换与点击原因快速过滤。
2. 增加“按失败原因批量重试最近 N 个任务”的操作入口。

## 实现内容

### 1) 失败聚合卡片可测化与交互增强
- 文件：`lib/feature/import/import_center_screen.dart`
- `ImportCenterScreen` 新增可选参数：`debugJobs`
  - 用于 widget test 注入任务数据并跳过数据库初始化。
- 失败聚合卡片每条原因新增操作：
  - 点击原因：快速过滤（切到“失败”并写入搜索词）
  - 点击 `重试最近N`：进入批量重试流程
- 搜索索引补强：
  - `_matchesJobSearch(...)` 新增 `errorMessage` 与标准化失败原因匹配，保证点击原因后能命中列表。

### 2) 按失败原因批量重试最近 N 个任务
- 文件：`lib/feature/import/import_center_screen.dart`
- 新增流程：
  - `_promptBatchRetryByReason(...)`
  - `_showRetryCountDialog(...)`
  - `_retryFailedJobsByReason(...)`
  - `_collectFailedJobsByReason(...)`
- 行为：
  - 按当前失败窗口（7天/30天/全部）收集同原因失败任务
  - 以“最近时间”倒序选取前 N
  - 顺序调用 `ImportService.retryJob(jobId)` 执行重试
  - 完成后展示汇总（目标数/成功/失败/新增）并刷新任务列表

### 3) 新增 widget tests
- 文件：`test/import_center_screen_test.dart`
- 用例：
  - `failure aggregate supports time window switch and retry entry`
  - `tap failure reason applies failed quick filter and search query`
- 覆盖点：
  - 失败窗口从 `30天` 切到 `全部` 后聚合项变化
  - 卡片存在 `重试最近N` 入口
  - 点击原因后：失败 quick filter 被选中、搜索框写入原因、历史列表按条件收敛

## 验证
在 `app/` 目录执行：

```bash
flutter analyze
flutter test test/import_center_screen_test.dart
flutter test test/import_history_analytics_test.dart
flutter test
```

结果：全部通过。

## 备注
- 本次改动聚焦失败任务运营效率，不改变导入策略与去重判定。
