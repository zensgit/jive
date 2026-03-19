# Sync Session Service MVP

## 目标

把 phase415 的 `sync cursor persistence + lease store` 推进到可恢复的运行态会话，解决三个缺口：

1. checkpoint 缺少完整性校验
2. lease 缺少 `owner/device` 身份边界
3. backup/restore 后缺少对 stale session 的集成回归

## 本轮落地

- `sync_checkpoint_snapshot.dart`
- `sync_cursor_store.dart`
- `sync_lease.dart`
- `sync_session_service.dart`
- `backup_restore_stale_session_regression_test.dart`
- `backup_restore_stale_session_flow_test.dart`

## 设计决策

### 1. checkpoint 先做 checksum + version，不直接做签名

当前先解决的是：

- 导入损坏 payload 的快速阻断
- 跨版本 snapshot 的恢复判定

因此本轮用：

- `version`
- `capturedAt`
- `checksum`

来形成最小完整性保护。真正的签名和租户级验签后续再补。

### 2. lease 必须绑定 owner/device

只靠 `leaseId` 不足以阻断旧回调或跨设备误写。

因此 `SyncLease` 现在显式持久化：

- `ownerId`
- `deviceId`
- `version`

`SyncSessionService.canWrite()` 和 `resumeSession()` 都会校验这三个维度。

### 3. backup 继续恢复 checkpoint，但不恢复旧 lease

这条策略保持不变，并在本轮通过集成回归加固：

- backup 导出 `syncCursors`
- import 恢复可校验的 checkpoint snapshot
- import 后清空旧 `syncLease`

## 当前能力

- snapshot 支持 checksum/version/capturedAt
- checksum 损坏时 snapshot 自动判为不可恢复
- owner/device mismatch 时 sync session 不可恢复
- stale lease 过期后不会继续持有写权限
- `backup_restore_stale_session_regression_test.dart` 在 host regression lane 覆盖 backup/export/import 与 stale session 清理闭环
- `backup_restore_stale_session_flow_test.dart` 进入 Android emulator lane，负责更接近真实设备的集成链路

## 下一步

1. 给 sync session 增加 `session owner/device/app instance` 统一运行态封装
2. 给 snapshot 增加更稳定的 schema migration 策略
3. 在 Android emulator lane 真正跑通 `backup/restore + stale session` 集成回归
