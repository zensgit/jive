# Jive SaaS Beta 任务清单 — Codex 执行

## 目标
把当前已经落地的 SaaS Alpha 骨架，收口成“可信、可维护、和现有本地模型对齐”的 SaaS Beta。

这份清单不是继续堆 SaaS 功能，而是优先修正 3 个真实前置问题：
- 数据边界还没统一：`book`、`shared_ledger`、未来 `workspace` 的关系未收口
- 同步模型还没对齐本地多账本数据：本地已有 `bookId`，云端 schema / sync payload 还没跟上
- 订阅可信度还不够：当前 entitlement 仍以客户端本地状态为主

---

## 2026-04-09 执行更新

当前不再从旧污染分支继续派生新工作，统一以 clean PR 队列作为 SaaS 主线。

### 当前 parent PR 主链
这些 PR 当前都以 `main` 为 base，是 SaaS Beta 的正式收口入口：
- `#139` B4.1 同步安全/文案纠偏
- `#142` Wave 0 smoke lane
- `#122` Google subscription webhook
- `#124` entitlement lifecycle
- `#127` analytics pipeline
- `#128` notification queue backend
- `#129` admin API
- `#134` phone + Apple auth entrypoints
- `#136` B1.1 book/workspace boundaries

### 当前 child PR 链
这些 PR 只在父 PR merged 后推进，不再新开 replacement：
- `#122 -> #131`
- `#124 -> #133 -> #138`
- `#129 -> #130`
- `#134 -> #135`
- `#136 -> #140 -> #141`

### 当前明确 defer
- Apple JWS / 证书链更强校验
- RevenueCat 评估
- admin dashboard UI
- analytics/report UI
- notification outbound delivery / provider 集成
- 任何 E2EE / 密钥管理实现

## 2026-04-10 集成更新

当前 clean SaaS 主链已经完整集成到一条独立分支：
- 分支: `codex/saas-beta-mainline`
- head: `d0e8168`

已集成范围：
- 基础与文案: `#139`、`#142`
- Sync: `#136`、`#140`、`#141`
- Billing webhook: `#122`、`#131`
- Billing truth: `#124`、`#133`、`#138`
- Auth: `#134`、`#135`
- Ops: `#127`、`#128`、`#129`、`#130`

已完成的额外收口：
- `#130` 已重放到新的 admin parent 上，远端 head 为 `e76de2e`
- `#138` 已补 App Store fake client 测试注入与 Apple active receipt fixture future-proof 修复，远端 head 为 `f80ecab`
- 集成线额外提交 `4ec2f49`，修掉只会在多链路合并后暴露的 smoke blockers
- 集成线额外提交 `d0e8168`，修掉 fresh-main merge 演练里暴露的时间相关测试夹具过期问题

当前最快的 Beta 收口路径已经变化：
1. 继续保留现有 PR 作为 review/审计入口
2. 以 `codex/saas-beta-mainline` 作为代码集成主线
3. 用 `bash scripts/run_saas_wave0_smoke.sh` 作为统一最小验收入口

当前已通过的统一验收：
- `bash scripts/run_saas_wave0_smoke.sh` 在 `codex/saas-beta-mainline` 上通过
- fresh `origin/main` worktree 本地 merge `origin/codex/saas-beta-mainline` 后，`bash scripts/run_saas_wave0_smoke.sh` 也通过

因此，剩余工作不再是继续扩功能，而是二选一：
- 继续按现有 PR 队列在 GitHub UI 逐条合并
- 或以 `codex/saas-beta-mainline` 为新的快速收口入口，统一 review 后并入 `main`

---

## 当前代码现实

### 已有 Alpha 基础
- **Auth**: [supabase_auth_service.dart](../lib/core/auth/supabase_auth_service.dart)
- **入口门控**: [main.dart](../lib/main.dart), [jive_app.dart](../lib/app/jive_app.dart)
- **订阅体系**: `lib/core/entitlement/`
- **支付**: [play_store_payment_service.dart](../lib/core/payment/play_store_payment_service.dart)
- **同步引擎**: [sync_engine.dart](../lib/core/sync/sync_engine.dart)
- **Supabase SQL 迁移**: `supabase/migrations/001-003`
- **共享账本**: [shared_ledger_model.dart](../lib/core/database/shared_ledger_model.dart)

### 已确认的 Beta 阻塞
- 本地 `transactions/accounts/budgets` 已有 `bookId`，但当前同步 payload 和 SQL schema 没有对应的 `book_id/book_key/workspace_key`
- 当前同步仍 heavily 依赖 `local_id`
- entitlement 仍由本地 `SharedPreferences` 缓存并直接生效
- `shared_ledger` 已存在，但和 `book` 的长期关系还没定清

---

## 执行原则
- 先修边界，再修可信度，最后再补运营能力
- 每个任务做成小 PR，不跨阶段扩 scope
- 不顺手做 Web 端
- 不新增 SaaS 之外的产品功能
- 每个阶段都要有文档、迁移说明和最小必要测试

## 2026-04-12 增补：国内支付接入主线

SaaS Beta 主线已经进入“上线后补可用支付渠道”的阶段，微信支付 / 支付宝接入改为单独主线推进。

本轮决策：
- 支持微信支付 / 支付宝
- 优先渠道：`自托管 Web + Android 直装 / 国内渠道包`
- `Google Play / App Store` 继续保持各自商店支付主链
- `user_subscriptions` 继续作为唯一权益真相
- 不把国内支付塞进现有 `verify-subscription` 商店验签链路

执行文档：
- [2026-04-12-wechat-alipay-payment-design.md](2026-04-12-wechat-alipay-payment-design.md)
- [2026-04-12-wechat-alipay-payment-validation.md](2026-04-12-wechat-alipay-payment-validation.md)

当前实现入口：
- PR: `#147`
- 分支: `codex/wechat-alipay-payment-design`
- 已落地骨架：
  - provider/channel 路由扩展
  - `PaymentRuntimeConfig` 平台/构建渠道收口
  - `WechatPayPaymentService` / `AlipayPaymentService`
  - `create-payment-order` / `domestic-payment-webhook`
  - `payment_orders` / `payment_events` migration
  - 订阅页 `pending` 购买提示

新增任务边界：
- 允许新增 `payment_orders`
- 允许新增国内支付 webhook / 建单函数
- 允许新增 `WechatPayPaymentService` / `AlipayPaymentService`
- 允许改造订阅页支付方式选择
- 不切 RevenueCat
- 不把国内支付作为 App Store / Google Play 默认替代

---

## Phase B0：边界设计与模型收口

### Task B0.1：定义 `book / shared_ledger / workspace`
**目标**: 给 SaaS 的主数据边界定规矩

**输出**
- 新增设计文档：`docs/saas-beta-boundaries.md`

**必须明确**
- `book` 是否就是 workspace 起点
- `shared_ledger` 是独立实体，还是 `book` 的共享协作层
- 单用户账本和家庭共享账本是否使用统一的 workspace/book 边界
- 哪些模型必须携带 `bookKey` 或 `workspaceKey`

**验收**
- 可以直接指导 sync schema 改造
- 不再允许 `book` 与 `shared_ledger` 各自扩张但关系不清

### Task B0.2：定义稳定云端标识
**目标**: 不再长期依赖本地 Isar `int` 自增 ID

**必须明确**
- 哪些模型使用 `key` 作为稳定标识
- 哪些模型需要新增 `remoteId` / `syncKey`
- 哪些外键不能继续直接传本地 `accountId/bookId`

**首批必须覆盖**
- transactions
- accounts
- budgets
- books
- shared_ledgers

---

## Phase B1：同步模型对齐当前本地数据

### Task B1.1：Schema 补齐账本/工作空间边界
**目标**: 让 Supabase schema 至少对齐当前多账本本地模型

**涉及**
- `supabase/migrations/`
- [sync_engine.dart](../lib/core/sync/sync_engine.dart)

**必须处理**
- transactions 增加 `book_key` 或等价字段
- accounts 增加 `book_key` 或等价字段
- budgets 增加 `book_key` 或等价字段
- 如需要，增加 `workspace_key`
- 增加相应索引与 RLS 约束

**禁止**
- 只改 Dart，不改 SQL
- 继续把多账本数据同步成“用户级平铺数据”

### Task B1.2：同步 payload 去本地 ID 中心化
**目标**: 降低 `local_id` 在云端模型中的中心地位

**必须处理**
- 审视 `upsert(user_id, local_id)` 是否继续保留
- 为跨设备稳定关联引入业务 key / 云端 key
- 避免账户、预算、交易长期通过本地 int ID 关联

**最小验收**
- 至少一类核心对象不再只依赖 `local_id`
- 有迁移脚本或兼容策略

### Task B1.3：删除与冲突策略升级
**目标**: 让同步能长期工作，而不是只适合“新增/覆盖”

**建议补齐**
- `deleted_at` / tombstone 策略
- per-table 或 per-workspace cursor 策略
- 共享账本冲突边界

---

## Phase B2：订阅可信化

### Task B2.1：服务端订阅真相
**目标**: entitlement 不再只由客户端本地状态决定

**输出**
- `user_subscriptions` 表
- `verify-subscription` Edge Function

**表建议**
```sql
create table public.user_subscriptions (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  plan text not null,
  status text not null,
  platform text,
  receipt_data text,
  expires_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

**必须处理**
- Google Play 收据验证
- 至少预留 Apple 扩展位
- entitlement 读取“可信来源 + 本地缓存”

### Task B2.2：Webhook 状态同步
**目标**: 订阅续费、取消、过期不依赖客户端上线才生效

**输出**
- `subscription-webhook` Edge Function

**处理范围**
- Google RTDN
- App Store Server Notifications v2
- subscriber 过期降级

### Task B2.3：客户端接线
**目标**: 把订阅可信链路真正接到 App 生命周期

**必须核对**
- [subscription_status_service.dart](../lib/core/payment/subscription_status_service.dart) 是否在启动链路执行
- 购买后是否记录可信状态同步
- restore / expiry / downgrade 是否真实生效

---

## Phase B3：真实登录收口

### Task B3.1：Email 登录可用化
**目标**: 先把最小真实登录跑通

**范围**
- [auth_screen.dart](../lib/feature/auth/auth_screen.dart)
- [supabase_auth_service.dart](../lib/core/auth/supabase_auth_service.dart)

**必须处理**
- 邮箱注册
- 邮箱登录
- 错误反馈
- 游客模式边界

### Task B3.2：Phone / OAuth 逐项接入
**目标**: 不并行铺开所有登录方式

**顺序建议**
1. Phone OTP
2. Google
3. Apple
4. 微信单独立项

**禁止**
- 在配置和验证都不到位时把按钮当成已支持能力对外承诺

---

## Phase B4：安全与文案收口

### Task B4.1：同步安全表述核对
**目标**: 页面文案与实际实现一致

**必须检查**
- [sync_settings_screen.dart](../lib/feature/settings/sync_settings_screen.dart)
- [subscription_screen.dart](../lib/feature/subscription/subscription_screen.dart)
- [auth_screen.dart](../lib/feature/auth/auth_screen.dart)

**当前已知风险**
- `SyncSettingsScreen` 提到“端到端加密”，需要核实是否真的存在端侧加解密与密钥管理

### Task B4.2：安全能力补齐或降级文案
**目标**: 二选一

**选项**
- 真做端侧加密与密钥管理
- 或先把文案改成真实、保守的表述

---

## Phase B5：运营能力

这一阶段后置，只有在 B0-B4 收口后才开始。

### Task B5.1：Analytics
**文件**: `supabase/functions/analytics/index.ts`

**功能**
- 事件上报
- DAU / MAU
- 转化率
- 留存

### Task B5.2：通知系统
**文件**: `supabase/functions/send-notification/index.ts`

**功能**
- 到期提醒
- 过期通知
- 关键系统通知

### Task B5.3：管理员 API
**文件**: `supabase/functions/admin/index.ts`

**功能**
- 用户列表
- 用户详情
- 手动升级/降级
- 汇总统计

---

## RevenueCat 策略

### 可选 Task RC1：评估是否接 RevenueCat
**建议**
- 如果短期只做 Android Google Play，可先不切
- 如果计划快速支持 iOS + Android + 多商店，尽早评估 RevenueCat，避免先自建完整验票体系再重做

---

## Git 工作流规范

### 当前执行入口
旧的 `saas/b1.1-sync-schema-book-key`、`saas/b1.2-remove-local-id-dependency`、`saas/b1.3-delete-tombstone-strategy` 等分支名只保留历史参考意义，不再作为执行入口。

当前统一规则：
- 以 clean PR 队列作为 SaaS 主线
- parent PR 直接基于 `main`
- child PR 只在父 PR merged 后 rebase 到 `main`
- 队列缩到 3 个以内前，不再开新的功能型 SaaS 分支

当前活跃执行分支示例：
```
saas/b4.1-sync-copy-audit-restacked
saas/wave0-smoke-lane
saas/b2.2-subscription-webhook
saas/b2.3-client-entitlement-wiring
saas/b5.1-analytics
saas/b5.2-notifications
saas/b5.3-admin-api
saas/b3.2-phone-and-apple-auth-restacked
saas/b1.1-book-key-boundaries-restacked
```

### 工作流程
1. **parent PR 一律从 `main` 创建**
2. **child PR 只在明确依赖 parent 时才允许 stacked**
3. **parent merged 后，child 统一 `rebase origin/main` 并 force-push**
4. **不要继续从旧污染 worktree 派生新功能**
5. **只有 review/blocker 修复和必要 restack 才允许新增提交**

### 冲突预防
- Codex 主要修改: `supabase/`, `lib/core/sync/`, `lib/core/entitlement/`, `lib/core/auth/`
- Claude 主要修改: `lib/feature/`, `lib/core/service/`, `lib/core/design_system/`, `test/`
- 共同可能修改: `lib/core/database/`, `lib/main.dart` — 这些文件改动前先 pull 最新 main

### Worktree 建议（可选）
如果需要并行开发多个 task:
```bash
git worktree add ../jive-saas-b0.2 -b saas/b0.2-stable-cloud-ids main
git worktree add ../jive-saas-b1.1 -b saas/b1.1-sync-schema-book-key main
```

---

## 交付要求
- 每个 task 单独 PR
- 每个 PR 必须汇报：
  1. 改了哪些文件
  2. 数据边界或行为边界如何变化
  3. 迁移风险
  4. `flutter analyze` 结果
  5. `flutter test` 结果
  6. 哪些问题刻意留到下一阶段
- PR 标题格式: `B{phase}.{task}: {简要描述}`
- PR body 包含 checklist:
  ```
  - [ ] flutter analyze 0 errors
  - [ ] flutter test 全部通过
  - [ ] SQL 迁移已测试
  - [ ] 向后兼容（不破坏现有本地数据）
  ```

---

## 当前推荐顺序
1. `#139`
2. `#142`
3. `#122`
4. `#124`
5. `#127`
6. `#128`
7. `#129`
8. `#134`
9. `#136`
10. `#131`
11. `#133`
12. `#138`
13. `#130`
14. `#135`
15. `#140`
16. `#141`

### 备注
- `#139` 和 `#142` 是当前最小阻塞项，必须先进入 `main`
- parent PR 合并后，再继续各自 child restack
- 队列压缩完成前，不再开新的功能型 SaaS 分支
