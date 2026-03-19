# Import Structured Field Pipeline MVP

## Scope
- 将 CSV 导入从松散文本预览提升到结构化字段预览。
- 让 `ImportParsedRecord`、`AutoCapture`、`AutoDraftService` 共享同一组结构化导入字段。
- 让导入后的草稿能优先消费显式账本、账户、分类、标签提示，而不是完全依赖规则推断。

## Added Fields
- `accountBookName`
- `accountName`
- `parentCategoryName`
- `childCategoryName`
- `tagNames`

## Pipeline
1. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_service.dart`
   - 从 CSV header alias 解析结构化字段。
   - 在 `copyWith`、prepared import 和 review checklist 中保留结构化字段。
2. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_csv_mapping_service.dart`
   - 支持列映射后的二次解析。
   - 支持 tag/account/category 结构化列。
3. `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/auto_draft_service.dart`
   - 优先按显式结构化字段解析账户、分类、标签。
   - 结构化分类提示可提前推断交易类型。

## Result
- 导入预览不再只展示 `amount/source/timestamp/rawText/type`。
- CSV 导入现在可直接承载账本、账户、父子分类、标签。
- 结构化字段在导入预览、手工修复、草稿落库之间不再丢失。
