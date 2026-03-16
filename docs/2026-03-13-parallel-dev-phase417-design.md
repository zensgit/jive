# 2026-03-13 Parallel Dev Phase417 Design

## 目标

本轮继续沿着 `sync foundation + release readiness + SaaS boundary` 推进，补三件缺口：

1. sync runtime identity
2. sync runtime open/reopen 协调层
3. Android emulator lane preflight

## 设计决策

### 1. identity 先做 install 级，不先做跨设备 registry

当前最缺的是：

- 同一安装实例内的稳定 `deviceId`
- runtime reopen 时 owner/device 对齐

因此本轮新增 `SyncRuntimeIdentityStore`，仅持久化：

- `deviceId`
- `createdAt`

不提前引入服务端 device registry。

### 2. runtime service 负责语义收口

phase416 已有：

- `SyncCursorStore`
- `SyncLeaseStore`
- `SyncSessionService`

但调用侧仍要自己判断：

- 当前是首次打开还是恢复
- lease 过期后是否该续租
- owner 变化后是否应该重建

因此本轮新增 `SyncRuntimeService`，把这些分支收口为：

- `issued`
- `resumed`
- `renewed`
- `rebound`

### 3. 向后兼容测试与回归调用面

为了不扩大变更面，本轮保留了 runtime 调用侧的直接访问能力：

- `result.identity`
- `result.session`
- `result.disposition`
- `result.status`
- `advanceCursor`
- `canCurrentRuntimeWrite`

这样 host regression、Android integration 和新单测都不需要各自维护一套分支接口。

### 4. Android lane 先补 preflight，不强行本地起 emulator

`run_android_e2e_smoke.sh` 本轮补：

- `boot_completed` 等待
- `pm clear`
- preflight artifact
- boot timeout 失败快断

先提高 CI/emulator 车道稳定性，再做真实设备回归扩展。

## 产出

- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/repository/sync_runtime_identity_store.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_runtime_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_session_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/backup_restore_stale_session_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/backup_restore_stale_session_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/sync_runtime_service_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase417-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-13-parallel-dev-phase417-validation.md`

## 风险与约束

### 1. identity 仍是本地信任模型

当前 `deviceId` 是本地 install 级标识，不是服务端认证身份。

它能解决：

- 同设备 runtime reopen
- stale lease 本地阻断

但不能替代后续云同步场景里的 device attestation。

### 2. Android 集成回归仍以脚本接线为主

本轮没有在当前机器强行起 emulator 直跑全链路，而是把：

- host regression
- regression suite
- Android preflight

先做稳。
