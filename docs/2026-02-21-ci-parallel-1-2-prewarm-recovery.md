# CI 并行开发报告：1+2（Prewarm + Recovery）v26

日期：2026-02-25

- 仓库：`Jive`
- 分支：`codex/next-batch-stability-core-v3`
- PR：`https://github.com/zensgit/jive/pull/50`
- 最新验证 Head：`4f030baafaf3e884c26e715a095f4cb1042e040b`
- 最新通过 Run：`22354318216`（后续十二次 run 因 Actions budget 阻断）

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

8. `ci(e2e): align sdk preinstall with compileSdk and make optional packages best-effort`（`0aaf069`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - 删除固定旧包预装（`platforms;android-30`、`build-tools;34.0.0`）。
  - 读取 `android/app/build.gradle.kts` 的 `compileSdk`，动态追加：
    - `platforms;android-<compileSdk>`
    - `build-tools;<compileSdk>.0.0`
  - 采用分层安装：
    - mandatory 包失败即失败；
    - compileSdk 相关 optional 包失败仅 warning，不阻断主链路。
- 目的：减少不必要安装并兼顾未来 compileSdk 演进的稳定性。

9. `ci(e2e): initialize summary placeholder and enrich step summary details`（`9c7f369`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - 在 emulator runner 前新增 `Initialize Android integration summary placeholder`，先写入占位 `suite-summary.txt`。
  - Step Summary 增加 `summary_entry` 与 `failed_test` 列表渲染，提升可读性。
- 目的：即使 emulator boot 失败，仍可在 summary 面板看到可解释状态。

10. `ci(e2e): avoid mapfile dependency in step summary parsing`（`5c79ad2`）
- 文件：`.github/workflows/flutter_ci.yml`
- 逻辑：
  - 将 `mapfile` 解析替换为 `while read`，避免 shell 版本差异导致的兼容性风险。
- 目的：提升本地与 CI 脚本行为一致性，降低解析逻辑环境依赖。

11. `ci(e2e): extract integration summary renderer script`（`44df02a`）
- 文件：
  - `scripts/render_integration_summary.sh`
  - `.github/workflows/flutter_ci.yml`
- 逻辑：
  - 将 `Append Android integration summary` 的渲染逻辑抽离到独立脚本。
  - workflow 仅调用脚本并写入 `GITHUB_STEP_SUMMARY`。
- 目的：让 summary 渲染可本地独立回归，降低 workflow 内联脚本复杂度。

12. `ci(e2e): add reusable summary placeholder initializer and local renderer self-check`（`73f422b`）
- 文件：
  - `scripts/init_integration_summary_placeholder.sh`
  - `scripts/test_integration_summary_tools.sh`
  - `.github/workflows/flutter_ci.yml`
- 逻辑：
  - 将占位摘要初始化抽离为复用脚本，workflow 直接调用。
  - 在 `analyze_and_test` 增加 `Validate CI helper scripts`，执行语法检查与本地自检脚本。
  - 自检覆盖 placeholder 初始化与 summary 渲染关键路径。
- 目的：进一步降低 workflow 内联脚本风险，并把摘要链路回归前移到 CI 静态阶段。

13. `ci(e2e): add integration runner smoke self-check`（`10eac1a`）
- 文件：
  - `scripts/test_run_integration_runner_smoke.sh`
  - `.github/workflows/flutter_ci.yml`
- 逻辑：
  - 新增 mock `flutter/adb` smoke 脚本，覆盖 `run_integration_tests.sh` 成功/失败路径与 summary 落盘字段。
  - 在 `Validate CI helper scripts` 增加：
    - `bash -n scripts/run_integration_tests.sh`
    - `bash -n scripts/test_run_integration_runner_smoke.sh`
    - `bash scripts/test_run_integration_runner_smoke.sh`
- 目的：把 integration runner 的关键回归从 emulator 真机链路前移到静态/脚本层，降低预算受限期间的回归盲区。

14. `ci(e2e): add signal smoke self-check for integration runner`（`46a36e0`）
- 文件：
  - `scripts/test_run_integration_runner_signal_smoke.sh`
  - `.github/workflows/flutter_ci.yml`
- 逻辑：
  - 新增 signal smoke 脚本，通过 mock runner 触发 `SIGTERM`，验证 `run_integration_tests.sh` 退出码与摘要落盘一致性。
  - 在 `Validate CI helper scripts` 增加：
    - `bash -n scripts/test_run_integration_runner_signal_smoke.sh`
    - `bash scripts/test_run_integration_runner_signal_smoke.sh`
- 目的：把中断场景从“依赖远端偶发”变成“本地可重复回归”，提升异常退出链路的可信度。

15. `ci(e2e): add args smoke and preflight test-file validation`（`9fdeb48`）
- 文件：
  - `scripts/run_integration_tests.sh`
  - `scripts/test_run_integration_runner_args_smoke.sh`
  - `scripts/test_run_integration_runner_smoke.sh`
  - `scripts/test_run_integration_runner_signal_smoke.sh`
  - `.github/workflows/flutter_ci.yml`
- 逻辑：
  - `run_integration_tests.sh` 在执行前新增 test file 存在性校验，不存在时直接 `exit 2`。
  - 新增参数边界 smoke（invalid retry / missing test file / unknown option）。
  - 修正现有 smoke 使用真实测试文件，避免被 preflight 误判。
  - CI helper 步骤接入 args smoke 语法检查与执行。
- 目的：把参数与输入错误提前暴露，降低“进入 emulator 后才失败”的调试成本。

16. `ci(e2e): consolidate helper script validation entrypoint`（`4f030ba`）
- 文件：
  - `scripts/test_ci_helper_scripts.sh`
  - `.github/workflows/flutter_ci.yml`
- 逻辑：
  - 新增统一 helper 校验入口脚本，集中执行语法检查与四类 smoke。
  - workflow 的 `Validate CI helper scripts` 改为调用单一脚本。
- 目的：降低 workflow 内联维护成本，减少后续新增/调整 helper 时的遗漏风险。

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

### 3.11 compileSdk 对齐 SDK 预装验证

- run `22354318216`（head `0aaf069`）
- 结果：`analyze_and_test` success，`android_integration_test` success（总耗时 `15m04s`）。
- 关键步骤：
  - `Pre-install Android SDK components`：`34s`
  - `Prewarm Android build toolchain`：`171s`
  - `Run Android integration_test (emulator)`：`577s`
  - `Append Android integration summary`：success
  - `Upload Android integration artifacts`：success（步骤不阻断）
- 对比（上一轮 `22348636097`）：
  - `Pre-install`：`53s -> 34s`（下降 `19s`）
  - `android_integration_test` 总时长：`16m30s -> 15m04s`（下降 `86s`）

### 3.12 Actions budget 阻断记录

- run `22377190762`（head `9c7f369`）、run `22377246231`（head `5c79ad2`）、run `22377470427`（head `44df02a`）、run `22379761651`（head `73f422b`）、run `22379833732`（head `f906d26`）、run `22382836852`（head `957f1f8`）、run `22382843780`（head `957f1f8`）、run `22384016101`（head `10eac1a`）、run `22384084422`（head `46a36e0`）、run `22388584445`（head `9fdeb48`）、run `22388638142`（head `6248250`）与 run `22391634299`（head `4f030ba`）
- 现象：
  - 前四次 run 中 `analyze_and_test` 与 `android_integration_test` 均在几秒内结束，job 未启动。
  - 后八次 run（`22379833732`、`22382836852`、`22382843780`、`22384016101`、`22384084422`、`22388584445`、`22388638142`、`22391634299`）均表现为 `analyze_and_test` 因预算阻断失败，`android_integration_test` 因依赖失败被跳过。
- 平台注解：
  - `The job was not started because an Actions budget is preventing further use.`
- 结论：
  - 这是平台预算限制，不是 workflow 逻辑回归。
  - 已完成本地验证（YAML + placeholder 初始化脚本 + summary 渲染脚本 + helper 自检脚本回归），待预算恢复后补一轮远端绿跑即可闭环。

## 4. 结论

1. 继续开发已完成并通过远端完整验证。
2. prewarm best-effort 策略已上线，流程韧性提升（即使 prewarm 异常也不会提前中断）。
3. `Gradle cache + SDK 预安装` 已完成冷缓存与热缓存多轮验证，缓存命中后 prewarm 从 `564s` 稳定到 `174s ~ 178s`。
4. 补齐 `build-tools;35.0.0 + cmake;3.22.1` 后，稳定路径 3-run 已收敛：`15m16s / 15m49s / 15m57s`，关键套件耗时 `7m14s ~ 7m35s`。
5. 手动 emulator 方案在 hosted runner 上稳定性不足，已明确回退到稳定 runner；当前主分支链路恢复并保持全绿。
6. summary 文件落盘、Step Summary 展示、artifact 上传已落地；其中平台配额异常已做非阻断处理。
7. summary 在异常退出场景也可稳定落盘，并可在 CI 页面直接看到结构化结果摘要。
8. SDK 预装已与 `compileSdk` 对齐，并通过 optional 包容错降低版本漂移导致的阻断风险。
9. summary 占位初始化与结构化列表展示已落地，且解析逻辑已去除 `mapfile` 依赖。
10. summary 渲染、占位初始化与本地自检逻辑已抽离为独立脚本，提升了本地可验证性与维护性。
11. 受 Actions budget 限制，最新十二次 run 无法完成远端验证；待预算恢复后补远端验证即可。
12. 下一步优化应在稳定 runner 框架内进行（例如缩短 `Run Android integration_test` 主段业务执行时长），避免高风险替换启动栈。
