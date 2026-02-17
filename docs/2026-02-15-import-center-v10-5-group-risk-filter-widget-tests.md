# Import Center V10.5：分组风险类型筛选 + Widget 测试

日期：2026-02-15

## 目标
1. 在任务详情 `dedupKey` 分组视图补充风险类型筛选（批内/历史/叠加），并与“仅高风险分组”组合使用。
2. 增加 widget test，覆盖分组排序、高风险筛选和筛空状态，降低 UI 迭代回归风险。

## 实现

### 1) 分组风险类型筛选
- 文件：`lib/feature/import/import_job_detail_screen.dart`
- 新增：
  - 枚举 `_DedupGroupRiskTypeFilter { all, batch, existing, both }`
  - 状态 `_groupRiskTypeFilter`
  - 分组摘要能力：`hasBatchRisk`、`hasExistingRisk`、`hasBothRisk`、`matchesRiskType(...)`
- UI 控件（分组模式下）：
  - `风险:全部` / `风险:批内` / `风险:历史` / `风险:叠加`
  - 与现有 `仅高风险分组`、`按最新时间`、`按总金额` 联动
- 分组筛选逻辑：
  - `_buildDedupGroups(...)` 新增 `riskTypeFilter` 参数
  - 先应用高风险筛选，再应用风险类型筛选
- 可测试性增强：
  - 分组卡片增加 `ValueKey('dedup_group_<dedupKey>')`

### 2) 可测试注入（仅用于测试场景）
- 文件：`lib/feature/import/import_job_detail_screen.dart`
- `ImportJobDetailScreen` 新增可选参数：
  - `debugJob`、`debugSummary`、`debugRecords`
- 当三者同时提供时，页面走本地 fixture 数据加载，不访问数据库。
- 过滤变更时使用 `_filterFixtureRecords(...)` 复用筛选行为。

### 3) Widget 测试
- 文件：`test/import_job_detail_screen_test.dart`
- 用例：
  - `dedup groups can switch sort by latest time and total amount`
  - `dedup groups support high-risk and risk-type filtering with empty state`
- 覆盖点：
  - 分组默认排序（按最新时间）与切换排序（按总金额）
  - “仅高风险分组”过滤效果
  - 选择“风险:叠加”后的空态文案 `当前分组筛选下无记录`

## 验证
在 `app/` 目录执行：

```bash
flutter analyze
flutter test test/import_job_detail_screen_test.dart
flutter test
```

结果：
- `flutter analyze`：通过（No issues found）
- 新增 widget test：通过
- 全量 `flutter test`：通过

## 备注
- 本次为 UI 层与可测试性增强，不改动导入核心策略（去重判定、写库决策、统计口径保持不变）。
