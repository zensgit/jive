# MoneyThings Category Import Segments Dev / Verify

## Summary

This branch continues the MoneyThings three-level category TODO without adding migrations or changing the transaction storage model.

The import pipeline now preserves full category path segments such as `出行 / 公务车 / 加油` while keeping the existing compatible transaction shape:

- `categoryKey` remains the top-level category.
- `subCategoryKey` remains the selected leaf category.
- Intermediate category names are used as import-time disambiguation hints only.

## Branch

- Branch: `codex/moneythings-category-import-segments`
- Base: `origin/main@6315589f`
- Commit: `b46e8aa9`
- PR: [#264](https://github.com/zensgit/jive/pull/264)

## Changes

- Added `CategoryPathNames.segments` so `CategoryPathImportParser.split()` keeps the full path while preserving existing `parentName` and `childName` behavior.
- Added `ImportParsedRecord.categoryPathSegments` and propagated it through CSV parsing and mapped CSV parsing.
- Added `AutoCapture.categoryPathSegments` and passed it from `ImportService.importPreparedRecords()`.
- Added `CategoryIndex.resolvePath()` so imports can resolve duplicate leaf category names by full path.
- Kept explicit parent/child column overrides safe: full path resolution is only used when it matches the parent and leaf hints.

## Compatibility

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync changes.
- No transaction model migration.
- Existing two-level category import remains compatible.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/category_path_service.dart lib/core/service/import_service.dart lib/core/service/import_csv_mapping_service.dart lib/core/service/auto_draft_service.dart test/moneythings_alignment_services_test.dart test/import_service_test.dart test/import_csv_mapping_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name CategoryPathImportParser`
- `/Users/chauhua/development/flutter/bin/flutter test test/import_csv_mapping_service_test.dart --plain-name "parseWithMapping accepts three-level category path"`
- `/Users/chauhua/development/flutter/bin/flutter test test/import_service_test.dart --plain-name "importPreparedRecords resolves duplicate leaf names by full category path"`
- `/Users/chauhua/development/flutter/bin/flutter test test/import_service_test.dart --plain-name "parseText accepts three-level category path csv fields"`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/category_path_service.dart lib/core/service/import_service.dart lib/core/service/import_csv_mapping_service.dart lib/core/service/auto_draft_service.dart test/moneythings_alignment_services_test.dart test/import_service_test.dart test/import_csv_mapping_service_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Notes

- A first parallel Flutter test attempt failed because multiple Flutter commands touched `.plugin_symlinks` at the same time. The affected tests were rerun sequentially and passed.
- Device smoke was not run in this branch because the change is import/service-only.
