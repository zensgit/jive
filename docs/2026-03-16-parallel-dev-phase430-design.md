# Phase430 Design

## Background
- Phase429 已经给 transfer import 补了 confirm gate，但判定仍停留在字符串层面：
  - 缺少转入账户会阻断
  - 未知转入账户只会 review
- 现有 `AutoDraftService` 在真正 ingest 时已经有自己的账户解析逻辑，因此 submit gate 需要和它对齐，不然会出现 preview gate 和 draft ingest 标准不一致。

## Design
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_transfer_confirm_service.dart`
  - 新增 `ImportTransferKnownAccount`
  - 支持按真实账户列表做解析，而不只依赖 name set
  - 账户匹配规则对齐 `AutoDraftService._resolveExplicitAccountId()`
  - 将 `unknown_target_account` 从 `review` 提升为 `block`
  - 保留 `unknown_source_account` 为 `review`
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
  - transfer gate 传入 `AccountService.getActiveAccounts()` 的真实账户快照
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/test/import_transfer_confirm_service_test.dart`
  - 覆盖 fuzzy source account 命中
  - 覆盖未知 target account 阻断
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_transfer_guard_flow_test.dart`
  - 新增 Android 场景：目标账户存在字段但未命中当前账户列表时阻断导入

## Tradeoff
- 本轮没有把 gate 下沉到 transaction commit 层做第二道 hard stop，因为当前最小收益点仍是 import submit 边界。
- 没有引入模糊评分、别名表或账户映射学习，只复用现有 exact/contains 规则，保持风险可控。
