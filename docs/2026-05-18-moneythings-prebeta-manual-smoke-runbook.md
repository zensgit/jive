# MoneyThings Pre-Beta Manual Smoke Runbook

Date: 2026-05-18

Branch: `codex/moneythings-smoke-wave8-gate`

Base: `origin/main@db294304`

## Purpose

This runbook turns the remaining MoneyThings manual smoke item into an
executable pre-beta checklist. It does not claim device validation by itself;
it defines the exact checks to run on a real device or simulator before an
external beta.

## Device Requirements

- Core flows can be checked on any runnable app target that supports the main
  Flutter app.
- Android widget checks require an Android emulator or physical Android
  device with home widget support.
- iOS Shortcuts/AppIntent checks require an iOS simulator or physical iOS
  device with Shortcuts support.
- Browser or macOS-only runs are useful for core UI confidence, but they do not
  satisfy Android widget or iOS Shortcuts smoke.

Current local observation on 2026-05-18:

- `flutter devices` found `macOS` and `Chrome`.
- No Android device, Android emulator, iOS simulator, or wireless device was
  available in this session.
- `flutter devices` also attempted a Flutter SDK git fetch and reported a
  GitHub connection failure before returning the local device list.

## Checklist Generator

Print the full checklist:

```bash
scripts/print_moneythings_prebeta_smoke_checklist.sh all
```

Print platform-specific sections:

```bash
scripts/print_moneythings_prebeta_smoke_checklist.sh core
scripts/print_moneythings_prebeta_smoke_checklist.sh android
scripts/print_moneythings_prebeta_smoke_checklist.sh ios
```

Suggested evidence capture:

```bash
scripts/print_moneythings_prebeta_smoke_checklist.sh all \
  > /tmp/jive-moneythings-prebeta-smoke.md
```

## Core Smoke Cases

| ID | Flow | Expected Result |
| --- | --- | --- |
| MT-CORE-01 | One-tap breakfast quick action | Saves directly, records the configured amount/category/account/context, and updates usage count. |
| MT-CORE-02 | Lunch confirm quick action | Opens confirm mode, requires amount, shows source context, and saves once. |
| MT-CORE-03 | Complex transfer or incomplete external entry | Opens `TransactionFormScreen` with source banner and missing-field highlights; no silent save attempt. |
| MT-CORE-04 | Third-level category | Default stays two-level; opt-in third-level path saves top + leaf compatible keys. |
| MT-CORE-05 | Account group | Grouped display path is visible, while the transaction still saves the concrete account id. |
| MT-CORE-06 | Shared-scene transaction | Shows shared visibility warning and blocks or replaces private account usage according to policy. |
| MT-CORE-07 | SmartList default | Restores default SmartList on entry and clears stale default after deletion. |

## Android Smoke Cases

| ID | Flow | Expected Result |
| --- | --- | --- |
| MT-ANDROID-01 | Widget default quick-add | Opens `jive://transaction/new` with widget source metadata and missing-field highlights. |
| MT-ANDROID-02 | Configured widget quick action | Opens `jive://quick-action?id=...` and reaches `QuickActionExecutor`. |
| MT-ANDROID-03 | Android share entry | Preserves raw text as note when parsing is incomplete and shows source metadata. |

## iOS Smoke Cases

| ID | Flow | Expected Result |
| --- | --- | --- |
| MT-IOS-01 | Shortcuts quick action | Shortcuts launches a saved quick action through the same executor as the app. |
| MT-IOS-02 | Scene switch URL | `jive://scene/switch` opens the expected scene/book context. |
| MT-IOS-03 | Transaction URL | `jive://transaction/new` opens structured editor with source banner and highlights. |

## Exit Criteria

- All core cases pass on at least one runnable app target.
- Android widget cases pass before Android external beta.
- iOS Shortcuts/AppIntent cases pass before iOS external beta.
- Every failed or blocked case has a linked follow-up issue or PR.
- No Wave 8 migration, RLS, sync protocol, or entitlement changes are made from
  manual-smoke follow-up PRs.

## Failure Handling

- Treat save failures, silent external-entry failure, wrong account identity,
  wrong category keys, missing shared-scene warning, and widget/shortcut routes
  entering the wrong screen as release blockers.
- Treat copy polish, icon spacing, or non-blocking info-level analyzer findings
  as follow-up unless they hide the primary action.
- Record platform, device, app commit, scenario id, actual result, expected
  result, screenshot/log, and next owner for every blocker.
