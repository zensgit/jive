# Jive 导入中心 V10.16（失败来源范围过滤）

日期：2026-02-16

## 目标

在 V10.15 的失败聚合与建议动作能力上，补齐“来源维度”范围控制：

1. 允许在失败聚合卡按来源筛选（全部/自动/CSV/支付宝/微信/OCR）。
2. 让失败聚合、重试入口、建议动作共享同一来源范围。
3. 降低多来源混合场景下的误判与误操作。

## 本轮实现

### 1) 失败聚合卡新增来源过滤 Chips

文件：`lib/feature/import/import_center_screen.dart`

新增状态：

- `_failureSourceTypeFilter`（`ImportSourceType?`，null 表示全部来源）

新增 UI：

- `来源:全部`
- `来源:自动`
- `来源:CSV`
- `来源:支付宝`
- `来源:微信`
- `来源:OCR`

影响范围：

1. 失败原因聚合结果。
2. 失败任务数量与可重试/不可重试统计。
3. 原因行级可重试占比。

### 2) 重试入口改为来源范围感知

文件：`lib/feature/import/import_center_screen.dart`

改动：

1. `重试最近N` 与 `重试可重试`（原因级）均仅作用于当前来源范围。
2. `本窗口重试可重试`（窗口级）同样仅作用于当前来源范围。
3. 确认弹窗范围文案升级为：
   - `当前窗口（<时间窗口> / <来源范围>）`

### 3) 建议动作改为来源范围感知

文件：`lib/feature/import/import_center_screen.dart`

改动：

1. `配置规则模板` 动作在推断主来源时，只统计当前来源范围内的失败任务。
2. 避免跨来源数据把模板编辑器切到不相关来源。

### 4) 失败任务收集逻辑统一

文件：`lib/feature/import/import_center_screen.dart`

新增统一方法：

- `_collectFailedJobs({since, sourceType})`

并让下列能力统一复用：

1. 失败聚合基数据。
2. 原因级重试。
3. 窗口级重试。
4. 原因级可重试快照。

## 测试更新

文件：`test/import_center_screen_test.dart`

新增测试：

- `failure aggregate supports source filter chips`

覆盖：

1. 默认来源范围下 `new issue ×2`。
2. 切换 `来源:支付宝` 后仅保留支付宝失败原因结果。
3. 切换 `来源:微信` 后显示微信失败原因结果。

## 验证结果

执行日期：2026-02-16

已执行：

1. `dart format lib/feature/import/import_center_screen.dart test/import_center_screen_test.dart`
2. `flutter analyze`
3. `flutter test test/import_center_screen_test.dart`
4. `flutter test test/import_history_analytics_test.dart`
5. `flutter test`

结果：

1. analyze 通过。
2. 定向测试通过。
3. 全量测试通过。

## 阶段结论

V10.16 为失败聚合与重试闭环补齐了“来源范围”控制，确保失败分析、重试执行与建议动作在同一范围内一致收敛，提升了多来源导入场景下的可控性与准确性。
