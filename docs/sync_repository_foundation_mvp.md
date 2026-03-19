# Sync Repository Foundation MVP

## 目标

为后续 SaaS 化的同步层先落一层最小可用基础抽象，避免后面直接从 UI/service 里拆 Isar 读写。

## 本轮落地

- `sync_cursor.dart`
- `sync_repository_contract.dart`
- `account_sync_repository.dart`
- `category_sync_repository.dart`
- `account_category_sync_repository_test.dart`

## 设计决策

### 1. 先抽 cursor + repository contract，不直接改现有 UI

本轮目标是打基础，不做大规模替换，因此 repository 先作为新边界存在，不强行接入现有页面。

### 2. 先覆盖 `account` 和 `category`

这两个实体都有明确的 `updatedAt` 字段，可直接用于同步游标。

### 3. `transaction` 暂不纳入本轮 sync repository

原因不是优先级，而是数据模型目前缺少统一 `updatedAt`/version 字段。若现在强做 transaction cursor，会把 `timestamp` 和“同步修改时间”混在一起，后续会出错。

## 当前能力

- `SyncCursor` 支持 `entityType + updatedAt + lastId` 三元组
- repository 支持按 `updatedAt`、`id` 稳定排序
- 支持按 cursor 增量翻页
- 支持 entityType 不匹配时阻断错误 cursor 使用

## 下一步

1. 给 transaction/project/tag 等核心实体补统一 sync version 或 `updatedAt`
2. 把 import/export/sync service 逐步收口到 repository boundary
3. 在真正接云端前补 `change journal` 和 `sync cursor persistence`
