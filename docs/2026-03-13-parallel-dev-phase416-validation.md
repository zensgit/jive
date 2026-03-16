# 2026-03-13 Parallel Dev Phase416 Validation

## 变更文件

- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_checkpoint_snapshot.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_cursor_store.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_session_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_session_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/backup_restore_stale_session_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/sync_session_service_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase416-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase416-validation.md`

## 执行记录

### 1. format

```bash
dart format \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_checkpoint_snapshot.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_cursor_store.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_session_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_session_service_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/backup_restore_stale_session_regression_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart
```

结果：通过。

中途说明：

- 误把 shell script 带进 `dart format` 参数，Dart formatter 对 shell 语法报错。
- Dart 文件格式化已经成功，shell script 未被改写。

### 2. targeted tests

```bash
flutter test \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_session_service_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart
```

结果：`All tests passed!`

覆盖点：

- snapshot checksum mismatch -> `isRestorable == false`
- lease `owner/device` 维度的 resume/canWrite
- stale lease 过期后的 resume 失败
- renew 后 version 自增
- backup round-trip 对 `syncCursors.version/capturedAt/checksum` 的导出保持

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
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_session_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/account_category_sync_repository_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/transaction_tag_project_sync_repository_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/sync_session_service_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart
```

结果：`No issues found!`

中途修复：

- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_checkpoint_snapshot.dart`
- 问题：`entry.key?.toString()` 触发 `invalid_null_aware_operator`
- 处理：改成 `entry.key.toString()` 后重跑 analyze 通过

### 4. shell syntax

```bash
bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh
bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh
```

结果：通过。

### 5. host mirror regression

```bash
flutter test /Users/huazhou/Downloads/Github/Jive/app/test/backup_restore_stale_session_regression_test.dart
```

结果：`All tests passed!`

中途修复：

- `/Users/huazhou/Downloads/Github/Jive/app/test/backup_restore_stale_session_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart`
- 问题：`JiveAccount.isArchived` 等必填字段未补齐，首次回归直接暴露模型序列化失败
- 处理：补齐 host 与 Android 两条场景的种子数据后重跑通过

### 6. release regression suite

```bash
bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh
```

结果：通过。

实际运行内容：

- focused analyze（20 项）
- repository/store/session/backup/auth regression tests
- 新增 host mirror regression test

说明：

- 首轮 `release_regression_suite` 会话在 Flutter lock 竞争期间出现过一次异常输出。
- 随后已通过 `bash -n` 复核脚本，并重新整套执行通过。
- 因此本轮把它记录为运行时异常现象，不视为新的脚本代码缺陷。

### 7. Android integration wiring

尝试项：

```bash
flutter test /Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart -d macos --dart-define=JIVE_E2E=true
flutter test /Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart
bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh
```

结果：

- 首次 `-d macos` 路径进入长时间 `build macos`，已终止。
- 随后改成 `host mirror regression + Android integration` 双轨策略。
- `backup_restore_stale_session_flow_test.dart` 已接入 `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`。
- 本地当前未启动 Android emulator，所以未在本轮直接实跑设备链路。

结论：

- host 侧逻辑闭环已由 `backup_restore_stale_session_regression_test.dart` 验证通过。
- `backup_restore_stale_session_flow_test.dart` 明确归入 Android emulator lane，作为更接近真实设备的集成回归。

## 结论

- sync checkpoint 已具备最小完整性校验：
  `version + capturedAt + checksum`
- sync session 已从 store 提升到 service：
  `issue/renew/resume/canWrite/clear`
- backup/restore + stale session 已有集成回归用例和 Android lane 接线

## 下一步

1. 把 `sync cursor + lease + owner/device` 收口进真正的 sync runtime
2. 在 Android emulator lane 跑通 `backup_restore_stale_session_flow_test.dart`
3. 继续把 repository boundary 往 backup/import/export 和未来 cloud sync 推进
