# MoneyThings Source Banner Contracts Dev / Verify

## Summary

This branch adds focused widget coverage for the MoneyThings-inspired
transaction editor source banner. The tests keep the unified entry model visible
to users: manual/edit flows stay quiet, while quick actions, deep links, share
receive, voice, and OCR entries show an explicit source banner.

## Branch

- Branch: `codex/moneythings-source-banner-contracts`
- Base: `origin/main@3604b361`
- PR: TBD

## Changes

- Added `test/transaction_source_banner_contract_test.dart`.
- Covered hidden banner behavior for manual and edit sources.
- Covered explicit quick action source labels, including the quick action name.
- Covered default external entry banners for deep link and share receive flows.
- Covered recognition banners for voice and OCR screenshot flows.

## Compatibility

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync behavior changes.
- No production behavior change; this is widget contract coverage only.

## Validation

- `dart format test/transaction_source_banner_contract_test.dart`
- `flutter test test/transaction_source_banner_contract_test.dart`
- `flutter analyze --no-fatal-infos lib/feature/transactions/widgets/transaction_source_banner.dart lib/feature/transactions/transaction_entry_params.dart test/transaction_source_banner_contract_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`
