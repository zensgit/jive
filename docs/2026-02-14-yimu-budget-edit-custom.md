# yimu 参考：预算编辑与自定义周期（含日期边界修正）

## 目标
在现有预算管理基础上补齐两块关键能力：
- 预算可编辑（名称/金额/分类/周期/预警等），而不是只能新建和删除
- 支持 `自定义` 预算周期，用户可选择任意日期范围创建预算

同时修正预算周期日期范围的“结束时间边界”，避免遗漏当天最后一刻的交易。

## 1) 预算编辑（Edit Budget）
入口：
- `预算管理` → 点击某预算卡片 → 详情底部弹窗右上角 `编辑` 图标

编辑能力（与创建同一套表单）：
- 预算名称
- 预算分类（全部分类 / 一级分类 / 二级分类）
- 金额与货币
- 预算周期（每日/每周/每月/每年/自定义）
- 预警开关与阈值

保存策略：
- 仅修改名称/金额/分类/预警时，不会意外改变原有 `startDate/endDate`（周期未变化）
- 当用户切换周期（非自定义）时，日期范围会按“当前时间”重新计算为对应周期范围

## 2) 自定义预算周期（Custom Range Budget）
在预算编辑器里开放 `自定义` 周期：
- 当选择 `自定义` 时出现可点击的 `预算范围`，从页面底部弹出日历范围选择器（`DateRangePickerSheet`）
- 未选择范围无法保存（会提示 `请选择预算日期范围`）

保存时的日期规范化：
- `startDate` 归一到当天 `00:00:00.000`
- `endDate` 归一到当天 `23:59:59.999`

说明：
- 预算范围在表单中始终展示；只有 `自定义` 时可点击选择/清除范围

## 3) 周期日期范围边界修正（End Boundary）
`BudgetService.getPeriodDateRange` 的结束时间边界从 `...:59` 调整为 `...:59.999`：
- daily/weekly：`+1 day - 1ms`
- monthly/yearly：显式设置 `millisecond=999`

目的：
- 避免 `timestampBetween(start, end)` 在 end=23:59:59 时遗漏 23:59:59.xxx 的交易

## 代码位置
- 预算周期范围：`app/lib/core/service/budget_service.dart`
- 预算管理 UI（编辑器/详情编辑入口）：`app/lib/feature/budget/budget_list_screen.dart`
- 日历范围选择器：`app/lib/core/widgets/date_range_picker_sheet.dart`

## 测试与验证
- `flutter analyze`
- `flutter test`

新增/调整的单测：
- 子分类预算统计口径（`subCategoryKey`）覆盖
- `daysRemaining` 同日预算返回 1 天（包含当天）
- 月度周期结束边界期望更新为 `...23:59:59.999`

