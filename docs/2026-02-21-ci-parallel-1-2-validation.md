# CI 验证记录：并行开发 1+2（2026-02-21，v5）

## 1. 本地验证

1. `bash -n scripts/run_integration_tests.sh`
- 结果：通过。

2. `bash scripts/run_integration_tests.sh --help`
- 结果：通过，且包含新增参数：
  - `--pub-get-once`
  - `--no-pub-get-once`
  - `--pub-get-timeout`

3. `dart format integration_test/support/e2e_flow_helpers.dart integration_test/calendar_date_picker_flow_test.dart integration_test/transaction_search_flow_test.dart lib/feature/category/category_transactions_screen.dart`
- 结果：通过。

4. `flutter analyze lib/feature/category/category_transactions_screen.dart integration_test/support/e2e_flow_helpers.dart integration_test/calendar_date_picker_flow_test.dart integration_test/transaction_search_flow_test.dart`
- 结果：`No issues found`。

## 2. 远端验证

1. `22257862912`（head `cbb3151`）
- `analyze_and_test`：success
- `android_integration_test`：success
- 关键日志：
  - `[integration] running flutter pub get once before integration suite`
  - `[integration] passed: integration_test/calendar_date_picker_flow_test.dart (attempt 1)`
  - `[integration] passed: integration_test/transaction_search_flow_test.dart (attempt 1)`
  - `[integration] timing summary:`
  - `[integration] suite elapsed: 9m15s`
  - `[integration] all integration tests passed`

## 3. PR

- `https://github.com/zensgit/jive/pull/50`
- 状态：OPEN（已更新至最新提交与绿跑验证）。

## 4. 结论

继续开发后的增量能力（ready sentinel + pub-get-once/no-pub）已完成并通过远端全链路验证。
