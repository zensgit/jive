# CI 验证记录：并行开发 1+2（v13，2026-02-24）

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
- 最新 head（`41b545d`）已追加复验并通过，当前分支状态可继续推进后续优化。
