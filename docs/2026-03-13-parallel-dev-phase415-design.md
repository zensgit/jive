# 2026-03-13 Parallel Dev Phase415 Design

## 目标

本轮继续沿着“sync foundation + release readiness”推进，补三件缺口：

1. sync cursor persistence
2. backup/import 与 sync repository 的边界打通
3. release regression suite 收口

## 设计决策

### 1. 先做 cursor store，不先做云端 cursor API

当前代码最缺的是本地恢复能力，不是远端协议。

因此本轮优先补：

- `SyncCheckpointSnapshot`
- `SyncCursorStore`
- `SyncLeaseStore`

先让本地 sync 进度、session lease 能在重启和导入后被正确处理。

### 2. backup 只恢复 checkpoint，不恢复旧 lease

checkpoint 是进度。

lease 是会话写权限。

如果 backup/import 把旧 lease 一起恢复，会把过期的 sync 写权限带回新环境，风险高于收益。所以本轮策略是：

- 导出 `syncCursors`
- 导入后恢复 `syncCursors`
- 导入后主动清空 `syncLease`

### 3. `project` 必须跟着 backup 一起补

在把 `project` 纳入 sync checkpoint 时，发现当前 backup 尚未覆盖 `JiveProject`。

如果不补 project backup，就会出现“有 project cursor、没 project data”的错误状态。

因此本轮把 `project` backup/import 一起纳入。

### 4. regression 和 smoke 拆层

原来的 `run_release_smoke.sh` 既做 regression 又做 integration smoke，边界不够清晰。

本轮改成两层：

- `run_release_regression_suite.sh`
- `run_release_smoke.sh`

并让 Android emulator lane 先跑 regression 再跑 E2E。

## 产出

- `sync_checkpoint_snapshot.dart`
- `sync_cursor_store.dart`
- `sync_lease.dart`
- `sync_lease_store.dart`
- `data_backup_service.dart` 扩展版
- `sync_cursor_store_and_lease_store_test.dart`
- `run_release_regression_suite.sh`
- `sync_cursor_persistence_mvp.md`
- `release_regression_suite_mvp.md`
- `2026-03-13-parallel-dev-phase415-design.md`
- `2026-03-13-parallel-dev-phase415-validation.md`

## 风险与约束

### 1. SharedPreferences store 目前没有加密

本轮的 cursor/lease 是同步进度元数据，不是敏感凭据，因此先用轻量持久化；后续若引入租户/多设备 owner，可再补签名和 checksum。

### 2. Android emulator lane 本轮仍以脚本/CI 接线为主

本地当前没有直接启动 emulator，所以本轮验证集中在：

- shell 语法
- host regression suite 实跑
- workflow/script 引用一致性
