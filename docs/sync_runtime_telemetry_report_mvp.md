# Sync Runtime Telemetry Report

## Goal
- Add a structured telemetry report for the `sync runtime -> backup/restore -> owner rebind` regression lane.
- Convert runtime regression from scattered boolean assertions into a reusable `ready / review / block` report.
- Prepare release regression and Android E2E lanes for future report artifact export.

## Changes
- Added report service:
  - `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_runtime_telemetry_report_service.dart`
- Added direct unit coverage:
  - `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_telemetry_report_service_test.dart`
- Wired the report into runtime regressions:
  - `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart`
  - `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
- Added the report service to the host regression suite:
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`

## Expected Effect
- Host regression can assert that restored checkpoints are restorable, stale writers are blocked, and rebound writers are allowed.
- Android runtime regression uses the same telemetry contract as host regression.
- Future CI artifact export can reuse the same report JSON / Markdown / CSV payloads without changing the runtime checks again.

## Scope
- Runtime regression / release lane only.
- No UI behavior changes.
