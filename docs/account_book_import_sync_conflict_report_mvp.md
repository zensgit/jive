# Account Book Import Sync Conflict Report

## Goal
- Add a host-side regression report that aggregates three high-risk chains together:
  - account book switch sync
  - account book delete-and-transfer
  - import edit writeback
- Convert those checks into one reusable `ready / review / block` report and archive the result under `build/reports`.
- Cover the parts highlighted by yimu reference code:
  - `AccountBookActivity.e0(...)`
  - `EditAccountBookActivity.b0()` / `m0()` / `k0()` / `c0()`
  - `ImportSelfActivity.c0()`

## Changes
- Added report service:
  - `/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/account_book_import_sync_conflict_report_service.dart`
- Added host regression-style test:
  - `/Users/huazhou/Downloads/Github/Jive/app/test/account_book_import_sync_conflict_report_service_test.dart`
- Added report artifact output under:
  - `/Users/huazhou/Downloads/Github/Jive/app/build/reports/account-book-import-sync`
- Added the new report to:
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`

## Expected Effect
- Release regression now surfaces one consolidated result for account-book switch, delete-transfer, and import writeback conflict risk.
- Report artifacts can be uploaded by CI without extra post-processing.
- Host regression covers the exact low-platform-risk flows that do not need Android `integration_test` first.

## Scope
- Host regression / report layer only.
- No UI behavior changes.
