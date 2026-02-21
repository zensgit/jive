# Jive 并行波次验收记录（2026-02-21）

## 1) 分支 / PR / 提交对照

| Stream | Branch | PR | 分支提交 | 合并提交 | 状态 |
|---|---|---|---|---|---|
| C CI E2E 稳定化 | `codex/parallel-ci-e2e-stabilize` | [#51](https://github.com/zensgit/jive/pull/51) | `48ce281` | `bfaf0fb45116` | MERGED |
| B 外币统计真实币种 | `codex/parallel-currency-spending-source` | [#52](https://github.com/zensgit/jive/pull/52) | `5c60130` | `951c2df6b532` | MERGED |
| A 预算钻取自动化 | `codex/parallel-budget-drilldown-e2e` | [#53](https://github.com/zensgit/jive/pull/53) | `ef3f33f` | `5a35913e911e` | MERGED |
| D 报告与验收文档 | `codex/parallel-release-reporting` | 待创建 | (this branch) | - | IN PROGRESS |

## 2) 命令与结果

### Stream A（预算钻取）

- `flutter analyze --no-fatal-infos` -> PASS（No issues found）
- `flutter test test/budget_manager_screen_test.dart` -> PASS（3 tests）
- `flutter test integration_test/budget_insight_drilldown_flow_test.dart --flavor dev --dart-define=JIVE_E2E=true -d EP0110MZ0BC110087W` -> PASS（1 test）
- `bash scripts/verify_dev_flow.sh` -> PASS（预算空数据场景记录 skip，其他断言链路通过）

### Stream B（外币统计）

- `dart format lib/core/service/currency_spending_analytics_service.dart lib/feature/currency/foreign_currency_spending_screen.dart test/currency_spending_analytics_service_test.dart` -> PASS
- `flutter analyze --no-fatal-infos` -> PASS（No issues found）
- `flutter test test/currency_spending_analytics_service_test.dart` -> PASS（4 tests）

### Stream C（CI runner）

- `bash -n scripts/run_android_integration_ci.sh` -> PASS
- `grep -n "run_android_integration_ci.sh\|upload-artifact\|android_integration_test\|run_android_e2e\|contains(github.event.pull_request.labels" .github/workflows/flutter_ci.yml` -> PASS（命中关键门控与调用）
- `CI_ARTIFACT_DIR=/tmp/jive-ci-dry-run bash scripts/run_android_integration_ci.sh __missing_case__` -> PASS（预期 exit=2，参数校验生效）
- `ANDROID_DEVICE_SERIAL=EP0110MZ0BC110087W CI_ARTIFACT_DIR=/tmp/jive-ci-local-run bash scripts/run_android_integration_ci.sh transaction_search_flow` -> PASS

## 3) 产物与证据

### 本地产物
- ADB 全链路脚本产物：`/tmp/jive-verify-20260221-214755`
- CI runner 本地 dry-run 产物：`/tmp/jive-ci-dry-run`
- CI runner 本地真机执行产物：`/tmp/jive-ci-local-run`

### GitHub Actions 运行
- PR #51（analyze_and_test success, android_integration_test skipped by gate）：
  - [Run 22258101873](https://github.com/zensgit/jive/actions/runs/22258101873)
- PR #52（analyze_and_test success, android_integration_test skipped by gate）：
  - [Run 22258107732](https://github.com/zensgit/jive/actions/runs/22258107732)
- PR #53（analyze_and_test success, android_integration_test skipped by gate）：
  - [Run 22258115538](https://github.com/zensgit/jive/actions/runs/22258115538)
- workflow_dispatch（手动触发 Android E2E）：
  - [Run 22258144671](https://github.com/zensgit/jive/actions/runs/22258144671)

## 4) 已知风险与后续项

1. **预算钻取脚本在空预算库场景无法执行真实钻取**
   - 现状：脚本识别空数据后记 `skip`，避免误报失败。
   - 后续：补一个“预算测试数据注入”脚本步骤，确保每次都能执行钻取断言。

2. **workflow_dispatch 的 Android E2E 运行时间较长**
   - 现状：已通过本地 runner 真机执行验证；CI 采用 artifact 化输出便于定位。
   - 后续：按需拆分 integration case 或降低默认执行集，缩短 job 时长。

3. **macOS 本地无 `timeout`/`gtimeout` 时无超时保护**
   - 现状：runner 降级为无 timeout 模式，但保持真实退出码与产物收集。
   - 后续：在本地开发环境补装 `coreutils`（`gtimeout`）可获得一致行为。

## 5) 验收结论

- 计划中的 A/B/C 功能已完成开发、验证、PR、合并。
- 阶段文档已交付：
  - `docs/2026-02-21-budget-drilldown-e2e.md`
  - `docs/2026-02-21-currency-spending-account-currency.md`
  - `docs/2026-02-21-ci-e2e-stabilize.md`
- 本文档 + `docs/2026-02-21-parallel-wave-summary.md` 组成本批总验收交付。
