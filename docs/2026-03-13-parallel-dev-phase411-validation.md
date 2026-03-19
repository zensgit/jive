# 2026-03-13 Parallel Dev Phase411 Validation

## 变更文件

- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/auth_stale_session_release_gate_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/data_backup_migration_regression_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/auth_stale_session_release_gate_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_smoke_lane_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase411-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase411-validation.md`

## 执行记录

### 1. format

```bash
dart format \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/auth_stale_session_release_gate_test.dart
```

结果：通过。

备注：曾误把 `scripts/run_release_smoke.sh` 也喂给 `dart format`，解析失败；已改为只格式化 Dart 文件。

### 2. unit test

```bash
flutter test \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/auth_stale_session_release_gate_test.dart
```

结果：`All tests passed!`

覆盖点：

- backup round-trip
- legacy backup 自动迁移修复
- future schema 阻断且不清空现有数据
- stale callback / stale bundle / token rotate / healthy bundle release gate

### 3. analyze

```bash
flutter analyze \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/test/auth_stale_session_release_gate_test.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/transaction_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/credential_bundle_lease_governance_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/credential_bundle_version_reconciliation_governance_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/password_modify_response_integrity_governance_service.dart \
  /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/email_credential_bundle_consistency_governance_service.dart
```

结果：`No issues found!`

中途修复：删除 `data_backup_service_migration_regression_test.dart` 中未使用的 `category_model` import 后重跑通过。

### 4. host release smoke

```bash
bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_smoke.sh
JIVE_SMOKE_DEVICE=macos bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_smoke.sh
```

结果：通过。

host lane 最终覆盖：

- targeted analyze 13 项
- 3 个 unit/regression test 文件
- `import_center_failure_analytics_flow_test.dart`
- `category_icon_picker_flow_test.dart`

### 5. smoke 车道修正记录

第一次重跑时发现两类车道问题，均已修正：

1. 多个 `integration_test` 文件放在同一条 `flutter test -d macos` 命令里时，第二个文件会在 app relaunch 阶段丢失 debug connection。
   处置：把 host smoke 与 Android emulator 车道统一改成“逐文件执行”。

2. `calendar_date_picker_flow_test.dart` 在 macOS host lane 会触发 `com.jive.app/stream` 的 `MissingPluginException`。
   处置：把 `calendar_date_picker_flow_test.dart` 和 `transaction_search_flow_test.dart` 保留在 Android emulator 车道，不再放进 host release smoke。

## 结论

- `phase411` 新增功能与回归已通过目标验证。
- host release smoke 车道现在只保留稳定桌面项。
- Android emulator 车道继续承担带平台插件依赖的 `calendar/transaction` integration smoke。
