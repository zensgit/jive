# MoneyThings Smoke And Wave 8 Gate Dev Verify

Date: 2026-05-18

Branch: `codex/moneythings-smoke-wave8-gate`

Base: `origin/main@db294304`

## Scope

This slice continues after the MoneyThings final closure by making the
remaining manual smoke and Wave 8 decision work executable and reviewable.

No app runtime logic, migrations, sync internals, SaaS entitlement/payment/sync
logic, Supabase functions, or GitHub workflow files were changed.

## Changes

- Added `scripts/print_moneythings_prebeta_smoke_checklist.sh`.
- Added `docs/2026-05-18-moneythings-prebeta-manual-smoke-runbook.md`.
- Added `docs/2026-05-18-moneythings-wave8-decision-gate.md`.
- Updated `docs/2026-05-14-moneythings-full-closure-todo.md` with links to
  the new smoke runbook and Wave 8 gate.

## Local Device Observation

Commands run:

```bash
/Users/chauhua/development/flutter/bin/flutter devices
xcrun simctl list devices booted
adb devices
```

Result:

- Flutter detected `macOS` and `Chrome`.
- No Android device/emulator and no booted iOS simulator were available.
- `adb devices` returned no connected Android devices.
- `flutter devices` reported a Flutter SDK GitHub connection failure before
  returning the local device list, so network fetches should not be treated as
  reliable in this session.

## Verification

Commands to run:

```bash
bash -n scripts/print_moneythings_prebeta_smoke_checklist.sh
scripts/print_moneythings_prebeta_smoke_checklist.sh all >/tmp/jive-moneythings-prebeta-smoke.md
scripts/print_moneythings_prebeta_smoke_checklist.sh core >/tmp/jive-moneythings-prebeta-smoke-core.md
git diff --check
```

Results:

- `bash -n`: passed.
- Full checklist render: passed, 76 lines written to
  `/tmp/jive-moneythings-prebeta-smoke.md`.
- Core checklist render: passed, 48 lines written to
  `/tmp/jive-moneythings-prebeta-smoke-core.md`.
- `git diff --check`: passed.
- Restricted path check: passed; only `docs/` and
  `scripts/print_moneythings_prebeta_smoke_checklist.sh` changed.

## Manual Smoke Status

Manual smoke is still pending real Android/iOS execution. This PR intentionally
does not claim those platform checks as passed; it makes them explicit and
repeatable before external beta.
