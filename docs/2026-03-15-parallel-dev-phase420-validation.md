# Phase420 Validation

## Completed
- Updated `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`:
  - Android emulator lane now runs on `push` to `main`
  - host smoke lane now runs on `push` to `main`
  - Android / host artifacts are uploaded with `actions/upload-artifact@v4`
- Added host regression:
  - `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart`
- Added Android integration regression:
  - `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
- Added the new regression to:
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`

## Command Validation
- `bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `flutter analyze /Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart /Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/sync_runtime_service.dart /Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart`
- `flutter test /Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart`
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `flutter test /Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart -d emulator-5554 --flavor dev --dart-define=JIVE_E2E=true`
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`

## Result
- Host regression suite: passed
- New runtime host regression: passed
- New runtime Android integration regression: passed
- Android emulator smoke lane: passed end-to-end with the added sixth test
