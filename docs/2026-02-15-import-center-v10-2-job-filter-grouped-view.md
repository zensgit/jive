# Jive 导入中心 V10.2（任务筛选 + 分组视图）

日期：2026-02-15

## 本轮目标（1+2）

1. 导入任务历史快速筛选（失败/高风险/策略跳过）
2. 任务详情支持按 `dedupKey` 分组查看

## 实现内容

### 1) 任务历史快速筛选

文件：`lib/feature/import/import_center_screen.dart`

新增：

- `_JobQuickFilter`：`all / failed / highRisk / skipped`
- 历史列表顶部 `ChoiceChip` 快速筛选
- 高风险筛选基于 `decisionSummaryJson.highRisk`
- 列表空态提示改为“当前筛选下暂无导入任务”

同时增强：

- 最近一次结果卡片显示风险摘要信息
- 任务历史列表展示摘要信息（风险统计/明细写入异常）

### 2) 任务详情 dedupKey 分组视图

文件：`lib/feature/import/import_job_detail_screen.dart`

新增：

- 视图切换：`按记录` / `按 dedupKey 分组`
- 分组卡片信息：
  - 组内记录数
  - 总金额
  - 最新时间
  - 决策分布
  - 高风险提示
- “查看组内记录”弹窗，展示该组记录细节

### 3) 导出增强（详情页）

文件：`lib/feature/import/import_job_detail_screen.dart`

导出 CSV 追加任务摘要头：

- 任务 ID
- 策略
- 总计/新增/重复/无效/策略跳过/高风险
- 当前筛选条件（决策/风险）

## 验证

已执行：

- `flutter analyze`
- `flutter test`

结果：

- 全部通过

