# MoneyThings Scene Switch Deep Link Development And Verification

Date: 2026-05-16
Branch: `codex/moneythings-wave-status-calibration`

## Development

- Added `jive://scene/switch` to the shared deep-link parser as the scene
  counterpart to `jive://quick-action` and `jive://transaction/new`.
- Supported scene targets by `bookId`, `bookKey`, scene `name`, or explicit
  `all=true` for "all scenes".
- Added `QuickActionEntryLinkBuilder.sceneSwitch(...)` so system integrations
  can generate scene links without hand-written query strings.
- Wired parsed scene-switch requests into `MainScreen`, where they update the
  current book/scene, reload transactions, and show a clear success or missing
  scene message.
- Added the Android manifest host entry for `jive://scene/...`; iOS already
  registers the `jive` URL scheme globally.
- Updated the MoneyThings full-closure TODO to mark the `jive://scene/switch`
  contract complete.

## Verification

Commands run:

```sh
/Users/chauhua/development/flutter/bin/dart format lib/feature/home/main_screen.dart lib/feature/quick_entry/quick_action_deep_link_service.dart lib/feature/quick_entry/quick_action_entry_link_builder.dart test/quick_action_deep_link_entry_contract_test.dart test/quick_action_entry_link_builder_test.dart
git diff --check
/Users/chauhua/development/flutter/bin/flutter test test/quick_action_deep_link_entry_contract_test.dart test/quick_action_entry_link_builder_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Targeted tests to run in Flutter-capable environments:

```sh
flutter analyze --no-fatal-infos
flutter test test/quick_action_deep_link_entry_contract_test.dart
flutter test test/quick_action_entry_link_builder_test.dart
```

Expected behavior:

- `jive://scene/switch?bookId=7` switches to the active scene/book with id `7`.
- `jive://scene/switch?bookKey=travel_book` switches by stable book key.
- `jive://scene/switch?name=旅行` switches by visible scene name.
- `jive://scene/switch?all=true` switches to the "all scenes" view.
- Missing or archived scenes show a non-destructive message and do not create or
  modify transactions.

Actual result:

- `dart format`: passed. The formatter emitted package-resolution warnings
  before dependencies were restored, then formatted the changed test files.
- `git diff --check`: passed.
- Targeted Flutter tests: passed, 11 tests.
- `flutter analyze --no-fatal-infos`: passed with exit code 0. The repository
  still reports existing info-level lint/deprecation items outside this slice.
