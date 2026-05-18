# MoneyThings Smoke Status Script Dev Verify

Date: 2026-05-18

Branch: `codex/moneythings-next-closure-20260518`

Base: `main@5458327`

## Scope

This documentation slice extends the MoneyThings pre-beta smoke tooling with a
status renderer for the latest committed device evidence. It also records one
additional Android onboarding regression smoke result.

No app runtime code, migrations, sync internals, SaaS entitlement/payment/sync
logic, Supabase functions, or GitHub workflow files were changed.

## Changes

- Added `status` mode to
  `scripts/print_moneythings_prebeta_smoke_checklist.sh`.
- The status renderer distinguishes:
  - `PASS` for the structured transaction deep link and onboarding
    `记一笔 -> 选择分类 -> 下一步` regression.
  - `PARTIAL` for Android scene-switch and quick-action route launch without
    seeded semantic data.
  - `BLOCKED / NOT YET RUN` for actual widget tap, iOS Shortcuts, and seeded
    full-core device smoke.
- Updated the pre-beta smoke runbook with the `main@5458327` Android follow-up
  observation.

## Android Evidence Added

Device:

- Serial: `EP0110MZ0BC110087W`
- Model: `P0110`
- Android: `16`

Commands and actions:

```bash
adb -s EP0110MZ0BC110087W install -r build/app/outputs/flutter-apk/app-prod-debug.apk
adb -s EP0110MZ0BC110087W shell monkey -p com.jivemoney.app -c android.intent.category.LAUNCHER 1
```

Manual UI smoke:

1. Opened the clean temporary `prod` debug package.
2. Skipped to onboarding `记一笔`.
3. Entered amount `12`.
4. Selected category `餐饮`.
5. Tapped `下一步`.

Observed result:

- The app advanced to `设分类`.
- This verifies the welcome-page `记一笔 -> 选择分类 -> 下一步` regression path on
  a physical Android device.

## Verification

```bash
bash -n scripts/print_moneythings_prebeta_smoke_checklist.sh
scripts/print_moneythings_prebeta_smoke_checklist.sh status
scripts/print_moneythings_prebeta_smoke_checklist.sh all
git diff --check
```

Restricted path check:

```bash
git diff --name-only HEAD -- \
  'supabase/migrations' \
  'lib/core/sync' \
  '.github/workflows'
```

Expected result: no output.

## Remaining Smoke

- Seed or create a saved quick action, then verify
  `jive://quick-action?id=<existing-id>` reaches `QuickActionExecutor`.
- Seed or create a `旅行` scene/book, then verify
  `jive://scene/switch?name=旅行` visibly switches context.
- Place the Android home widget and tap the actual widget button.
- Boot an iOS simulator or use an iOS device before running Shortcuts/AppIntent
  smoke.
