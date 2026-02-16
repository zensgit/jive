# Jive 导入中心 V10.14（窗口一键重试 + 原因级建议动作入口）

日期：2026-02-16

## 目标

在 V10.13 的基础上继续提升失败处置效率：

1. 提供“当前时间窗口”维度的一键重试可重试任务。
2. 在每个失败原因行直接提供“建议动作”快捷入口。

## 本轮实现

### 1) 失败聚合卡新增窗口级一键重试

文件：`lib/feature/import/import_center_screen.dart`

新增入口：

- `本窗口重试可重试`

新增方法：

- `_retryAllRetryableInWindow()`

流程：

1. 取当前窗口（7天/30天/全部）的失败任务。
2. 预检可重试性并生成可重试列表。
3. 弹窗确认后批量执行全部可重试任务。

### 2) 失败原因行新增建议动作按钮

文件：`lib/feature/import/import_center_screen.dart`

改动：

1. 每个原因行根据 `deriveImportFailureActionSuggestion(...)` 生成建议动作。
2. 若存在可执行动作，显示 `TextButton(actionLabel)`。
3. 点击后复用 `_handleFailureActionSuggestion(...)` 执行。

动作类型包括：

1. 筛选失败任务
2. 配置规则模板
3. 刷新任务

### 3) 一键重试确认弹窗支持范围语义

文件：`lib/feature/import/import_center_screen.dart`

`_confirmRetryAllDialog(...)` 扩展：

1. 新增 `scopeLabel` 参数。
2. 支持“失败原因范围”和“窗口范围”两种确认文案。

## 测试更新

文件：`test/import_center_screen_test.dart`

更新与新增：

1. 既有用例断言新增按钮存在：
   - `本窗口重试可重试`
   - `查看失败任务`
2. 新增 `tap window retry-all-retryable shows unsupported message in debug mode`
   - 覆盖窗口级一键入口在 debug 模式下的链路可达性。

## 验证结果

执行日期：2026-02-16

已执行：

1. `dart format lib/feature/import/import_center_screen.dart test/import_center_screen_test.dart`
2. `flutter test test/import_center_screen_test.dart`
3. `flutter test test/import_history_analytics_test.dart`
4. `flutter analyze`
5. `flutter test`

结果：

1. analyze 通过
2. 定向测试通过
3. 全量测试通过

## 阶段结论

V10.14 将失败处置入口从“原因级重试”扩展到“窗口级批量重试”，并把建议动作下沉到每个失败原因行，显著减少了操作路径与判断成本。
