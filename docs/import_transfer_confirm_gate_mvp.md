# Import Transfer Confirm Gate MVP

## Scope
- 在 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart` 的“确认导入所选记录”前增加转账导入校验。
- 对 `transfer` 记录做最小但明确的阻断和待确认分流，避免把明显错误的转账行直接送进 `ImportCenter -> AutoDraftService`。
- 保持现有导入主链路不变，不新开一条 transfer-only production flow。

## Gate Rules
1. 阻断
   - 缺少转入账户
   - 转出账户与转入账户相同
   - 金额本身已无效
2. 待确认
   - 缺少显式转出账户
   - 转出账户不在当前有效账户列表
   - 转入账户不在当前有效账户列表
   - 手续费大于等于转账金额

## Pipeline
1. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_transfer_confirm_service.dart`
   - 只评估 `type == transfer` 的记录。
   - 输出 `ready/review/block` 统计和可展示的 issue 列表。
2. `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
   - 在 `_confirmImportPrepared()` 里先做 transfer confirm gate。
   - 有阻断项时弹窗提示并终止导入。
   - 只有待确认项时允许用户“继续导入”或“返回检查”。
3. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/account_service.dart`
   - 提供当前有效账户名列表，供 gate 做已知账户校验。

## Result
- 转账导入在进入 `AutoDraftService` 之前就会拦下缺少转入账户和同账户互转这类硬错误。
- 对“未知账户”“高手续费占比”这类灰区场景，用户仍可显式确认继续，不会误伤可修复数据。
- 这层校验比 yimu 更严格，因为它把阻断和 review 区分成了两级，而不是只依赖后续导入结果页兜底。
