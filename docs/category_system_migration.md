# Category System/User Category Migration

## Development Notes
- Added `JiveCategoryOverride` to persist system-category edits (name, icon, color, parent, order, hidden) across system updates.
- System category keys are now stable SHA1 hashes: `sys_<hash>` derived from `type|parent|child` (case-insensitive, whitespace stripped).
- System update flow no longer clears user categories; migration matches by name and remaps user categories to the new system keys, then removes duplicates.
- System defaults are re-applied from the library, then overrides are applied on top.
- System categories can be hidden/edited; deletion remains limited to user categories.
- Transaction category keys are remapped during migration and names are refreshed after overrides apply.

## Verification Performed
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `dart analyze` (fails due to pre-existing issues: `lib/feature/accounts/accounts_screen.dart:223` nullable access, and `test/widget_test.dart:16` missing `MyApp`)
- Built and installed debug APK to device (after fixing `app/lib/feature/accounts/accounts_screen.dart` nullability for the build).
- Reset system categories and verified DB matches `references/fenlei/all_icons_manifest.csv`:
  - Parents: 31
  - Children: 1427
  - No missing/extra pairs vs CSV.
- Verified system override persistence:
  - Injected override for system parent “交通” -> “交通X”.
  - Relaunched app; category name updated to “交通X” and override record persisted.
- Verified migration by name:
  - Injected user categories “交通/公交车” plus a transaction.
  - Forced seed version rollback and relaunched app.
  - User duplicates removed; transaction remapped to system hashed keys; names preserved.

## Suggested Manual Checks
1. Launch app -> Settings -> reset system categories. Verify parent/child counts match `references/fenlei/all_icons_manifest.csv`.
2. Edit a system category (rename/icon/hidden/move parent), restart app, confirm the changes persist.
3. Create user categories, bump `_systemCategorySeedVersion`, relaunch, confirm user categories remain and same-name items are merged into system categories.
4. Move/rename categories and confirm transaction category names stay in sync.
