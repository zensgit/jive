# Import Job History Repository MVP

## Scope
- 新增 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/import_job_history_repository.dart`。
- 只抽 `JiveImportJob` 和 `JiveImportJobRecord` 的持久化边界，不碰解析/OCR/去重/自动草稿逻辑。

## Provided Methods
- `getJob`
- `listRecentJobs`
- `listJobRecords`
- `createPendingJob`
- `markJobRunning`
- `finishJob`
- `saveJobRecords`
- `exportSnapshot`
- `replaceAll`

## Current Integration
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
  - 任务创建、状态推进、记录落库改由 repository 承接。
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_job_detail_screen.dart`
  - 任务读取不再直接 raw query `JiveImportJob`。
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart`
  - 导出导入任务快照时改走 repository 的 export 边界。

## Why
- 这是最小安全切口。
- 它把 import history 从 orchestration service 里分离出来，但不会误把跨表 duplicate risk / OCR / draft ingest 一起耦死到 repository。
