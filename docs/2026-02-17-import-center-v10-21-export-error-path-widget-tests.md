# Jive 导入中心 V10.21（导出失败分支 Widget 测试）

日期：2026-02-17

## 目标

在既有导出正向测试基础上，补齐 UI 层异常分支覆盖：

1. 失败报表导出失败时，页面应给出明确错误提示。
2. 复核清单导出失败时，页面应给出明确错误提示。

## 本轮实现

### 1) 失败报表导出失败提示测试

文件：`test/import_center_screen_test.dart`

新增用例：

- `tap export failure report shows error message when exporter throws`

覆盖点：

1. 注入抛异常的 `ImportFailureReportExporter`。
2. 点击 `导出失败报表`。
3. 断言出现 `导出失败报表失败：...` Snackbar 文案。

### 2) 复核清单导出失败提示测试

文件：`test/import_center_screen_test.dart`

新增用例：

- `tap export review checklist shows error message when exporter throws`

覆盖点：

1. 注入抛异常的 `ImportReviewChecklistExporter`。
2. 使用 `debugPreviewData` 构造可导出预览数据。
3. 点击 `导出复核清单`。
4. 断言出现 `导出复核清单失败：...` Snackbar 文案。

## 验证结果

执行日期：2026-02-17

已执行：

1. `flutter test test/import_center_screen_test.dart`
2. `flutter analyze`
3. `flutter test`

结果：

1. 新增与既有 Widget 测试通过。
2. analyze 通过（No issues found）。
3. 全量测试通过。

## 阶段结论

V10.21 使导出能力在 UI 层完成“成功 + 失败”双分支闭环，降低未来改动导致提示缺失或文案回退的风险。
