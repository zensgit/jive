# Calendar: E2E + Holiday Data + Auto-Permission Prompt (2026-02-14)

## Scope

- Date picking is unified via `JiveDatePicker` (see `calendar_system_date_component_2026-02-14.md`).
- Calendar day cell layout:
  - Supports lunar / solar term / festival labels.
  - Optional holiday corner mark (rest/work: `休`/`班`) in top-right.
  - Fixes the “中文与数字重叠” issue by reserving right padding when the corner mark is shown.
- Adds a repeatable validation loop:
  - Manual device acceptance checklist.
  - `integration_test` flow that opens the date range picker and asserts the corner mark does not overlap the day number.
- Auto-permission prompt (`自动记账权限未开启`) is less disruptive:
  - “稍后” snoozes the dialog for 24 hours.
  - E2E runs can disable the prompt via `--dart-define=JIVE_E2E=true`.

## Holiday Data Strategy (China)

Current implementation uses the `lunar` package’s `HolidayUtil.getHolidayByYmd(...)`:

- When `节假日` is enabled, and locale is Chinese, the calendar queries `HolidayUtil`:
  - `holiday.isWork() == true` -> show `班`
  - `holiday.isWork() == false` -> show `休`
- This supports *adjusted* workdays/rest days (调休) when the dataset provides them.

Tradeoffs:

- Pros: offline, zero network dependency, simple.
- Cons: accuracy depends on the `lunar` package dataset; annual updates may lag official announcements.

Recommended next iteration (if/when needed):

- Keep the `lunar` dataset as fallback.
- Add an override layer (JSON, shipped as asset + optional remote update with cache) so we can patch yearly schedules without waiting for upstream package releases.

## Manual Device Acceptance Checklist

Target: Android device, dev flavor (`com.jivemoney.app.dev`) so it does not overwrite the production app.

### A. “全部账单 -> 查找账单 -> 日期范围”

1) Home -> `View All` -> open filter (tune icon) -> tap `日期范围`.
2) In the calendar bottom chips:
   - Toggle `农历` / `节气` / `节日` / `节假日` in different combinations.
3) Verify visually:
   - Day numbers are always readable.
   - When `节假日` is on, the `休/班` corner mark does **not** cover 2-digit days (e.g. 14/28).
4) Range selection:
   - Tap start day then end day, sheet should close automatically.
   - Filter sheet should show `YYYY-MM-DD - YYYY-MM-DD`.
   - Use clear `x` to reset range back to `不限`.

### B. Reuse / Consistency

Verify other entrypoints that use the same calendar logic:

- Add transaction -> date picker
- Recurring rule -> start/end date pickers
- Any other screen that uses `DatePickerSheet` / `DateRangePickerSheet` via `JiveDatePicker`

Expectation:

- Same month picker UI
- Same lunar/festival/holiday chips (and remembered prefs)
- Same “no overlap” behavior

### C. Auto Permission Prompt

If `自动记账` is enabled and permissions are missing:

- Dialog shows once.
- Tapping `稍后` snoozes it for 24 hours (no repeated popups during routine testing).

## Automated Verification (integration_test)

### Setup

- Device connected: `adb devices`
- Use dev flavor + E2E define to avoid the permission dialog during automation.

### Run

```bash
cd /Users/huazhou/Downloads/Github/Jive/app
flutter pub get

# Run on a physical device
flutter test integration_test/calendar_date_picker_flow_test.dart \
  -d EP0110MZ0BC110087W \
  --flavor dev \
  --dart-define=JIVE_E2E=true
```

What it validates:

- Opens: Home -> View All -> filter -> date range picker
- Switches month to `2026-02`
- Enables `节假日`
- Asserts: the `班` corner mark rect does not overlap the day number rect inside the same calendar cell
- Selects a date range and verifies it is reflected in the filter sheet

