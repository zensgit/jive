# Jive 导入中心 V10（任务回溯闭环）

日期：2026-02-15

## 目标

在 V8+V9（规则模板 + 重复决策）基础上，完成导入后可追溯闭环：

1. 任务级决策持久化
2. 记录级决策明细可查询
3. 任务详情页可筛选/导出

## 主要实现

### 1) ImportJob 扩展

文件：`lib/core/database/import_job_model.dart`

新增字段：

- `skippedByDuplicateDecisionCount`
- `duplicatePolicy`（`keep_latest / keep_all / skip_all`）
- `decisionSummaryJson`

### 2) 新增 ImportJobRecord 持久化模型

文件：`lib/core/database/import_job_record_model.dart`

每条导入记录会持久化：

- 原始行信息（行号、金额、来源、时间、类型）
- 质量信息（置信度、warnings）
- 风险信息（riskLevel）
- 决策结果（decision + reason）

支持按 `jobId` 查询，作为任务详情与导出数据源。

### 3) 导入服务改造

文件：`lib/core/service/import_service.dart`

新增：

- `ImportDuplicatePolicy`
- `ImportJobDetailSummary`
- `listJobRecords(jobId, ...)`
- `getJobDetailSummary(jobId)`

导入流程变化：

- `importPreparedRecords` 支持传入 `duplicatePolicy`
- 执行导入时先做重复风险分析，再按策略做决策
- 决策结果逐条写入 `JiveImportJobRecord`
- 任务写回新增统计与策略信息

策略语义：

- `keep_latest`：高风险分组里仅保留“导入批次中最新且晚于历史最新”的记录
- `keep_all`：不做策略跳过
- `skip_all`：高风险记录全部策略跳过

### 4) 导入中心 UI 接入

文件：`lib/feature/import/import_center_screen.dart`

新增：

- 导入前“重复策略”下拉选择（默认：仅保留最新）
- 结果卡片展示：`策略跳过` + `策略标签`
- 任务历史展示：`跳过数量 + 策略`
- 点击任务进入详情页

### 5) 新增任务详情页

文件：`lib/feature/import/import_job_detail_screen.dart`

能力：

- 任务摘要（总计/新增/重复/无效/策略跳过/风险统计）
- 按决策和风险维度筛选记录
- 导出当前筛选结果 CSV
- 展示每条记录的决策原因和警告信息

### 6) 数据库与备份兼容

文件：

- `lib/core/service/database_service.dart`
- `lib/core/service/data_backup_service.dart`

改动：

- 注册 `JiveImportJobRecordSchema`
- 备份 `schemaVersion` 升级为 `4`
- 备份导入导出新增 `importJobRecords`
- `importJobs` 备份映射包含新字段

## 测试与验证

执行时间：2026-02-15

已执行：

- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test test/import_service_test.dart`
- `flutter test`

结果：

- analyze 通过
- import service 定向测试通过
- 全量测试通过

新增测试覆盖：

- `importPreparedRecords keep_latest skips older duplicates and persists record decisions`
- `importPreparedRecords skip_all skips all high risk records`

## 阶段结论

V10 已形成“导入前决策 + 导入后审计”的闭环能力：

1. 导入任务可回溯到记录级决策
2. 重复策略行为可审计
3. 历史任务可筛选、复核、导出

