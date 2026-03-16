# Phase420 Design

## Background
- Phase419 made the Android emulator lane green by fixing split-per-ABI APK discovery and ADB preflight hangs.
- The next missing piece was runtime-level regression coverage for features beyond yimu: sync session ownership, restored checkpoint bootstrap, and stale-writer invalidation after backup/restore.
- CI was also still under-instrumented for Android lane results; failures would be harder to inspect remotely.

## Design
- Extend CI workflow:
  - run Android emulator lane on `push` to `main` in addition to manual dispatch / PR label
  - upload Android E2E artifacts and build reports for inspection
  - upload host smoke artifacts as well
- Extend runtime regression coverage:
  - add a host regression for `sync runtime -> export -> import -> same-owner reopen -> owner rebind`
  - add an Android integration variant of the same flow
  - include the new coverage in both release regression suite and Android E2E smoke lane

## Files
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/test/sync_runtime_backup_restore_rebind_regression_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/integration_test/sync_runtime_backup_restore_rebind_flow_test.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/sync_runtime_backup_restore_rebind_mvp.md`

## Tradeoff
- Android lane is now slightly longer because of the sixth integration test, but the added runtime coverage closes a real release risk.
- CI now spends more time on `main`, but the payoff is a verifiable device lane instead of a label-only lane.
