# MoneyThings Scene Template Contracts Dev / Verify

## Summary

This branch adds focused contract coverage for the MoneyThings-inspired scene
templates. It keeps the first-stage scene productization anchored on the six
non-migration templates already present in `kSceneTemplates`: daily life,
travel, renovation, family, pet, and freelance.

## Branch

- Branch: `codex/moneythings-scene-template-contracts`
- Base: `origin/main@432e8716`
- PR: TBD

## Changes

- Added `test/scene_templates_contract_test.dart`.
- Fixed the expected scene template ID order so accidental insertions,
  removals, or renames become visible in tests.
- Covered baseline data quality for every template: id, name, emoji,
  non-empty categories, and positive suggested budget.
- Covered product semantics for the six supported templates, including travel,
  family, pet, renovation, freelance, and daily life category/tag expectations.

## Compatibility

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No scene model migration; this is a low-risk contract test branch.

## Validation

- `dart format test/scene_templates_contract_test.dart`
- `flutter test test/scene_templates_contract_test.dart`
- `flutter analyze --no-fatal-infos lib/core/data/scene_templates.dart test/scene_templates_contract_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`
