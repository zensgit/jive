# Jive 导入中心 V4（行内编辑 + 置信度/异常）

日期：2026-02-15

## 本轮目标（1+2）

1. 预览记录可编辑（金额/时间/类型）
2. 增加解析置信度与异常提示

## 主要改动

### 1) 解析结果结构增强

文件：`lib/core/service/import_service.dart`

`ImportParsedRecord` 新增：

- `confidence`：0~1 置信度
- `warnings`：异常/风险提示列表
- `copyWith()`：支持预览编辑后替换记录

解析逻辑增强（CSV 与宽松文本均覆盖）：

- 金额不可识别 -> `无法识别金额`
- 大额（>= 50000）-> `金额较大，请确认`
- 时间无法识别 -> `时间未识别，已使用默认值`
- 时间异常（未来过远/年份过旧）-> `时间异常，请确认`
- 来源未识别 -> `来源未识别，使用默认来源`
- 类型不明确 -> `交易类型未知`
- 类型由规则推断 -> `交易类型为推断值`

### 2) 导入预览支持行内编辑

文件：`lib/feature/import/import_center_screen.dart`

新增能力：

- 每条预览记录提供编辑按钮
- 弹窗可修改：
  - 金额
  - 时间（`yyyy-MM-dd HH:mm`）
  - 来源
  - 类型（未知/支出/收入/转账）
  - 原文
- 保存后会重新计算该条记录的：
  - `warnings`
  - `confidence`
- 若编辑后记录变为无效（如金额<=0），会自动取消勾选

### 3) 预览区新增质量指标

文件：`lib/feature/import/import_center_screen.dart`

新增统计 chip：

- `有警告`
- `低置信度`（confidence < 0.6）

每行展示：

- 置信度百分比 badge
- 异常提示文字（橙色）
- 编辑入口

### 4) 测试补充

文件：`test/import_service_test.dart`

新增/更新：

- `parseText produces confidence and warnings for anomaly records`
- 调整 `importFromText writes job and retry keeps history chain` 断言，适配“无效行也进入解析结果”的行为

## 验证结果

- `flutter analyze`：通过
- `flutter test test/import_service_test.dart`：通过
- `flutter test`：全量通过

## 当前效果

导入前可对单条记录做精修，并可快速识别低置信度和风险数据，显著降低错误导入概率。

## 下一步建议

1. 预览列表支持批量编辑（批量改类型/来源）
2. 增加“只看异常”过滤开关
3. 为不同 warning 赋予权重并展示“高/中/低风险等级”
