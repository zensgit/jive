# MoneyThings Tag Archive Warnings Dev Verify

This low-risk PR extends the shared-scene warning coverage for tag management.

## Scope

- Single tag archive and restore actions now ask for confirmation when the current book/scene is shared.
- The prompt reuses `ObjectSharePolicyService.evaluate(...).warning`, matching existing tag edit and tag-group archive warnings.
- Private scenes keep the previous direct archive/restore behavior with no extra confirmation.

## Non-Goals

- No object-level permissions, RLS, Supabase migrations, sync engine changes, SaaS payment, entitlement, or workflow changes.
- No changes under `supabase/migrations`, `lib/core/sync`, `.github/workflows`, SaaS payment/sync/entitlement surfaces.

## Manual QA

- Open a shared scene and archive an active tag; confirm the shared warning appears before the tag is archived.
- Open a shared scene, enable archived tags, and restore a tag; confirm the shared warning appears before restore.
- Repeat archive and restore in a private scene; confirm the action remains immediate with no extra warning dialog.
- Confirm tag-group archive/restore behavior is unchanged.

## Verification

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/tag/tag_management_screen.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name ObjectSharePolicyService`
- `/Users/chauhua/development/flutter/bin/flutter analyze lib/feature/tag/tag_management_screen.dart test/moneythings_alignment_services_test.dart`
