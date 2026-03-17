# Phase431 Design

## Background
上一轮已经把 `ImportCenter` 的 transfer guard 做到导入确认边界，但 `AutoDraftService.confirmDraft()` 仍可被旧 draft 或批量确认路径直接调用，存在两类缺口：
1. `toAccountId == null` 但 metadata/rawText 还能解析时，没有二次解析。
2. `accountId == toAccountId` 时，service 侧没有最终阻断。

`AutoDraftsScreen._confirmAll()` 也只做了 UI 层补全，没有对 service 拒绝结果做批量反馈。

## Design
### 1. Service-side hard gate
在 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`：
- 新增 `AutoDraftConfirmException`
- `confirmDraft()` 在提交前调用 `_resolveDraftAccountIds()`
- 对 transfer 使用现有账户解析逻辑二次补全：
  - `draft.accountId`
  - `draft.toAccountId`
  - metadata `transferToAccountName`
  - rawText hint / mapping fallback
- `_commitTransaction()` 增加最终约束：
  - `missing_transfer_target_account`
  - `same_transfer_account`

### 2. Batch confirm fail-soft
在 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/auto/auto_drafts_screen.dart`：
- 单条确认 catch `AutoDraftConfirmException` 并提示
- `全部确认` 改成：
  - 可确认的继续提交
  - 非法 transfer 跳过
  - 结束后统一 snackbar 汇总
  - 用户取消补全转账账户时停止剩余批量确认

### 3. Regression coverage
新增 `/Users/huazhou/Downloads/Github/Jive/app/test/auto_draft_service_test.dart`：
- metadata 解析成功后确认转账
- unresolved target 阻断
- same-account 阻断

并把新测试接入 `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`。
