# CI 并行开发报告：1+2（Prewarm + Recovery）v10

日期：2026-02-23

- 仓库：`Jive`
- 分支：`codex/next-batch-stability-core-v3`
- PR：`https://github.com/zensgit/jive/pull/50`
- 最新验证 Head：`247d8200b63becef1eac101b536cd1e7529856ad`
- 最新通过 Run：`22313642147`

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

## 4. 结论

1. 继续开发已完成并通过远端完整验证。
2. prewarm best-effort 策略已上线，流程韧性提升（即使 prewarm 异常也不会提前中断）。
3. `Gradle cache + SDK 预安装` 已完成冷缓存与热缓存双轮验证，缓存命中后 prewarm 从 `564s` 降至 `175s`。
4. 当前关键用例时长在 hosted runner 上仍有波动，但连续多轮均全绿，稳定性达到预期。
