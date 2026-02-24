# CI 并行开发报告：1+2（Prewarm + Recovery）v15

日期：2026-02-24

- 仓库：`Jive`
- 分支：`codex/next-batch-stability-core-v3`
- PR：`https://github.com/zensgit/jive/pull/50`
- 最新验证 Head：`6f8db00ea99d477316c6d734f9629e1a8614cc90`
- 最新通过 Run：`22348636097`

## 1. 本轮继续开发目标

1. 继续提高 Android integration 流程的抗波动能力。
2. 让 prewarm 不再成为阻断后续真实测试执行的单点失败。
3. 减少 emulator 阶段的环境安装抖动（SDK 组件与 Gradle 依赖准备）。

## 2. 本轮新增改动

1. `ci(e2e): make prewarm best-effort before emulator run`（`f5608b1`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - prewarm 构建执行后读取退出码。
  - 非 0 时输出 warning 并继续进入 emulator 测试步骤。
- 目的：避免 prewarm 偶发失败直接终止 pipeline；由 step9 进行真实可观测验证。

2. `ci(e2e): pre-install sdk components and cache gradle in android job`（`ff0c191`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - 新增 `Cache Gradle`（`~/.gradle/caches`、`~/.gradle/wrapper`）。
  - 新增 `Pre-install Android SDK components`（`platform-tools`、`platforms;android-30`、`platforms;android-33`、`build-tools;34.0.0`、`ndk;27.0.12077973`）。
- 目的：在 emulator 启动前主动完成高波动依赖准备，降低测试阶段额外下载干扰。

3. `ci(e2e): preinstall cmake and build-tools 35 for android job`（`7320b18`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - 在 SDK 预安装中追加 `build-tools;35.0.0`、`cmake;3.22.1`。
- 目的：减少后续步骤按需安装，进一步压缩 Android e2e 总时长。

4. `ci(e2e): upload integration artifacts and emit suite summary`（`1b895df`）
- 文件：
  - `.github/workflows/flutter_ci.yml`
  - `scripts/run_integration_tests.sh`
- 逻辑：
  - 脚本新增 `--summary-file` 与 `FLUTTER_TEST_SUMMARY_FILE`，落盘 `suite-summary.txt`。
  - CI 增加 `Append Android integration summary`（写入 `GITHUB_STEP_SUMMARY`）。
  - CI 增加 `Upload Android integration artifacts`（`always()`）。
  - 两条 job 增加 `Cache Pub dependencies`。
- 目的：提升故障定位与运行结果可观测性。

5. `ci(e2e): fix artifact path in emulator runner script`（`2af12fe`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - 在 `android-emulator-runner` 的 `script` 中改为直接使用 `${{ runner.temp }}/jive-integration`，避免跨行 shell 变量失效。
- 目的：修复 `mkdir` 空路径导致的误失败。

6. `ci(e2e): tolerate artifact upload quota failures`（`f585392`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - `Upload Android integration artifacts` 增加 `continue-on-error: true`。
- 目的：将 GitHub artifact 配额耗尽降级为非阻断告警，避免平台配额波动导致主验证链路判红。

7. `ci(e2e): persist suite summary on signal exits and format step summary`（`6f8db00`）
- 文件：
  - `scripts/run_integration_tests.sh`
  - `.github/workflows/flutter_ci.yml`
- 逻辑：
  - `run_integration_tests.sh` 新增 `EXIT/TERM/INT` trap，在 `SIGTERM`/超时/异常退出时也会落盘 `suite-summary.txt`，并记录：
    - `script_exit_code`
    - `script_result`
    - `interrupted_reason`（若有）
  - `Append Android integration summary` 改为结构化 Markdown 输出（Result / Suite elapsed / Failed tests / Artifacts dir + raw summary）。
- 目的：让失败和中断场景具备稳定可观测性，减少仅靠长日志排查。

## 3. 关键验证链路

### 3.1 优化基线
- `22306626056`：combined-suite，`suite elapsed 9m04s`
- `22307870910`：combined-suite + skip-pub-get，`suite elapsed 8m49s`

### 3.2 本轮 best-effort 验证
- Run：`22310492003`
- head：`f5608b1`
- `analyze_and_test`：success
- `android_integration_test`：success
- 关键日志：
  - `[integration] skipping flutter pub get once (requested)`
  - `[integration] combined suite mode enabled (2 files)`
  - `[integration]   - combined_suite(2 files): PASS in 9m24s (attempt 1/1)`
  - `[integration] suite elapsed: 9m25s`
  - `[integration] all integration tests passed`

### 3.3 本轮 SDK/Gradle 准备优化验证
- Run：`22312570907`
- head：`ff0c191`
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `23m48s`）
- 关键日志：
  - `Cache Gradle`：`Cache not found for input keys: Linux-gradle-..., Linux-gradle-`（首次 key 未命中，行为符合预期）
  - `Pre-install Android SDK components`：执行了 `platforms;android-30`、`platforms;android-33`、`build-tools;34.0.0`、`ndk;27.0.12077973`
  - `Prewarm Android build toolchain`：`Running Gradle task 'assembleDevDebug'... 560.4s`，随后成功构建 APK
  - `Run Android integration_test (emulator)`：`combined_suite(2 files): PASS in 8m30s`，`suite elapsed: 8m30s`

步骤耗时分解（`22312570907`）：
- `Pre-install Android SDK components`：`38s`
- `Prewarm Android build toolchain`：`564s`
- `Run Android integration_test (emulator)`：`694s`

### 3.4 热缓存命中验证
- Run：`22313642147`
- head：`247d820`
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `18m14s`）
- 关键日志：
  - `Cache Gradle`：`Cache restored from key: Linux-gradle-a2e627...`
  - `Post Cache Gradle`：`Cache hit occurred on the primary key Linux-gradle-a2e627..., not saving cache.`
  - `Prewarm Android build toolchain`：`171.9s`（流程步骤统计 `175s`）
  - `Run Android integration_test (emulator)`：`combined_suite(2 files): PASS in 10m00s`

步骤耗时分解（`22313642147`）：
- `Cache Gradle`：`51s`
- `Pre-install Android SDK components`：`33s`
- `Prewarm Android build toolchain`：`175s`
- `Run Android integration_test (emulator)`：`787s`

### 3.5 补齐 SDK 组件后的连续复验
- Run：`22337941629`
- head：`7320b18`
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `15m16s`）
- 关键日志：
  - `Cache Gradle` 命中主 key
  - `Pre-install Android SDK components` 包含 `build-tools;35.0.0`、`cmake;3.22.1`
  - `Prewarm Android build toolchain`：`174s`
  - `Run Android integration_test (emulator)`：`combined_suite(2 files): PASS in 7m14s`

- Run：`22338299455`（同 head 复验）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `15m49s`）
- 关键日志：
  - `Cache Gradle` 持续命中主 key
  - `Prewarm Android build toolchain`：`178s`
  - `Run Android integration_test (emulator)`：`combined_suite(2 files): PASS in 7m22s`

步骤耗时分解：
- `22337941629`：`Cache 52s`、`Pre-install 41s`、`Prewarm 174s`、`Run step 602s`
- `22338299455`：`Cache 59s`、`Pre-install 40s`、`Prewarm 178s`、`Run step 618s`

### 3.6 第 3 样本与统计收敛
- Run：`22339561892`
- head：`93a41aa`（稳定 runner）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `15m57s`）
- 关键日志：
  - `Cache Gradle` 命中主 key
  - `Pre-install Android SDK components` 包含 `build-tools;35.0.0`、`cmake;3.22.1`
  - `Prewarm Android build toolchain`：`179s`
  - `Run Android integration_test (emulator)`：`combined_suite(2 files): PASS in 7m35s`

3-run 统计（`22337941629`、`22338299455`、`22339561892`，nearest-rank）：
- `android_integration_test` 总时长：P50=`949s`，P90=`957s`
- `suite elapsed`：P50=`442s`（`7m22s`），P90=`455s`（`7m35s`）
- `Prewarm Android build toolchain`：P50=`178s`，P90=`179s`
- `Run Android integration_test (emulator)`：P50=`618s`，P90=`641s`

### 3.7 手动 emulator 消除安装开销实验与回退
- 实验提交：
  - `466fdbe`（手动 emulator 启动路径）
  - `715aa15`（AVD config 容错）
  - `d878dd3`（AVD 名称回退）
- 对应失败 run：
  - `22338788876`
  - `22338966526`
  - `22339361672`
- 主要失败模式：
  - `Unknown AVD name`
  - `No available AVD after avdmanager create`
  - `Emulator boot timeout`
- 回退提交：`93a41aa`（恢复 `reactivecircus/android-emulator-runner@v2` 稳定路径）

### 3.8 最新 head 复验
- Run：`22343824918`
- head：`41b545d`（文档提交，workflow 逻辑未变）
- `analyze_and_test`：success
- `android_integration_test`：success（总耗时 `19m53s`）
- 结论：稳定 runner 路径在最新分支头部继续保持全链路通过。

### 3.9 Summary + Artifact 能力接入与修复闭环

1. run `22345150767`（head `1b895df`）
- 结果：`analyze_and_test` success，`android_integration_test` failure。
- 观察：
  - `Prewarm` success。
  - `Run Android integration_test (emulator)` 报错：
    - `mkdir: cannot create directory ‘’: No such file or directory`
  - `Append Android integration summary` success。
- 结论：`android-emulator-runner` `script` 跨行变量未保留，导致路径为空。

2. run `22345625297`（head `2af12fe`）
- 结果：`Run Android integration_test (emulator)` success，但 job failure。
- 观察：
  - `Upload Android integration artifacts` 失败：
    - `Failed to CreateArtifact: Artifact storage quota has been hit.`
- 结论：失败来自平台 artifact 配额，不是测试链路本身。

3. run `22346306100`（head `f585392`）
- 结果：`analyze_and_test` success，`android_integration_test` success（总耗时 `19m11s`）。
- 关键步骤：
  - `Cache Pub dependencies`（两 job）success。
  - `Prewarm Android build toolchain`：`165s`。
  - `Run Android integration_test (emulator)`：`842s`。
  - `Append Android integration summary`：success。
  - `Upload Android integration artifacts`：success（配额异常被容错，不再阻断）。
- 结论：summary + artifact 能力在稳定 runner 基线下已完成闭环并通过终验。

### 3.10 signal-safe summary 与结构化摘要终验

- run `22348636097`（head `6f8db00`）
- 结果：`analyze_and_test` success，`android_integration_test` success（总耗时 `16m30s`）。
- 关键步骤：
  - `Prewarm Android build toolchain`：`168s`
  - `Run Android integration_test (emulator)`：`669s`
  - `Append Android integration summary`：success（结构化摘要已执行）
  - `Upload Android integration artifacts`：success（非阻断）
- 注解：
  - 仍会出现平台注解 `Failed to CreateArtifact: Artifact storage quota has been hit`；
  - 因上传步骤已 `continue-on-error`，不会把 job 判为失败。
- 额外本地验证：
  - 人工发送 `SIGTERM` 至脚本进程，summary 成功写出 `interrupted_reason=SIGTERM` 与 `script_exit_code=143`。

## 4. 结论

1. 继续开发已完成并通过远端完整验证。
2. prewarm best-effort 策略已上线，流程韧性提升（即使 prewarm 异常也不会提前中断）。
3. `Gradle cache + SDK 预安装` 已完成冷缓存与热缓存多轮验证，缓存命中后 prewarm 从 `564s` 稳定到 `174s ~ 178s`。
4. 补齐 `build-tools;35.0.0 + cmake;3.22.1` 后，稳定路径 3-run 已收敛：`15m16s / 15m49s / 15m57s`，关键套件耗时 `7m14s ~ 7m35s`。
5. 手动 emulator 方案在 hosted runner 上稳定性不足，已明确回退到稳定 runner；当前主分支链路恢复并保持全绿。
6. summary 文件落盘、Step Summary 展示、artifact 上传已落地；其中平台配额异常已做非阻断处理。
7. summary 在异常退出场景也可稳定落盘，并可在 CI 页面直接看到结构化结果摘要。
8. 最新 head 复验（`22348636097`）已通过，当前状态可在稳定 runner 基线下继续做增量优化。
9. 下一步优化应在稳定 runner 框架内进行（例如缩短 `Run Android integration_test` 主段业务执行时长），避免高风险替换启动栈。
