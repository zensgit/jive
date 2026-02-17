# Jive 导入中心 V8+V9（规则模板 + 重复决策）

日期：2026-02-15

## 本轮目标（1+2）

1. V8：导入规则模板化（可保存复用）
2. V9：高风险重复项导入前决策

## 实现概览

### V8 规则模板化

文件：`lib/feature/import/import_center_screen.dart`

新增模板能力（按来源维度保存）：

- 模板字段：
  - 默认来源
  - 默认类型（可不设置）
  - 时间偏移（分钟，支持正负）
  - 工作日规则（不校正/周末顺延/周末前移）
  - 来源覆盖策略（仅覆盖默认来源 Import/OCR / 覆盖全部）
- 存储方式：`SharedPreferences`
  - key：`import_rule_template_<sourceType>`
- 交互能力：
  - `规则模板`：打开编辑弹窗并保存
  - `清除模板`：清空当前来源模板
  - `应用到预览`：对当前预览批次即时套用模板

模板应用时会自动重算：

- warning
- confidence

### V9 高风险重复决策

文件：`lib/core/service/import_service.dart`

新增重复分析模型：

- `ImportDuplicateRiskItem`
  - 记录索引
  - 去重键
  - 是否批内重复
  - 是否历史重复
  - 历史最新时间
- `ImportDuplicateReview`
  - 高风险总数
  - 批内重复计数
  - 历史重复计数
  - 索引映射

新增分析方法：

- `analyzeDuplicateRisk(List<ImportParsedRecord>)`
  - 结合导入批次与历史交易/草稿，生成逐条风险明细
- `estimateDuplicateRisk(...)` 重构为复用统一历史键加载逻辑

文件：`lib/feature/import/import_center_screen.dart`

预览页新增：

- 高风险统计 Chip（`高风险 N`）
- 行级风险标签（`疑似重复：批内 / 历史 / 批内+历史`）
- 一键决策按钮：
  - `重复: 全保留`
  - `重复: 全跳过`
  - `重复: 仅保留最新`

“仅保留最新”规则：

- 按 dedupKey 分组，仅保留导入批次中最新的一条
- 若历史已存在且历史时间不早于导入最新，则该组不保留

## 导出复核清单增强

文件：`lib/feature/import/import_center_screen.dart`

CSV 新增 `duplicateRisk` 列（`batch` / `existing` / `batch+existing`），支持复核时快速定位风险来源。

## 测试与验证

执行时间：2026-02-15

已执行：

- `flutter analyze`
- `flutter test test/import_service_test.dart`
- `flutter test`

结果：

- 分析通过
- 定向测试通过
- 全量测试通过

新增测试：

- `analyzeDuplicateRisk returns risk items with batch/existing flags`

## 当前导入体验（阶段结论）

导入链路已具备完整“预处理-决策-复核”能力：

1. 规则模板先做结构化预处理
2. 重复风险前置暴露并支持一键决策
3. 复核清单可导出并携带风险列

