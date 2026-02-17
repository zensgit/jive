# Jive 导入中心 V10.15（窗口建议动作 + 来源感知模板跳转）

日期：2026-02-16

## 目标

继续提升失败处置效率：

1. 在失败聚合卡中增加“窗口建议动作”入口。
2. 在“配置规则模板”动作中自动按失败原因主来源切换模板来源，减少手动切换。

## 实施内容

### 1) 新增窗口建议动作入口

文件：`lib/feature/import/import_center_screen.dart`

改动：

1. 基于当前窗口聚合结果构建 `windowSuggestion`。
2. 在卡片中新增按钮：`窗口建议：<actionLabel>`。
3. 点击后复用 `_handleFailureActionSuggestion(...)` 执行。

效果：

- 用户不需要先点击某个具体原因，也可以直接执行窗口级推荐动作。

### 2) “配置规则模板”动作支持来源感知

文件：`lib/feature/import/import_center_screen.dart`

改动：

1. `_handleFailureActionSuggestion(...)` 在 `openRuleTemplate` 分支中：
   - 根据建议中的 `reasonKeyword` 收集匹配失败任务；
   - 统计主来源（sourceType）并自动切换 `_sourceType`；
   - 提示“已切换模板来源：xxx”；
   - 再打开模板编辑器。
2. 新增辅助方法：
   - `_parseImportSourceType(...)`
   - `_pickDominantSourceTypeForFailedReason(...)`
3. `_sourceLabelFromString(...)` 复用统一解析函数，避免重复逻辑。

效果：

- 点击“配置规则模板”时，默认定位到最相关来源模板，缩短操作路径。

### 3) 继续保留既有能力

仍保留：

1. 原因级 `重试可重试` / `重试最近N`
2. 窗口级 `本窗口重试可重试`
3. 批量重试完成后的二次失败摘要 + 可点击建议动作

## 测试更新

文件：`test/import_center_screen_test.dart`

新增与更新：

1. 断言 `窗口建议：查看失败任务` 按钮存在。
2. 新增 `format failure reason shows configure-template action`：
   - 断言原因级 `配置规则模板` 存在；
   - 断言窗口级 `窗口建议：配置规则模板` 存在。

## 验证结果

执行日期：2026-02-16

已执行：

1. `dart format lib/feature/import/import_center_screen.dart test/import_center_screen_test.dart`
2. `flutter test test/import_center_screen_test.dart`
3. `flutter test test/import_history_analytics_test.dart`
4. `flutter analyze`
5. `flutter test`

结果：

1. analyze 通过
2. 定向测试通过
3. 全量测试通过

## 阶段结论

V10.15 将建议动作从“仅重试结果提示可见”扩展为“窗口卡片可直接触发”，并把模板配置动作做成来源感知跳转，进一步减少失败排查与修复的人机切换成本。
