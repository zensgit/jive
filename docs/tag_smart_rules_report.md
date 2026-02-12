# 标签增强与刷新机制 - 设计与验证报告

日期：2026-01-25

## 目标与结论
- 首页列表：新增交易后应立即刷新，避免“退出再进才显示”的体验。
- 智能标签：在交易详情中区分“智能标签”来源，避免与普通标签混淆。
- 智能标签补标：支持对历史交易进行智能规则补标（只补未打该标签的交易）。
- 补标过程：提供进度显示与取消能力。
- 标签相关页面：响应数据变更的统一刷新机制。

已实现并打包安装 debug 版本。

## 设计说明
### 1) 首页列表自动刷新
- **改动点**：`lib/main.dart`
- **设计**：在新增交易返回时，`await _loadTransactions()` + `await _loadAutoDraftCount()`，确保 Home 数据刷新完成后再继续通知。
- **原因**：避免异步未完成导致 UI 未及时更新。

### 2) 交易详情展示“智能”标识
- **改动点**：`lib/core/database/transaction_model.dart`、`lib/feature/transactions/transaction_detail_screen.dart`
- **数据结构**：新增字段 `smartTagKeys`，记录“由规则自动添加的标签”。
- **UI 表现**：标签 Chip 右侧显示小徽标「智能」，与标签名分离，避免被误认为标签名一部分。
- **准确性**：仅对自动添加的标签标记“智能”，手动添加的标签不标记。

### 3) 智能标签历史补标
- **改动点**：`lib/core/service/tag_rule_service.dart`、`lib/feature/tag/tag_rule_screen.dart`
- **能力**：基于当前规则对历史交易补标，仅补“尚未包含该标签”的交易。
- **结果提示**：完成后提示“已补标 X 笔（匹配 Y/共 Z）”。
- **数据一致性**：补标后调用 `TagService.refreshUsageCounts()` 更新使用次数。

### 4) 补标进度与取消
- **改动点**：`lib/feature/tag/tag_rule_screen.dart`、`lib/core/service/tag_rule_service.dart`
- **能力**：补标过程显示进度条、已处理数量，并支持用户取消。
- **策略**：每处理一批次更新进度；用户取消后返回“已处理数量”的提示。

### 5) 数据变更统一刷新
- **改动点**：`lib/core/service/data_reload_bus.dart`、`lib/feature/tag/*`、`lib/feature/transactions/add_transaction_screen.dart`、`lib/core/service/auto_draft_service.dart`、`lib/main.dart`
- **设计**：引入全局通知 `DataReloadBus`，标签管理/统计/交易列表在收到通知后自动刷新。
- **触发点**：交易保存、自动记账落库时通知刷新。

### 6) 数据导入导出兼容
- **改动点**：`lib/core/service/data_backup_service.dart`
- **内容**：`smartTagKeys` 纳入备份 JSON 导出/导入。

## 关键实现点
- **新增字段**：`JiveTransaction.smartTagKeys`（Isar List<String>）
- **规则补标**：`TagRuleService.backfillForTag(tagKey)`
- **详情展示**：交易详情里新增“标签”区块，显示标签 Chip + 智能徽标
- **进度取消**：`TagRuleService.backfillForTag(... onProgress/shouldCancel)` + 进度对话框
- **统一刷新**：`DataReloadBus.notify()` + 标签页面监听刷新

## 验证步骤
### A. 首页刷新
1. 首页点「+」新建交易。
2. 保存后返回首页。
3. **期望**：新交易立即出现在列表中，无需重新进入页面。

### B. 智能标签标识
1. 进入「标签管理 → 长按标签 → 智能标签」。
2. 新增规则（示例：类型=支出，关键词=外卖）。
3. 新建一笔支出交易，备注填写“外卖”。
4. 打开交易详情。
5. **期望**：标签 Chip 显示小徽标「智能」。

### C. 历史补标
1. 打开「智能标签」页面右上角“魔法棒”按钮。
2. 点击“补标历史交易”。
3. **期望**：出现完成提示，历史交易中符合规则且未含该标签的记录被补标。

### D. 补标进度/取消
1. 在有较多历史交易时点击“补标历史交易”。
2. **期望**：弹出进度对话框，显示进度条与已处理数量。
3. 点击“取消”。
4. **期望**：补标被停止，提示已处理数量。

### E. 标签页统一刷新
1. 在标签管理页保持打开。
2. 新建一笔交易或触发自动记账入库。
3. **期望**：标签管理/统计/交易列表自动刷新，无需返回重进。

## 验证结果（本次）
- `flutter pub get` 成功。
- `dart run build_runner build --delete-conflicting-outputs` 成功。
- `flutter build apk --debug` 成功。
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 成功。
- 端侧交互验证（A-E）需在手机上按步骤确认。

## 变更文件
- `lib/main.dart`
- `lib/core/database/transaction_model.dart`
- `lib/core/database/transaction_model.g.dart`
- `lib/core/database/tag_rule_model.dart`
- `lib/core/database/tag_rule_model.g.dart`
- `lib/core/service/data_backup_service.dart`
- `lib/core/service/auto_draft_service.dart`
- `lib/core/service/tag_rule_service.dart`
- `lib/core/service/data_reload_bus.dart`
- `lib/feature/tag/tag_rule_screen.dart`
- `lib/feature/tag/tag_management_screen.dart`
- `lib/feature/tag/tag_statistics_screen.dart`
- `lib/feature/tag/tag_transactions_screen.dart`
- `lib/feature/transactions/add_transaction_screen.dart`
- `lib/feature/transactions/transaction_detail_screen.dart`

## 构建与安装
- 已执行 `dart run build_runner build --delete-conflicting-outputs`
- 已构建并安装 `build/app/outputs/flutter-apk/app-debug.apk`
