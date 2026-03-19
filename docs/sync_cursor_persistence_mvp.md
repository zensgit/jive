# Sync Cursor Persistence MVP

## 目标

把 phase413/414 的 sync repository 从“可算游标”推进到“可持久化游标”，避免应用重启、备份恢复、设备迁移后丢失同步进度。

## 本轮落地

- `sync_checkpoint_snapshot.dart`
- `sync_cursor_store.dart`
- `sync_lease.dart`
- `sync_lease_store.dart`

## 设计决策

### 1. cursor 按 entityType 独立存储

每个实体单独落到 `SharedPreferences`：

- `account`
- `category`
- `transaction`
- `tag`
- `project`

同时维护一个实体索引，避免只能靠固定枚举回读。

### 2. snapshot 和单 cursor 都支持

- `SyncCursorStore.save()` 适合单实体增量推进
- `SyncCursorStore.saveSnapshot()` 适合 backup/import 或全量 sync 收口

### 3. lease 与 cursor 分离

- cursor 表示同步进度
- lease 表示当前持有写权限的同步会话

这样在 backup/import 后可以恢复 cursor，但主动清空旧 lease，避免把过期写权限一起恢复出来。

## 当前能力

- sync checkpoint 可序列化/反序列化
- cursor 可按实体持久化、加载、清除
- lease 可持久化、判断是否 active、清除
- backup/import 已能恢复 checkpoint，并在导入后清空旧 lease

## 下一步

1. 增加 cursor checksum / snapshot version
2. 引入 sync session owner / device id
3. 接入真正的 pull/push sync service
