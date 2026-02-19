# Jive 导入中心 V10.20（导出文件名非 ASCII 段回退）

日期：2026-02-17

## 目标

继续提升导出链路鲁棒性：

1. 当导出文件名分段包含中文或其他非 ASCII 字符时，不再丢失该段。
2. 为失败报表与复核清单导出补齐非 ASCII 场景单测，避免后续回归。

## 本轮实现

### 1) 文件名段规范化增强

文件：`lib/feature/import/import_failure_report_exporter.dart`

改动：

1. 新增 `_normalizeFileSegment(...)`：
   - 先尝试 `_sanitizeFileSegment(...)`（保留 `[a-z0-9_-]`）。
   - 若清洗后为空且原始段非空，回退为稳定哈希段：`u<hex>`。
2. `_buildFileName(...)` 改为调用 `_normalizeFileSegment(...)`。
3. 新增 `_stableHash(...)`（31 进位累乘，`0x7fffffff` 截断）确保结果稳定、可重复。

效果：

- 非 ASCII 名称不会被静默丢弃，可稳定映射到文件名中的哈希段。

### 2) 单测补充

#### 2.1 失败报表导出

文件：`test/import_failure_report_exporter_test.dart`

新增：

- `export keeps non-ascii segment with hash fallback`

覆盖：

1. `sourceName = 微信文本` 时，文件名符合：
   - `jive_failure_aggregate_d30_u<hex>_20260217_093100.csv`

#### 2.2 复核清单导出

文件：`test/import_review_checklist_exporter_test.dart`

新增：

- `export keeps non-ascii filter segment with hash fallback`

覆盖：

1. `previewFilterName = 仅已选` 时，文件名符合：
   - `jive_import_review_u<hex>_20260217_120100.csv`

## 验证结果

执行日期：2026-02-17

已执行：

1. `dart format lib/feature/import/import_failure_report_exporter.dart test/import_failure_report_exporter_test.dart test/import_review_checklist_exporter_test.dart`
2. `flutter test test/import_failure_report_exporter_test.dart test/import_review_checklist_exporter_test.dart test/import_center_screen_test.dart`
3. `flutter analyze`
4. `flutter test`

结果：

1. 格式化通过。
2. 定向测试通过。
3. analyze 通过（No issues found）。
4. 全量测试通过。

## 阶段结论

V10.20 在不改变导出主流程的前提下，提升了文件命名在多语言输入下的稳定性与可追踪性，并通过双导出器单测覆盖保证行为可回归。
