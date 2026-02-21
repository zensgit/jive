# Jive 并行波次总结（2026-02-21）

## 本批目标
在 `origin/main@5522dcc` 基线上并行完成稳定性与核心体验改造：
- 预算洞察钻取自动化闭环（A）
- 外币消费统计改为真实账户币种（B）
- CI Android E2E runner 稳定化（C）
- 总结与验收文档（D）

## 已交付功能

### A. 预算洞察钻取自动化
- 在预算洞察列表增加稳定定位 key：
  - `budget_top_category_<categoryKey>`
  - `budget_anomaly_day_<yyyyMMdd>`
- 保留未分类行点击提示：`未分类暂不支持快捷钻取`。
- 新增自动化覆盖：
  - `test/budget_manager_screen_test.dart`
  - `integration_test/budget_insight_drilldown_flow_test.dart`
- 扩展 `scripts/verify_dev_flow.sh`：
  - 增加预算钻取断言段
  - 包名自动探测（`auto.dev/dev/auto`）
  - 日期筛选清空路径兼容 filter sheet 与 calendar sheet

### B. 外币消费链路修正
- 新增 `CurrencySpendingAnalyticsService`，将统计逻辑从页面剥离。
- 货币来源规则落地：`expense/income -> account.currency`，缺失回退 `baseCurrency`。
- 外币消费页面移除硬编码 `CNY`，改为服务输出。
- 新增 `test/currency_spending_analytics_service_test.dart`（4 场景）。

### C. CI E2E 稳定化
- 新增 `scripts/run_android_integration_ci.sh` 作为统一 runner。
- `.github/workflows/flutter_ci.yml` 的 `android_integration_test` 改为调用 runner。
- 失败时始终上传 `ci_artifacts/android_integration`。
- 关闭冲突噪音 PR：[#45](https://github.com/zensgit/jive/pull/45)，由 [#51](https://github.com/zensgit/jive/pull/51) 替代。
- 后续修正 [#56](https://github.com/zensgit/jive/pull/56)：
  - 默认执行集降为 `transaction_search_flow`
  - artifact 上传改为 `continue-on-error`（避免配额问题掩盖主失败原因）

## 合并结果（按计划顺序）
1. C -> main: [#51](https://github.com/zensgit/jive/pull/51)（merge commit: `bfaf0fb45116`）
2. B -> main: [#52](https://github.com/zensgit/jive/pull/52)（merge commit: `951c2df6b532`）
3. A -> main: [#53](https://github.com/zensgit/jive/pull/53)（merge commit: `5a35913e911e`）
4. D -> main: [#54](https://github.com/zensgit/jive/pull/54) + [#55](https://github.com/zensgit/jive/pull/55)
5. C follow-up -> main: [#56](https://github.com/zensgit/jive/pull/56)（merge commit: `aaa0419d0e9a`）

## 影响范围
- 预算页：新增测试 key、钻取链路可自动化回归。
- 外币页：统计结果与账户币种一致，避免误用主币。
- CI：Android E2E 具备统一入口、可追溯日志与截图产物。

## 结论
- 本批并行计划 A/B/C/D 已完成开发、验证、PR 与合并。
- 验收证据见：`docs/2026-02-21-parallel-wave-validation.md`。
