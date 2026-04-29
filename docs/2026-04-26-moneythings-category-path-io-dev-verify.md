# MoneyThings Category Path I/O Development & Verification

Date: 2026-04-26
Branch: `feature/moneythings-category-path-io`
Base: stacked on `feature/moneythings-autodraft-editor-bridge` / PR #201

## Summary

This slice advances the three-level category TODO without changing the transaction model or adding migrations.

Completed:

- CSV import can read a single category path column such as `出行 / 私家车 / 加油`.
- Manual CSV mapping can map that category path column through `categoryPathColumnIndex`.
- Parsed import records still use the compatible fields:
  - `parentCategoryName = 出行`
  - `childCategoryName = 加油`
- CSV export now includes a `分类路径` column.
- Full transaction CSV export also includes `分类路径`.
- Export resolves category paths from a prebuilt category-key map, avoiding repeated map reconstruction for every transaction.
- Import and manual CSV mapping now share one `CategoryPathImportParser` helper for path splitting and explicit-column precedence.

## Design

### Import Compatibility

Jive still stores imported category hints as parent and child names. For a three-level path:

`大类 / 中类 / 小类`

the importer maps:

- parent category name: first segment
- child category name: last segment

The middle segment is preserved in user-facing CSV text and can be resolved later by the category picker/path services, but it is not written into a new transaction field.

### Header Aliases

The import parser recognizes these path headers:

- `categoryPath`
- `fullCategory`
- `分类路径`
- `完整分类`
- `分类全路径`
- `大类/中类/小类`
- `三级分类`

Existing `一级分类` and `二级分类` columns continue to work. If both explicit columns and a path column are present, explicit parent/child columns win.

The path parsing helper is shared by `ImportService` and `ImportCsvMappingService`, keeping automatic import and manual mapping behavior consistent when separators or precedence rules evolve.

### Export

CSV export adds a `分类路径` column next to the existing `分类` and `子分类` columns.

When category keys resolve to a tree, export uses `CategoryPathService` to render the full path. If categories are unavailable, it falls back to the stored transaction names.

`CsvExportService` builds the category lookup map once per export and uses `CategoryPathService.resolveFromMap(...)` inside the transaction loop, keeping large exports linear in transaction count.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync logic changes.
- No `tertiaryCategoryKey` field added.
- Existing two-level import/export columns continue to work.

## Verification

Commands run:

```bash
flutter analyze --no-fatal-infos
flutter test test/import_csv_mapping_service_test.dart test/import_service_test.dart test/moneythings_alignment_services_test.dart
```

Results:

- Import mapping tests: passed.
- Import service tests: passed, including old two-level structured CSV and new category path CSV.
- MoneyThings alignment protocol tests: passed.
- `flutter analyze --no-fatal-infos`: passed with existing info-level lints only.

## Manual Smoke Checklist

- Import CSV with `分类路径` = `出行 / 私家车 / 加油` and confirm preview shows parent `出行` and child `加油`.
- Import older CSV with `一级分类` + `二级分类` and confirm behavior is unchanged.
- Export transactions and confirm the CSV contains both legacy columns and `分类路径`.
