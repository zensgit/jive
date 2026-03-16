# 2026-03-13 Parallel Dev Phase414 Design

## 目标

本轮沿着 phase413 的 sync foundation 继续推进，补齐两件前面明确缺失的能力：

1. 给 `transaction` 增加真正可用的同步元数据
2. 把 `transaction/tag/project` 接入最小 sync repository

## 设计决策

### 1. 先补 `updatedAt`，不直接上复杂 sync version

当前仓库已经广泛使用 `updatedAt` 作为 account/category/tag/project 的变更时间。

因此 transaction 本轮先采用同一语义：

- 模型新增 `updatedAt`
- 主要写路径显式 touch
- repository 以 `updatedAt + id` 作为稳定分页键

这样可以先把 transaction 纳入 sync foundation，而不需要先做更重的 journal/version 大重构。

### 2. 不把业务发生时间 `timestamp` 混成同步时间

这是本轮最关键的边界：

- `timestamp` 可以被用户回填到过去
- `updatedAt` 必须代表“最近一次本地写库”

如果继续把两者混用，后面做：

- 增量同步
- stale bundle invalidate
- result replay
- remote diff

都会产生错误排序。

### 3. 主要写路径先补齐，暂不做全仓替换

本轮只对会修改既有 transaction 的主要入口补 touch：

- UI 直接写库
- 分类重写
- 标签规则回填/清理
- 项目关联
- 备份导入 repair

这样能先保证 sync cursor 基本可信。

## 产出

- `transaction_model.dart` / `transaction_model.g.dart`
- `transaction_service.dart`
- `transaction_sync_repository.dart`
- `tag_sync_repository.dart`
- `project_sync_repository.dart`
- `transaction_tag_project_sync_repository_test.dart`
- backup regression 断言增强
- `transaction_sync_metadata_mvp.md`
- `2026-03-13-parallel-dev-phase414-design.md`
- `2026-03-13-parallel-dev-phase414-validation.md`

## 风险与约束

### 1. `category_service.dart`、`auto_draft_service.dart` 已有大量历史 info 级 lint

本轮没有顺手做大规模样式改写，只确认：

- 无新的 error/warning
- 仅保留历史 `curly_braces_in_flow_control_structures` info

### 2. repository 目前仍然是内存排序

本轮优先保证语义正确和测试稳定，尚未对大数据量做索引驱动分页优化。

### 3. sync foundation 仍是底座，不是完整云同步

当前只解决了本地变更排序与游标边界问题，尚未实现：

- cursor store
- push/pull protocol
- 冲突合并
- 远端事实源
