# Sync Runtime Service MVP

## 目标

把 phase416 的 `checkpoint + lease + session service` 继续推进为可恢复的 runtime 协调层，解决三件事：

1. 设备侧 identity 持久化
2. owner/device/scope 维度的 runtime open/reopen 语义
3. host regression 与 Android emulator lane 的分层验证

## 本轮落地

- `sync_runtime_identity_store.dart`
- `sync_runtime_service.dart`
- `sync_runtime_service_test.dart`
- `backup_restore_stale_session_regression_test.dart` 适配 runtime open result
- `backup_restore_stale_session_flow_test.dart` 适配 runtime open result
- `run_release_regression_suite.sh`
- `run_android_e2e_smoke.sh`

## 设计决策

### 1. 设备 identity 独立于 lease

`SyncRuntimeIdentityStore` 只负责：

- `deviceId`
- `createdAt`

它不参与权限判断，只提供稳定设备身份。

### 2. runtime service 负责协调，不直接替代 session service

`SyncRuntimeService` 在 `SyncSessionService` 之上收口：

- `openRuntime`
- `advanceCursor`
- `persistSnapshot`
- `canCurrentRuntimeWrite`
- `clearRuntime`

底层 lease 签发与校验仍由 `SyncSessionService` 负责。

### 3. openRuntime 明确四种结果

- `issued`
- `resumed`
- `renewed`
- `rebound`

这样后续接 auth/session fanout、backup/restore telemetry 时，调用侧能区分：

- 首次打开
- 同 owner/device 恢复
- 同 owner/device 续租
- owner/scope 变化后的重建

### 4. host 和 Android 分层不变

- host：`backup_restore_stale_session_regression_test.dart`
- Android emulator：`backup_restore_stale_session_flow_test.dart`

host 负责稳定逻辑回归，Android 负责更接近真实设备的链路。

## 当前能力

- install 内 `deviceId` 稳定
- runtime open 支持 `issued/resumed/renewed/rebound`
- cursor 推进后可在后续 runtime reopen 中恢复
- regression suite 已纳入 runtime 相关 analyze/test
- Android E2E 脚本新增 emulator boot/preflight 收口

## 下一步

1. 给 runtime 增加 `owner scope snapshot checksum` 的统一 telemetry
2. 在 Android emulator lane 真正跑通 `backup_restore_stale_session_flow_test.dart`
3. 继续把 backup/import/export 与未来 cloud sync runtime 对齐
