# CI 并行开发报告：1+2（Prewarm + Recovery）v4

日期：2026-02-21

- 仓库：`Jive`
- Worktree：`app-next-batch`
- 分支：`codex/next-batch-stability-core-v3`
- PR：`https://github.com/zensgit/jive/pull/50`
- 最终验证 Head：`0a67d63b51f0574b574145543dbce89434d90dab`
- 最终通过 Run：`22257064102`

## 1. 目标

在 strict-failure 前提下完成 Android integration CI 稳定化，并持续推进下一批并行开发：

1. CI 基础设施稳定（prewarm/emulator/timeout）。
2. E2E 页面就绪与操作时序稳定。
3. 降低测试辅助代码重复并补齐耗时观测。

## 2. 并行任务拆分

1. 任务流 A：CI 稳定化
- 文件：`.github/workflows/flutter_ci.yml`
- 文件：`scripts/run_integration_tests.sh`
- 目标：控制预热与执行预算，吸收 runner 抖动。

2. 任务流 B：E2E 稳定化与复用
- 文件：`integration_test/support/e2e_flow_helpers.dart`
- 文件：`integration_test/calendar_date_picker_flow_test.dart`
- 文件：`integration_test/transaction_search_flow_test.dart`
- 目标：统一就绪哨兵与操作 helper，减少重复并提升可维护性。

## 3. 实施变更（关键提交）

1. `c27dbc0` `test(e2e): retry entering all-transactions screen before filter waits`
- 两个 integration test 引入进入“全部账单”页重试与更长等待窗口。

2. `3d9f3fe` `test(e2e): share readiness helpers and print integration timing summary`
- 新增 `integration_test/support/e2e_flow_helpers.dart`：
  - `pumpUntilSettled`
  - `waitForFinder` / `waitForFinderMaybe`
  - `tapWhenVisible`
  - `dismissAutoPermissionDialogIfPresent`
  - `openAllTransactionsScreen`
  - `selectMonthFromJiveCalendar`
- 两个 integration test 改为复用公共 helper。
- `scripts/run_integration_tests.sh` 新增每个用例与整套执行耗时摘要输出。

3. `0a67d63` `ci(e2e): raise prewarm timeout to tolerate sdk component installs`
- `.github/workflows/flutter_ci.yml`
  - `Prewarm Android build toolchain` 从 `timeout 900` 提升到 `timeout 1200`。

## 4. 时间线与根因映射（本轮新增）

1. `22256824644`（head `3d9f3fe`）失败
- 失败点：`Prewarm Android build toolchain`
- 证据：`Process completed with exit code 124`
- 上下文：prewarm 期间出现 SDK/NDK 组件安装长尾（首次/缓存失效场景）
- 归因：`timeout 900` 对长尾安装窗口不足。

2. `22257064102`（head `0a67d63`）成功
- `analyze_and_test`: success
- `android_integration_test`: success
- prewarm 在新预算内完成，随后 step9 完整通过。

## 5. 最终结果

- Workflow：`https://github.com/zensgit/jive/actions/runs/22257064102`
- 结论：并行开发 1+2（创建 PR + 继续并行研发并验证）已闭环完成。

## 6. 可观测性改进结果

来自 `22257064102` 的脚本摘要日志：

1. `integration_test/calendar_date_picker_flow_test.dart: PASS in 6m41s (attempt 1/1)`
2. `integration_test/transaction_search_flow_test.dart: PASS in 1m49s (attempt 1/1)`
3. `suite elapsed: 8m30s`

## 7. 残余风险与建议

1. Hosted runner 的 SDK 组件安装仍可能带来 prewarm 长尾。
2. 若后续仍出现 prewarm 波动，可考虑显式预装关键 SDK 组件并缓存。
3. 已具备用例级耗时数据，可继续做“慢用例定向优化”。
