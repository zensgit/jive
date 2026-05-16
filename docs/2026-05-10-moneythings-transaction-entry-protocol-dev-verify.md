# MoneyThings Transaction Entry Protocol Dev / Verify

## Summary

This branch adds regression coverage for the unified transaction entry protocol inspired by MoneyThings One Touch and Transaction Editor flows.

The goal is to protect the shared `TransactionEntryParams` contract used by manual entry, quick actions, voice, OCR, share receive, deep links, auto drafts, and edit mode.

## Branch

- Branch: `codex/moneythings-transaction-entry-protocol`
- Base: `origin/main@6315589f`
- Commit: `160f339a`
- PR: [#266](https://github.com/zensgit/jive/pull/266)

## Changes

- Added `test/transaction_entry_params_protocol_test.dart`.
- Covered the fixed highlight field contract:
  - `amount`
  - `category`
  - `account`
  - `transferAccount`
  - `time`
  - `note`
  - `tags`
- Covered source banner behavior for quick action, voice, OCR screenshot, share receive, and deep link entries.
- Covered source-specific submit button labels.
- Covered complex transfer prefill data and missing-field highlights.
- Covered `copyWith()` preserving unspecified prefill data while overriding protocol fields.

## Compatibility

- No production behavior changes.
- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync changes.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format test/transaction_entry_params_protocol_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_entry_params_protocol_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/transactions/transaction_entry_params.dart test/transaction_entry_params_protocol_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Notes

- This is a protocol guardrail branch, intentionally test-only.
- Device smoke was not run because no UI or persistence behavior changed.
