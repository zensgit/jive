# Import Record Repair Fan-out MVP

## Scope
- 为 `ImportCenter` 增加“修一条，同步到相似记录”的结构化修复能力。
- 批量传播只覆盖结构化字段，不覆盖金额和时间，避免把人工校正扩散到不安全字段。

## Matching Rule
- 默认按以下维度匹配相似记录：
  - `source`
  - `type`
  - 规范化后的 `rawText`

## Fan-out Fields
- `accountBookName`
- `accountName`
- `parentCategoryName`
- `childCategoryName`
- `tagNames`

## UI Entry
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart`
  - 编辑预览记录时新增结构化字段输入框。
  - 新增“将结构化修复批量应用到相似记录”复选框。
  - 保存后展示同步到多少条相似记录的提示。

## Service
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_record_repair_fanout_service.dart`
  - 负责匹配、批量应用和生成影响摘要。

## Result
- 预览修复不再只能逐条处理。
- 同类 OCR/CSV 记录可以批量收敛到账户、分类、标签一致状态。
- 该能力对 `yimu` 的单条修复 fallback 做了超越，增加了结构化 fan-out。
