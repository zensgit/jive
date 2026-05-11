# MoneyThings Scene Candidates Development & Verification

## Slice

This slice closes a low-risk service-layer gap from the MoneyThings Scene/SmartList follow-up work:

- Scene templates can now influence default category candidates without changing category storage.
- Scene book context can now influence default account candidates without changing account storage.
- The resolver is pure and side-effect free, so it can be wired into UI/editor flows later without migration risk.

## Non-Duplication Check

Open PRs reviewed before choosing this slice:

- PR #256 covers SmartList default persistence, saved-filter regression coverage, ordering, and filter snapshot behavior.
- PR #262 clears stale SmartList default-view preferences.
- PR #271 covers baseline scene template contract tests.
- PR #272 covers the scene template picker widget.

This slice does not add another SmartList persistence/default-view test and does not re-test the basic template catalog. It adds the missing service contract that converts a selected scene into category/account candidate ordering.

## Implementation

- Added `SceneCandidateService`.
- Category candidates prioritize template category names/keys, filter hidden categories, optionally filter income/expense, then append remaining visible categories.
- Account candidates prioritize accounts in the current scene book, optionally fall back to default-book accounts, skip hidden/archived accounts, and expose a default-account helper.
- Added MoneyThings alignment tests for category ordering and account scoping/default fallback.

## Guardrails

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement, payment, or sync logic changes.
- No model or schema changes.

## Verification

Run locally on 2026-05-11:

- `dart format lib/core/service/scene_candidate_service.dart test/moneythings_alignment_services_test.dart`
- `flutter test test/moneythings_alignment_services_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/scene_candidate_service.dart test/moneythings_alignment_services_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`
