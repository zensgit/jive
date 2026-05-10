# MoneyThings Scene Template Picker Dev / Verify

## Summary

This branch adds a focused widget regression test for the MoneyThings-inspired
scene template picker. It verifies that the onboarding picker keeps the apply
button disabled until a scene is selected, then returns the selected template.

## Branch

- Branch: `codex/moneythings-scene-template-picker-test`
- Base: `origin/main@432e8716`
- PR: TBD

## Changes

- Added `test/scene_template_picker_test.dart`.
- Covered the picker state transition from no selection to selected scene.
- Verified that applying the travel scene returns the `travel` template and
  keeps the expected `旅行` tag semantics.

## Compatibility

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No scene model or onboarding behavior change; this is test-only coverage.

## Validation

- `dart format test/scene_template_picker_test.dart`
- `flutter test test/scene_template_picker_test.dart`
- `flutter analyze --no-fatal-infos lib/feature/onboarding/scene_template_picker.dart test/scene_template_picker_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`
