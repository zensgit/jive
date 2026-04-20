# 2026-04-20 微信/支付宝支付设计收口与验证报告

## 背景

PR #147 的原分支包含微信/支付宝支付设计，但分支历史落后于当前 `main`，直接合并会带入大量旧历史副作用。本轮采用 restack 策略，只把国内支付相关业务提交摘到最新 `main`，并排除旧分支中会误删 SaaS、同步、交易等模块的无关变更。

基线：

- `origin/main`: `3a02590e ops(saas): restack staging rollout fallback (#148)`
- 工作分支：`codex/wechat-alipay-payment-design-restack`
- 目标 PR：#147，更新为干净 restack 后的内容

## 开发内容

### App 支付运行时

- 新增支付渠道与服务商解析：
  - `PaymentChannel`: `auto`、`appStore`、`googlePlay`、`selfHostedWeb`、`directAndroid`、`desktopWeb`
  - `PaymentProvider`: `googlePlay`、`appleAppStore`、`wechatPay`、`alipay`
  - 通过 `PAYMENT_CHANNEL`、`ENABLE_STORE_BILLING`、`ENABLE_WECHAT_PAY`、`ENABLE_ALIPAY` 控制运行时支付能力。
- 新增国内支付服务骨架：
  - `WechatPayPaymentService`
  - `AlipayPaymentService`
  - `DomesticPaymentServiceBase`
  - `SupabaseDomesticPaymentOrderClient`
- `createPlatformPaymentService` 统一根据平台、渠道和 dart-define 选择支付服务。

### 订阅页体验收口

- 订阅购买返回 `PurchaseResult.pending` 时，不再只弹 Snackbar。
- 改为展示“支付订单已创建”弹窗，包含：
  - 订单号
  - 支付链接
  - 二维码链接
  - 复制支付链接按钮
  - 完成支付后回 App 恢复权益的说明
- 保留订阅版锁定功能清单，避免 restack 时回退 #148 后已有文案。

### Supabase 订单与 Webhook

- 新增 migration `013_create_domestic_payment_orders.sql`：
  - 扩展 `user_subscriptions.platform` 支持 `wechat_pay` / `alipay`
  - 增加 `source_order_no`、`provider_trade_no`
  - 新增 `payment_orders`
  - 新增 `payment_events`
  - 增加订单、事件去重索引
- 新增 Edge Function：
  - `create-payment-order`: 需用户登录，创建 mock 国内支付订单。
  - `domestic-payment-webhook`: 使用 `DOMESTIC_PAYMENT_WEBHOOK_TOKEN` 自定义鉴权，处理国内支付回调并投影到 `user_subscriptions`。

### 部署与验证脚本

- `run_saas_staging_rollout.sh`
  - full profile 部署 `create-payment-order` 和 `domestic-payment-webhook`。
  - `domestic-payment-webhook` 使用 `--no-verify-jwt`。
  - `create-payment-order` 保持 JWT 校验。
  - full profile 必填 `DOMESTIC_PAYMENT_WEBHOOK_TOKEN`。
  - `DOMESTIC_PAYMENT_MOCK_BASE_URL` 作为可选 secret：如果 env 文件中存在，会随 deploy 一起推送。
- `check_saas_deployment_readiness.sh`
  - 检查 migration 013。
  - 检查两个国内支付 Edge Function。
  - full profile 检查 `DOMESTIC_PAYMENT_WEBHOOK_TOKEN`。
- `run_saas_wave0_smoke.sh`
  - 纳入国内支付 Edge Function 的 Deno check/test。
  - 使用统一 `run_deno` 包装，保留 Deno 下载/重试逻辑。
- `run_saas_staging_function_smoke.sh`
  - 如果 env 文件提供 `DOMESTIC_PAYMENT_WEBHOOK_TOKEN`，额外验证：
    - `create-payment-order` 匿名请求返回 401。
    - `domestic-payment-webhook` 缺 token 返回 401。
    - `domestic-payment-webhook` 带 token 但订单不存在返回 404。
- `supabase_db_fallback.py`
  - 支持 migration 013 的 direct Postgres fallback 已应用检测。

## 验证结果

### Flutter

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/payment lib/feature/subscription test/payment_service_factory_test.dart test/payment_runtime_config_test.dart test/domestic_payment_service_test.dart test/payment_provider_resolver_test.dart test/subscription_screen_test.dart
```

结果：`No issues found!`

```bash
/Users/chauhua/development/flutter/bin/flutter test test/payment_service_factory_test.dart test/payment_runtime_config_test.dart test/payment_service_test.dart test/domestic_payment_service_test.dart test/payment_provider_resolver_test.dart test/subscription_screen_test.dart
```

结果：`39/39 passed`

全仓库 analyzer 也已验证通过：

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

结果：0 errors，0 warnings，仅剩仓库既有 info 级 lint。

### Deno / Edge Functions

```bash
npx -y deno-bin@2.2.7 check supabase/functions/create-payment-order/index.ts supabase/functions/create-payment-order/index_test.ts supabase/functions/domestic-payment-webhook/index.ts supabase/functions/domestic-payment-webhook/index_test.ts
```

结果：通过。

```bash
npx -y deno-bin@2.2.7 test --allow-env supabase/functions/create-payment-order/index_test.ts
npx -y deno-bin@2.2.7 test --allow-env supabase/functions/domestic-payment-webhook/index_test.ts
```

结果：`4/4 passed` + `2/2 passed`

### SaaS Wave0 Smoke

```bash
bash scripts/run_saas_wave0_smoke.sh
```

结果：通过，包含同步、订阅 webhook、verify-subscription、国内支付订单、国内支付 webhook、Auth、Analytics、Notification、Admin smoke。

### Readiness

使用完整临时 full profile env 验证：

```bash
STAGING_PROJECT_REF=... STAGING_DB_PASSWORD=... SUPABASE_ACCESS_TOKEN=... \
  bash scripts/check_saas_deployment_readiness.sh --profile full --strict --env-file <temp-full-env> --skip-github
```

结果：`failures=0 warnings=0 profile=full strict=1`

### Rollout Deploy Dry Simulation

使用 fake Supabase CLI 验证 deploy 参数和 secret subset：

- `create-payment-order` 部署时不带 `--no-verify-jwt`。
- `domestic-payment-webhook` 部署时带 `--no-verify-jwt`。
- full profile secret subset 包含 `DOMESTIC_PAYMENT_WEBHOOK_TOKEN`。
- env 文件中存在 `DOMESTIC_PAYMENT_MOCK_BASE_URL` 时会被推送。

结果：fake deploy assertions passed。

### 静态检查

```bash
git diff --check
bash -n scripts/run_saas_staging_rollout.sh scripts/run_saas_wave0_smoke.sh scripts/check_saas_deployment_readiness.sh scripts/run_saas_staging_function_smoke.sh
python3 -m py_compile scripts/supabase_db_fallback.py
```

结果：全部通过。

## 当前边界与后续建议

- 当前国内支付仍是 mock order skeleton，不包含真实微信/支付宝 SDK、商户签名、回调验签与退款链路。
- `domestic-payment-webhook` 目前通过共享 token 做 staging 级自定义鉴权，生产接入前应改为平台签名验签。
- 如果同时启用微信和支付宝，当前 App 会选择解析列表中的第一个服务商；后续应在订阅页提供明确的支付方式选择。
- 真实部署前需在 Supabase 应用 migration 013，并设置 full profile 所需 secrets。
