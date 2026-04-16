# Jive 微信支付 / 支付宝支付接入设计

## 目标
在不破坏当前 SaaS Beta 主线的前提下，为 Jive 增加微信支付与支付宝支付能力，并明确不同分发渠道下的支付边界。

这份设计文档回答 5 个问题：
- 当前主线代码是否已经具备统一支付扩展点
- 微信支付 / 支付宝支付应该接在哪一层
- 哪些渠道可以优先上线国内支付
- 怎样继续保持 `user_subscriptions` 作为唯一权益真相
- 在还没有 Google / Apple 开发者账号时，怎样先做自托管验证

---

## 结论

### 结论 1：技术上可行，而且主线已经具备统一支付入口
当前 clean `main` 已经不是“单一 Google Play 实现”，而是统一支付入口：
- 启动链路使用 [main.dart](../lib/main.dart#L46) 中的 `createPlatformPaymentService(...)`
- 平台支付路由已集中在 [payment_service_factory.dart](../lib/core/payment/payment_service_factory.dart#L9)
- 客户端升级入口已统一通过 [subscription_screen.dart](../lib/feature/subscription/subscription_screen.dart#L12) 调用 `PaymentService.purchase(productId)`
- 服务端订阅真相已经固定读取 [user_subscriptions](../supabase/migrations/007_create_user_subscriptions.sql#L4) 并通过 [supabase_subscription_truth_repository.dart](../lib/core/payment/supabase_subscription_truth_repository.dart#L17) 回流客户端

因此，这次不是“从零加支付系统”，而是在现有统一支付骨架上增加新的 provider 与服务端订单链路。

### 结论 2：产品上必须分渠道，不能把国内支付当成商店支付的统一替代
Jive 当前售卖的是数字功能解锁与 SaaS 订阅，不是线下实物。

推荐边界：
- `自托管 Web`：可直接支持微信支付 / 支付宝
- `Android 直装包 / 企业内测包 / 国内渠道包`：可支持微信支付 / 支付宝
- `Google Play 包`：默认仍使用 Google Play Billing
- `iOS App Store / TestFlight 包`：默认仍使用 Apple IAP
- `桌面自托管分发`：可复用 Web 支付或跳转网页支付

这意味着我们不做“一个支付方式跑所有渠道”，而做“一个权益真相 + 多支付渠道接入”。

### 结论 3：`user_subscriptions` 继续作为唯一权益真相，不引入第二套 entitlement 模型
无论用户通过哪种渠道付款，最后都应归一到同一份订阅真相：
- 统一落表 `user_subscriptions`
- 统一由服务端签名验证 / webhook 回写
- 客户端继续只负责：
  - 发起购买
  - 展示支付中状态
  - 拉取 / 刷新可信权益

客户端本地“支付成功”不能直接发放权益。

### 结论 4：首版已经可以先落“自建单 + mock webhook + pending 权益刷新”骨架
本轮已经把首版最关键的扩展点落到代码里：
- 新增支付 provider / channel 路由，允许在 `directAndroid`、`selfHostedWeb`、`desktopWeb` 渠道启用微信支付 / 支付宝
- 新增国内支付建单客户端与 `WechatPayPaymentService` / `AlipayPaymentService`
- 新增服务端 `create-payment-order` 与 `domestic-payment-webhook` 合同
- 新增 `payment_orders / payment_events` migration，并把 `user_subscriptions.platform` 扩展到 `wechat_pay / alipay`

这意味着现在已经可以先在你自己的服务器上跑“mock 建单 -> pending -> fake webhook -> entitlement 刷新”的闭环，不需要先注册 Google / Apple 开发者账号。

### 结论 5：Claude 的“全平台默认 Drift + Web 启用”变更，会把支付默认渠道问题提前暴露出来
在 [feat/sharing-system-integration](../) 当前最新主线里，Claude 新推进了两次关键平台变更：
- `427f42d` `feat: full Drift migration — Web platform support enabled`
- `695af5b` `feat: default all platforms to Drift (SQLite)`

这两个提交的实际含义是：
- Web 现在不再是“以后再说”的平台，而是已进入真实运行面
- macOS / Windows / Linux 也不应继续被默认视作商店内购环境

因此，国内支付首版必须把“支付运行时渠道选择”显式化，而不能继续让启动链路永远默认掉回商店支付。

---

## 当前代码现实

### 2026-04-12 已落地实现
- 支付路由扩展：
  - [payment_provider_resolver.dart](../lib/core/payment/payment_provider_resolver.dart)
  - [payment_service_factory.dart](../lib/core/payment/payment_service_factory.dart)
  - [payment_runtime_config.dart](../lib/core/payment/payment_runtime_config.dart)
- 国内支付客户端骨架：
  - [domestic_payment_order_client.dart](../lib/core/payment/domestic_payment_order_client.dart)
  - [domestic_payment_service_base.dart](../lib/core/payment/domestic_payment_service_base.dart)
  - [wechat_pay_payment_service.dart](../lib/core/payment/wechat_pay_payment_service.dart)
  - [alipay_payment_service.dart](../lib/core/payment/alipay_payment_service.dart)
- 购买结果语义扩展：
  - [payment_service.dart](../lib/core/payment/payment_service.dart)
  - [subscription_screen.dart](../lib/feature/subscription/subscription_screen.dart)
- 服务端订单 / webhook 骨架：
  - [013_create_domestic_payment_orders.sql](../supabase/migrations/013_create_domestic_payment_orders.sql)
  - [create-payment-order/index.ts](../supabase/functions/create-payment-order/index.ts)
  - [domestic-payment-webhook/index.ts](../supabase/functions/domestic-payment-webhook/index.ts)

### 当前首版语义
- 微信支付 / 支付宝当前返回 `pending`，而不是客户端立即发放权益
- 当前建单函数先返回 mock `redirect_url / qr_code_url`
- webhook 成功后，服务端回写：
  - `payment_orders`
  - `payment_events`
  - `user_subscriptions`
- 客户端订阅页当前已经能识别 `pending` 并提示用户完成支付后刷新权益
- `run_saas_wave0_smoke.sh` 与 `run_saas_staging_rollout.sh` 已纳入国内支付函数与 secrets
- 启动链路会按运行平台推导默认支付渠道：
  - Web -> `selfHostedWeb`
  - macOS / Windows / Linux -> `desktopWeb`
  - Android / iOS -> `auto`
- 支持通过 `dart-define` 覆盖：
  - `PAYMENT_CHANNEL`
  - `ENABLE_STORE_BILLING`
  - `ENABLE_WECHAT_PAY`
  - `ENABLE_ALIPAY`

### 已具备的基础
- 统一支付接口：[payment_service.dart](../lib/core/payment/payment_service.dart)
- 平台路由工厂：[payment_service_factory.dart](../lib/core/payment/payment_service_factory.dart)
- Google Play 实现：[play_store_payment_service.dart](../lib/core/payment/play_store_payment_service.dart)
- App Store 实现：[app_store_payment_service.dart](../lib/core/payment/app_store_payment_service.dart)
- 订阅真相仓库：[supabase_subscription_truth_repository.dart](../lib/core/payment/supabase_subscription_truth_repository.dart)
- 服务端验签入口：
  - [verify-subscription/index.ts](../supabase/functions/verify-subscription/index.ts)
  - [subscription-webhook/index.ts](../supabase/functions/subscription-webhook/index.ts)
- 订阅 UI：[subscription_screen.dart](../lib/feature/subscription/subscription_screen.dart)

### 当前不足
1. `PaymentService.purchase(productId)` 语义偏向“商店内同步购买”，不够表达“先建单，再等待异步回调”的国内支付流程。
2. `user_subscriptions.platform` 目前只允许：
   - `google_play`
   - `apple_app_store`
3. 订阅商品模型 [product_ids.dart](../lib/core/payment/product_ids.dart) 仍然是 IAP 风格，缺少“渠道可售 offer”层。
4. 当前订阅 UI 默认只有直接购买与恢复购买，缺少“选择支付方式”“支付中轮询”“网页/二维码跳转”状态。
5. 设计文档中的商业档位是 `Free / Pro / Family`，但代码档位与计划命名仍偏 `free / paid / subscriber`，需要逐步统一。
6. 当前服务端仍是 mock provider 合同，尚未接入真实微信支付 / 支付宝商户签名、下单与回调验签。

### 仓库内现有“微信 / 支付宝”能力，不等于商户支付
仓库里已经有不少微信 / 支付宝相关代码，但主要是这些方向：
- 账户类型预置：[account_service.dart](../lib/core/service/account_service.dart)
- 导入与 OCR：[import_service.dart](../lib/core/service/import_service.dart)
- 自动识别与通知解析：[payment_notification_parser.dart](../lib/core/service/payment_notification_parser.dart)

这些能力可以帮助我们做“账单导入”和“支付来源识别”，但不能直接替代 SaaS 商户支付接入。

---

## 分发渠道设计

## 1. 自托管 Web
推荐作为第一落地渠道。

原因：
- 不依赖 Apple / Google 开发者账号
- 最容易先打通“建单 -> 支付 -> webhook -> entitlement”完整链路
- 微信支付与支付宝都更适合网页、H5、收银台或二维码场景

推荐体验：
- 用户在 Web 订阅页点击 `升级`
- 服务端创建订单
- 前端展示：
  - 微信二维码 / H5 拉起
  - 支付宝跳转或二维码
- 前端轮询订单状态
- 订单成功后刷新 `user_subscriptions`

## 2. Android 直装包 / 国内渠道包
推荐作为第二落地渠道。

原因：
- 可以直接为中国用户提供熟悉的支付方式
- 不必先进入 Google Play 计费链路

推荐体验：
- 订阅页展示：
  - 微信支付
  - 支付宝
  - 可选的“官网支付”
- 支付服务尝试：
  - 已安装 App 时优先 native/app-scheme 拉起
  - 否则退回 H5 / 网页支付

## 3. Google Play
Beta 阶段保持现状。

推荐策略：
- 继续使用 `PlayStorePaymentService`
- 不在默认 Play 构建里直接替换为微信 / 支付宝
- 若未来要支持 Google alternative billing，再单独加一层渠道策略，不与本次国内支付首版耦合

## 4. iOS App Store / TestFlight
Beta 阶段保持现状。

推荐策略：
- 继续使用 `AppStorePaymentService`
- 国内支付只作为：
  - 自托管 Web 购买入口
  - 或 App Store 之外分发版本能力

这里的核心原则不是“技术做不到”，而是“分发渠道合规与用户体验边界不同”。

---

## 目标架构

```text
SubscriptionScreen
  -> PaymentOptionResolver
  -> PaymentServiceFactory
     -> PlayStorePaymentService
     -> AppStorePaymentService
     -> WechatPayPaymentService
     -> AlipayPaymentService
  -> Supabase Edge Functions
     -> create-payment-order
     -> domestic-payment-webhook
     -> verify-subscription
  -> user_subscriptions
```

### 1. 客户端分层

#### PaymentOptionResolver
新增一个轻量策略层，职责是：
- 根据平台 / 分发渠道 / feature flag 决定要展示哪些支付方式
- 决定某个支付方式是否可用
- 决定默认支付方式排序

建议输入：
- 平台：`web / android / ios / macos / windows / linux`
- 分发渠道：`self_hosted / app_store / google_play / direct_android / enterprise`
- 区域：可选，Beta 先不强依赖定位
- feature flags：
  - `enable_wechat_pay`
  - `enable_alipay`
  - `enable_store_billing`

建议输出：
- `List<PaymentOption>`
- 每个 `PaymentOption` 包含：
  - provider
  - displayName
  - purchaseFlow
  - enabled
  - reasonIfDisabled

#### PaymentServiceFactory
保留现有 [payment_service_factory.dart](../lib/core/payment/payment_service_factory.dart#L9)，但升级为“按渠道路由”，而不是只做 OS 判断。

#### PaymentRuntimeConfig
新增 [payment_runtime_config.dart](../lib/core/payment/payment_runtime_config.dart)，职责是：
- 把平台默认值和 `dart-define` 覆盖统一收口
- 避免 Web / 桌面仍错误回退到商店支付
- 为后续 staging、自托管和渠道构建提供稳定入口

建议新增：
- `PaymentProvider` 枚举：
  - `googlePlay`
  - `appleAppStore`
  - `wechatPay`
  - `alipay`
- `PaymentChannel` 枚举：
  - `appStore`
  - `googlePlay`
  - `selfHostedWeb`
  - `directAndroid`
  - `desktopWeb`

#### PaymentService 接口升级
当前 `PurchaseResult` 只有：
- `success`
- `errorMessage`
- `grantedTier`

这不够表达国内支付里的“待支付 / 已建单 / 等待回调 / 轮询中”。

建议升级为：
- `PurchaseStatus`
  - `success`
  - `pending`
  - `cancelled`
  - `failed`
- `PurchaseResult`
  - `status`
  - `errorMessage`
  - `grantedTier`
  - `orderId`
  - `provider`
  - `redirectUrl`
  - `qrCodeUrl`

这样 `PlayStore` / `AppStore` 仍可直接返回 `success`，而微信 / 支付宝可返回 `pending`。

#### WechatPayPaymentService / AlipayPaymentService
新增两个实现：
- `WechatPayPaymentService`
- `AlipayPaymentService`

职责：
- 请求服务端创建订单
- 拉起 H5 / app-scheme / 二维码支付
- 返回 `pending`
- 在客户端发起短轮询，或引导用户手动刷新
- 由 `SubscriptionStatusService.checkAndSync()` 最终吃到服务端真相

这两个实现不直接持有商户密钥，不在客户端做最终验签。

### 2. 服务端分层

#### 新增 `payment_orders` 表
建议新增表：

```sql
create table public.payment_orders (
  id bigserial primary key,
  order_no text not null unique,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null,
  plan_code text not null,
  status text not null,
  amount_cents integer not null,
  currency text not null default 'CNY',
  product_id text,
  provider_trade_no text,
  client_channel text not null,
  expires_at timestamptz,
  paid_at timestamptz,
  raw_request jsonb not null default '{}'::jsonb,
  raw_response jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

状态建议：
- `created`
- `pending`
- `paid`
- `failed`
- `expired`
- `closed`

#### 新增 `payment_events` 或复用 webhook 幂等表
建议每条 provider 回调都落事件表，便于：
- 幂等控制
- 审计
- 排查支付投诉

最小字段：
- provider
- event_id
- order_no
- provider_trade_no
- event_type
- payload
- processed_at

#### 扩展 `user_subscriptions`
建议把 [007_create_user_subscriptions.sql](../supabase/migrations/007_create_user_subscriptions.sql#L11) 中 `platform` 扩展为：
- `google_play`
- `apple_app_store`
- `wechat_pay`
- `alipay`
- 可选：`admin_override`

同时建议增加：
- `source_order_no`
- `provider_trade_no`

这样 `user_subscriptions` 继续是权益真相，`payment_orders` 则是交易事实。

#### 新增 `create-payment-order`
职责：
- 鉴权当前用户
- 根据 `plan_code` 和 `provider` 计算价格
- 创建 `payment_orders`
- 调用 provider SDK / 网关创建预支付订单
- 返回给客户端：
  - `order_no`
  - `redirect_url`
  - `qr_code_url`
  - `expires_at`

#### 新增 `domestic-payment-webhook`
职责：
- 校验微信支付 / 支付宝回调签名
- 查找并更新 `payment_orders`
- 幂等处理重复回调
- 上行写入 / upsert `user_subscriptions`
- 返回 provider 需要的确认响应

#### 保持 `verify-subscription` 只做可信真相读取与商店验证
不建议把所有支付逻辑都塞进 `verify-subscription`。

推荐边界：
- `verify-subscription`
  - Google / Apple 收据验证
  - 客户端主动拉取可信状态
- `domestic-payment-webhook`
  - 微信 / 支付宝异步支付回调
- `create-payment-order`
  - 建单

---

## 订阅与商品模型设计

### 当前问题
现在 [product_ids.dart](../lib/core/payment/product_ids.dart) 直接把“产品 ID”和“权益档位”绑死在商店商品上：
- `jive_paid_unlock`
- `jive_subscriber_monthly`
- `jive_subscriber_yearly`

这适合 IAP，不适合多支付渠道。

### 建议新增 Offer 层
新增：
- `BillingPlan`
  - `free`
  - `pro_lifetime`
  - `pro_monthly`
  - `pro_yearly`
  - `family_monthly`
  - `family_yearly`
- `PaymentOffer`
  - `offerId`
  - `planCode`
  - `provider`
  - `channel`
  - `displayPrice`
  - `providerProductId`

设计原则：
- `planCode` 是产品定义
- `providerProductId` 是渠道落地映射
- `user_subscriptions.plan` 不再和单一商店商品强耦合

### 档位统一建议
建议逐步从当前：
- `free`
- `paid`
- `subscriber`

迁移到更接近产品文档的业务档位：
- `free`
- `pro`
- `family`

Beta 兼容期可以保持旧值，但新增映射层：
- `paid -> pro_lifetime`
- `subscriber -> pro_subscription`
- 后续再演进 `family`

---

## 订阅 UI 设计

### 当前 UI 基线
[subscription_screen.dart](../lib/feature/subscription/subscription_screen.dart#L21) 已经是统一升级入口。

### 建议改造
首版不重做整页，只做 3 个低风险补强：

#### 1. 价格区改为“方案 + 支付方式”
每个付费卡片下新增：
- `Google Play`
- `App Store`
- `微信支付`
- `支付宝`

其中只展示当前渠道允许的选项。

#### 2. 支付中状态页
新增统一的 pending sheet / page，展示：
- 当前订单号
- 支付方式
- 剩余有效时间
- “已完成支付，刷新权益”
- “改用其他方式支付”

#### 3. 恢复购买逻辑区分 provider
商店渠道保留“恢复购买”。
国内支付渠道改为：
- “查询订单状态”
- “刷新权益”

因为微信 / 支付宝不存在与 IAP 完全等价的 restore 语义。

---

## 推荐落地顺序

## Phase 1：先把国内支付做成“自托管可闭环”
目标：
- 不依赖 Google / Apple 开发者账号
- 先打通真实建单链路

交付：
- `payment_orders`
- `create-payment-order`
- `domestic-payment-webhook`
- `PaymentOptionResolver`
- Web / Android 直装版支付中轮询页

## Phase 2：接微信支付
目标：
- 支持 H5 / 二维码
- 如后续需要，再加 native scheme 唤起

交付：
- `WechatPayPaymentService`
- WeChat provider adapter
- webhook 验签与订单更新

## Phase 3：接支付宝
目标：
- 支持 H5 / 收银台 / 二维码

交付：
- `AlipayPaymentService`
- Alipay provider adapter
- webhook 验签与订单更新

## Phase 4：订阅 UI 补支付方式选择
目标：
- 用户可理解“当前渠道有哪些支付方式”

交付：
- 订阅页 provider picker
- pending / refresh / fallback 状态

## Phase 5：再考虑商店版差异化体验
这一步不是首要目标。

只在下面条件满足后再推进：
- 自托管国内支付链路跑通
- `user_subscriptions` 与订单对账稳定
- 用户开始真实使用

---

## 还没有 Google / Apple 账号时，怎么先跑

可以，完全可以。

推荐做法：
- 先做 `自托管 Web`
- 再做 `Android 直装`
- 先不依赖 Apple / Google 商店收银台

你现在真正需要准备的是：
- HTTPS 可访问域名
- Supabase 项目
- 服务器公网回调地址
- 微信支付 / 支付宝商户资料

如果商户资料也还没准备好，仍然可以先跑：
- mock provider
- admin override entitlement
- fake webhook

先把“订单 -> 真相 -> UI 刷新”链路跑顺，再接真实资金流。

---

## 风险与约束

### 1. 不能让客户端本地成功页直接发权益
否则会破坏当前 SaaS Beta 最重要的“服务端真相”设计。

### 2. 不要把国内支付塞进 `verify-subscription`
否则会把“商店收据验证”和“订单回调处理”混成一团。

### 3. 不要把支付方式判断写死在 OS 上
现在 [payment_service_factory.dart](../lib/core/payment/payment_service_factory.dart#L18) 主要按平台选商店实现，接下来要升级到“平台 + 渠道 + flag”联合判断。

### 4. 微信登录与微信支付是两件不同的事
即使后续要开放微信登录，也不应阻塞微信支付接入。

### 5. 国内支付首版优先 H5 / 二维码，不先赌 native SDK
原因：
- 更容易自托管跑通
- 风险更低
- 便于桌面端 / Web 复用

---

## 明确不做
- 本轮不切 RevenueCat
- 本轮不把微信 / 支付宝接进 App Store 默认收银路径
- 本轮不做独立后台 UI
- 本轮不重写整套 entitlement 模型
- 本轮不把支付问题扩展成微信登录 / 社交绑定总工程

---

## 最小实施清单

### 客户端
- `PaymentProvider` / `PaymentChannel` 枚举
- `PaymentOptionResolver`
- `WechatPayPaymentService`
- `AlipayPaymentService`
- `PurchaseResult` 扩展 `pending` 语义
- 订阅页 provider 选择与支付中状态

### 服务端
- `payment_orders` migration
- `payment_events` 或等价幂等事件表
- `create-payment-order`
- `domestic-payment-webhook`
- `user_subscriptions.platform` 扩展

### 文档
- 渠道矩阵
- 环境变量模板
- 验证清单
- 回滚策略

---

## 推荐下一步
直接进入实现时，建议按下面顺序开工：

1. 先补 SQL 与 Edge Function 合同
2. 再补客户端 provider 枚举和路由策略
3. 再补 WeChat / Alipay 的 pending purchase 流程
4. 最后才改订阅页交互

这样做的好处是：
- 不会先把 UI 做花，再发现服务端合同不够
- 也不会先接 SDK，再发现权益真相落不下来
