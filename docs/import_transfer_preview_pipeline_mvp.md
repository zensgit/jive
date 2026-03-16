# Import Transfer Preview Pipeline MVP

## Scope
- 让 `ImportCenter` 和现有导入管线真正识别转账导入，而不是把转账仅当作普通 `type` 字段。
- 在 CSV 自动解析、列映射修复、导入预览、草稿落库、最终确认之间保留转账专属字段。
- 复用现有 `ImportCenter -> AutoDraftService` 链路，不额外新开一条高风险 transfer-only production flow。

## Added Fields
- `toAccountName`
- `serviceCharge`

## Pipeline
1. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
   - 识别 `转入账户`、`手续费` header alias。
   - 若出现 `toAccountName` 或 `serviceCharge`，优先推断为 `transfer`。
   - 在 review checklist 和 prepared import 中保留转账字段。
2. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
   - 支持显式选择 `转入账户列`、`手续费列`。
   - 映射重放后保留转账字段和 review warning。
3. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`
   - ingest 时优先消费显式 `toAccountName`。
   - 在 draft metadata 中保留转入账户名和手续费。
   - confirm draft 时把手续费回填到 `exchangeFee`。
4. `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
   - 编辑对话框新增 `转入账户`、`手续费`。
   - 预览 chips 展示 `转入 ...` 和 `手续费 ¥...`。
   - review checklist CSV 新增 `toAccountName`、`serviceCharge`。

## Result
- `ImportCenter` 现在能真实预览转账导入的转出账户、转入账户和手续费。
- 转账导入不再在 `ImportCenter -> AutoDraftService` 之间丢失目标账户与费用信息。
- 保持现有 pipeline 结构，避免提前把 repayment/fee split 之类高风险语义硬塞进主链路。
