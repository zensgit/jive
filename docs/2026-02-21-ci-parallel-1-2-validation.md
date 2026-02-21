# CI 验证记录：并行开发 1+2（2026-02-21，v4）

## 1. 本地验证

执行与结果：

1. `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/flutter_ci.yml'); puts 'YAML OK'"`
- 结果：通过。

2. `bash -n scripts/run_integration_tests.sh`
- 结果：通过。

3. `bash scripts/run_integration_tests.sh --help`
- 结果：通过（参数展示正常，含 recovery/timeout 配置）。

4. `dart format integration_test/support/e2e_flow_helpers.dart integration_test/calendar_date_picker_flow_test.dart integration_test/transaction_search_flow_test.dart`
- 结果：通过。

5. `flutter analyze integration_test/support/e2e_flow_helpers.dart integration_test/calendar_date_picker_flow_test.dart integration_test/transaction_search_flow_test.dart`
- 结果：`No issues found`。

## 2. 远端验证（本轮关键 Run）

1. `22256824644`（head `3d9f3fe`）
- `analyze_and_test`：success
- `android_integration_test`：failure
- 失败点：`Prewarm Android build toolchain`
- 失败证据：`Process completed with exit code 124`（prewarm 超时）。

2. `22257064102`（head `0a67d63`）
- `analyze_and_test`：success
- `android_integration_test`：success
- 关键步骤：
  - `Prewarm Android build toolchain` success（约 15m39s）
  - `Run Android integration_test (emulator)` success（约 12m43s）
- 关键日志：
  - `[integration] passed: integration_test/calendar_date_picker_flow_test.dart (attempt 1)`
  - `[integration] passed: integration_test/transaction_search_flow_test.dart (attempt 1)`
  - `[integration] timing summary:`
  - `[integration] suite elapsed: 8m30s`
  - `[integration] all integration tests passed`

## 3. PR 状态

- PR：`https://github.com/zensgit/jive/pull/50`
- 状态：OPEN（已包含最新提交与最新绿跑验证）。

## 4. 结论

1+2 已完成：PR 已创建并更新，且继续并行开发后的增量改动已通过远端完整验证。
