# Phase423 Design

## Background
- Phase422 added artifact-grade runtime telemetry and a host report for account-book/import/sync conflicts.
- The next gap was:
  - CI still lacked a readable step summary for the generated JSON reports
  - yimu-style custom import fail-fast checks were not explicitly modeled in Jive host regression
  - Android lane still lacked a real ImportCenter duplicate-resolution path

## Design
- Add a report summary renderer:
  - read `build/reports/**.json`
  - write concise markdown to CI step summary
- Add host-side import column mapping fail-fast service:
  - block missing category / amount / date mapping
  - block duplicate source-column reuse
  - review partial optional mapping gaps
- Add Android ImportCenter integration test:
  - seed one historical duplicate
  - parse CSV text
  - show duplicate risk chips
  - skip high-risk rows
  - confirm import of the remaining valid row
- Extend the fixed lanes:
  - release regression suite gets the new host fail-fast test
  - Android smoke lane gets the new ImportCenter duplicate-resolution flow

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/import_column_mapping_failfast_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/import_column_mapping_failfast_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/import_center_duplicate_resolution_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`

## Tradeoff
- Android lane gets longer by one test, but it now covers an actual import-resolution path rather than only analytical/export surfaces.
- The column-mapping fail-fast service is an abstraction, but it captures a real guardrail missing from the current regression matrix.
