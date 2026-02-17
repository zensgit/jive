# Jive 导入中心 V10.17（失败范围持久化 + 失败报表导出）

日期：2026-02-17

## 目标

在 V10.16 的失败来源范围过滤基础上，补齐两个关键能力：

1. 让失败聚合范围（时间窗口 + 来源范围）可持久化，重进页面后保持上次分析上下文。
2. 提供失败聚合报表导出，支持按当前范围输出结构化 CSV，便于复盘与外部协作。

## 本轮实现

### 1) 失败分析范围持久化

文件：`lib/feature/import/import_center_screen.dart`

新增：

- `_FailureScopePrefs`：封装失败范围偏好（`window` + `sourceType`）。
- `_failureWindowPrefKey = 'import_failure_window'`
- `_failureSourcePrefKey = 'import_failure_source_type'`

新增方法：

- `_loadFailureScopePrefs()`：读取并解析 `SharedPreferences`，非法值自动回退默认窗口 `30天`。
- `_saveFailureScopePrefs()`：保存当前窗口与来源范围。
- `_persistFailureScopePrefs()`：统一触发保存。

接入点：

1. `_init()` 阶段先加载失败范围偏好，再恢复 `_failureWindow` 与 `_failureSourceTypeFilter`。
2. 失败聚合卡中时间窗口与来源范围 `ChoiceChip` 切换后，立即持久化。

### 2) 失败聚合报表导出入口

文件：`lib/feature/import/import_center_screen.dart`

新增 UI：

- 失败聚合卡新增按钮 `导出失败报表`。

新增行为：

- `_exportFailureAggregateReport(...)`：
  1. 基于当前聚合结果构建 reason 级重试/阻塞统计。
  2. 生成 CSV 文本。
  3. 写入临时目录文件（文件名包含窗口、来源、时间戳）。
  4. 调用 `SharePlus` 分享导出文件。
  5. 成功/失败均给出消息反馈。

### 3) 失败聚合 CSV 生成器

文件：`lib/feature/import/import_history_analytics.dart`

新增：

- `buildImportFailureAggregateCsv(...)`

输出内容：

1. `meta,value` 区块：生成时间、时间窗口、来源范围、失败任务数、可重试/不可重试任务数、不可重试占比。
2. reason 明细区块：失败原因、次数、最新任务 ID、最新发生时间、可重试/不可重试数量、原因级不可重试占比。
3. 字段统一使用 `_csvEscape(...)`，避免逗号/引号等字符破坏 CSV 结构。

## 测试更新

### 1) UI 入口可见性

文件：`test/import_center_screen_test.dart`

更新断言：

- 在失败聚合场景中校验 `导出失败报表` 按钮存在。

### 2) CSV 内容验证

文件：`test/import_history_analytics_test.dart`

新增测试：

- `buildImportFailureAggregateCsv includes meta and reason rows`

覆盖点：

1. meta 区块关键字段存在（时间窗口、来源范围、失败任务数）。
2. reason 行包含正确的次数、时间与占比字段。

## 验证结果

执行日期：2026-02-17

已执行：

1. `flutter analyze`
2. `flutter test test/import_center_screen_test.dart`
3. `flutter test test/import_history_analytics_test.dart`
4. `flutter test`

结果：

1. analyze 通过（No issues found）。
2. 定向测试通过。
3. 全量测试通过。

## 阶段结论

V10.17 将“失败分析”从临时交互提升为可持续追踪能力：

1. 分析范围可恢复，减少重复配置成本。
2. 失败聚合可直接导出，支持跨端复盘、归档与协同排障。
3. 与 V10.16 的范围一致性机制保持对齐，确保导出的数据与当前视图一致。
