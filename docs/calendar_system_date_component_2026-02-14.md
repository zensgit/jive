# Calendar System Date Component (2026-02-14)

## Goal

- Make date selection consistent across the app by using a shared calendar UI component.
- Fix overlap issues when enabling lunar/solar-term/festival labels.
- Add a "节假日" toggle that shows adjusted `休/班` marks on the date cell top-right corner.

## Components

### DateRangePickerSheet (existing)

- Path: `app/lib/core/widgets/date_range_picker_sheet.dart`
- Used by: "全部账单 -> 查找账单 -> 日期范围" (via `TransactionFilterSheet`), export/report, etc.
- Features:
  - Month/year jump
  - Chips: `农历` / `节气` / `节日` / `节假日`
  - Holiday mark: `休` (rest) / `班` (work) shown at the top-right corner of a day cell

### DatePickerSheet (new)

- Path: `app/lib/core/widgets/date_picker_sheet.dart`
- Features:
  - Single-day selection (auto-close on pick)
  - Optional clear (`allowClear: true`) for nullable date fields
  - Same chips + holiday marks as `DateRangePickerSheet`

### JiveCalendarDayCell (shared day cell)

- Path: `app/lib/core/widgets/jive_calendar/jive_calendar_day_cell.dart`
- Reason:
  - Prevents "中文标签与数字重叠" by allocating vertical slices (day / label / today) and scaling down when cells are small.
  - Supports holiday corner marks (and reserves space so `班/休` won't collide with 2-digit day numbers).

### JiveDatePicker (system entry point)

- Path: `app/lib/core/widgets/jive_calendar/jive_date_picker.dart`
- Reason:
  - Provides a stable, reusable API for opening the sheet pickers across the app.
  - Avoids duplicating `showModalBottomSheet` glue code in every feature screen.
- APIs:
  - `JiveDatePicker.pickDate(...)` -> `Future<DateTime?>`
  - `JiveDatePicker.pickDateRange(...)` -> `Future<DateTimeRange?>`

### Barrel Export

- Path: `app/lib/core/widgets/jive_calendar/jive_calendar.dart`
- Exports:
  - `DatePickerSheet`
  - `DateRangePickerSheet`
  - `JiveDatePicker`
  - `JiveCalendarDayCell` + holiday mark types

## Preferences (Shared)

- `calendar_show_lunar`
- `calendar_show_jieqi`
- `calendar_show_festival`
- `calendar_show_holiday`

Stored via `shared_preferences` and shared between date picker and range picker.

## Adoptions / Replacements

Replaced remaining system dialogs with the shared sheet components:

- `showDatePicker` -> `DatePickerSheet`
  - `app/lib/feature/recurring/recurring_rule_form_screen.dart`
  - `app/lib/feature/transactions/add_transaction_screen.dart`

- `showDateRangePicker` / custom sheets -> `DateRangePickerSheet` (prefer calling via `JiveDatePicker.pickDateRange`)
  - `app/lib/core/widgets/transaction_filter_sheet.dart` (via `JiveDatePicker`)
  - `app/lib/feature/accounts/account_reconcile_screen.dart`
  - `app/lib/feature/budget/budget_list_screen.dart`
  - `app/lib/feature/settings/report_export_screen.dart`
  - `app/lib/feature/tag/tag_management_screen.dart`
  - `app/lib/feature/tag/tag_rule_screen.dart`
  - `app/lib/feature/tag/tag_statistics_screen.dart`

## Verification

Automated:

- `flutter analyze`
- `flutter test test/jive_calendar_day_cell_test.dart`

Manual sanity checks (recommended):

- "全部账单 -> 查找账单 -> 日期范围"
  - Toggle `农历/节气/节日/节假日` and swipe between months; confirm no overlaps.
  - Verify `节假日` shows `休/班` on adjusted dates.
- "新建周期规则"
  - Start/end date pickers open the sheet and end date supports clearing to "无".
- "新增账单"
  - Date picker opens the sheet, then time picker still works as before.
