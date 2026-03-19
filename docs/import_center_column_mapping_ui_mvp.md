# ImportCenter Column Mapping UI MVP

## Scope
- 在 `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/import/import_center_screen.dart` 的预览区新增真实的“列映射检查/修复”入口。
- 面向当前 `ImportCenter` 的通用 CSV 预览链路，只要求 `金额 + 日期` 为硬门禁，不再把账本/分类当作当前场景的阻断条件。
- 允许用户在预览阶段人工指定：金额列、日期列、账户/来源列、收支类型列、备注列。

## Behavior
- 解析 CSV 预览后，如果检测到可识别列头，则展示列映射状态卡。
- 列映射状态使用 `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_column_mapping_failfast_service.dart` 统一评估：
  - `ready`
  - `review`
  - `block`
- `block` 时阻断“应用到预览”。
- `review` 和 `ready` 均允许将人工修复结果重新应用到当前预览。
- 重新应用后会：
  - 重新生成 `ImportParsedRecord`
  - 重新计算有效/无效数量
  - 重新刷新重复风险洞察
  - 重新按“有效记录默认选中”生成勾选状态

## Why
- 对标 yimu 的 `ImportSelfActivity`，Jive 之前只有 host 侧 fail-fast 报告，没有真正的 UI 修复路径。
- 这次补齐的是“导入前人工纠偏”的最小生产闭环，而不是只停在回归服务。
