# MoneyThings Category Share Path Preview Dev / Verify

## Summary

This branch improves the category sharing preview for the MoneyThings three-level category experience.

Category share export/import already preserves `parentKey`. The missing piece was preview readability: imported share payloads only displayed each category's own name, so a three-level tree like `出行 / 私家车 / 加油` was hard to verify before import.

## Branch

- Branch: `codex/moneythings-category-share-path-preview`
- Base: `origin/main@6315589f`
- PR: TBD

## Changes

- Updated `CategoryShareService.previewNames()` to render full ancestor paths from exported `parentKey` data.
- Kept export/import payload structure unchanged.
- Added regression coverage for:
  - three-level preview path rendering
  - export/import roundtrip preserving `parentKey` for root, middle, and leaf categories

## Compatibility

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync changes.
- No category schema or transaction model changes.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/core/service/category_share_service.dart test/category_share_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/category_share_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/core/service/category_share_service.dart test/category_share_service_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Notes

- Device smoke was not run because the branch is service/test-only.
- This complements the category import segment branch by making shared category packages easier to inspect before import.
