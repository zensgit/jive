# Import Transfer Metadata Bridge MVP

## Scope
- 在导入阶段为 transfer 草稿补一层稳定的 metadata bridge。
- 让 `ImportParsedRecord` 到 `JiveAutoDraft` 之间的转账专属信息可恢复、可确认、可测试。

## Metadata Keys
- `transferToAccountName`
- `transferServiceCharge`

## Design
1. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`
   - `AutoCapture` 新增 `toAccountName`、`serviceCharge`。
   - ingest 时生成 JSON metadata 挂到 `JiveAutoDraft.metadataJson`。
   - confirm 时读取 metadata 并补回 transaction transfer fields。
2. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart`
   - 相似记录修复 fan-out 会同步传播 `toAccountName`、`serviceCharge`。
3. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
   - `importPreparedRecords` 负责把转账字段从 preview record 传给 `AutoCapture`。

## Result
- transfer import 的目标账户和手续费可以稳定跨过 draft bridge。
- host 测试和 Android 集成都能直接断言 metadata，不必依赖 UI 文案间接推断。
- 为后续单独拆 `transfer import preview/edit/confirm` 链路保留了稳定边界。
