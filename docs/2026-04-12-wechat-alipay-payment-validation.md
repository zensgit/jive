# Jive 微信支付 / 支付宝支付验证方案

## 目标
验证国内支付接入不会破坏当前 SaaS Beta 主线，并且在“还没有 Google / Apple 开发者账号”的情况下，仍然可以先完成自托管闭环验证。

## 2026-04-12 当前执行结果

### 已完成
- Flutter analyze 已通过：
  - `flutter analyze lib/core/payment/payment_service.dart lib/core/payment/payment_provider_resolver.dart lib/core/payment/payment_service_factory.dart lib/core/payment/domestic_payment_order_client.dart lib/core/payment/domestic_payment_service_base.dart lib/core/payment/wechat_pay_payment_service.dart lib/core/payment/alipay_payment_service.dart lib/feature/subscription/subscription_screen.dart test/payment_service_test.dart test/payment_provider_resolver_test.dart test/payment_service_factory_test.dart test/domestic_payment_service_test.dart`
- Flutter tests 已通过：
  - `flutter test test/payment_service_test.dart test/payment_provider_resolver_test.dart test/payment_service_factory_test.dart test/domestic_payment_service_test.dart`
- `git diff --check` 已通过
- 已新增 mock 国内支付核心测试：
  - [payment_provider_resolver_test.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-wechat-alipay-payment-design/test/payment_provider_resolver_test.dart)
  - [payment_service_factory_test.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-wechat-alipay-payment-design/test/payment_service_factory_test.dart)
  - [payment_service_test.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-wechat-alipay-payment-design/test/payment_service_test.dart)
  - [domestic_payment_service_test.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-wechat-alipay-payment-design/test/domestic_payment_service_test.dart)

### 当前未完成
- 本机未发现可用 `deno`，因此这轮还没有执行：
  - `deno check supabase/functions/create-payment-order/index.ts`
  - `deno check supabase/functions/domestic-payment-webhook/index.ts`
  - `deno test supabase/functions/create-payment-order/index_test.ts`
  - `deno test supabase/functions/domestic-payment-webhook/index_test.ts`
- 尚未在 staging 实际 apply：
  - [013_create_domestic_payment_orders.sql](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-wechat-alipay-payment-design/supabase/migrations/013_create_domestic_payment_orders.sql)
- 尚未接入真实商户配置，因此当前验证仍停留在 mock 建单 / mock webhook 层

---

## 验证范围

本次验证分 4 组：
- `合同验证`
- `客户端验证`
- `服务端验证`
- `自托管验收`

---

## 前置条件分级

### A. 现在就可以做
不依赖 Google / Apple 账号：
- `flutter analyze`
- `flutter test`
- Supabase migration apply
- Edge Function 本地 / staging 部署
- fake webhook 回放
- admin override entitlement
- Web 订阅页与支付中状态联调

### B. 需要真实商户资料
需要你后续准备：
- 微信支付商户号 / API 凭据
- 支付宝应用 ID / 密钥
- HTTPS 回调域名

### C. 当前不是阻塞项
这次国内支付首版不要求：
- Google Play Console
- Apple Developer Program
- App Store Connect 订阅配置

---

## 验证矩阵

| 场景 | Web 自托管 | Android 直装 | Google Play | iOS App Store |
|---|---|---|---|---|
| 微信支付 | 必测 | 必测 | 不在首版范围 | 不在首版范围 |
| 支付宝 | 必测 | 必测 | 不在首版范围 | 不在首版范围 |
| Google Play Billing | 不测 | 不测 | 回归验证 | 回归无关 |
| Apple IAP | 不测 | 不测 | 回归无关 | 回归验证 |

---

## 合同验证

## 1. 数据库 migration
必须验证：
- `payment_orders` 可创建
- `payment_events` 或幂等事件表可创建
- `user_subscriptions.platform` 可扩展到：
  - `wechat_pay`
  - `alipay`
- 订单与订阅可以通过 `order_no` / `provider_trade_no` 关联

检查项：
- migration 编号不冲突
- 回滚脚本清晰
- 索引覆盖：
  - `order_no`
  - `provider + provider_trade_no`
  - `user_id + updated_at`

## 2. Edge Function 合同
必须验证 3 条合同：

### `create-payment-order`
输入：
- `provider`
- `plan_code`
- `client_channel`

输出至少包含：
- `order_no`
- `status`
- `redirect_url` 或 `qr_code_url`
- `expires_at`

### `domestic-payment-webhook`
必须验证：
- 签名错误时拒绝
- 重复回调幂等
- 首次成功回调能写入 `payment_orders`
- 成功后能 upsert `user_subscriptions`

### `verify-subscription`
必须验证：
- 不受国内支付新增逻辑影响
- 仍能读取最新 `user_subscriptions`

---

## 客户端验证

## 1. 支付方式展示
必须验证：
- Web 自托管能看到微信支付 / 支付宝
- Android 直装能看到微信支付 / 支付宝
- Google Play / App Store 默认不出现不允许的国内支付按钮

## 2. 支付中状态
必须验证：
- 建单后进入 pending 状态
- 可以显示订单号与剩余时间
- 可以手动刷新权益
- 可以切换到其他支付方式

## 3. 成功后的权益刷新
必须验证：
- webhook 回写后，客户端刷新 `SubscriptionStatusService`
- 订阅页与权益门控同步变化
- 重启 App 后仍可从 `user_subscriptions` 拉回正确状态

## 4. 失败与取消
必须验证：
- 用户取消支付不发放权益
- 订单过期不发放权益
- provider 返回失败时有可读错误提示

---

## 服务端验证

## 1. 订单状态机
必须验证：
- `created -> pending -> paid`
- `created -> pending -> failed`
- `created -> pending -> expired`

## 2. 幂等
必须验证：
- 同一 webhook 回调 2 次，不重复发放权益
- 同一订单号重复查询，不会生成多条订阅记录

## 3. 对账
必须验证：
- `payment_orders.status = paid`
- `user_subscriptions.status = active`
- `provider_trade_no` 一致
- `plan_code` / `plan` 映射一致

---

## 自托管最小验收

## 1. 无商户号阶段
使用 mock provider：

步骤：
1. 用户进入订阅页
2. 选择微信支付或支付宝
3. `create-payment-order` 返回 fake order
4. 人工回放 fake webhook
5. 客户端点击“刷新权益”
6. 订阅状态成功升级

通过标准：
- 整条链路不依赖 Apple / Google
- UI、订单、权益都能闭环

当前代码已经满足这条验收的实现前提：
- 客户端可返回 `pending`
- 服务端可创建 mock order
- webhook 可回写 `user_subscriptions`
- 权益真相仍统一收口到现有订阅链路

## 2. 有真实商户资料阶段
步骤：
1. 创建真实订单
2. 用沙箱或真实小额支付完成付款
3. webhook 成功回调
4. `payment_orders` 更新为 `paid`
5. `user_subscriptions` 更新为对应档位
6. 客户端刷新后看到升级成功

通过标准：
- 不需要人工改库
- 不需要手工补 entitlement

---

## 回归验证

新增国内支付后，必须回归下面 4 组现有能力：

### 1. 订阅真相回归
- `user_subscriptions` 读取正常
- 旧的 Google / Apple 记录不受影响

### 2. 启动链路回归
- [main.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-wechat-alipay-payment-design/lib/main.dart#L46) 中支付服务初始化正常
- `SubscriptionStatusService.checkAndSync()` 不因新 provider 崩溃

### 3. 订阅页回归
- [subscription_screen.dart](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-wechat-alipay-payment-design/lib/feature/subscription/subscription_screen.dart#L21) 仍可打开
- 商店渠道仍可购买 / 恢复

### 4. SaaS 主线回归
- 现有 `run_saas_wave0_smoke.sh` 通过
- 至少补一组“国内支付 mock 不影响主线”的测试

---

## 推荐测试清单

### 自动化
- Flutter:
  - `flutter analyze`
  - `flutter test test/core/payment/...`
  - `flutter test test/feature/subscription/...`
- Deno / Supabase:
  - `deno check supabase/functions/create-payment-order/index.ts`
  - `deno check supabase/functions/domestic-payment-webhook/index.ts`
  - `deno test supabase/functions/...`

### 手工
- Web 自托管订阅页
- Android 直装包支付拉起
- fake webhook 回放
- entitlement 刷新
- 重启后权益保持

---

## 推荐实施前检查单

- 已有 staging Supabase 项目
- 已有 HTTPS 域名
- 已明确订单号生成规则
- 已明确 `plan_code -> amount -> provider product` 映射
- 已决定首版先做 H5 / 二维码，而不是 native SDK
- 已确认本轮不改 App Store / Google Play 默认支付路径

---

## 验收标准

满足下面条件，就可以认定“国内支付接入具备首版落地条件”：
- 自托管 Web 上可完成 mock 闭环
- `payment_orders` 与 `user_subscriptions` 可稳定联动
- 客户端出现支付中、成功、失败三种可理解状态
- 新逻辑不破坏现有 Google / Apple 订阅链路
- 不依赖 Google / Apple 账号也能先跑起来

---

## 推荐下一步
按优先级执行：

1. 先做 `payment_orders` migration
2. 再做 `create-payment-order`
3. 再做 `domestic-payment-webhook`
4. 再做客户端 `pending` 状态与 provider 选择
5. 最后接真实商户资料

这样最快，也最不容易把支付做成一锅粥。
