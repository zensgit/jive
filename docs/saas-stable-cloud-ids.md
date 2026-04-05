# Jive SaaS Beta 稳定云端标识设计

## 目标
为 Jive 的 SaaS Beta 定义一套稳定、可迁移、可跨设备的云端标识方案。

这份文档聚焦回答 4 个问题：
- 哪些对象已经有稳定业务 key，可以直接作为云端同步标识
- 哪些对象还没有稳定 key，需要新增 `syncKey` 或等价字段
- 哪些本地 `int` 外键必须退出云端主关联链路
- 迁移到新标识方案时，如何兼容现有 `local_id`

---

## 设计原则

### 1. 本地 Isar `int` ID 不再作为长期云端身份
本地 `Id` 继续保留，但仅用于：
- 本地索引
- 本地缓存映射
- 调试与兼容字段

它不应继续承担：
- 跨设备主身份
- 云端业务关联主键
- 长期同步冲突归并主键

### 2. 优先复用已有业务 key
如果模型已经存在稳定 `key` 字段，就优先使用该字段，而不是再造一层 `remote_id`。

### 3. 缺 key 的核心对象必须补 `syncKey`
如果对象天然没有稳定业务 key，但又会被同步、引用、跨设备创建，就必须新增稳定 key。

### 4. 所有账本内对象都要显式绑定 `bookKey`
账本空间必须成为云端边界，不允许对象只靠 `user_id + local_id` 漂浮在用户空间里。

---

## 对象级标识策略

| 对象 | 当前本地主键 | 已有稳定 key | Beta 云端主标识 | 云端关联键 | 说明 |
|---|---|---|---|---|---|
| Book | `book.id` | `book.key` | `book.key` | `book_key` | 直接作为 workspace 起点 |
| Account | `account.id` | `account.key` | `account.key` | `book_key` | 交易应优先引用 `account_key` |
| Category | `category.id` | `category.key` | `category.key` | `user_id`，后续可扩 `book_key` | 当前先保持用户级分类库 |
| Tag | `tag.id` | `tag.key` | `tag.key` | `user_id`，后续可扩 `book_key` | 当前先保持用户级标签库 |
| SharedLedger | `ledger.id` | `ledger.key` | `ledger.key` | `workspace_key` | 共享协作层，不是新顶层容器 |
| SharedLedgerMember | `member.id` | 无 | `ledger_key + user_id` | `ledger_key` | 使用组合唯一键即可 |
| Transaction | `tx.id` | 无 | `tx.syncKey` | `book_key`, `account_key`, `to_account_key` | 必须新增稳定 key |
| Budget | `budget.id` | 无 | `budget.syncKey` | `book_key` | 必须新增稳定 key |

---

## 各模型详细约定

### Book
**使用方式**
- 本地继续保留 `id`
- 云端使用 `book.key`
- `workspace_key == book.key`

**不需要新增**
- `remoteId`
- `syncKey`

### Account
**使用方式**
- 云端使用 `account.key`
- 所有云端引用账户的对象应优先引用 `account_key`

**必须补齐**
- `book_key`

**不建议继续依赖**
- `account_id bigint` 作为长期云端关联键

### Category / Tag
**使用方式**
- 继续使用 `key`
- 当前 Beta 允许仍按用户维度同步

**保留空间**
- 如果未来支持账本级私有分类/标签，可再加 `book_key`

### Shared Ledger
**使用方式**
- 云端身份使用 `ledger.key`
- 必须增加 `workspace_key`

**语义**
- `ledger.key`: 共享协作记录身份
- `workspace_key`: 它服务于哪个账本空间

### Shared Ledger Member
**使用方式**
- 不新增独立 `syncKey`
- 采用组合唯一键：`ledger_key + user_id`

**原因**
- 成员关系天然是关联型实体
- 组合键更稳定，也更贴近权限模型

### Transaction
**当前问题**
- 只有本地 `id`
- 当前同步只上传 `local_id`
- 还在传 `account_id`
- 未显式携带 `book_key`

**Beta 必须新增**
- `String syncKey`

**生成策略**
- 本地创建时生成 UUID/ULID
- 创建后永久不变

**云端字段建议**
- `tx_key`
- `book_key`
- `account_key`
- `to_account_key`
- `updated_at`
- `deleted_at`

### Budget
**当前问题**
- 有 `bookId`
- 无稳定云端身份

**Beta 必须新增**
- `String syncKey`

**云端字段建议**
- `budget_key`
- `book_key`
- `updated_at`
- `deleted_at`

---

## 必须退出云端主关联链路的本地字段

以下字段不应继续作为长期云端主关联：
- `transaction.accountId`
- `transaction.toAccountId`
- `transaction.bookId`
- `account.bookId`
- `budget.bookId`

原因：
- 这些值是本地 Isar 自增 ID
- 多设备间不能保证一致
- 导入、恢复、迁移后也不稳定

替代方案：
- `bookId` → `book_key`
- `accountId` → `account_key`
- `toAccountId` → `to_account_key`

---

## 兼容策略

### 阶段 1：双写
在过渡期内，允许：
- 本地仍保留 `int` 外键
- 云端新增 `*_key`
- 同步层同时携带：
  - 兼容字段：`local_id`
  - 新字段：`book_key`, `account_key`, `tx_key`, `budget_key`

### 阶段 2：读新写新
一旦新字段在本地和云端都完成回填：
- 同步冲突与归并优先依据稳定 key
- `local_id` 降级为兼容字段

### 阶段 3：逐步淡出旧关联
后续新增逻辑和云端查询不再依赖本地 int 外键。

---

## 迁移建议

### Migration 1：本地模型补 key
- `JiveTransaction` 增加 `syncKey`
- `JiveBudget` 增加 `syncKey`
- 对历史数据做一次本地回填

### Migration 2：Supabase schema 补 key
- transactions 增加 `tx_key`, `book_key`, `account_key`, `to_account_key`, `deleted_at`
- budgets 增加 `budget_key`, `book_key`, `deleted_at`
- accounts 增加 `book_key`, `deleted_at`
- shared_ledgers 增加 `workspace_key`, `deleted_at`

### Migration 3：同步引擎改造
- `_getTransactionChanges()` 输出 `tx_key/book_key/account_key`
- `_getAccountChanges()` 输出 `account.key/book_key`
- `_getBudgetChanges()` 输出 `budget_key/book_key`
- `_applyRemoteChanges()` 优先按稳定 key 归并

### Migration 4：历史云数据兜底
- 老数据没有 `book_key` 时，回填到默认账本
- 老数据没有 `tx_key/budget_key` 时，执行一次云端 backfill

---

## 对 B1.1 / B1.2 的直接约束

### B1.1 必须实现
- SQL migration 中补齐 `book_key/workspace_key`
- Dart sync payload 中补齐 `book_key`
- 相关索引与唯一约束同步补齐

### B1.2 必须实现
- 至少让 `transaction` 和 `budget` 不再只依赖 `local_id`
- 至少让 `transaction` 不再用 `account_id` 作为长期云端关联主键

---

## 非目标
- 这一步不要求删掉所有本地 `int` 外键
- 这一步不要求一次性把所有历史云数据彻底迁完
- 这一步不要求重写全部 sync engine

---

## 结论
Jive 的 SaaS Beta 不需要“全面 remote-first 重写”，但必须完成一件关键事：

把云端身份从“`user_id + local_id`”升级为“`book_key/workspace_key + 稳定业务 key`”。

只要这一步做稳，多账本、共享账本、跨设备同步和订阅能力才能真正站住。
