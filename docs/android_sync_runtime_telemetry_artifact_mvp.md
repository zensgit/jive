# Android Sync Runtime Telemetry Artifact

## Goal
- Extract `sync_runtime_backup_restore_rebind` integration telemetry from Android test logs.
- Persist the telemetry as JSON/Markdown/CSV under `build/reports/sync-runtime`.
- Let CI step summary and uploaded artifacts consume Android telemetry the same way host regression already does.

## Changes
- Extended:
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- Reused:
  - `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
  - `/Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh`

## Expected Effect
- Android lane no longer hides runtime telemetry inside raw console logs.
- `build/reports/sync-runtime/android-sync_runtime_backup_restore_rebind_flow_test.json` and companion `.md` / `.csv` become first-class CI artifacts.
- Missing telemetry markers in the runtime Android flow now fail the smoke lane fast.

## Scope
- Android smoke lane and report artifacts only.
- No business UI changes.
