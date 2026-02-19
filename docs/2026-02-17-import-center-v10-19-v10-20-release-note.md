# Jive 导入中心发版说明（V10.19 + V10.20）

日期：2026-02-17

## 发布范围

本次说明合并以下两轮迭代：

1. V10.19：导出动作测试增强 + 复核导出基建验证
2. V10.20：导出文件名非 ASCII 段回退

并补充本轮收尾：

3. 复核清单导出按钮 Widget 级点击测试（与失败报表导出同级）

## 核心能力更新

### 1) 失败报表导出测试闭环（V10.19）

1. 新增按钮点击测试，验证默认范围下导出请求参数：
   - 窗口
   - 来源范围
   - 失败/可重试/不可重试统计
   - 聚合原因与 reason 级统计
2. 新增来源切换后的导出参数测试，确保“所见即所导”。

对应文件：

- `test/import_center_screen_test.dart`

### 2) 复核清单导出基建验证（V10.19）

1. `ImportReviewChecklistExporter` 导出器具备独立单测覆盖。
2. 覆盖正常导出与分享失败异常上抛分支。
3. 命名与分享文案具备稳定断言。

对应文件：

- `lib/feature/import/import_failure_report_exporter.dart`
- `test/import_review_checklist_exporter_test.dart`

### 3) 导出文件名非 ASCII 段回退（V10.20）

1. 导出文件名段新增规范化流程：
   - 先 ASCII 清洗
   - 清洗为空时回退稳定哈希段 `u<hex>`
2. 避免中文来源或筛选名被静默丢弃，提升文件可追踪性。
3. 失败报表与复核清单导出均补齐非 ASCII 场景测试。

对应文件：

- `lib/feature/import/import_failure_report_exporter.dart`
- `test/import_failure_report_exporter_test.dart`
- `test/import_review_checklist_exporter_test.dart`

### 4) 本轮补充：复核清单导出按钮 Widget 点击测试

1. 为了在 debug 测试路径稳定构建预览区，`ImportCenterScreen` 增加可选 `debugPreviewData` 注入。
2. 新增用例直接点击 `导出复核清单`，断言 exporter 收到：
   - `previewFilterName`
   - `previewFilterLabel`
   - `visibleCount`
   - CSV 头与关键数据行

对应文件：

- `lib/feature/import/import_center_screen.dart`
- `test/import_center_screen_test.dart`

## 兼容性与风险

1. 运行时行为保持向后兼容：`debugPreviewData` 为可选测试注入参数，不影响生产路径。
2. 导出文件命名在非 ASCII 输入下会变更为哈希段表示，这是预期行为，用于保证命名稳定。

## 验证结果

执行日期：2026-02-17

已执行：

1. `flutter test test/import_center_screen_test.dart`
2. `flutter test test/import_failure_report_exporter_test.dart test/import_review_checklist_exporter_test.dart`
3. `flutter analyze`
4. `flutter test`

结果：

1. 定向测试通过。
2. analyze 通过（No issues found）。
3. 全量测试通过。

## 建议落地方式

1. 将本说明作为 V10.19 + V10.20 合并发布记录。
2. 保留原子迭代文档（V10.19、V10.20）用于研发追溯，本说明用于对外/对团队同步。
