# CI 并行开发报告：1+2（Prewarm + Recovery）v3 完整闭环

日期：2026-02-21

- 仓库：`Jive`
- Worktree：`app-next-batch`
- 分支：`codex/next-batch-stability-core-v3`
- 最终验证 Head：`c27dbc075d0e3b5d2d787f135eaedfa2c31bf84e`
- 最终通过 Run：`22251591482`

## 1. 目标

在不放松失败语义（strict failure）的前提下，完成 Android integration CI 稳定性收敛：

1. 降低 emulator + Gradle 组合下的基础设施抖动。
2. 修复集成测试中由页面异步加载导致的脆弱等待。
3. 形成可复用的验证记录与证据链。

## 2. 并行任务拆分

1. 任务流 A：CI 基础设施稳定化
- 文件：`.github/workflows/flutter_ci.yml`
- 文件：`scripts/run_integration_tests.sh`
- 目标：控制超时预算、预热构建链路、降低资源竞争、保留必要恢复能力。

2. 任务流 B：E2E 测试稳定化
- 文件：`integration_test/calendar_date_picker_flow_test.dart`
- 文件：`integration_test/transaction_search_flow_test.dart`
- 目标：避免页面未就绪时直接 `tap` 导致的随机失败。

## 3. 实施变更（按提交）

1. `e7c0d44` `ci(e2e): cap retry budget to keep runs within time window`
- `scripts/run_integration_tests.sh`
  - 新增 timeout-recovery rerun 配置：`FLUTTER_TIMEOUT_RECOVERY_RERUNS` / `--timeout-recovery-rerun`（默认 0）。
- `.github/workflows/flutter_ci.yml`
  - 执行参数收敛：`--retry 0 --timeout 720 --timeout-recovery-rerun 0`。

2. `40ca383` `ci(e2e): tune emulator resources and gradle worker pressure`
- `.github/workflows/flutter_ci.yml`
  - Emulator：`cores=4`、`ram=4096M`、`heap=1024M`。
  - Gradle：限制 worker 压力。

3. `56e8d9e` `ci(e2e): remove low heap override from gradle opts`
- `.github/workflows/flutter_ci.yml`
  - 移除导致 prewarm OOM 的低堆上限 `-Xmx2g`，保留 worker 限制。

4. `dd0becc` `test(e2e): wait for home/filter widgets before tapping`
- 两个 integration test 增加 `_waitForFinder` / `_tapWhenVisible`，替换直接 tap。

5. `c27dbc0` `test(e2e): retry entering all-transactions screen before filter waits`
- 两个 integration test 新增 `_openAllTransactionsScreen`。
- 进入“全部账单”页时：
  - 检查页面标题 `全部账单` 与 `transaction_filter_open_button`。
  - 支持最多 2 轮进入重试。
  - 针对 filter 按钮引入更长等待窗口（40s）。

## 4. CI 时间线与根因映射

1. `22250342336`（head `e7c0d44`）失败
- 失败点：`Run Android integration_test (emulator)`
- 证据：`adb: device offline` + `QEMU2 ... hanging thread`
- 归因：emulator 运行时资源竞争。

2. `22250626355`（head `40ca383`）失败
- 失败点：`Prewarm Android build toolchain`
- 证据：`Java heap space`
- 归因：prewarm 阶段 JVM 堆限制过紧。

3. `22250845009`（head `56e8d9e`）失败
- 失败点：`Run Android integration_test (emulator)`
- 证据：`home_view_all_button` finder 未命中
- 归因：UI 时序脆弱。

4. `22251181202`（head `dd0becc`）失败
- 失败点：`Run Android integration_test (emulator)`
- 证据：`Timed out waiting for finder: transaction_filter_open_button`
- 归因：进入“全部账单”后页面未完全就绪，等待窗口与重试策略不足。

5. `22251591482`（head `c27dbc0`）成功
- `analyze_and_test`: success
- `android_integration_test`: success
- 两个 integration 流程均一次通过。

## 5. 最终结果

- Workflow：`https://github.com/zensgit/jive/actions/runs/22251591482`
- 结论：本轮并行开发任务已闭环完成，CI 已恢复全绿。

## 6. 残余风险与后续建议

1. GitHub hosted runner 上 emulator 性能波动仍可能带来偶发长尾。
2. 后续可考虑在 app 中增加轻量“页面 ready sentinel”并在 E2E 统一复用。
3. 如需继续压缩时长，可在保证稳定的前提下评估 prewarm 缓存策略与用例并行拆分。
