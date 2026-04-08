# B5.1 Analytics Foundation

## 本次交付
- 新增 `public.analytics_events` 表，用于承接客户端和游客事件上报。
- 新增 `supabase/functions/analytics/index.ts`，提供：
  - `POST` 事件写入
  - `GET` 管理侧汇总摘要
- 新增 `supabase/functions/analytics/index_test.ts`，覆盖事件名归一化与摘要聚合逻辑。

## 事件表设计
- `user_id`：已登录用户
- `device_id`：游客或匿名设备标识
- `event_name` / `event_group`：事件名与分组
- `platform` / `app_version`：客户端上下文
- `properties`：可扩展事件属性
- `occurred_at` / `occurred_on`：精确时间与 UTC 日期

## 摘要输出
- `DAU / MAU`
- 近窗口事件总量与去重 actor 数
- 两条基础转化漏斗：
  - `auth_screen_viewed -> auth_signed_in`
  - `subscription_purchase_started -> subscription_purchase_completed`
- 留存 cohort：
  - `D1`
  - `D7`
  - `D30`

## 管理侧访问
- `GET /analytics` 需要 `ANALYTICS_ADMIN_TOKEN`
- 目前是最小可用版本，适合运营或内部脚本调用

## 本次刻意不做
- App 内埋点 SDK 或自动事件上报
- 图表后台或仪表盘页面
- 管理员用户体系
- 通知联动

## 验证
- `npx -y deno-bin@2.2.7 check supabase/functions/analytics/index.ts supabase/functions/analytics/index_test.ts`
- `npx -y deno-bin@2.2.7 test supabase/functions/analytics/index_test.ts`
