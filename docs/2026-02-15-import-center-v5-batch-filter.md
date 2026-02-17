# Jive 导入中心 V5（批量编辑 + 异常筛选）

日期：2026-02-15

## 本轮目标

在 V4（单条编辑 + 置信度）基础上继续推进：

1. 批量编辑预览记录
2. 仅看异常/低置信度筛选

## 主要改动

### 1) 预览筛选能力

文件：`lib/feature/import/import_center_screen.dart`

新增筛选枚举与逻辑：

- `_PreviewFilter`：
  - `all`
  - `warning`
  - `lowConfidence`
  - `invalid`
- `FilterChip` 快速切换筛选
- 支持在筛选结果为空时展示空态提示
- 预览列表现在基于可见索引渲染，而不是固定前 N 条原始记录

### 2) 批量编辑能力（对已勾选记录）

文件：`lib/feature/import/import_center_screen.dart`

新增按钮：

- `批量改类型`
- `批量改来源`

行为：

- 仅对当前已勾选记录生效
- 批量更新后自动重算每条记录的：
  - `warnings`
  - `confidence`
- 若记录变为无效，自动取消勾选

### 3) 解析质量链路保持一致

文件：`lib/core/service/import_service.dart`

保持/完善：

- `ImportParsedRecord` 包含 `confidence` 与 `warnings`
- CSV 与宽松文本解析都统一打标异常
- 金额、时间、来源、类型共同影响置信度

## 测试与验证

- `flutter analyze`：通过
- `flutter test test/import_service_test.dart`：通过
- `flutter test`：全量通过

## 当前导入体验

导入流程已经支持：

1. 解析预览
2. 筛选异常
3. 批量修正
4. 勾选确认导入

这使得真实账单导入时，异常数据能被快速定位并一次性修正。

## 下一步建议

1. 增加“仅看已勾选”筛选
2. 批量编辑再扩展“批量改时间（偏移分钟/小时）”
3. 预览列表支持导出异常报告（便于人工复核）
