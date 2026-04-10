# 2026-04-09 B2.4 App Store Payment Service

## 这次补了什么

- 新增 `AppStorePaymentService`
- 新增 `payment_service_factory.dart`，按平台选择 `PlayStorePaymentService` 或 `AppStorePaymentService`
- `main.dart` 不再默认只创建 Google Play 支付服务
- iOS / macOS 购买与恢复时，会把当前登录用户的 UUID 作为 `applicationUserName`

## 为什么先做这个

当前订阅可信链路已经有：

- 服务端真相表
- Google webhook
- Apple webhook
- 客户端生命周期刷新

但客户端支付入口仍然只接了 Google Play。这个分支先把 App Store 客户端支付接线补齐，让 iOS/macOS 不再走错支付实现。

## 当前边界

- 本次不新增 Apple 服务端验票接口
- `AppStorePaymentService` 会优先读取已有的可信订阅快照；如果服务端状态尚未到位，则回退到本地授权结果
- 更强的 Apple 服务端验票可以继续叠在这条线上做
