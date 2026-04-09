# Jive SaaS Beta 验证收口

> 日期: 2026-04-09
> 基线: `main@7b9b893`
> 适用范围: 当前 clean SaaS PR 队列

## 目标
把当前 SaaS Beta 的验证入口、PR 顺序、人工步骤和最终验收标准收成一份执行文档。

这份文档不再把旧污染分支当执行入口，而是只围绕当前 clean PR 队列推进。

## 2026-04-10 集成更新

当前已经有一条集成分支把 clean SaaS 主链完整收口：
- 分支: `codex/saas-beta-mainline`
- 当前 head: `0793a2c`

已集成的 clean PR 能力：
- 基础与文案: `#139`、`#142`
- Sync: `#136`、`#140`、`#141`
- Billing webhook: `#122`、`#131`
- Billing truth: `#124`、`#133`、`#138`
- Auth: `#134`、`#135`
- Ops: `#127`、`#128`、`#129`、`#130`

本轮新增的集成 blocker 修复：
- `4ec2f49` `test(saas): fix integrated smoke blockers`
  - `test/subscription_lifecycle_gate_test.dart` 为 `AuthService.sendPasswordResetEmail` 补 no-op fake
  - `test/app_store_payment_service_test.dart` 为 `syncTrustedReceipt` 用例注入 `_FakeAppStorePurchaseClient`
- `#138` 源分支也已补回对应测试修复，当前远端 head 为 `8378e16`
- `#130` rebase 到新的 admin parent 后，当前远端 head 为 `e76de2e`

当前最重要的验证结果：
- `bash scripts/run_saas_wave0_smoke.sh`
  - 在 `codex/saas-beta-mainline` 上已通过
- 这意味着 sync、billing webhook、billing truth、auth、ops analytics、ops notification、ops admin 这 7 组最小回归都已在同一条集成线上同时通过

因此，这份文档下面保留的 PR 队列和 restack 步骤，应该视为 GitHub PR 收口路径；代码层面已经存在一条可工作的集成主线。

## 当前总原则
- 不再开新的功能型 SaaS 分支
- 继续只修 surviving PR 的 review/blocker
- parent PR 先合入 `main`
- child PR 只在父 PR merged 后 restack
- `Wave 0 smoke lane` 作为统一最小回归入口

## 当前 clean PR 队列

### 第一批 parent PR
这些 PR 当前都处于：
- `open`
- `draft`
- `mergeable=true`
- `base=main`

| PR | 作用 | 当前 head |
|---|---|---|
| `#139` | B4.1 文案纠偏 | `6154dd8` |
| `#142` | Wave 0 smoke lane | `19aa9c4` |
| `#122` | Google webhook 主干 | `be22487` |
| `#124` | entitlement lifecycle | `07c5dc3` |
| `#127` | analytics pipeline | `0f328a4` |
| `#128` | notification queue backend | `1e8edd6` |
| `#129` | admin API | `cd78ebf` |
| `#134` | phone + Apple auth entrypoints | `016d927` |
| `#136` | B1.1 book/workspace boundaries | `ade2a7e` |

### 第二批 child PR
这些 PR 目前仍然 stacked 在对应 parent 上，因此在父 PR merged 前不应改 base。

| PR | 依赖 parent | 当前 head | mergeable |
|---|---|---:|---|
| `#131` | `#122` | `e7d24e1` | `false` |
| `#133` | `#124` | `6fd8d7f` | `true` |
| `#138` | `#133` | `c32a04c` | `false` |
| `#130` | `#129` | `a97534e` | `false` |
| `#135` | `#134` | `9ecefc5` | `true` |
| `#140` | `#136` | `4a469fc` | `true` |
| `#141` | `#140` | `a42b388` | `true` |

## 合并与 restack 顺序

### Wave 0：先清最小阻塞项
1. `#139`
2. `#142`

原因：
- `#139` 先收掉错误安全/同步承诺
- `#142` 先把 smoke lane 合进 `main`

### Wave 1：合 parent PR
固定顺序：
1. `#122`
2. `#124`
3. `#127`
4. `#128`
5. `#129`
6. `#134`
7. `#136`

### Wave 2：父 PR merged 后推进 child PR
- `#122` merged 后：推进 `#131`
- `#124` merged 后：推进 `#133`
- `#133` merged 后：推进 `#138`
- `#129` merged 后：推进 `#130`
- `#134` merged 后：推进 `#135`
- `#136` merged 后：推进 `#140`
- `#140` merged 后：推进 `#141`

## 已完成的代码侧收口

### parent PR 已补完的 review-fix
- `#122` `be22487`
  - webhook 初始化、幂等 stale reclaim、plan/entitlement 推导
- `#127` `0f328a4`
  - `invalid_json_body`
  - `invalid_days`
  - summary window 限制
- `#128` `552c853`
  - 队列分批 upsert
  - system notice recipient scope 收紧
- `#128` `1e8edd6`
  - 剩余 `supabase: any` 收成 `SupabaseClient`
- `#129` `0f5798e`
  - origin allowlist
  - constant-time token compare
  - POST body 显式校验
- `#129` `cd78ebf`
  - `adminClient` / auth user 类型收紧
- `#134` `016d927`
  - 手机号登录完成判定
- `#136` `ade2a7e`
  - `SyncBookScope` fallback helper 去重
  - 保留 `sharedLedgerWorkspaceKey(null)` 语义

### child PR 已补完的 review-fix
- `#130` `a97534e`
  - ops summary 的 queue window、retrying 口径、单一 `now`
- `#131` `e7d24e1`
  - Apple webhook typed admin client
  - 批量 identifier lookup
- `#133` `6fd8d7f`
  - App Store restore 等待真实 stream 结果
- `#135` `9ecefc5`
  - 邮箱登录/注册显示具体异常
- `#140` `4a469fc`
  - category/tag 的最小 LWW 保护
  - 缩小 `shared_ledger_members` push 范围
- `#141` `a42b388`
  - tombstone “有 cursor 就记录”
  - 批量删除与 `upsertAll()`

## 统一回归入口

### 最小 smoke lane
当前统一入口是：
- [run_saas_wave0_smoke.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/saas-wave0-smoke-lane/scripts/run_saas_wave0_smoke.sh)

注意：
- 这个脚本当前仍在 `#142`
- 在 `#142` merged 前，它还不是 `main` 的正式入口
- `#142` merged 后，surviving SaaS PR 一律追加跑这条 smoke

### smoke 覆盖范围
- sync
- billing webhook
- billing verify / client truth
- auth
- ops analytics
- ops notification
- ops admin

### smoke 已验证的脚本命令
- `bash -n scripts/run_saas_wave0_smoke.sh`
- `bash scripts/run_saas_wave0_smoke.sh`

## 各链路验证要求

### Sync
PR：
- `#136`
- `#140`
- `#141`

要求：
- Flutter / Dart analyze 通过
- 对应 sync/tombstone tests 通过
- `Wave 0 smoke` 的 sync 组通过

### Billing webhook
PR：
- `#122`
- `#131`

要求：
- `deno check`
- `deno test`
- `Wave 0 smoke` 的 webhook 组通过

### Billing truth
PR：
- `#124`
- `#133`
- `#138`

要求：
- Flutter analyze/test 通过
- `verify-subscription` 的 Deno check/test 通过
- `Wave 0 smoke` 的 billing 组通过

### Auth
PR：
- `#134`
- `#135`

要求：
- Flutter analyze/test 通过
- `Wave 0 smoke` 的 auth 组通过

### Ops
PR：
- `#127`
- `#128`
- `#129`
- `#130`

要求：
- `deno check`
- `deno test`
- `Wave 0 smoke` 的 ops 组通过

## child PR restack 操作卡

### 标准步骤
对每条 child PR，父 PR merged 后执行：
1. `git fetch origin`
2. 在对应独立 worktree 上 `rebase origin/main`
3. `git push --force-with-lease`
4. GitHub UI 将 PR base 改为 `main`
5. 重跑原有定向验证
6. 重跑 `bash scripts/run_saas_wave0_smoke.sh`

### 什么时候允许开 replacement PR
只有一种情况：
- rebase 后 diff 仍然混入无关改动，无法靠 base 变更和 force-push 消掉

除此之外，默认复用现有 child 分支，不再新开 replacement。

## 当前真正的阻塞点
代码侧当前已经基本清完，真正的阻塞已经转移到 GitHub UI。

当前工具限制：
- 不能直接把 PR 从 `draft` 改为 `ready`
- 不能直接修改 PR base
- 不能直接点 merge

因此当前必须人工完成的步骤是：
1. 把 `#139` 转 ready 并 merge
2. 把 `#142` 转 ready 并 merge
3. 依次把 parent PR 转 ready 并 merge
4. 父 PR merged 后，再继续 child restack

## 最终验收标准
- surviving clean SaaS PR 全部 merged 或明确 defer
- `main` 上能跑通 `bash scripts/run_saas_wave0_smoke.sh`
- `docs/codex-saas-tasks.md` 更新为真实 clean PR 链和 defer 列表

## 明确 defer 列表
- Apple JWS / 证书链更强校验
- RevenueCat 评估
- admin dashboard UI
- analytics/report UI
- notification outbound delivery / provider 集成
- 任何 E2EE / 密钥管理实现

## 结论
当前 SaaS Beta 已经不是“能力缺失”，而是“需要把 clean 队列尽快压进 `main`”。

从代码侧看，最该做的加速动作已经不是再开新功能，而是：
- 先清 parent PR
- 再批量 restack child PR
- 最后用 Wave 0 smoke 在 `main` 上做统一验收
