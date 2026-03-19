# Auto Draft Transfer Confirm Gate MVP

## Goal
在 `AutoDraftService.confirmDraft()` 和 `AutoDraftsScreen._confirmAll()` 增加最终转账确认兜底，避免旧 draft、批量确认或未来调用方绕过 UI 层检查后写入非法转账。

## Scope
- `AutoDraftService`
  - 在确认前重做一次账户解析
  - 对 `transfer` 强制拦截 `missing_transfer_target_account`
  - 对 `transfer` 强制拦截 `same_transfer_account`
- `AutoDraftsScreen`
  - 单条确认时展示 service 级失败提示
  - 批量确认时跳过非法 draft，并给出汇总提示
- `run_release_regression_suite.sh`
  - 纳入 `auto_draft_service_test.dart`

## Non-goals
- 不改 `settings_screen.dart`
- 不做 Android 新集成页
- 不改现有导入预览/确认流程

## Result
- 旧 transfer draft 即使缺少 `toAccountId`，也会先尝试从 metadata/rawText 解析真实账户
- 无法解析目标账户时不会落库 transaction
- 源/目标账户解析后相同也不会落库 transaction
- 批量确认不再因单条非法 transfer 直接写脏数据
