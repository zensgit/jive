# Jive 导入中心 V7（重复风险 + 复核导出）

日期：2026-02-15

## 本轮目标

在 V6（仅已选筛选 + 时间偏移）基础上继续完成导入闭环：

1. 导入前给出重复风险预估
2. 批量偏移时间支持工作日校正
3. 按当前筛选结果导出复核清单

## 功能增量

### 1) 重复风险预估（导入前）

文件：`lib/core/service/import_service.dart`

新增：

- `ImportDuplicateEstimate`
  - `validCount`
  - `inBatchDuplicates`
  - `existingDuplicates`
  - `duplicateRate`
- `estimateDuplicateRisk(List<ImportParsedRecord>)`
  - 统计当前批次内部重复（按风险去重键）
  - 对比历史交易与历史草稿，统计潜在历史重复

预览面板展示：

- `批内重复 N`
- `历史重复 N`
- `预估重复率 X%`

### 2) 批量时间偏移增强（含工作日规则）

文件：`lib/feature/import/import_center_screen.dart`

新增能力：

- 偏移单位：分钟 / 小时
- 偏移值支持正负（前移/后移）
- 工作日规则：
  - 不校正
  - 遇周末顺延到下个工作日
  - 遇周末前移到上个工作日

实现要点：

- `_TimeShiftConfig`
- `_WorkdayAdjustMode`
- `_adjustToWorkday()`
- `_isWeekend()`

### 3) 当前筛选结果导出“复核清单”

文件：`lib/feature/import/import_center_screen.dart`

新增按钮：

- `导出复核清单`

导出行为：

- 导出范围：当前筛选命中的记录（不是固定前 30 条）
- 导出格式：CSV
- 输出字段：
  - `lineNumber`
  - `selected`
  - `isValid`
  - `amount`
  - `timestamp`
  - `type`
  - `source`
  - `confidence`
  - `warnings`
  - `rawText`
- 导出路径：临时目录
- 分享方式：系统分享面板（`share_plus`）

## 关键交互

文件：`lib/feature/import/import_center_screen.dart`

- 新增预览筛选：`仅已选`
- 批量操作：`批量改类型 / 批量改来源 / 批量偏移时间 / 导出复核清单`
- 预览质量统计：`有警告 / 低置信度 / 批内重复 / 历史重复 / 预估重复率`

## 测试与验证

执行时间：2026-02-15

已执行：

- `dart format lib/core/service/import_service.dart lib/feature/import/import_center_screen.dart test/import_service_test.dart`
- `flutter analyze`
- `flutter test test/import_service_test.dart`
- `flutter test`

结果：

- `flutter analyze` 通过
- 定向测试通过（包含 `estimateDuplicateRisk` 新增用例）
- 全量测试通过

## 与 yimu / qianji 的差异化进度（导入链路）

当前已经形成“导入前可控”优势：

1. 预览前置 + 手工修正（单条 + 批量）
2. 质量可视化（警告/置信度/重复风险）
3. 复核清单可导出，适合人工复核流程

## 下一阶段计划（V8~V10）

### V8：规则模板化（可保存）

- 保存“来源默认值 / 时间偏移 / 工作日规则 / 类型映射”预设
- 不同来源（微信/支付宝/OCR）可绑定不同模板

### V9：智能去重决策

- 导入前对高风险重复项显示“保留/跳过”建议
- 支持用户一次性应用“全部保留/全部跳过/仅保留最新”

### V10：导入后对账与回溯

- 导入任务结果生成“差异报告”
- 可从任务历史一键回看“当时导入内容 + 决策轨迹”
