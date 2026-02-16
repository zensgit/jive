# Import Center V10.6：分组搜索 + 分组导出模式

日期：2026-02-15

## 目标
1. 分组视图支持 `dedupKey` 关键词搜索，缩短重复组定位路径。
2. “导出当前筛选”在分组模式下导出分组汇总（而不是逐条记录），让复盘文件更贴近运营场景。

## 实现内容

### 1) 分组关键词搜索
- 文件：`lib/feature/import/import_job_detail_screen.dart`
- 新增状态：
  - `TextEditingController _groupSearchController`
  - `String _groupSearchQuery`
- 交互：
  - 分组模式下显示 `搜索分组 dedupKey` 输入框
  - 支持清空按钮
- 逻辑：
  - `_buildDedupGroups(...)` 新增 `searchQuery` 参数
  - 对 `dedupKey` 做不区分大小写匹配
  - 与“仅高风险分组 / 风险类型 / 排序”组合生效

### 2) 导出模式按视图切换
- 文件：`lib/feature/import/import_job_detail_screen.dart`
- 调整 `导出当前筛选`：
  - 记录视图：保持原有逐条记录 CSV 导出
  - 分组视图：导出分组汇总 CSV（每组一行）
- 分组导出字段：
  - `dedupKey,count,totalAmount,latestTimestamp,hasHighRisk,hasBatchRisk,hasExistingRisk,hasBothRisk,decisionBreakdown`
- 分组导出头部新增筛选上下文：
  - 决策筛选、风险筛选、分组风险筛选、仅高风险开关、关键词

### 3) 测试补充
- 文件：`test/import_job_detail_screen_test.dart`
- 新增用例：
  - `dedup groups support keyword search by dedupKey`
- 覆盖：
  - 分组模式输入关键词后仅保留匹配组
  - 清空关键词后恢复所有组

## 验证
在 `app/` 目录执行：

```bash
flutter analyze
flutter test test/import_job_detail_screen_test.dart
flutter test
```

结果：
- `flutter analyze`：通过（No issues found）
- 详情页 widget test：通过
- 全量 `flutter test`：通过

## 说明
- 本次改动主要为 UI 交互与导出体验增强，不影响导入去重策略和写库统计口径。
