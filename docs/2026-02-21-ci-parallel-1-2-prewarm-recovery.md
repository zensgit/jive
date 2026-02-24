# CI 并行开发报告：1+2（Prewarm + Recovery）v13

日期：2026-02-24

- 仓库：`Jive`
- 分支：`codex/next-batch-stability-core-v3`
- PR：`https://github.com/zensgit/jive/pull/50`
- 最新验证 Head：`41b545d53a651339d825f35b8bec48fc9a10d244`
- 最新通过 Run：`22343824918`

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

## 4. 结论

1. 继续开发已完成并通过远端完整验证。
2. prewarm best-effort 策略已上线，流程韧性提升（即使 prewarm 异常也不会提前中断）。
3. `Gradle cache + SDK 预安装` 已完成冷缓存与热缓存多轮验证，缓存命中后 prewarm 从 `564s` 稳定到 `174s ~ 178s`。
4. 补齐 `build-tools;35.0.0 + cmake;3.22.1` 后，稳定路径 3-run 已收敛：`15m16s / 15m49s / 15m57s`，关键套件耗时 `7m14s ~ 7m35s`。
5. 手动 emulator 方案在 hosted runner 上稳定性不足，已明确回退到稳定 runner；当前主分支链路恢复并保持全绿。
6. 最新 head 复验（`22343824918`）已通过，当前状态可在稳定 runner 基线下继续做增量优化。
7. 下一步优化应在稳定 runner 框架内进行（例如缩短 `Run Android integration_test` 主段业务执行时长），避免高风险替换启动栈。
