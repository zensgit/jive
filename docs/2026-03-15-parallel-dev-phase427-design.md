# Phase427 Design

## Background
- Phase426 已经补了真实列映射修复 UI 和 import history repository。
- 但导入主链路还有两个明显缺口：
  - `ImportParsedRecord` 仍以松散文本为主，账本、账户、父子分类、标签在导入预览到草稿落库之间没有统一字段。
  - `ImportCenter` 虽然能手工修一条记录，但没有对同类记录做结构化 repair fan-out。

## Design
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
  - 为 `ImportParsedRecord` 增加结构化字段。
  - 在 CSV 解析阶段直接识别账本、账户、父分类、子分类、标签。
  - 在 `_importRecords()` 中把结构化字段传给 `AutoCapture`。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
  - 让列映射修复对话框可以显式指定结构化列。
  - 映射重放后保留结构化字段，而不是回退为普通备注。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`
  - 在 ingest 时优先消费显式账户、分类、标签。
  - 仅在结构化提示缺失时回退到现有规则引擎推断。
- 新增 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart`
  - 为 `ImportCenter` 提供结构化修复批量应用能力。
  - fan-out 只传播 source/type/account/category/tag，不传播金额和时间。
- 扩展 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
  - 预览卡展示结构化字段。
  - 列映射对话框新增账本/父分类/子分类/标签列。
  - 记录编辑对话框新增结构化字段和 fan-out 复选框。

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_csv_mapping_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_center_screen_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_record_repair_fanout_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_column_mapping_repair_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_structured_field_pipeline_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_record_repair_fanout_mvp.md`

## Tradeoff
- 结构化字段让 import pipeline 更强，但也增加了 `ImportParsedRecord`、`AutoCapture`、UI 编辑态之间的字段同步成本。
- fan-out 默认只按 `source/type/rawText` 相似性传播，这是偏保守策略；短期内不会覆盖金额和时间，避免把错误扩散到高风险字段。
- 本轮优先把真实存在的 `ImportCenter` 链路做实，没有把 `transfer import` 单独拆成新的 production flow。
