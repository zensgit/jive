# Jive SaaS Beta 任务清单 — Codex 执行

## 目标
把当前已经落地的 SaaS Alpha 骨架，收口成“可信、可维护、和现有本地模型对齐”的 SaaS Beta。

这份清单不是继续堆 SaaS 功能，而是优先修正 3 个真实前置问题：
- 数据边界还没统一：`book`、`shared_ledger`、未来 `workspace` 的关系未收口
- 同步模型还没对齐本地多账本数据：本地已有 `bookId`，云端 schema / sync payload 还没跟上
- 订阅可信度还不够：当前 entitlement 仍以客户端本地状态为主

---

## 当前代码现实

### 已有 Alpha 基础
- **Auth**: [supabase_auth_service.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/core/auth/supabase_auth_service.dart)
- **入口门控**: [main.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/main.dart), [jive_app.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/app/jive_app.dart)
- **订阅体系**: `lib/core/entitlement/`
- **支付**: [play_store_payment_service.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/core/payment/play_store_payment_service.dart)
- **同步引擎**: [sync_engine.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/core/sync/sync_engine.dart)
- **Supabase SQL 迁移**: `supabase/migrations/001-003`
- **共享账本**: [shared_ledger_model.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/core/database/shared_ledger_model.dart)

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
- 不顺手做国内支付/广告平台扩展
- 不新增 SaaS 之外的产品功能
- 每个阶段都要有文档、迁移说明和最小必要测试

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
- [sync_engine.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/core/sync/sync_engine.dart)

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
- [subscription_status_service.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/core/payment/subscription_status_service.dart) 是否在启动链路执行
- 购买后是否记录可信状态同步
- restore / expiry / downgrade 是否真实生效

---

## Phase B3：真实登录收口

### Task B3.1：Email 登录可用化
**目标**: 先把最小真实登录跑通

**范围**
- [auth_screen.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/feature/auth/auth_screen.dart)
- [supabase_auth_service.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/core/auth/supabase_auth_service.dart)

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
- [sync_settings_screen.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/feature/settings/sync_settings_screen.dart)
- [subscription_screen.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/feature/subscription/subscription_screen.dart)
- [auth_screen.dart](/Users/chauhua/Documents/GitHub/Jive/app/lib/feature/auth/auth_screen.dart)

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

## 交付要求
- 每个 task 单独 PR 或小批量 PR
- 每个 PR 必须汇报：
  1. 改了哪些文件
  2. 数据边界或行为边界如何变化
  3. 迁移风险
  4. `flutter analyze`
  5. `flutter test`
  6. 哪些问题刻意留到下一阶段

## 当前推荐顺序
1. B0.1
2. B0.2
3. B1.1
4. B1.2
5. B2.1
6. B2.2
7. B2.3
8. B3.1
9. B4.1
10. 其余任务按资源推进
