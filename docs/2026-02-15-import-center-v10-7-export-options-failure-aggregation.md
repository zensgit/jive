# Import Center V10.7：分组导出选项 + 失败原因聚合

日期：2026-02-15

## 目标
1. 分组导出支持 `当前页 / 全部页` 选择，并可按金额限制 `Top N`。
2. 导入历史新增“最近失败原因聚合”卡片，便于集中排障。

## 实现内容

### 1) 分组分页与导出选项
- 文件：`lib/feature/import/import_job_detail_screen.dart`
- 新增分组分页状态：
  - `_groupPageSize`（20/50/100）
  - `_groupPageIndex`
- 分组视图 UI：
  - 显示页码信息 `第 x/y 页`
  - 上一页/下一页按钮
  - 每页条数切换（20/50/100）
- 分组导出增强：
  - 点击导出时弹窗选择：
    - `仅导出当前页`
    - `导出全部页`
  - 可选输入 `Top N（按金额）`
  - 导出 CSV 头增加：导出范围、TopN、页码（当前页导出时）
- 导出策略：
  - 默认按当前分组筛选/排序结果导出
  - 若设置 Top N，则在导出集合内按总金额降序取前 N

### 2) 历史失败原因聚合
- 新文件：`lib/feature/import/import_history_analytics.dart`
- 新增能力：
  - `normalizeImportFailureReason(...)`：失败原因标准化（去异常前缀、压缩空白、长度截断）
  - `aggregateImportFailureReasons(...)`：按失败原因聚合并排序（次数优先，其次最近时间）
- 视图接入：
  - 文件：`lib/feature/import/import_center_screen.dart`
  - 任务历史卡片内新增“最近失败原因聚合”区块，展示：
    - 原因文本
    - 次数
    - 最近任务 ID 与时间

### 3) 测试
- 更新：`test/import_job_detail_screen_test.dart`
  - 新增分页用例：`dedup groups support pagination and next page export context`
- 新增：`test/import_history_analytics_test.dart`
  - 聚合排序与计数
  - 失败原因标准化（空值、前缀剥离、长文本截断）

## 验证
在 `app/` 目录执行：

```bash
flutter analyze
flutter test test/import_job_detail_screen_test.dart
flutter test test/import_history_analytics_test.dart
flutter test
```

结果：全部通过。

## 备注
- 本次变更为导出与运营排障能力增强，不改变导入去重策略和写库口径。
