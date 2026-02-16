# Jive 导入中心 V6（仅已选筛选 + 批量时间偏移）

日期：2026-02-15

## 本轮目标（1+2）

1. 增加“仅看已勾选”筛选
2. 增加“批量改时间（分钟/小时偏移）”

## 主要改动

### 1) 预览筛选新增“仅已选”

文件：`lib/feature/import/import_center_screen.dart`

- 扩展 `_PreviewFilter`：新增 `selected`
- 过滤逻辑改为按 `index + record` 判定，支持依据勾选状态过滤
- 新增筛选 Chip：`仅已选`

### 2) 批量时间偏移

文件：`lib/feature/import/import_center_screen.dart`

新增功能：

- 按当前勾选记录执行“时间整体偏移”
- 支持输入正负整数（可前移/后移）
- 单位支持：分钟 / 小时
- 批量应用后自动重算每条记录质量：
  - warnings
  - confidence

### 3) 现有能力保持

- 预览筛选：全部 / 仅已选 / 仅异常 / 低置信度 / 无效
- 批量编辑：类型、来源、时间偏移
- 单条编辑：金额、时间、类型、来源、原文

## 验证

- `flutter analyze`：通过
- `flutter test test/import_service_test.dart`：通过
- `flutter test`：全量通过

## 下一步建议

1. 批量偏移支持“按工作日规则”自动校正
2. 导入前增加“预估重复率”提示
3. 支持将当前筛选结果导出为复核清单
