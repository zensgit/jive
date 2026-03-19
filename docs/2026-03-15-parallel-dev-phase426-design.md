# Phase426 Design

## Background
- Phase425 已经补了：
  - Android runtime telemetry artifact
  - import column mapping header conflict report
  - Android preview-repair import flow
- 但还存在两个明显缺口：
  - 列映射 fail-fast 仍然只是 host report，没有真实 UI 修复路径
  - import history 仍直接散落在 `ImportService` / `ImportJobDetailScreen` / backup 导出里，没有单独 repository 边界

## Design
- 为 `ImportCenter` 新增真实列映射修复链路：
  - 新增 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
  - 负责 CSV 列头检测、初始映射推断、按人工映射重新生成 `ImportParsedRecord`
  - 在 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart` 的预览卡内展示状态卡和“检查/修复列映射”对话框
- 将 `ImportColumnMappingFailfastService` 拆出当前场景兼容项：
  - 保留自定义账本导入场景的严格要求
  - 对 `ImportCenter` 通用 CSV 预览链路关闭“分类必填”和“账本列缺失不得 ready”的额外约束
- 抽出 `ImportJobHistoryRepository`：
  - 把任务创建、状态推进、记录落库、快照导出抽成单独边界
  - `ImportService` 继续保留解析、去重、ingest orchestration

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_column_mapping_failfast_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/import_job_history_repository.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_job_detail_screen.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_column_mapping_failfast_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_csv_mapping_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_job_history_repository_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_center_screen_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_column_mapping_repair_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_center_column_mapping_ui_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_job_history_repository_mvp.md`

## Tradeoff
- `ImportCenter` 现在引入了额外对话框和一层 CSV mapping service，复杂度高于原先“自动猜列直接预览”的单路径，但它补上了真正的人工修复入口。
- `ImportJobHistoryRepository` 只抽 import history，不抽解析和去重，短期内会保留一部分 service 侧逻辑；这是为了控制这轮改动面，不在活跃的 import 逻辑上做过度重构。
- 本轮没有强行补 `account book / import / sync conflict` 的 Android 真实生产页链路，因为当前仓库里没有对应的明确 production flow；优先补真实存在的 `ImportCenter` 链路收益更高。
