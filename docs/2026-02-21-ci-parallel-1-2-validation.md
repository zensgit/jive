# CI 验证记录：并行开发 1+2（2026-02-21）

## 1. 本地验证

执行与结果：

1. `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/flutter_ci.yml'); puts 'YAML OK'"`
- 结果：通过。

2. `bash -n scripts/run_integration_tests.sh`
- 结果：通过。

3. `bash scripts/run_integration_tests.sh --help`
- 结果：通过（参数可解析，含 recovery/timeout 配置）。

4. `dart format integration_test/calendar_date_picker_flow_test.dart integration_test/transaction_search_flow_test.dart`
- 结果：通过。

5. `flutter analyze integration_test/calendar_date_picker_flow_test.dart integration_test/transaction_search_flow_test.dart`
- 结果：`No issues found`。

## 2. 远端验证（关键 Run）

1. `22251181202`（head `dd0becc`）
- `analyze_and_test`：success
- `android_integration_test`：failure
- 失败证据：`Timed out waiting for finder: Found 0 widgets with key [<'transaction_filter_open_button'>]`。

2. `22251591482`（head `c27dbc0`）
- `analyze_and_test`：success
- `android_integration_test`：success
- 关键步骤：
  - `Prewarm Android build toolchain` success（约 11m18s）
  - `Run Android integration_test (emulator)` success（约 11m07s）
- 关键日志：
  - `[integration] passed: integration_test/calendar_date_picker_flow_test.dart (attempt 1)`
  - `[integration] passed: integration_test/transaction_search_flow_test.dart (attempt 1)`
  - `[integration] all integration tests passed`

## 3. 结论

并行开发任务（CI 稳定化 + E2E 时序稳健化）已完成并通过远端全链路验证。
