# CI 验证记录：并行开发 1+2（v10，2026-02-23）

## 1. 本地验证

1. `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/flutter_ci.yml'); puts 'YAML OK'"`
- 结果：通过。

2. `bash -n scripts/run_integration_tests.sh`
- 结果：通过。

3. `bash scripts/run_integration_tests.sh --help`
- 结果：通过，包含：
  - `--skip-pub-get`
  - `--combined-suite`

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

## 3. 对比观察

- `22306626056`：`suite elapsed 9m04s`
- `22307870910`：`suite elapsed 8m49s`
- `22310492003`：`suite elapsed 9m25s`
- `22312570907`：`suite elapsed 8m30s`
- `22313642147`：`suite elapsed 10m00s`

`22312570907` 步骤耗时分解：
- `Pre-install Android SDK components`：`38s`
- `Prewarm Android build toolchain`：`564s`
- `Run Android integration_test (emulator)`：`694s`

`22313642147` 步骤耗时分解（热缓存）：
- `Cache Gradle`：`51s`
- `Pre-install Android SDK components`：`33s`
- `Prewarm Android build toolchain`：`175s`
- `Run Android integration_test (emulator)`：`787s`

注：时长受 hosted runner 抖动影响，但策略链路稳定，连续多轮均全绿。

## 4. PR

- `https://github.com/zensgit/jive/pull/50`
- 状态：OPEN（已包含本轮提交与绿跑验证）。

## 5. 结论

继续开发任务完成：新增 `Gradle cache + SDK 预安装` 已完成冷缓存与热缓存两轮远端验证；热缓存命中后 prewarm 显著缩短，整体链路稳定全绿。
