# Jive SaaS 化任务清单 — Codex 执行

## 项目背景
Jive 积叶是一款 Flutter 个人记账 App，已有完整的本地功能。现需要 SaaS 化以支持订阅变现。

## 已有基础设施
- **Supabase**: URL=`https://evnluvzvbqmsmypbchym.supabase.co`
- **Auth**: `lib/core/auth/supabase_auth_service.dart` — 邮箱/手机/OAuth
- **订阅体系**: `lib/core/entitlement/` — free/paid/subscriber 3 级
- **功能门控**: `lib/core/entitlement/feature_registry.dart` — 22 个功能 FeatureId
- **支付**: `lib/core/payment/play_store_payment_service.dart` — Google Play IAP
- **云同步**: `lib/core/sync/sync_engine.dart` — 7 张表增量同步
- **SQL 迁移**: `supabase/migrations/` — 001-003 已有

---

## Task 1: Supabase Edge Functions — 订阅验证

**文件**: `supabase/functions/verify-subscription/index.ts`

功能:
- 接收 Google Play / App Store 收据
- 验证收据有效性 (Google Play Developer API / App Store Server API)
- 写入 `user_subscriptions` 表: user_id, plan, status, expires_at, receipt
- 返回当前订阅状态给客户端

需要创建的 SQL 表:
```sql
create table public.user_subscriptions (
  id bigserial primary key,
  user_id uuid not null references auth.users(id),
  plan text not null, -- 'paid' | 'subscriber'
  status text not null, -- 'active' | 'expired' | 'cancelled'
  platform text, -- 'google' | 'apple'
  receipt_data text,
  expires_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

---

## Task 2: Webhook — 订阅状态变更

**文件**: `supabase/functions/subscription-webhook/index.ts`

功能:
- 接收 Google Play Real-time Developer Notifications
- 接收 App Store Server Notifications v2
- 解析事件类型 (续费/取消/过期/退款)
- 更新 `user_subscriptions` 表状态
- 触发降级逻辑 (subscriber→free 时清理云数据标记)

---

## Task 3: 用户分析 Edge Function

**文件**: `supabase/functions/analytics/index.ts`

功能:
- `POST /analytics/event` — 记录用户事件 (screen_view, feature_use, purchase)
- `GET /analytics/dashboard` — 返回聚合数据:
  - DAU/MAU
  - 付费转化率
  - 功能使用排行
  - 留存率 (D1/D7/D30)

需要的表:
```sql
create table public.analytics_events (
  id bigserial primary key,
  user_id uuid references auth.users(id),
  event_type text not null,
  event_data jsonb,
  created_at timestamptz default now()
);
```

---

## Task 4: 邮件通知系统

**文件**: `supabase/functions/send-notification/index.ts`

功能:
- 订阅到期前 3 天提醒
- 订阅过期通知
- 新功能上线通知
- 使用 Supabase 内置邮件或 Resend API

需要的表:
```sql
create table public.notification_queue (
  id bigserial primary key,
  user_id uuid references auth.users(id),
  type text not null,
  subject text,
  body text,
  status text default 'pending',
  sent_at timestamptz,
  created_at timestamptz default now()
);
```

---

## Task 5: 管理员 API

**文件**: `supabase/functions/admin/index.ts`

功能:
- `GET /admin/users` — 用户列表 (分页、搜索)
- `GET /admin/users/:id` — 用户详情 (订阅状态、使用统计)
- `POST /admin/users/:id/upgrade` — 手动升级/降级
- `GET /admin/stats` — 总体统计 (用户数、付费率、收入)
- 需要 admin role 验证 (检查 auth.users.raw_app_meta_data.role)

---

## Task 6: RevenueCat 集成 (可选)

如果需要跨平台订阅管理:
- 创建 `supabase/functions/revenuecat-webhook/index.ts`
- RevenueCat webhook → 更新 user_subscriptions
- 客户端用 RevenueCat SDK 替代直接 IAP

---

## 技术栈
- Supabase Edge Functions (Deno/TypeScript)
- PostgreSQL (Supabase 托管)
- Row Level Security (RLS)

## 代码规范
- 每个 function 一个目录
- 包含 `index.ts` + `README.md`
- SQL 迁移放 `supabase/migrations/` 编号递增
- 所有 API 返回 JSON `{ success: boolean, data?: any, error?: string }`
