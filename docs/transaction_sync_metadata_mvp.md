# Transaction Sync Metadata MVP

## 目标

把 `transaction` 正式纳入 sync foundation，而不是继续把业务发生时间 `timestamp` 误当成同步游标。

## 本轮落地

- `JiveTransaction` 新增 `updatedAt`
- `transaction_model.g.dart` 已重新生成并包含 `updatedAt` schema/index
- 新增：
  - `transaction_sync_repository.dart`
  - `tag_sync_repository.dart`
  - `project_sync_repository.dart`
- 新增测试：
  - `transaction_tag_project_sync_repository_test.dart`
- 备份链路已支持：
  - 导出 transaction `updatedAt`
  - 导入时恢复 `updatedAt`
  - legacy 备份缺失 `updatedAt` 时降级为 `timestamp`

## 设计决策

### 1. `timestamp` 和 `updatedAt` 分离

- `timestamp` 表示业务发生时间
- `updatedAt` 表示本地实体最近一次被修改并写库的时间

这样后续做：

- 增量同步
- stale callback 阻断
- 远端 merge/replay

才不会把“旧账单补录”误判成“新同步变更”。

### 2. transaction 写路径必须显式 touch

本轮没有只依赖字段默认值，而是把主要交易写路径统一补成：

- 单笔写入前 `TransactionService.touchSyncMetadata(tx)`
- 批量写入前 `TransactionService.touchSyncMetadataForAll(txs)`

已覆盖：

- 手动新增/编辑交易
- 项目关联/取消关联
- 分类迁移/解绑/重命名回写
- 标签合并/删除/转换分类
- smart tag opt-out / backfill / cleanup
- 周期入账提交
- auto draft 提交
- 对账页批量插入测试数据
- 备份导入后的 legacy transaction repair

### 3. sync repository 继续沿用 `updatedAt + lastId`

本轮新增的 `transaction/tag/project` repository 都延续 phase413 的 cursor 契约：

- `entityType`
- `updatedAt`
- `lastId`

避免同一毫秒内多条记录更新时丢分页边界。

## 当前能力

- `account/category/transaction/tag/project` 已全部具备最小 sync repository
- `transaction` 已具备独立同步元数据，不再依赖业务时间
- backup/import 不会丢失 transaction sync metadata

## 仍未完成

1. sync cursor persistence
2. change journal / op log
3. 远端 sync endpoint 契约
4. transaction/tag/project repository 接入真正的 sync service
5. 跨端冲突合并策略

## 下一步

1. 把 `import/export`、`backup/restore` 逐步改为通过 repository boundary 读写
2. 为 sync 层补 `cursor store + lease + replay window`
3. 开始抽 `cloud sync` 的 pull/push protocol，为 SaaS 的单用户云同步做准备
