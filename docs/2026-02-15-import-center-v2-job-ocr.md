# Jive 导入中心 V2（ImportJob + OCR）

日期：2026-02-15

## 目标

在现有自动草稿体系上继续推进 `1+2`：

1. 导入任务持久化与状态机（ImportJob）
2. OCR 导入流程（截图 -> 识别 -> 解析 -> 草稿）

## 实现内容

### 1) ImportJob 持久化与状态机

新增模型：`lib/core/database/import_job_model.dart`

- 字段覆盖：
  - 状态：`status`（`pending/running/review/failed`）
  - 来源：`sourceType`（auto/csv/alipay/wechat/ocr）
  - 入口：`entryType`（text/file/image）
  - 任务统计：`totalCount/insertedCount/duplicateCount/invalidCount`
  - 重试链：`retryFromJobId/retryCount`
  - 调试信息：`payloadText/filePath/fileName/errorMessage`
  - 时间戳：`createdAt/updatedAt/finishedAt`

新增生成文件：`lib/core/database/import_job_model.g.dart`

### 2) 导入服务（含任务状态驱动）

新增服务：`lib/core/service/import_service.dart`

能力：

- 导入入口：
  - `importFromText`
  - `importFromFile`
  - `importFromImage`
  - `retryJob`
- 解析策略：
  - CSV/TSV（支持表头别名）
  - 微信/支付宝/通用 OCR 文本（宽松行解析）
- 入库策略：
  - 统一调用 `AutoDraftService.ingestCapture`，保持去重/分类行为一致
  - 导入结果汇总：新增/重复/无效
- 任务状态流：
  - `pending -> running -> review`
  - 异常时：`pending -> running -> failed`
- 重试历史：
  - 新任务引用 `retryFromJobId`
  - 自动计算 `retryCount`

### 3) OCR 服务

新增服务：`lib/core/service/ocr_service.dart`

- 基于 `google_mlkit_text_recognition`
- 输入图片路径，输出识别文本
- `ImportService.importFromImage` 负责串联 OCR + 导入

### 4) 导入中心页面

新增页面：`lib/feature/import/import_center_screen.dart`

功能：

- 来源切换：自动识别 / CSV / 支付宝 / 微信 / OCR
- 三类入口：
  - 文件导入（CSV/TSV/TXT）
  - 粘贴文本导入
  - OCR 导入（相册截图）
- 结果面板：总计/新增/重复/无效/任务ID
- 任务历史：状态、统计、来源、重试按钮
- 跳转草稿页：直接进入“待确认自动记账”

### 5) 主菜单接入

修改：`lib/main.dart`

- 新增“导入中心”菜单项
- 新增 `_openImportCenter()`
- 导入中心返回 `changed == true` 时刷新：
  - 交易列表
  - 待确认草稿计数
  - 数据刷新信号

### 6) 数据库与备份兼容

修改：

- `lib/core/service/database_service.dart`
  - 注册 `JiveImportJobSchema`
- `lib/core/service/data_backup_service.dart`
  - `schemaVersion` 升级到 `3`
  - 导出/导入 `importJobs`
  - `BackupImportSummary` 新增 `importJobs`

### 7) 依赖更新

修改：`pubspec.yaml`

- 新增：`google_mlkit_text_recognition`

## 验证

执行结果：

- `flutter analyze`：通过
- `flutter test test/import_service_test.dart`：通过
- `flutter test`：全量通过

新增测试：`test/import_service_test.dart`

- CSV 解析
- 微信文本解析
- ImportJob 状态与重试链路

## 已知限制

- OCR 质量受截图清晰度、布局和金额格式影响
- 通用 OCR 文本解析采用启发式规则，极端账单模板仍可能出现漏识别
- 重试依赖 `payloadText` 或可访问的 `filePath`；若原始文件丢失且无 payload，会提示无法重试

## 下一步建议

1. 为 OCR 结果增加“导入前预览编辑”能力（逐条勾选/修正）
2. 增加“金额/时间/来源”解析置信度与异常提示
3. 针对真实账单样本补充回归测试集（微信/支付宝/银行通知）
