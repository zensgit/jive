# Jive 导入中心 V3（预览勾选后导入）

日期：2026-02-15

## 本轮目标

在 V2（ImportJob + OCR）的基础上继续推进：

1. 导入前预览
2. 按记录勾选后再导入
3. 保持任务链路与重试能力

## 主要改动

### 1) ImportService 支持“预览后提交”

文件：`lib/core/service/import_service.dart`

新增能力：

- `readTextFromFile(File)`：读取并解码文件文本
- `recognizeTextFromImage(XFile)`：OCR 识别文本（空结果报错）
- `importPreparedRecords(...)`：
  - 接收已经预览/筛选后的记录
  - 创建并驱动 `ImportJob` 状态机
  - 写入任务统计（总数/新增/重复/无效）

重构：

- `importFromText` 改为：`parseText -> importPreparedRecords`
- `importFromFile` / `importFromImage` 改为先取文本再走统一导入链路

### 2) 导入中心升级为“两段式流程”

文件：`lib/feature/import/import_center_screen.dart`

从“点按钮直接导入”升级为：

- 第一步：解析到预览区
  - 文件解析预览
  - 文本解析预览
  - OCR 识别并预览
- 第二步：勾选记录并确认导入
  - 支持“全选有效 / 清空选择”
  - 无效记录不可勾选
  - 支持大批量时仅展示前 30 条（导入按全部勾选执行）

导入成功后：

- 清空本次预览状态
- 刷新任务历史

### 3) 测试补充

文件：`test/import_service_test.dart`

新增覆盖：

- `importPreparedRecords` 任务统计行为（预览所选记录入任务统计）

已保留：

- CSV 解析
- 微信文本解析
- ImportJob 重试链路

## 验证结果

- `flutter analyze`：通过
- `flutter test test/import_service_test.dart`：通过
- `flutter test`：全量通过

## 现阶段体验

用户可在导入前看到解析结果，并手动决定哪些记录进入待确认草稿，避免一次性脏数据落库。

## 下一步建议

1. 在预览列表支持行内编辑（金额/时间/类型）
2. 增加“解析置信度”与异常标注（低置信金额、异常时间）
3. 增加“导入模板配置”（列映射、来源默认值、时间格式）
