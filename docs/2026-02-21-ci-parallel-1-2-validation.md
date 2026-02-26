# CI 验证记录：并行开发 1+2（v39，2026-02-26）

## 1. 本地验证

1. `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/flutter_ci.yml'); puts 'YAML OK'"`
- 结果：通过。

2. `bash -n scripts/run_integration_tests.sh`
- 结果：通过。

3. `bash scripts/run_integration_tests.sh --help`
- 结果：通过，包含：
  - `--skip-pub-get`
  - `--combined-suite`
  - `--summary-file`

4. `bash scripts/run_integration_tests.sh --test integration_test/transaction_search_flow_test.dart --no-pub-get-once --no-device-recovery --retry 0 --artifact-dir <tmp> --summary-file <tmp>/suite-summary.txt emulator-5554`
- 结果：在失败路径下仍输出 `suite-summary.txt`，包含 `suite_elapsed_*`、`summary_entry`、`failed_tests_count` 等字段。

5. `bash scripts/run_integration_tests.sh ... & kill -TERM <pid>`（SIGTERM 场景）
- 结果：脚本退出码为 `143`，并写出：
  - `script_exit_code=143`
  - `script_result=failure`
  - `interrupted_reason=SIGTERM`

6. Step Summary 本地渲染校验（placeholder + 列表解析）
- 结果：通过，验证项：
  - placeholder 可解析 `script_result=unknown`、`script_exit_code=999`、`interrupted_reason=not_started_or_emulator_boot_failure`
  - `summary_entry` 与 `failed_test` 可被 `while read` 渲染为列表（不依赖 `mapfile`）

7. `scripts/render_integration_summary.sh` 本地回归
- 结果：通过，验证项：
  - 失败样本可正确渲染 `Result/exit/Suite elapsed/Failed tests/Artifacts dir`
  - `summary_entry` 与 `failed_test` 列表可正常输出
  - 占位样本可输出 `summary is placeholder-only` 提示

8. `bash -n scripts/init_integration_summary_placeholder.sh`
- 结果：通过。

9. `bash -n scripts/test_integration_summary_tools.sh`
- 结果：通过。

10. `bash scripts/test_integration_summary_tools.sh`
- 结果：通过，输出 `integration summary tools: OK`。

11. `bash scripts/init_integration_summary_placeholder.sh <tmp>/suite-summary.txt`
- 结果：通过，生成占位摘要，包含：
  - `script_result=unknown`
  - `script_exit_code=999`
  - `interrupted_reason=not_started_or_emulator_boot_failure`

12. `GITHUB_STEP_SUMMARY=<tmp>/step-summary.md bash scripts/render_integration_summary.sh <tmp>/suite-summary.txt`
- 结果：通过，输出包含：
  - `Result: unknown (exit 999)`
  - `summary is placeholder-only; integration script likely did not execute.`

13. `bash -n scripts/test_run_integration_runner_smoke.sh`
- 结果：通过。

14. `bash scripts/test_run_integration_runner_smoke.sh`
- 结果：通过，验证项：
  - mock 成功路径可写出 `script_result=success` 与 `summary_entry=... PASS ...`
  - mock 失败路径可写出 `script_result=failure`、`failed_tests_count=1` 与 `failed_test=integration_test/transaction_search_flow_test.dart`
  - 重复 `--test` 输入可被去重，summary 中 `test_files_count=1`

15. `bash -n scripts/test_run_integration_runner_signal_smoke.sh && bash scripts/test_run_integration_runner_signal_smoke.sh`
- 结果：通过，验证项：
  - runner 被 `SIGTERM` 中断后返回码为 `143`
  - summary 包含 `script_exit_code=143`、`script_result=failure`、`interrupted_reason=SIGTERM`

16. `bash -n scripts/test_run_integration_runner_args_smoke.sh && bash scripts/test_run_integration_runner_args_smoke.sh`
- 结果：通过，验证项：
  - `--retry invalid` 返回参数错误（exit `2`）
  - `--test integration_test/does_not_exist_smoke.dart` 返回 `integration test file not found`（exit `2`）
  - `--does-not-exist` 返回 unknown option（exit `2`）

17. `bash scripts/test_ci_helper_scripts.sh`
- 结果：通过，输出 `ci helper scripts: OK`（若环境缺少 `shellcheck`，则以提示信息跳过该静态检查，不影响其余自检）。

18. `scripts/run_integration_tests.sh` summary config 回归
- 结果：通过，验证项：
  - summary 文件新增 `config_entry=*` 字段（`device_id`、`flavor`、`dart_define`、timeout 与 recovery 参数）
  - `scripts/render_integration_summary.sh` 可渲染 `### Runtime config` 区块

19. `dart-define` 脱敏回归
- 结果：通过，验证项：
  - 当 `FLUTTER_TEST_DART_DEFINE=API_TOKEN=abc123,JIVE_E2E=true` 时，summary 写出：
    - `config_entry=dart_define=API_TOKEN=<redacted>,JIVE_E2E=true`

20. `render_integration_summary` Raw summary 截断回归
- 结果：通过，验证项：
  - `SUMMARY_RAW_MAX_LINES=40` 时输出截断提示并仅展示前 40 行 raw summary
  - `SUMMARY_RAW_MAX_LINES=0` 时不截断，可完整展示 raw summary（包含尾部行）

21. `run_integration_tests.sh` dry-run 回归
- 结果：通过，验证项：
  - 新增 `--dry-run` 后可在不执行 `flutter/adb` 的情况下完成参数与配置校验。
  - dry-run 输出可展示解析后的 `effective config` 与去重后的 `test_files_count`。
  - summary 文件可写出 `config_entry=dry_run=1`、`summary_entry=dry_run(...): SKIPPED (validation only)`。

22. `run_integration_tests.sh` summary json 与聚合校验回归
- 结果：通过，验证项：
  - 新增 `--print-summary-json` 后，脚本退出时可输出机器可解析 JSON 摘要（`jq` 校验通过）。
  - dry-run + summary-json 场景可写出 `config_entry=print_summary_json=1`，并在 stdout JSON 中包含 `summary_entries`。
  - 参数校验已改为聚合输出；多项错误会一次性返回（示例包含 `--retry`、`--timeout`、`FLUTTER_TEST_IGNORE_TIMEOUTS`、`pub-get-once`、缺失 test file）。

23. `run_integration_tests.sh` summary-json-file 与 schema smoke 回归
- 结果：通过，验证项：
  - 新增 `--summary-json-file` / `FLUTTER_TEST_SUMMARY_JSON_FILE`，可稳定落盘 JSON 摘要文件。
  - `scripts/test_run_integration_runner_summary_json_schema.sh` 校验 JSON 字段结构、类型与关键值（含脱敏与 dry-run）。
  - 当同时启用 `--print-summary-json` + `--summary-json-file` 时，stdout JSON 与文件 JSON 一致（`cmp` 校验通过）。

24. summary schema/version 与 renderer JSON 元数据回归
- 结果：通过，验证项：
  - JSON 摘要新增 `schema_version=1`、`generator_version=run_integration_tests.sh@v1` 字段。
  - `render_integration_summary.sh` 支持消费 `suite-summary.json` 并渲染 `### Summary JSON`（schema/generator/dry_run/print_summary_json）。
  - workflow 已将 `--summary-json-file` 接入 emulator runner，并在 Step Summary 渲染步骤传入 JSON 路径。

25. placeholder summary JSON 初始化回归
- 结果：通过，验证项：
  - `scripts/init_integration_summary_placeholder.sh` 可在初始化 `suite-summary.txt` 时同步写出 `suite-summary.json`。
  - 占位摘要包含 `summary_schema_version=1`、`summary_generator_version=init_integration_summary_placeholder.sh@v1`、`summary_json_file=*`。
  - `render_integration_summary.sh` 在 placeholder 场景可直接渲染 `### Summary JSON`，不再出现 JSON 文件缺失提示。

26. `render_integration_summary` summary-json-file 回落与无效 JSON 处理回归
- 结果：通过，验证项：
  - 未显式传入 JSON 路径时，可从 `config_entry=summary_json_file=*` 自动回落定位摘要 JSON。
  - JSON 文件内容无效时，会输出 `invalid JSON content; skipping JSON field rendering.` 提示并继续渲染其余摘要。
  - JSON 文件缺失时，会输出 `summary JSON file not found` 提示，不影响主摘要渲染。

## 2. 远端验证

1. `22310492003`（head `f5608b1`）
- `analyze_and_test`：success
- `android_integration_test`：success
- 日志证据：
  - `[integration] skipping flutter pub get once (requested)`
  - `[integration] combined suite mode enabled (2 files)`
  - `[integration] combined_suite(2 files): PASS in 9m24s (attempt 1/1)`
  - `[integration] suite elapsed: 9m25s`
  - `[integration] all integration tests passed`

2. `22312570907`（head `ff0c191`）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `23m48s`）
- 关键日志证据：
  - `Cache Gradle`：`Cache not found for input keys: Linux-gradle-..., Linux-gradle-`
  - `Pre-install Android SDK components`：执行了 `platforms;android-30`、`platforms;android-33`、`build-tools;34.0.0`、`ndk;27.0.12077973`
  - `Prewarm Android build toolchain`：`Running Gradle task 'assembleDevDebug'... 560.4s`，随后 `✓ Built ... app-dev-debug.apk`
  - `Run Android integration_test (emulator)`：
    - `[integration] skipping flutter pub get once (requested)`
    - `[integration] combined suite mode enabled (2 files)`
    - `[integration]   - combined_suite(2 files): PASS in 8m30s (attempt 1/1)`
    - `[integration] suite elapsed: 8m30s`
    - `[integration] all integration tests passed`

3. `22313642147`（head `247d820`，热缓存验证）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `18m14s`）
- 关键日志证据：
  - `Cache Gradle`：`Cache restored from key: Linux-gradle-a2e627...`
  - `Post Cache Gradle`：`Cache hit occurred on the primary key Linux-gradle-a2e627...`
  - `Prewarm Android build toolchain`：步骤耗时 `175s`（上轮同步骤 `564s`）
  - `Run Android integration_test (emulator)`：
    - `[integration] skipping flutter pub get once (requested)`
    - `[integration] combined suite mode enabled (2 files)`
    - `[integration]   - combined_suite(2 files): PASS in 10m00s (attempt 1/1)`
    - `[integration] suite elapsed: 10m00s`
    - `[integration] all integration tests passed`

4. `22337941629`（head `7320b18`，补齐 `build-tools;35.0.0 + cmake;3.22.1` 后验证）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `15m16s`）
- 关键日志证据：
  - `Cache Gradle`：`Cache restored from key: Linux-gradle-a2e627...`
  - `Pre-install Android SDK components`：包含 `build-tools;35.0.0`、`cmake;3.22.1`
  - `Prewarm Android build toolchain`：步骤耗时 `174s`
  - `Run Android integration_test (emulator)`：
    - `[integration]   - combined_suite(2 files): PASS in 7m14s (attempt 1/1)`
    - `[integration] suite elapsed: 7m14s`
    - `[integration] all integration tests passed`

5. `22338299455`（head `7320b18`，同版本复验）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `15m49s`）
- 关键日志证据：
  - `Cache Gradle`：`Cache restored from key: Linux-gradle-a2e627...`
  - `Pre-install Android SDK components`：包含 `build-tools;35.0.0`、`cmake;3.22.1`
  - `Prewarm Android build toolchain`：步骤耗时 `178s`
  - `Run Android integration_test (emulator)`：
    - `[integration]   - combined_suite(2 files): PASS in 7m22s (attempt 1/1)`
    - `[integration] suite elapsed: 7m22s`
    - `[integration] all integration tests passed`

6. `22339561892`（head `93a41aa`，稳定 runner 第 3 样本）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `15m57s`）
- 关键日志证据：
  - `Cache Gradle`：`Cache restored from key: Linux-gradle-a2e627...`
  - `Pre-install Android SDK components`：包含 `build-tools;35.0.0`、`cmake;3.22.1`
  - `Prewarm Android build toolchain`：步骤耗时 `179s`
  - `Run Android integration_test (emulator)`：
    - `[integration]   - combined_suite(2 files): PASS in 7m35s (attempt 1/1)`
    - `[integration] suite elapsed: 7m35s`
    - `[integration] all integration tests passed`

7. 手动 emulator 消除安装开销实验（失败回退）
- 失败 run：
  - `22338788876`（head `466fdbe`）
  - `22338966526`（head `715aa15`）
  - `22339361672`（head `d878dd3`）
- 主要失败模式：
  - `Unknown AVD name`
  - `No available AVD after avdmanager create`
  - `Emulator boot timeout`
- 处理：已回退到稳定 `reactivecircus/android-emulator-runner@v2`（head `93a41aa`）。

8. `22343824918`（head `41b545d`，最新 head 复验）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `19m53s`）
- 说明：
  - 该 run 对应文档提交 head（无 workflow 代码变化），用于确认“回退后稳定路径”在最新分支头部仍可全链路通过。

9. `22345150767`（head `1b895df`，接入 summary/artifact 首轮）
- `analyze_and_test`：success
- `android_integration_test`：failure
- 关键日志证据：
  - `Prewarm Android build toolchain`：success
  - `Run Android integration_test (emulator)`：failure，错误为：
    - `mkdir: cannot create directory ‘’: No such file or directory`
  - `Append Android integration summary`：success
  - `Upload Android integration artifacts`：warning（路径为空导致无文件）
- 根因：`android-emulator-runner` 的 `script` 按行执行，行内变量未在后续行保留。
- 处理：改为直接使用 `${{ runner.temp }}/jive-integration` 字面路径，不依赖跨行 shell 变量。

10. `22345625297`（head `2af12fe`，修复路径后复验）
- `analyze_and_test`：success
- `android_integration_test`：failure
- 关键日志证据：
  - `Run Android integration_test (emulator)`：success
  - `Append Android integration summary`：success
  - `Upload Android integration artifacts`：failure，注解：
    - `Failed to CreateArtifact: Artifact storage quota has been hit.`
- 根因：GitHub Actions artifact 存储配额不足（平台侧限制）。
- 处理：为上传步骤增加 `continue-on-error: true`，避免平台配额波动阻断主验证链路。

11. `22346306100`（head `f585392`，配额容错后终验）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `19m11s`）
- 关键步骤：
  - `Cache Pub dependencies`：两条 job 均 success
  - `Prewarm Android build toolchain`：`165s`（`10:15:56 -> 10:18:41`）
  - `Run Android integration_test (emulator)`：`842s`（`10:18:41 -> 10:32:43`）
  - `Append Android integration summary`：success
  - `Upload Android integration artifacts`：success（配额异常被容错，不再导致 job 失败）

12. `22348636097`（head `6f8db00`，异常退出 summary + 结构化 summary 终验）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `16m30s`）
- 关键步骤：
  - `Run Android integration_test (emulator)`：success（`11:26:57 -> 11:38:06`）
  - `Append Android integration summary`：success（结构化 Markdown 摘要已写入）
  - `Upload Android integration artifacts`：success（步骤不阻断）
- 注解：
  - 仍可见平台注解 `Failed to CreateArtifact: Artifact storage quota has been hit`；因已启用 `continue-on-error`，不会将 job 判失败。

13. `22354318216`（head `0aaf069`，compileSdk 对齐 SDK 预装）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `15m04s`）
- 关键步骤：
  - `Pre-install Android SDK components`：`34s`（`14:08:27 -> 14:09:01`）
  - `Prewarm Android build toolchain`：`171s`（`14:09:01 -> 14:11:52`）
  - `Run Android integration_test (emulator)`：`577s`（`14:11:52 -> 14:21:29`）
  - `Append Android integration summary`：success
  - `Upload Android integration artifacts`：success（步骤不阻断）
- 注解：
  - 仍可见平台注解 `Failed to CreateArtifact: Artifact storage quota has been hit`；但已不影响 job 结果。

14. `22377190762`（head `9c7f369`）与 `22377246231`（head `5c79ad2`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：failure（job 未启动）
- 注解一致：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：属于平台预算限制，非 workflow 逻辑失败。

15. `22377470427`（head `44df02a`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：failure（job 未启动）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，远端无法启动验证任务。

16. `22379761651`（head `73f422b`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：failure（job 未启动）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，最新 head 远端验证仍不可用。

17. `22379833732`（head `f906d26`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，文档提交后的复验仍不可用。

18. `22382836852`（head `957f1f8`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，首次重试复验仍不可用。

19. `22382843780`（head `957f1f8`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，连续重试后仍未恢复可用预算。

20. `22384016101`（head `10eac1a`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，新增 smoke 自检提交后的复验仍不可用。

21. `22384084422`（head `46a36e0`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，新增 signal smoke 自检提交后的复验仍不可用。

22. `22388584445`（head `9fdeb48`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，新增 args smoke 与 test-file preflight 提交后的复验仍不可用。

23. `22388638142`（head `6248250`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，v24 文档提交后的复验仍不可用。

24. `22391634299`（head `4f030ba`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，helper 校验入口收敛提交后的复验仍不可用。

25. `22391741600`（head `d9c5a75`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，helper 可选 shellcheck 增强后的复验仍不可用。

26. `22394058502`（head `545d51c`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，测试目标去重与 args smoke 扩展提交后的复验仍不可用。

27. `22394113804`（head `7c5bc55`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，v28 文档提交后的复验仍不可用。

28. `22396318360`（head `c0ea763`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，summary runtime config 增强提交后的复验仍不可用。

29. `22396554550`（head `479aaa5`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，dart-define 脱敏增强提交后的复验仍不可用。

30. `22401367675`（head `2f19500`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，raw summary 截断增强提交后的复验仍不可用。

31. `22401502483`（head `b2aa0b5`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，v32 文档提交后的复验仍不可用。

32. `22401694121`（head `0d3b892`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，dry-run 增强提交后的复验仍不可用。

33. `22402394776`（head `e828255`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，summary-json + 聚合校验增强提交后的复验仍不可用。

34. `22424860242`（head `8f36d90`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，summary-json-file + schema smoke 增强提交后的复验仍不可用。

35. `22425027988`（head `6df20bc`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，schema/version + renderer JSON 元数据增强提交后的复验仍不可用。

36. `22426677104`（head `ae89523`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，placeholder summary JSON 初始化增强提交后的复验仍不可用。

37. `22428255458`（head `2abeb94`）
- `analyze_and_test`：failure（job 未启动）
- `android_integration_test`：skipped（依赖前置 job）
- 注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：预算限制仍在，summary JSON 回落与无效 JSON 诊断增强提交后的复验仍不可用。

## 3. 对比观察

- `22306626056`：`suite elapsed 9m04s`
- `22307870910`：`suite elapsed 8m49s`
- `22310492003`：`suite elapsed 9m25s`
- `22312570907`：`suite elapsed 8m30s`
- `22313642147`：`suite elapsed 10m00s`
- `22337941629`：`suite elapsed 7m14s`
- `22338299455`：`suite elapsed 7m22s`
- `22339561892`：`suite elapsed 7m35s`
- `22343824918`：success（未纳入性能统计样本）
- `22345150767`：failure（emulator step 内路径变量作用域问题）
- `22345625297`：failure（artifact 配额耗尽）
- `22346306100`：success（summary + artifact 容错链路终验）
- `22348636097`：success（signal-safe summary + 结构化 Step Summary）
- `22354318216`：success（compileSdk 对齐 SDK 预装）
- `22377190762`：failure（Actions budget 阻断，job 未启动）
- `22377246231`：failure（Actions budget 阻断，job 未启动）
- `22377470427`：failure（Actions budget 阻断，job 未启动）
- `22379761651`：failure（Actions budget 阻断，job 未启动）
- `22379833732`：failure（Actions budget 阻断，主 job 未启动）
- `22382836852`：failure（Actions budget 阻断，主 job 未启动）
- `22382843780`：failure（Actions budget 阻断，主 job 未启动）
- `22384016101`：failure（Actions budget 阻断，主 job 未启动）
- `22384084422`：failure（Actions budget 阻断，主 job 未启动）
- `22388584445`：failure（Actions budget 阻断，主 job 未启动）
- `22388638142`：failure（Actions budget 阻断，主 job 未启动）
- `22391634299`：failure（Actions budget 阻断，主 job 未启动）
- `22391741600`：failure（Actions budget 阻断，主 job 未启动）
- `22394058502`：failure（Actions budget 阻断，主 job 未启动）
- `22394113804`：failure（Actions budget 阻断，主 job 未启动）
- `22396318360`：failure（Actions budget 阻断，主 job 未启动）
- `22396554550`：failure（Actions budget 阻断，主 job 未启动）
- `22401367675`：failure（Actions budget 阻断，主 job 未启动）
- `22401502483`：failure（Actions budget 阻断，主 job 未启动）
- `22401694121`：failure（Actions budget 阻断，主 job 未启动）
- `22402394776`：failure（Actions budget 阻断，主 job 未启动）
- `22424860242`：failure（Actions budget 阻断，主 job 未启动）
- `22425027988`：failure（Actions budget 阻断，主 job 未启动）
- `22426677104`：failure（Actions budget 阻断，主 job 未启动）
- `22428255458`：failure（Actions budget 阻断，主 job 未启动）

`22312570907` 步骤耗时分解：
- `Pre-install Android SDK components`：`38s`
- `Prewarm Android build toolchain`：`564s`
- `Run Android integration_test (emulator)`：`694s`

`22313642147` 步骤耗时分解（热缓存）：
- `Cache Gradle`：`51s`
- `Pre-install Android SDK components`：`33s`
- `Prewarm Android build toolchain`：`175s`
- `Run Android integration_test (emulator)`：`787s`

`22337941629` 步骤耗时分解：
- `Cache Gradle`：`52s`
- `Pre-install Android SDK components`：`41s`
- `Prewarm Android build toolchain`：`174s`
- `Run Android integration_test (emulator)`：`602s`

`22338299455` 步骤耗时分解：
- `Cache Gradle`：`59s`
- `Pre-install Android SDK components`：`40s`
- `Prewarm Android build toolchain`：`178s`
- `Run Android integration_test (emulator)`：`618s`

`22339561892` 步骤耗时分解：
- `Cache Gradle`：`50s`
- `Pre-install Android SDK components`：`36s`
- `Prewarm Android build toolchain`：`179s`
- `Run Android integration_test (emulator)`：`641s`

`22346306100` 步骤耗时分解：
- `Cache Gradle`：`54s`
- `Pre-install Android SDK components`：`34s`
- `Prewarm Android build toolchain`：`165s`
- `Run Android integration_test (emulator)`：`842s`

`22348636097` 步骤耗时分解：
- `Cache Gradle`：`53s`
- `Pre-install Android SDK components`：`53s`
- `Prewarm Android build toolchain`：`168s`
- `Run Android integration_test (emulator)`：`669s`

`22354318216` 步骤耗时分解：
- `Cache Gradle`：`57s`
- `Pre-install Android SDK components`：`34s`
- `Prewarm Android build toolchain`：`171s`
- `Run Android integration_test (emulator)`：`577s`

3-run 统计（样本：`22337941629`、`22338299455`、`22339561892`，百分位采用 nearest-rank）：
- `android_integration_test` 总时长：P50=`949s`，P90=`957s`
- `suite elapsed`：P50=`442s`（`7m22s`），P90=`455s`（`7m35s`）
- `Prewarm Android build toolchain`：P50=`178s`，P90=`179s`
- `Run Android integration_test (emulator)`：P50=`618s`，P90=`641s`

注：时长受 hosted runner 抖动影响，但策略链路稳定，连续多轮均全绿。

## 4. PR

- `https://github.com/zensgit/jive/pull/50`
- 状态：OPEN（已包含本轮提交与绿跑验证）。

## 5. 结论

继续开发任务完成：
- 稳定 runner 路径完成 3-run 连续全绿，关键套件耗时分布收敛（P50 `7m22s` / P90 `7m35s`）。
- 手动 emulator 去除安装开销方案在 hosted runner 上不稳定，已回退到稳定实现并保持全绿。
- 新增 `suite-summary` 与 artifact 链路已接入并完成闭环修复（路径作用域 + 配额容错）。
- 新增 `EXIT/TERM` 兜底写摘要与结构化 Step Summary，异常退出可追踪性增强。
- SDK 预装已与 `compileSdk` 对齐，兼容可选包安装失败场景并保持主链路稳定。
- summary 渲染逻辑已抽离到 `scripts/render_integration_summary.sh`，占位与列表展示已完成本地回归。
- summary 占位初始化与自检能力已抽离为独立脚本（`scripts/init_integration_summary_placeholder.sh`、`scripts/test_integration_summary_tools.sh`），并完成本地回归。
- `run_integration_tests.sh` 已新增 mock smoke 自检脚本（`scripts/test_run_integration_runner_smoke.sh`），并完成成功/失败摘要落盘本地回归。
- `run_integration_tests.sh` 已新增 `SIGTERM` smoke 自检（`scripts/test_run_integration_runner_signal_smoke.sh`），中断场景摘要落盘可验证。
- `run_integration_tests.sh` 已新增参数边界 smoke 与 test-file preflight（`scripts/test_run_integration_runner_args_smoke.sh` + 文件存在性校验），参数错误可快速失败。
- CI helper 校验入口已统一到 `scripts/test_ci_helper_scripts.sh`，降低了 workflow 内联脚本复杂度。
- CI helper 校验脚本已增加可选 `shellcheck` 静态检查（有工具则执行，无工具则提示跳过），在不增加硬依赖的前提下增强脚本质量基线。
- `run_integration_tests.sh` 已新增测试目标去重逻辑，避免重复 `--test` 参数导致重复执行。
- `run_integration_tests.sh` summary 已增加 runtime config 信息并在 Step Summary 展示，远端排障上下文更完整。
- `run_integration_tests.sh` 对 `dart-define` 的敏感 key（token/secret/password/auth 等）已做 summary 脱敏，避免泄露风险。
- `render_integration_summary` 已支持 raw summary 行数上限（默认 200，可通过 `SUMMARY_RAW_MAX_LINES` 配置，0 表示不截断），并配套 limits smoke 回归。
- `run_integration_tests.sh` 已支持 `--dry-run` 快速回归模式，可在预算受限时做参数/配置与 summary 落盘验证。
- `run_integration_tests.sh` 已支持 `--print-summary-json`，并将参数校验升级为聚合错误输出，提升脚本可诊断性与自动化集成能力。
- `run_integration_tests.sh` 已支持 `--summary-json-file` 并新增 summary JSON schema smoke，提升对下游自动化消费的兼容性保障。
- `run_integration_tests.sh` JSON 摘要已加入 schema/generator version 字段，`render_integration_summary.sh` 也可直接消费 JSON 并展示元数据。
- `init_integration_summary_placeholder.sh` 已可同步生成占位 JSON 摘要，确保启动失败场景下的 JSON 可观测性与渲染一致性。
- `render_integration_summary.sh` 已支持从 `config_entry=summary_json_file` 自动回落定位 JSON，并可对无效 JSON 输出显式诊断，降低摘要渲染静默降级风险。
- 受平台 Actions budget 限制，`9c7f369`、`5c79ad2`、`44df02a`、`73f422b`、`f906d26`、`957f1f8`、`10eac1a`、`46a36e0`、`9fdeb48`、`6248250`、`4f030ba`、`d9c5a75`、`545d51c`、`7c5bc55`、`c0ea763`、`479aaa5`、`2f19500`、`b2aa0b5`、`0d3b892`、`e828255`、`8f36d90`、`6df20bc`、`ae89523`、`2abeb94` 的远端复验均未完整启动；待预算恢复后补一轮绿跑即可完成远端闭环。
