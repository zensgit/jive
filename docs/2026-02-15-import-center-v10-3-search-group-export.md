# Jive 导入中心 V10.3（历史搜索 + 分组导出完善）

日期：2026-02-15

## 本轮目标

在 V10.2 基础上继续增强可运营性：

1. 任务历史支持更快定位（快速筛选已就位并强化展示）
2. 任务详情分组视图可用于重复组复盘（分组卡片 + 组内查看）
3. 服务层筛选能力增加回归测试，确保分页/过滤稳定

## 主要改动

### 1) 导入中心历史视图强化

文件：`lib/feature/import/import_center_screen.dart`

- 历史列表保留快速筛选：全部/失败/高风险/策略跳过
- 任务条目摘要显示 `risk` 统计与明细落库异常
- 最近结果卡片补充决策摘要展示

### 2) 任务详情分组复盘能力

文件：`lib/feature/import/import_job_detail_screen.dart`

- 新增视图切换：按记录 / 按 dedupKey 分组
- 分组卡片展示：
  - 组内记录数
  - 总金额
  - 最新时间
  - 决策分布
  - 高风险提示
- 支持弹窗查看组内记录明细
- 导出 CSV 包含任务摘要头（策略、统计、筛选条件）

### 3) 测试补充

文件：`test/import_service_test.dart`

新增测试：

- `listJobRecords supports decision/risk filters and stable pagination`

覆盖点：

- 按 `decision` 筛选
- 按 `riskLevel` 筛选
- `limit + offset` 分页排序稳定性

## 验证

已执行：

- `flutter analyze`
- `flutter test test/import_service_test.dart`
- `flutter test`

结果：全部通过

