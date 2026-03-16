# 2026-03-13 Parallel Dev Phase416 Design

## 目标

本轮继续沿着 “sync foundation + release readiness + SaaS boundary” 推进，补三件缺口：

1. sync checkpoint 完整性
2. sync session 运行态
3. backup/restore + stale session 集成回归

## 设计决策

### 1. snapshot 先做 checksum/version，再谈远端协议

phase415 已经有了本地 checkpoint persistence，但还缺两个基本防线：

- 数据损坏检测
- 跨版本恢复判定

因此 `SyncCheckpointSnapshot` 本轮加入：

- `version`
- `capturedAt`
- `checksum`
- `checksumValid`

同时在 `SyncCursorStore.loadSnapshot()` 上收口：

- payload 不可恢复时主动 `clearAll()`
- 返回空 snapshot，避免把坏 checkpoint 留在本地反复污染恢复链路

### 2. session 要从 store 提升为 service

phase415 只有：

- `SyncCursorStore`
- `SyncLeaseStore`

这两个 store 能持久化，但还不能表达：

- 谁持有 lease
- 谁可以 resume
- 哪些写操作应该被 stale callback 阻断

因此本轮新增 `SyncSessionService`，把：

- `issueSession`
- `renewSession`
- `resumeSession`
- `canWrite`
- `persistCheckpoint`
- `clearSession`

收口成最小运行态协议。

### 3. owner/device 先用轻量身份边界

当前还没有正式的 device registry，也没有 server-issued lease。

所以本轮采用最小可行策略：

- `leaseId`
- `ownerId`
- `deviceId`
- `version`
- `expiresAt`

其中：

- `ownerId` 解决跨账号误恢复
- `deviceId` 解决跨设备误写
- `version` 为后续 token rotate / session fanout 留接口

### 4. stale session 回归拆成 host mirror + Android integration

本轮新增的风险不是纯算法错误，而是 backup/import、prefs、isar、lease 清理之间的联动。

因此本轮拆成两条：

- host `backup_restore_stale_session_regression_test.dart`
- Android `backup_restore_stale_session_flow_test.dart`

两条都覆盖同一核心场景：

- 建库并写入 account/category/project/transaction
- issue sync session
- 导出 backup
- 注入 stale lease
- 清库
- 导入 backup
- 验证 checkpoint 恢复
- 验证 stale lease 清空
- 验证 stale callback gate 仍能打出 `review`

其中：

- host lane 用普通 `flutter test`，收口 release regression
- Android lane 保留真实 `integration_test` 路径

### 5. Android lane 先接线，不强行依赖 host integration runner

`backup_restore_stale_session_flow_test.dart` 仍然补了 host 兼容层：

- host Isar init
- `path_provider` mock
- temp documents dir

但真实 `integration_test` 在 host 上仍会走额外的 macOS embed / plugin 装配，收益不高；因此它的稳定归宿仍然是 Android emulator lane。

因此本轮把它接入：

- `run_android_e2e_smoke.sh`

host 只保留“尽量可跑”的补充验证，不把 release gate 绑死在 host integration 上。

## 产出

- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_checkpoint_snapshot.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_cursor_store.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_lease.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_session_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_cursor_store_and_lease_store_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_session_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_roundtrip_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/backup_restore_stale_session_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/sync_session_service_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase416-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase416-validation.md`

## 风险与约束

### 1. checksum 解决的是损坏，不是伪造

当前 checksum 只能拦截：

- 损坏 payload
- 手工篡改 payload

它不是真正的签名体系，后续若进入云同步和 SaaS，多租户/设备场景仍要补：

- 服务端签发
- 设备级 owner 绑定
- 可信 session source

### 2. host 与 Android 的验证边界已经分开

本轮不再尝试把真正的 `integration_test` 强塞进 host release lane。

- host：跑 mirror regression test，验证逻辑闭环
- Android emulator：跑 `integration_test`，验证更真实的设备链路

这样 release regression 稳定，Android lane 也保留后续扩展空间。
