# 2026-02-13 系统日历组件（日期范围）+ 节假日角标

本文记录：

- 将「日期范围选择」日历单元格抽成系统组件，便于复用与统一样式
- 修复部分月份中「农历/节气/节日」中文标签与日期数字在小格子里发生重叠的问题
- 增加可选的「节假日」开关，并在日历日期右上角显示 `休/班` 角标
- 「导出报表」页面日期选择统一为底部弹出的 `DateRangePickerSheet`

## 目标

1. 让多个入口的“日期范围选择”统一使用同一套日历渲染逻辑（组件化、可复用）。
2. 解决日历为 6 行时（单个日期格较矮）中文标签与日期数字重叠/溢出的问题。
3. 提供可选“节假日”能力：
   - 用户可切换 `节假日`
   - 日历单元格右上角显示角标：
     - `休`：休息/节假日
     - `班`：调休补班

## 变更说明

### 1) 新增可复用的日历单元格组件

新增：

- `lib/core/widgets/jive_calendar/jive_calendar_day_cell.dart`

该组件用于日历日期单元格统一渲染，包含：

- 日期数字
- 可选“今日”
- 可选「农历/节气/节日」单行文本（ellipsis）
- 可选节假日角标（右上角 `休/班`）

同时增加 barrel 导出：

- `lib/core/widgets/jive_calendar/jive_calendar.dart`

### 2) 修复中文标签与日期重叠/溢出

更新：

- `lib/core/widgets/date_range_picker_sheet.dart`

核心思路：

- 使用 `JiveCalendarDayCell` 替代旧的固定位置布局
- 通过 `LayoutBuilder + Expanded` 为“今日/日期/中文标签”分配垂直空间
- 对文本使用 `FittedBox(BoxFit.scaleDown)`，在格子很矮时自动缩小字号

### 3) 增加“节假日”开关 + 角标

新增偏好设置：

- `calendar_show_holiday`（SharedPreferences）

UI 行为：

- 在日期范围日历底部的筛选 chips 行中增加 `节假日`
- 开启后，使用 `lunar` 包 `HolidayUtil.getHolidayByYmd(...)` 获取节假日信息：
  - `holiday.isWork() == true` -> 显示 `班`
  - 其它情况 -> 显示 `休`

### 4) 报表导出：统一日期范围选择交互

更新：

- `lib/feature/settings/report_export_screen.dart`

将原来的系统 `showDateRangePicker(...)` 替换为底部弹出的 `DateRangePickerSheet`，使其与其它入口体验一致，并共享「农历/节气/节日/节假日」能力。

## 使用方式（开发）

推荐通过 bottom sheet 打开：

```dart
await showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => DateRangePickerSheet(
    initialRange: initialRange,
    firstDay: DateTime(2020),
    lastDay: DateTime.now(),
    onChanged: (range) {
      if (range == null) return;
      setState(() => selectedRange = range);
    },
  ),
);
```

或直接导入 barrel：

```dart
import 'package:jive/core/widgets/jive_calendar/jive_calendar.dart';
```

## 验证

自动化：

```bash
flutter analyze
flutter test
```

其中包含：

- `test/jive_calendar_day_cell_test.dart`：回归“中文标签 + 小格子不溢出”

手工验证（推荐）：

1. `全部账单` -> 筛选 -> `日期范围`，观察日历月份在 5 行与 6 行时：
   - 日期数字与中文标签不重叠
   - 切换 `农历/节气/节日/节假日` 后显示正确
   - `节假日` 开启后出现右上角 `休/班`
2. `设置` -> `导出报表` -> 日期范围：
   - 点击后从底部弹出 `DateRangePickerSheet`
   - 选择范围后能回填到导出页面
