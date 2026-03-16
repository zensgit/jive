# Phase428 Validation

## Completed
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`，为 transfer import 增加 `toAccountName`、`serviceCharge` 字段，并在 CSV 解析、review checklist、prepared import 中保留。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`，支持转入账户列和手续费列映射重放。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`，通过 metadata bridge 持久化 transfer 目标账户和手续费，并在 confirm 时回填 transaction。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart`，支持 transfer 结构化修复 fan-out。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`，新增 transfer 编辑字段、preview chips 和 review checklist 列。
- 新增 `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_preview_flow_test.dart`，覆盖 transfer 预览和导入确认。
- 更新 `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`，将 transfer preview flow 纳入 Android smoke。
- 修复 `/Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart` 在 Android smoke 中暴露的脆弱 selector：为 `/Users/huazhou/Downloads/Github/Jive/app/lib/main.dart` 的 Home `View All` 入口增加 `home_view_all_transactions_button`，并将 `/Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart`、`/Users/huazhou/Downloads/Github/Jive/app/integration_test/calendar_date_picker_flow_test.dart` 改为 key-first 导航。

## Command Validation
- `dart format /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_csv_mapping_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_center_screen_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_record_repair_fanout_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_preview_flow_test.dart`
- `flutter analyze /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_csv_mapping_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_center_screen_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_record_repair_fanout_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_preview_flow_test.dart`
- `flutter test /Users/huazhou/Downloads/Github/Jive/app/test/import_csv_mapping_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_service_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_center_screen_test.dart /Users/huazhou/Downloads/Github/Jive/app/test/import_record_repair_fanout_service_test.dart`
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `flutter test /Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_preview_flow_test.dart -d emulator-5554 --flavor dev --dart-define=JIVE_E2E=true`
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `dart format /Users/huazhou/Downloads/Github/Jive/app/lib/main.dart /Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart /Users/huazhou/Downloads/Github/Jive/app/integration_test/calendar_date_picker_flow_test.dart`
- `flutter analyze /Users/huazhou/Downloads/Github/Jive/app/lib/main.dart /Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart /Users/huazhou/Downloads/Github/Jive/app/integration_test/calendar_date_picker_flow_test.dart`
- `flutter test /Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart -d emulator-5554 --flavor dev --dart-define=JIVE_E2E=true`
- `flutter test /Users/huazhou/Downloads/Github/Jive/app/integration_test/calendar_date_picker_flow_test.dart -d emulator-5554 --flavor dev --dart-define=JIVE_E2E=true`

## Result
- `dart format`: passed
- targeted `flutter analyze`: passed, `No issues found!`
- targeted host `flutter test`: passed
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`: passed
- targeted Android integration `import_center_transfer_preview_flow_test.dart`: passed
- full Android smoke: passed
- selector stabilization analyze: passed, `No issues found!`
- targeted Android integration `transaction_search_flow_test.dart`: passed on first run after key-first selector fix
- targeted Android integration `calendar_date_picker_flow_test.dart`: passed on first run after key-first selector fix

## Android Smoke Coverage
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_failure_analytics_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_duplicate_resolution_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_preview_repair_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_column_mapping_repair_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_preview_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/category_icon_picker_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/calendar_date_picker_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart`

## Note
- 首次全量 Android smoke 在 `/Users/huazhou/Downloads/Github/Jive/app/integration_test/transaction_search_flow_test.dart` 暴露了 `View All` 文案 selector 脆弱性。
- 已通过 Home 页固定 key 和 key-first 导航修复，并对受影响的 `transaction_search` 与 `calendar_date_picker` 两条用例单独重跑验证通过。
