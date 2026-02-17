# Import Center V10.4：任务搜索补强 + 分组视图控制

日期：2026-02-15

## 目标
1. 补强任务历史关键词搜索可读性与命中范围（ID/策略/状态/来源/摘要）。
2. 在任务详情的 `dedupKey` 分组视图增加可操作控制：仅高风险分组、分组排序（最新时间/总金额）。

## 实现内容

### 1) 任务历史搜索补强（ImportCenter）
- 文件：`lib/feature/import/import_center_screen.dart`
- 调整：
  - 搜索框文案更新为 `搜索任务（ID/策略/状态/来源/摘要）`。
  - hint 增加“风险”示例，便于用户理解摘要搜索。
  - `_matchesJobSearch(...)` 中新增 `job.decisionSummaryJson` 原始内容参与匹配，提升摘要关键词覆盖。

### 2) 分组视图控制（ImportJobDetail）
- 文件：`lib/feature/import/import_job_detail_screen.dart`
- 新增状态：
  - `_groupHighRiskOnly`：是否仅显示高风险分组。
  - `_groupSort`：分组排序方式，枚举 `_DedupGroupSort { latestTime, totalAmount }`。
- 交互控件：
  - `FilterChip`：`仅高风险分组`。
  - `ChoiceChip`：`按最新时间`、`按总金额`。
- 分组构建逻辑：
  - `_buildDedupGroups(...)` 支持参数 `highRiskOnly` 与 `sort`。
  - 过滤：当 `highRiskOnly=true` 时，仅保留 `hasHighRisk` 分组。
  - 排序：
    - `latestTime`：按最新时间倒序，其次按记录数、总金额。
    - `totalAmount`：按总金额倒序，其次按最新时间、记录数。
- 空态优化：
  - 当记录存在但分组被筛空时，展示 `当前分组筛选下无记录`，避免误判为“无数据”。

## 验证
在 `app/` 目录执行：

```bash
dart format lib/feature/import/import_center_screen.dart lib/feature/import/import_job_detail_screen.dart
flutter analyze
flutter test test/import_service_test.dart
flutter test
```

结果：
- `flutter analyze`：通过（No issues found）
- `flutter test test/import_service_test.dart`：通过
- `flutter test`：全量通过

## 影响范围
- 仅修改导入中心与导入任务详情页面，不影响导入核心写库策略。
- 导出逻辑保持不变（仍导出当前记录筛选结果）。

## 后续建议
1. 在分组视图增加“风险类型筛选”（批内/历史/叠加），与现有高风险开关形成组合筛选。
2. 为分组视图补 widget test：验证高风险过滤、排序切换、空态文案。
