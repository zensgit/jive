# 2026-04-09 B2.2 Apple Webhook

## 这次补了什么

- `subscription-webhook` 新增 Apple App Store Server Notifications v2 路径
- 使用 `notificationUUID` 做 webhook 幂等
- 解码 `signedPayload`、`signedTransactionInfo`、`signedRenewalInfo`
- 将常见订阅事件映射到 `user_subscriptions`
- 支持按 `originalTransactionId` / `transactionId` / `appAccountToken` 查找现有订阅
- 新增 Deno 单测覆盖 Apple 事件映射和 JWS payload 解码

## 新增环境变量

- `APPLE_APP_STORE_BUNDLE_ID`
- `APPLE_APP_STORE_APPLE_ID`
- `APPLE_APP_STORE_ENVIRONMENT`

这些变量是可选的；配置后会校验 Apple webhook 的 bundle / app / environment 是否匹配。

## 当前边界

- 本次先完成 JWS payload 解码和状态落库
- Apple JWS 的证书链验签仍是后续增强项
- 若库里还没有 Apple 订阅记录，且 webhook 里也没有可用的 `appAccountToken`，函数会返回 `subscription_not_found`
