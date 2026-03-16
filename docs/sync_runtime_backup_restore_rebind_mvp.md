# Sync Runtime Backup Restore Rebind

## Goal
- Cover the part yimu does not have: a reusable sync runtime that survives backup/restore and safely rotates ownership on the same device.
- Validate that restored checkpoints can seed a new runtime session after lease cleanup.
- Validate that an old lease loses write permission after owner rebind.

## Changes
- Added host regression:
  - `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart`
- Added Android integration regression:
  - `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
- Added the new regression to:
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`

## Expected Effect
- Backup import restores sync checkpoint snapshots even after lease cleanup.
- Same-owner reopen can bootstrap a fresh runtime from restored snapshot state.
- Owner rebind rotates the lease and invalidates the previous writer.

## Scope
- Regression/test lane only.
- No UI behavior or release packaging changes.
