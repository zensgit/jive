# 周期记账与预算稳定性迭代报告（2026-02-12）

## 1. 迭代目标

- 让用户在规则保存后立即感知是否生效（新建+编辑都自动执行一次）。
- 保留手动执行入口，便于临时补执行。
- 预算页保持超时/失败兜底，确保可恢复。
- 补齐服务层自动化回归，覆盖去重和跨月边界。

## 2. 代码变更摘要

### 2.1 周期规则表单保存后自动执行

文件：`lib/feature/recurring/recurring_rule_form_screen.dart`

- 新增 `RecurringRuleSaveResult` 结构化返回对象。
- `_save()` 在规则保存成功后调用 `RecurringService.processDueRules()`。
- 保存结果通过 `Navigator.pop` 回传：
  - `saved`
  - `generatedDrafts`
  - `committedTransactions`
  - `processingError`

### 2.2 周期规则列表统一展示执行结果

文件：`lib/feature/recurring/recurring_rule_list_screen.dart`

- `_openRuleForm()` 改为接收 `RecurringRuleSaveResult`。
- 新增统一提示方法：
  - `_showProcessResultSnack()`
  - `_buildProcessResultMessage()`
- 保存返回后提示策略：
  - 无到期：`规则已保存，当前没有到期规则`
  - 有产出：`规则已保存并执行：草稿 X 笔，入账 Y 笔`
  - 异常：`规则已保存，但自动执行失败：...`
- 手动“立即执行一次”入口沿用同一提示逻辑。

### 2.3 预算页稳定性兼容修正

文件：`lib/feature/budget/budget_list_screen.dart`

- 删除预算时调整执行顺序并补 `mounted` 检查，规避 async context 风险。
- 货币下拉改用 `initialValue`，兼容新版 Flutter API。

### 2.4 回归测试新增

新增文件：

- `test/recurring_service_test.dart`
- `test/budget_service_test.dart`

覆盖点：

- 周期草稿去重
- 周期入账去重
- `dayOfMonth=31` 跨月补齐
- 停用规则跳过执行
- 预算汇总 smoke
- 分类预算过滤
- 周期日期边界计算

## 3. 验证矩阵

| 验证项 | 命令/方式 | 结果 | 证据 |
|---|---|---|---|
| 单元测试（全量） | `flutter test` | PASS | 终端输出全绿 |
| 定向新增测试 | `flutter test test/recurring_service_test.dart test/budget_service_test.dart` | PASS | 7 条新增测试通过 |
| Debug 构建 | `flutter build apk --debug` | PASS | `build/app/outputs/flutter-apk/app-debug.apk` |
| Dev Debug 构建 | `flutter build apk --debug --flavor dev -t lib/main.dart` | PASS | `build/app/outputs/flutter-apk/app-dev-debug.apk` |
| 真机安装 | `adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk` | PASS | `Success` |
| ADB 冒烟 | `bash scripts/verify_dev_flow.sh com.jivemoney.app.dev` | PASS | `/tmp/jive-verify-20260212-005901` |
| 静态检查 | `flutter analyze --no-fatal-infos ...` | PASS（有 info） | 表单页 9 条弃用 info |

## 4. 风险与兼容性

- 当前保留了 `RecurringRuleFormScreen` 的 Flutter 弃用 API info（`DropdownButtonFormField.value`、`RadioListTile` 旧参数），不影响功能与构建。
- 保存成功但自动执行失败时，规则仍保持已保存（符合“不因后置执行失败回滚保存”的策略）。
- 大量历史补齐仍可能增加执行耗时，建议后续考虑分批执行或后台任务化。

## 5. 回退方案

如需快速回退本轮行为，可按文件回滚：

- 回退“保存后自动执行”：`lib/feature/recurring/recurring_rule_form_screen.dart`
- 回退“列表统一结果提示”：`lib/feature/recurring/recurring_rule_list_screen.dart`
- 回退预算页兼容修正：`lib/feature/budget/budget_list_screen.dart`
- 回退新增测试：`test/recurring_service_test.dart`、`test/budget_service_test.dart`

## 6. 后续建议

- 独立推进表单组件 API 迁移，清理 analyze info。
- 在 ADB 脚本中增加“保存后提示文案”自动化断言，减少手工确认步骤。
- 如果周期规则数量增长，考虑执行耗时监控与分批补齐策略。
