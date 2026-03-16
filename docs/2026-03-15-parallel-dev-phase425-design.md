# Phase425 Design

## Background
- Phase423 added CI step summary rendering, import duplicate-resolution Android coverage, and host import mapping fail-fast checks.
- The remaining gaps were:
  - Android runtime telemetry still lived only in raw test logs
  - import column mapping did not report blank/dirty/duplicate candidate headers
  - Android ImportCenter lane still lacked a preview-repair path before confirm import

## Design
- Extend Android smoke script to:
  - parse telemetry markers from the runtime integration log
  - materialize JSON/Markdown/CSV into `build/reports/sync-runtime`
  - fail fast if the runtime telemetry markers disappear
- Extend import column mapping fail-fast to review:
  - blank headers
  - dirty headers
  - duplicate candidate headers
  - and write a report artifact under `build/reports/import-column-mapping`
- Add a new Android ImportCenter flow:
  - parse malformed CSV preview
  - edit the invalid row inside preview
  - reselect repaired rows
  - confirm import and verify persistence

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_column_mapping_failfast_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_column_mapping_failfast_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_preview_repair_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/android_sync_runtime_telemetry_artifact_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_column_mapping_header_conflict_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/import_center_preview_repair_smoke_mvp.md`

## Tradeoff
- Android smoke lane becomes longer by one more ImportCenter flow, but the lane now covers repair-before-import instead of only “happy path” import.
- Telemetry extraction adds shell/python glue, but it turns Android runtime regression into artifact-grade output that CI can summarize and archive.
