# Calendar: Holiday Override Data Layer + Optional CI E2E (2026-02-15)

## Goals

1) Provide a **system holiday data layer** for the calendar (CN workday/rest-day adjustments).
2) Ship a **local JSON dataset** (offline, stable).
3) Allow **optional remote updates** (cache + fallback).
4) Run the existing `integration_test` on GitHub Actions via an **optional** Android emulator job.

## Holiday Data Layer (CN)

### What is displayed

When the user enables `节假日`:

- `休` in the day cell’s top-right corner = adjusted **rest day**
- `班` in the day cell’s top-right corner = adjusted **work day**

### Data sources (priority order)

1) Remote override (optional): downloaded JSON, cached on disk
2) Local asset: `assets/holidays/cn_public_holidays.json`
3) Fallback: `lunar` package dataset (`HolidayUtil.getHolidayByYmd`)

This ensures:

- Offline works (asset + lunar fallback)
- Remote updates can patch new yearly schedules without waiting for upstream dependencies

### Implementation

- Service: `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/holiday_calendar_service.dart`
  - `JiveHolidayCalendarService.instance.ensureInitialized()`
  - `getCnHolidayType(DateTime day)` returns `work/rest/null`
  - `refreshCnIfNeeded()` downloads remote JSON only when `JIVE_HOLIDAY_CN_URL` is provided
  - Remote refresh TTL: 24h
  - Notifies UI via `revision` (`ValueNotifier<int>`)

- Base dataset (asset):
  - `/Users/huazhou/Downloads/Github/Jive/app/assets/holidays/cn_public_holidays.json`
  - Generated from the `lunar` package, years `2010-2035`

- Generator script:
  - `/Users/huazhou/Downloads/Github/Jive/app/tool/generate_cn_public_holidays_from_lunar.dart`
  - Regenerate:
    ```bash
    cd /Users/huazhou/Downloads/Github/Jive/app
    dart run tool/generate_cn_public_holidays_from_lunar.dart --start=2010 --end=2035
    ```

### UI integration

- Date picker: `/Users/huazhou/Downloads/Github/Jive/app/lib/core/widgets/date_picker_sheet.dart`
- Date range picker: `/Users/huazhou/Downloads/Github/Jive/app/lib/core/widgets/date_range_picker_sheet.dart`

Both:

- Lazily initialize holiday data when `节假日` is enabled.
- Use `ValueListenableBuilder` to refresh the calendar when holiday data is loaded/updated.

### Remote update configuration

- Provide a URL at build/run time:
  - `--dart-define=JIVE_HOLIDAY_CN_URL=https://.../cn_public_holidays.json`

Remote JSON schema (minimal):

```json
{
  "schema": 1,
  "days": {
    "2026-02-14": "work",
    "2026-02-15": "rest"
  }
}
```

## Optional Android E2E in GitHub Actions

Workflow: `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`

Adds job `android_integration_test` which runs:

- `flutter test integration_test/calendar_date_picker_flow_test.dart --flavor dev --dart-define=JIVE_E2E=true`
- on an Android emulator

### How to trigger

- For pull requests: add label `e2e`
- Or run manually via `workflow_dispatch` and enable `run_android_e2e`

Notes:

- This job is optional (not executed for every PR by default).

