# Jive SaaS Beta Mainline Merge 风险清单与推荐策略

> 日期: 2026-04-10
> 集成分支: `codex/saas-beta-mainline`
> 当前 head: `d0e8168`
> 总收口 PR: `#144`

## 结论
当前最快、最稳的 SaaS Beta 收口方式，是把 [#144](https://github.com/zensgit/jive/pull/144) 作为唯一主入口推进到 `main`，而不是继续把 clean PR 队列逐条合并。

推荐原因：
- 当前 clean SaaS 主链已经在同一条集成分支里跑通
- `bash scripts/run_saas_wave0_smoke.sh` 已在这条集成分支上通过
- 在 fresh `origin/main` worktree 本地 merge `origin/codex/saas-beta-mainline` 后，`bash scripts/run_saas_wave0_smoke.sh` 也已通过
- 集成过程中暴露出的两个跨链路 blocker 已经被修掉
- fresh-main merge 演练里额外暴露出的一个时间相关测试夹具问题也已修掉
- 继续逐条合并虽然更细，但会重新引入 queue 管理成本和状态漂移风险

推荐 merge 方式：
- `Create a merge commit`

不推荐：
- `Squash and merge`
  - 会把当前已经整理好的 clean 链路历史压成单点大提交，降低后续审计可读性
- `Rebase and merge`
  - 当前分支已经包含多次有意义的 merge 组装，rebase 价值不高，反而会拉高历史重写成本

## 当前已集成范围

### 基础与文案
- `#139`
- `#142`

### Sync
- `#136`
- `#140`
- `#141`

### Billing webhook
- `#122`
- `#131`

### Billing truth
- `#124`
- `#133`
- `#138`

### Auth
- `#134`
- `#135`

### Ops
- `#127`
- `#128`
- `#129`
- `#130`

## 本轮集成后新增修复
这些修复不是新功能，而是只会在“多链路合并后”暴露出来的集成 blocker。

### 1. Auth test mock 漂移
- 文件: [subscription_lifecycle_gate_test.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/test/subscription_lifecycle_gate_test.dart)
- 问题:
  - `AuthService` 新增 `sendPasswordResetEmail`
  - 老的 fake auth service 没有补实现
  - 导致 integrated smoke 在 auth/billing truth 交界处失败
- 处理:
  - 为 fake service 补 no-op `sendPasswordResetEmail`

### 2. App Store receipt sync test 误触真实 IAP
- 文件: [app_store_payment_service_test.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/test/app_store_payment_service_test.dart)
- 问题:
  - `syncTrustedReceipt` 的测试实例化路径仍会落到 `InAppPurchase.instance`
  - 集成 smoke 中会触发平台通道连接错误
- 处理:
  - 显式注入 `_FakeAppStorePurchaseClient`
  - 同步将修复推回 `saas/b2.5-apple-subscription-verify`

### 3. Ops summary rebase 风险已消化
- 文件: [admin/index.ts](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/supabase/functions/admin/index.ts)
- 问题:
  - `#130` 需要叠在 `#129` 的安全/分页重构之后
  - 直接沿用旧 child diff 会覆盖掉 parent 的安全收口
- 处理:
  - 已将 `#130` 重放到新的 admin parent 上
  - 当前远端 `saas/b5.4-ops-overview` head 为 `e76de2e`

## 主要风险清单

### P1. GitHub PR 队列与集成主线双轨并存
风险描述：
- 当前 GitHub 上仍保留原 clean PR 队列
- 但代码层面已经有一条完整的 `codex/saas-beta-mainline`
- 如果继续同时推进两条路径，容易出现“主线已修，子 PR 还显示旧状态”的认知分裂

影响：
- reviewer 容易重复 review
- 后续 superseded 关系会越来越难维护

建议：
- 将 `#144` 视为最终整合入口
- 原 clean PR 保留为审计材料，但不要再按原计划继续逐条进入 `main`

### P1. migration 顺序已对齐，但还没做真实环境 apply 验证
当前 migration 顺序是：
- `001_create_transactions.sql`
- `002_create_sync_tables.sql`
- `003_create_shared_ledger_tables.sql`
- `004_add_book_key.sql`
- `006_add_sync_tombstones.sql`
- `007_create_user_subscriptions.sql`
- `008_add_sync_keys_for_core_sync.sql`
- `009_webhook_idempotency.sql`
- `010_create_analytics_events.sql`
- `011_create_notification_queue.sql`
- `012_allow_admin_subscription_override.sql`

风险描述：
- 文件编号顺序当前是干净的
- 但这轮主要做的是代码级与 smoke 级验证，不是把 migration 在真实 staging/production DB 上完整 replay 一遍

影响：
- 如果现网数据库状态和本地预期不一致，仍可能在 apply 时出现约束或 backfill 差异

建议：
- 合并 `#144` 后，第一优先级是在 staging 做一次完整 migration apply
- 不建议在 merge 前再回头拆 migration

### P1. `#144` diff 面积较大
风险描述：
- `#144` 汇总了 sync、billing、auth、ops 四大链路
- 虽然链路已经在集成 smoke 上通过，但 reviewer 视觉上会感觉“变更很大”

影响：
- 审核时间变长
- 容易让人本能想退回“继续拆 PR”

建议：
- review 按风险面切，不按文件总数切
- 最值得先看的文件是：
  - [sync_engine.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/lib/core/sync/sync_engine.dart)
  - [subscription_status_service.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/lib/core/payment/subscription_status_service.dart)
  - [app_store_payment_service.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/lib/core/payment/app_store_payment_service.dart)
  - [subscription-webhook/index.ts](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/supabase/functions/subscription-webhook/index.ts)
  - [verify-subscription/index.ts](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/supabase/functions/verify-subscription/index.ts)
  - [admin/index.ts](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/supabase/functions/admin/index.ts)

### P2. 老 PR 的线程上下文不会自动迁移到 `#144`
风险描述：
- 很多 review 讨论还挂在旧 PR 上
- `#144` 是总集成入口，但不会自动带来旧 PR 的 review 线程状态

影响：
- reviewer 可能不知道哪些问题已在集成线解决

建议：
- 在 `#144` 顶部说明里显式保留链路映射
- 如有必要，在旧 PR 留一句 “merged via #144”

### P2. smoke 已通过，但还不是完整发布验证
风险描述：
- `Wave 0 smoke` 覆盖了 sync、billing、auth、ops 的最小回归
- 但它不是完整 release regression

影响：
- 对 Beta 足够
- 对正式广泛上线还不够

建议：
- 把 `#144` 合并目标定义为 “SaaS Beta 主线收口”
- 不要把它当成“所有 SaaS 运营能力全部完工”

## 推荐 merge 策略

### 推荐策略 A：直接推进 `#144`
这是当前最推荐的方案。

步骤：
1. 保持 `#144` 为唯一主入口做 review
2. review 重点只盯高风险链路：
   - sync
   - billing truth
   - billing webhook
   - admin ops summary
3. GitHub 上使用 `Create a merge commit`
4. 合入 `main` 后立刻在 fresh main worktree 重跑：
   - `bash scripts/run_saas_wave0_smoke.sh`
5. 再做 staging migration apply 和最小手工验收

为什么这是最快的：
- 这条线已经过集成验证
- 不需要再维护 parent/child PR 顺序
- 不需要再做一轮 child restack

### 备选策略 B：继续走原 clean PR 队列
这个策略不是错，但已经不是最快路径。

代价：
- 需要继续处理 parent/child 状态
- 需要继续维护 superseded 链路
- 每条 PR 还要重复跑一轮验证
- 容易再次遇到“单条 PR 看不出来、合起来才爆炸”的集成问题

结论：
- 只在你特别希望保留逐条 merge 审计时使用
- 否则不推荐

## merge 前 checklist
- [ ] `#144` 保持以 `main` 为 base
- [ ] `codex/saas-beta-mainline` 与远端一致
- [ ] `bash scripts/run_saas_wave0_smoke.sh` 最近一次结果为通过
- [ ] fresh `origin/main` merge 演练最近一次结果为通过
- [ ] `saas/b2.5-apple-subscription-verify` 已包含 fake App Store client 测试修复
- [ ] `saas/b2.5-apple-subscription-verify` 已包含 Apple active receipt fixture 的 future-proof 修复
- [ ] `saas/b5.4-ops-overview` 已包含新的 admin parent 重放结果
- [ ] reviewer 已知晓旧 PR 只作为审计参考，不再是推荐 merge 主路径

## merge 后第一时间动作
1. 在 fresh `main` worktree 拉最新代码
2. 运行：
   - `bash scripts/run_saas_wave0_smoke.sh`
3. 在具备 Supabase CLI 与 staging 凭据的环境里 apply migrations
4. 部署并核对：
   - `subscription-webhook`
   - `verify-subscription`
   - `analytics`
   - `send-notification`
   - `admin`
5. 核对订阅相关环境变量与 Edge Function 部署顺序
6. 将旧 clean PR 标记为 superseded / merged via `#144`

## 明确 defer
以下内容继续留在 Beta 之后，不建议在 `#144` 合并前扩 scope：
- Apple JWS / 证书链更强校验
- RevenueCat 评估
- admin dashboard UI
- analytics/report UI
- notification outbound delivery/provider 集成
- 任何 E2EE / 密钥管理实现

## 最终建议
如果目标是“尽快 SaaS 化”，当前最优解就是：

**把 `#144` 当成唯一主入口，用 merge commit 合进 `main`，然后在 `main` 上重跑 `Wave 0 smoke` 与 staging migrations。**

继续沿原 PR 队列逐条推进，不会更安全，只会更慢。
