# CI 并行开发报告：1+2（Prewarm + Recovery）v5

日期：2026-02-21

- 仓库：`Jive`
- Worktree：`app-next-batch`
- 分支：`codex/next-batch-stability-core-v3`
- PR：`https://github.com/zensgit/jive/pull/50`
- 最新验证 Head：`cbb315152b2460db9d828890a09d77d9d6e2a4ac`
- 最新通过 Run：`22257862912`

## 1. 目标

在 strict-failure 前提下，持续推进并行开发并收敛 Android integration CI：

1. 提升 prewarm/emulator 长尾稳定性。
2. 增强 E2E 页面就绪判定的确定性。
3. 降低 E2E 脚本重复工作与非必要网络依赖。

## 2. 本轮新增并行任务

1. 任务 A：页面就绪哨兵
- 文件：`lib/feature/category/category_transactions_screen.dart`
- 文件：`integration_test/support/e2e_flow_helpers.dart`
- 内容：在交易页引入 `transactions_screen_ready` key，并让 `openAllTransactionsScreen` 以“ready marker/title + filter button”作为就绪判定。

2. 任务 B：脚本执行优化
- 文件：`scripts/run_integration_tests.sh`
- 内容：新增“suite 内一次性 `flutter pub get` + 每次测试 `--no-pub`”模式，避免每个测试重复解析依赖。

## 3. 本轮关键提交

1. `cbb3151` `test(e2e): add transactions-ready sentinel and no-pub suite mode`
- `lib/feature/category/category_transactions_screen.dart`
  - 为交易页主 `Stack` 添加 `Key('transactions_screen_ready')`。
- `integration_test/support/e2e_flow_helpers.dart`
  - `openAllTransactionsScreen` 由“仅标题+filter”升级为“ready marker/title + filter”。
- `scripts/run_integration_tests.sh`
  - 新增参数：
    - `--pub-get-once`（默认开启）
    - `--no-pub-get-once`
    - `--pub-get-timeout <seconds>`
  - 新增环境变量：
    - `FLUTTER_TEST_PUB_GET_ONCE`
    - `FLUTTER_TEST_PUB_GET_TIMEOUT_SECONDS`
  - 启用 `pub-get-once` 时，测试命令自动附带 `--no-pub`。

## 4. 验证时间线（增量）

1. `22257064102`（head `0a67d63`）
- 结论：success
- 作用：验证 prewarm timeout 上调（900 -> 1200）后的稳定性。

2. `22257862912`（head `cbb3151`）
- 结论：success
- `analyze_and_test`: success
- `android_integration_test`: success
- 关键证据：
  - 日志出现：`[integration] running flutter pub get once before integration suite`
  - 两个 integration 用例均 attempt 1 通过
  - timing summary 输出正常

## 5. 最新结果

- Workflow：`https://github.com/zensgit/jive/actions/runs/22257862912`
- 结论：1+2（持续并行开发 + 持续验证）已完成并保持全绿。

## 6. 可观测性（最新 run）

来自 `22257862912`：

1. `integration_test/calendar_date_picker_flow_test.dart: PASS in 7m20s (attempt 1/1)`
2. `integration_test/transaction_search_flow_test.dart: PASS in 1m45s (attempt 1/1)`
3. `suite elapsed: 9m15s`

## 7. 结论

本轮继续开发后，稳定性改动（ready sentinel + pub-get-once/no-pub）已通过远端完整验证并并入 PR，具备继续迭代的稳定基线。
