# Jive SaaS Beta 边界设计

## 目标
把当前已经存在的 SaaS Alpha 骨架，收口成一套可以继续演进的 Beta 边界。

这份文档只回答 3 类问题：
- `book`、`shared_ledger`、`workspace` 之间到底是什么关系
- 哪些同步对象必须拥有稳定云端标识，不能继续长期依赖本地 Isar `int` 主键
- 本地优先架构下，哪些数据上云，哪些数据保持本地

本文档不覆盖：
- Web 管理后台
- 复杂组织体系
- 多平台订阅供应商比较
- 端到端加密实现细节

---

## 当前代码现实

### 本地主数据边界
- `JiveBook` 已存在稳定 `key`，适合作为账本级业务标识
- `JiveTransaction` / `JiveAccount` / `JiveBudget` 已支持 `bookId`
- `JiveSharedLedger` / `JiveSharedLedgerMember` 已存在，且已进入同步范围
- 当前同步层已覆盖：
  - transactions
  - accounts
  - categories
  - tags
  - budgets
  - shared_ledgers
  - shared_ledger_members

### 当前主要问题
1. 同步模型还没有显式表达 `book` 边界
2. 云端写入仍然过度依赖 `local_id`
3. `book` 和 `shared_ledger` 目前并存，但长期关系未定义

---

## 核心决策

### 决策 1：`book` 是 workspace 起点
`book` 不是一个纯本地概念，而是 Jive SaaS 中最自然的工作空间起点。

原因：
- 现有交易、账户、预算已经天然按 `book` 划分
- `book` 已有稳定 `key`
- 用户心智已经接受“账本”作为数据边界
- 如果再平行引入一个新的顶层 `workspace` 容器，会让本地模型和云端模型脱节

因此，Beta 阶段建议：
- 产品层继续显示“账本”
- 云端模型允许用 `workspace_key` 作为技术名
- 但默认采用：
  - `workspace_key == book.key`

也就是说：
- 账本是用户可见概念
- workspace 是云端实现概念
- 在 Beta 阶段，两者一一对应

### 决策 2：`shared_ledger` 不是新的顶层容器
`shared_ledger` 不应长期与 `book` 平级扩张。

建议定义：
- `shared_ledger` 是 `book/workspace` 的共享协作层
- 它负责：
  - 邀请码
  - 成员关系
  - 角色
  - 协作元数据
- 它不应该成为另一套和 `book` 独立演进的数据归属体系

因此，Beta 阶段建议把关系收口为：
- 一个 `book/workspace` 可以选择开启共享
- 开启共享后，会附着一个 `shared_ledger`
- `shared_ledger.key` 继续存在，但其语义是“共享协作记录 key”，不是新的业务主容器

### 决策 3：云端冲突和关联必须逐步摆脱 `local_id`
`local_id` 可以继续保留作兼容字段，但不能再作为长期核心身份标识。

Beta 阶段要求：
- 所有核心同步对象都应具备稳定业务 key 或云端 sync key
- 本地 Isar `int` ID 只作为：
  - 本地索引
  - 本地缓存映射
  - 调试辅助字段

---

## 模型边界定义

### 1. Book / Workspace
定义：
- `book` 是用户可见账本
- `workspace` 是云端同步边界
- Beta 阶段一一映射

主键策略：
- 本地：`book.id` 保持 Isar 主键
- 业务稳定标识：`book.key`
- 云端：使用 `workspace_key`，值默认等于 `book.key`

结论：
- 不新增另一套独立 `workspace` 本地模型
- 先以 `book.key` 代表 workspace

### 2. Shared Ledger
定义：
- `shared_ledger` 是账本共享的协作层
- 依附于某个 `book/workspace`

Beta 建议新增字段：
- `workspace_key` 或 `book_key`

语义：
- `shared_ledger.key`：共享协作记录 key
- `shared_ledger.workspace_key`：它服务于哪个账本空间

### 3. Transaction
定义：
- 交易属于单一 `book/workspace`
- 交易同步时必须带 `book_key`

当前问题：
- 只有 `bookId`
- 当前同步没有 `book_key`

Beta 建议新增稳定标识：
- `tx_key` 或 `sync_key`

不建议长期依赖：
- `local_id`
- `account_id` 这类本地 int 外键

### 4. Account
定义：
- 账户属于单一 `book/workspace`

已有优势：
- `JiveAccount` 已有稳定 `key`

Beta 要求：
- 云端同步使用 `account.key`
- 同步 payload 带 `book_key`
- 交易引用账户时优先引用 `account_key`

### 5. Category / Tag
定义：
- 分类和标签默认按用户维度拥有，但实际使用会落在某个账本上下文中

Beta 建议：
- 保持现有 `key`
- 如果继续支持“用户全局分类库”，则云端保留 `user_id + key`
- 如后续要支持账本级私有分类，再引入可选 `book_key`

### 6. Budget
定义：
- 预算明确属于某个 `book` 或全局账本视图

当前现实：
- 本地已有 `bookId`
- 云端同步未携带 `book` 边界

Beta 建议：
- 增加 `budget_key`
- 增加 `book_key`

### 7. Shared Ledger Member
定义：
- 成员记录不属于本地账本实体本身，而属于共享协作层

稳定标识建议：
- 组合唯一键：`ledger_key + user_id`

---

## 首批稳定云端标识方案

### 已具备稳定 key 的对象
- `book.key`
- `account.key`
- `category.key`
- `tag.key`
- `shared_ledger.key`

### 需要新增稳定 key 的对象
- `transaction.txKey`
- `budget.budgetKey`

### 可继续使用组合键的对象
- `shared_ledger_member`: `ledger_key + user_id`

### `local_id` 的保留策略
保留，但降级为兼容字段：
- 可继续用于已有迁移兼容
- 可继续参与首轮回填
- 不应再是未来 schema 的唯一对齐手段

---

## 上云 / 不上云边界

### 首批必须上云
- books / workspaces
- transactions
- accounts
- budgets
- categories
- tags
- shared_ledgers
- shared_ledger_members
- user_subscriptions

### 继续本地优先，仅本地存储
- UI 偏好
- 动画/引导状态
- 本地调试 seed 开关
- 本地缓存游标快照
- 本地运行时临时状态

### 先不上云
- 纯调试数据
- 临时导入中间态
- 本地权限检测结果
- 仅用于设备侧自动化的运行时状态

---

## 同步契约

### 核心原则
1. 所有业务对象必须带 `updated_at`
2. 所有账本内对象必须带 `book_key`
3. 关键对象必须带稳定业务 key / sync key
4. 删除必须有 tombstone 方案，不能只靠“本地删掉了”

### 建议字段

#### transactions
- `tx_key`
- `book_key`
- `account_key`
- `to_account_key`
- `updated_at`
- `deleted_at`

#### accounts
- `account_key`
- `book_key`
- `updated_at`
- `deleted_at`

#### budgets
- `budget_key`
- `book_key`
- `updated_at`
- `deleted_at`

#### shared_ledgers
- `ledger_key`
- `workspace_key`
- `updated_at`
- `deleted_at`

### cursor 策略
Beta 建议从“全用户 per-table cursor”逐步升级为：
- `per-table + per-workspace cursor`

这样可以避免：
- 多账本下一个表共用游标导致状态耦合
- 后续共享账本扩展时游标边界混乱

### 删除策略
Beta 阶段建议统一引入：
- `deleted_at timestamptz`

原因：
- 跨设备同步必须能表达删除
- 共享账本成员变更也需要墓碑语义

---

## 迁移路径

### Step 1：本地对象补齐稳定 key
- 为 transactions 增加 `txKey`
- 为 budgets 增加 `budgetKey`
- 对已有本地历史数据进行一次性回填

### Step 2：云端 schema 补齐账本边界
- transactions 增加 `book_key`
- accounts 增加 `book_key`
- budgets 增加 `book_key`
- shared_ledgers 增加 `workspace_key`

### Step 3：同步 payload 改为以稳定 key 为主
- 继续保留 `local_id` 兼容字段
- 新逻辑优先用 `tx_key / account.key / budget_key / book.key`

### Step 4：老数据回填默认账本
- 对现有没有 `book_key` 的云数据，统一回填到默认账本
- 默认值：
  - `book_default`
  - 或该用户首个本地默认账本对应 key

### Step 5：共享账本绑定到账本空间
- 将现有 shared ledger 记录和具体 `workspace_key` 绑定
- 不再允许 shared ledger 成为脱离账本的独立容器

---

## 风险与约束

### 风险 1：如果继续平铺按 user_id 同步，多账本会越来越难收口
后果：
- 云端统计和权限边界混乱
- 共享账本无法可靠挂接到具体账本数据

### 风险 2：如果继续长期依赖 `local_id`，多设备和数据迁移成本会持续上升
后果：
- 本地 int 外键耦合越来越深
- 迁移和合并更难做

### 风险 3：如果 `shared_ledger` 不收口为协作层，会和 `book` 形成双主容器
后果：
- 权限模型重复
- 同步 schema 重复
- UI 心智混乱

---

## 非目标
- 这一步不实现 Web 管理后台
- 这一步不引入组织/团队层级
- 这一步不一次性把所有模型全部云化
- 这一步不做完整端到端加密方案

---

## 推荐实施顺序
1. 先按本文档确认边界
2. 改 SQL migration 和 sync schema
3. 改本地模型与 sync payload
4. 再做订阅可信化
5. 最后做登录补完与文案收口

---

## 结论
Jive Beta 阶段的正确收口方式不是“再造一个 workspace 系统”，而是：
- 以 `book` 作为 workspace 起点
- 以 `shared_ledger` 作为共享协作层
- 以稳定业务 key 替代 `local_id` 中心化同步
- 以 `book_key/workspace_key` 作为所有云端账本数据的主边界

只要这 4 点定住，后面的同步、订阅和协作能力就能持续演进，而不会越做越绕。
