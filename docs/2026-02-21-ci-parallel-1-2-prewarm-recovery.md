# CI 并行开发报告：1+2（Prewarm + Recovery）v7

日期：2026-02-23

- 仓库：`Jive`
- 分支：`codex/next-batch-stability-core-v3`
- PR：`https://github.com/zensgit/jive/pull/50`
- 最新验证 Head：`876496a7e2f6a14a629be9505b6892d33b6fd1b2`
- 最新通过 Run：`22307870910`

## 1. 本轮继续开发目标

1. 进一步压缩 Android integration suite 执行时长。
2. 在 strict-failure 前提下移除 CI 中重复 pub 解析路径。

## 2. 本轮新增改动

1. `ci(e2e): skip redundant pub get in emulator execution path`（`876496a`）
- `scripts/run_integration_tests.sh`
  - 新增：`--skip-pub-get` / `--no-skip-pub-get`
  - 新增环境变量：`FLUTTER_TEST_SKIP_PUB_GET`
  - 当启用时，跳过 suite 内 one-time `flutter pub get`。
- `.github/workflows/flutter_ci.yml`
  - prewarm 使用 `flutter build ... --no-pub`
  - emulator 运行脚本增加 `--skip-pub-get`

## 3. 关键验证链路

### 3.1 combined-suite 基线
- Run：`22306626056`
- 结果：success
- 关键数据：`suite elapsed: 9m04s`

### 3.2 skip-pub-get + no-pub
- Run：`22307870910`
- 结果：success
- 关键日志：
  - `[integration] skipping flutter pub get once (requested)`
  - `[integration] combined suite mode enabled (2 files)`
  - `[integration]   - combined_suite(2 files): PASS in 8m49s (attempt 1/1)`
  - `[integration] suite elapsed: 8m49s`
  - `[integration] all integration tests passed`

## 4. 对比结论

1. 分文件模式：`9m15s`（`22257862912`）
2. combined-suite：`9m04s`（`22306626056`）
3. combined-suite + skip-pub-get：`8m49s`（`22307870910`）

结论：本轮继续开发获得持续时长下降，并维持稳定全绿。

## 5. 后续方向

1. 进一步优化 prewarm 长尾（SDK/NDK 组件准备）是下一阶段主要收益点。
2. 可考虑将稳定的 Android E2E 路径拆成 nightly 深测与 PR 轻量烟测组合。
