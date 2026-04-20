# 2026-04-20 国内支付 Checkout 体验闭环开发与验证报告

## 背景

PR #147 已经把微信支付 / 支付宝的基础骨架合并到 `main`，但 checkout 层仍有两个体验缺口：

- 当 `ENABLE_WECHAT_PAY=true` 与 `ENABLE_ALIPAY=true` 同时开启时，支付工厂只取第一个 provider，用户无法选择微信或支付宝。
- 国内支付建单后进入 `pending`，弹窗只提示用户稍后“恢复购买”，没有明确的“刷新权益”入口，容易把国内支付异步 webhook 流程和商店恢复购买混在一起。

本轮以一个小 PR 收口这两个缺口，不扩展真实商户签名、退款、SDK 拉起或 webhook 验签。

## 开发内容

### 1. PaymentService 支持显式 provider

- `PaymentService.purchase` 新增可选参数 `provider`。
- `PaymentService` 新增：
  - `availableProviders`
  - `defaultProvider`
- Google Play / App Store / 国内支付实现都声明自己的 provider。
- Google Play / App Store 在收到不匹配 provider 时直接返回可读错误，避免静默忽略错误选择。

### 2. 国内多 provider 支付服务

- 新增 `DomesticPaymentService`，用于同时暴露微信支付与支付宝。
- 保留原有 `WechatPayPaymentService` / `AlipayPaymentService` 的单 provider 行为。
- `createPlatformPaymentService` 在国内 provider 数量大于 1 时返回 `DomesticPaymentService`。
- 国内支付建单逻辑抽成 `createDomesticPaymentOrder`，单 provider 与多 provider 复用同一套 pending 订单语义。

### 3. 订阅页支付方式选择

- 当 `PaymentService.availableProviders.length > 1` 时，订阅卡片展示“选择支付方式”。
- 用户可以在微信支付 / 支付宝之间切换。
- 升级按钮会把用户选择的 provider 传给 `PaymentService.purchase(...)`。
- 单 provider 或商店支付渠道不展示额外选择器，避免影响 Google Play / App Store 体验。

### 4. pending 支付弹窗支持刷新权益

- 国内支付 pending 弹窗新增“刷新权益”按钮。
- 点击后调用 `SubscriptionStatusService.checkAndSync()`。
- 如果 webhook 已经写回 `user_subscriptions`，客户端会应用 trusted snapshot 并提示“权益已刷新为...”。
- 如果 webhook 尚未到达，提示“暂未检测到支付成功，请稍后再试”。
- 弹窗文案从“恢复购买”改成“刷新权益”，与国内支付的异步回调语义对齐。

## 验证结果

### Target Analyzer

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/payment lib/feature/subscription test/payment_service_factory_test.dart test/domestic_payment_service_test.dart test/subscription_screen_test.dart test/subscription_status_service_test.dart test/subscription_lifecycle_gate_test.dart
```

结果：`No issues found!`

### Target Tests

```bash
/Users/chauhua/development/flutter/bin/flutter test test/payment_service_factory_test.dart test/domestic_payment_service_test.dart test/subscription_screen_test.dart test/subscription_status_service_test.dart test/subscription_lifecycle_gate_test.dart
```

结果：`30/30 passed`

新增覆盖：

- 多 provider 国内支付服务按用户选择的支付宝建单。
- 国内支付服务拒绝不可用 provider。
- 订阅页展示微信 / 支付宝选择器。
- 订阅页选择支付宝后，把 `PaymentProvider.alipay` 传入 purchase。
- pending 弹窗展示“刷新权益”。
- pending 弹窗刷新 trusted subscription 后，权益升级为专业版。

### Full Analyzer

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

结果：通过。当前全仓库仍有 80 个既有 info 级 lint，无 error、无 warning。

### SaaS Wave0 Smoke

```bash
bash scripts/run_saas_wave0_smoke.sh
```

结果：通过。

覆盖范围包括：

- sync book scope / tombstone smoke
- subscription webhook Deno tests
- verify-subscription Deno tests
- create-payment-order Deno tests
- domestic-payment-webhook Deno tests
- auth smoke
- analytics smoke
- notification smoke
- admin smoke

### Static Checks

```bash
git diff --check
```

结果：通过。

## 未做范围

- 没有接入真实微信 / 支付宝商户 SDK。
- 没有实现真实平台签名验签。
- 没有实现订单轮询、倒计时或支付页内嵌二维码渲染。
- 没有调整 GitHub Actions 默认 PR 门禁；并行探索建议后续单独做“让 SaaS Wave0 smoke 自动进入相关 PR 检查”的小 PR。

## 后续建议

1. 下一步优先把 `saas_wave0_smoke` 改成“相关路径变更自动跑”，避免 Edge Function / sync / payment 改动只靠手动 smoke。
2. 再下一步补 `domestic-payment-webhook` 的 `handleRequest` 级测试，覆盖鉴权失败、订单不存在、重复事件和成功投影订阅。
3. 真实商户接入前，先把 `DOMESTIC_PAYMENT_WEBHOOK_TOKEN` 升级为平台签名验签策略。
