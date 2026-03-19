# 2026-03-13 Parallel Dev Phase415 Validation

## 变更文件

- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_checkpoint_snapshot.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_cursor_store.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease_store.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/sync_cursor_persistence_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_regression_suite_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase415-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase415-validation.md`

## 执行记录

### 1. format

```bash
dart format \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_checkpoint_snapshot.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_cursor_store.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease_store.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart
```

结果：通过。

### 2. targeted tests

```bash
flutter test \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart
```

结果：`All tests passed!`

覆盖点：

- `SyncCursorStore` 的 snapshot 持久化与 selective clear
- `SyncLeaseStore` 的 active/expired/clear
- backup round-trip 的 `project + syncCursors + clearedSyncLease`
- legacy backup 导入后的 transaction repair 与空 checkpoint 处理

中途修复：

- backup schema 从 `4` 升到 `5` 后，future schema reject 用例仍写死旧断言；已改为基于 `JiveDataBackupService.schemaVersion` 断言。

### 3. focused analyze

```bash
flutter analyze \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_cursor.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_checkpoint_snapshot.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_cursor_store.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease_store.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/account_sync_repository.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/category_sync_repository.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/transaction_sync_repository.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/tag_sync_repository.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/project_sync_repository.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/account_category_sync_repository_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/transaction_tag_project_sync_repository_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart
```

结果：`No issues found!`

### 4. regression suite script

```bash
bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh
bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh
```

结果：通过。

实际运行内容：

- focused analyze（17 项）
- repository/store/backup/auth release gate 测试

### 5. smoke / android scripts syntax

```bash
bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_smoke.sh
bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh
```

结果：通过。

### 6. workflow wiring

检查文件：

- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`

结果：

- host `release_smoke_host` 继续调用 `run_release_smoke.sh`
- Android emulator lane 在跑 E2E 前新增 `run_release_regression_suite.sh`

## 结论

- sync foundation 已从“可算游标”推进到“可持久化游标 + lease”。
- backup/import 已与 repository boundary 打通，并覆盖 `project`。
- release 车道已从单个 smoke 脚本收口为 `regression suite + smoke` 两层结构。

## 下一步

1. 给 cursor snapshot 增加 checksum / version
2. 为 Android lane 增加 `backup/restore + stale session` 的更真实集成回归
3. 把 sync cursor/lease 接入真正的 sync session service，而不是只停留在 store 层
