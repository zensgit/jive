# Phase421 Design

## Background
- Phase420 added host and Android runtime regressions for `backup/restore + owner rebind`.
- Those regressions proved correctness, but the result was still spread across raw assertions and CI logs.
- The next useful step is a structured runtime report that can be reused by host regression, Android E2E, and later CI artifact export.

## Design
- Add a dedicated telemetry service for runtime restore/rebind:
  - input covers runtime dispositions, restored snapshot state, lease cleanup, stale writer blocking, and rebound writer availability
  - output collapses to `ready / review / block`
- Align the report export surface with the existing governance-report style:
  - JSON
  - Markdown
  - CSV
- Wire the new report into both runtime regressions:
  - host regression
  - Android integration regression
- Extend host release regression suite to always analyze/test the new report service.

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_runtime_telemetry_report_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_telemetry_report_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/sync_runtime_telemetry_report_mvp.md`

## Tradeoff
- This adds one more report abstraction, but it removes duplicated interpretation logic from tests and creates a stable boundary for later CI artifact generation.
- The Android integration test gets slightly more assertions, but no new external dependency or plugin surface.
