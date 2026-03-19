# Phase422 Design

## Background
- Phase421 added a structured telemetry report for sync runtime restore/rebind and wired it into host/Android regressions.
- The next practical gap was twofold:
  - report artifacts still needed to land in `build/reports` for CI upload
  - account-book/import/sync conflict checks were still scattered across individual governance services
- yimu reference code confirms these conflict-heavy flows are best covered in host regression first:
  - account book switch refresh chain
  - delete with transfer target selection
  - import column / book binding / writeback guards

## Design
- Extend runtime regression output:
  - host regression writes JSON / Markdown / CSV telemetry files to `build/reports/sync-runtime`
  - Android integration regression prints structured telemetry JSON into the test log
- Add a new host-side aggregation report:
  - combine `AccountBookSwitchSyncGovernanceService`
  - combine `AccountBookDeleteTransferPolicyService`
  - combine `ImportEditReconciliationGovernanceService`
  - collapse them into one `ready / review / block` conflict report
- Add report artifact output for the new account-book/import conflict report under `build/reports/account-book-import-sync`
- Extend release regression suite so the new report always participates in analyze/test

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/account_book_import_sync_conflict_report_service.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/test/account_book_import_sync_conflict_report_service_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/account_book_import_sync_conflict_report_mvp.md`

## Tradeoff
- The new account-book/import report is an aggregation layer, not a new product feature. That keeps risk low and avoids touching UI.
- Android still only gets structured telemetry via logs, not separate files. That is intentional for now because host file output is reliable while emulator-side file export would add more moving parts.
