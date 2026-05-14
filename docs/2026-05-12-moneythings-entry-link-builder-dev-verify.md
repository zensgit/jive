# MoneyThings Entry Link Builder Dev Verify

## Summary

This slice adds a single builder for MoneyThings-style quick-action and transaction entry links. The goal is to stop widgets, share extensions, shortcuts, and future external entrypoints from manually assembling `jive://...` URLs.

## Implementation

- Added `QuickActionEntryLinkBuilder`.
- Supports quick action links:
  - `jive://quick-action?id=template:<id>`
- Supports transaction links:
  - `jive://transaction/new?...`
- Omits empty optional fields instead of emitting blank query values.
- Preserves parse compatibility with `QuickActionDeepLinkService`.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement/payment/sync logic.
- Did not change transaction save semantics.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/quick_entry/quick_action_entry_link_builder.dart test/quick_action_entry_link_builder_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/quick_entry/quick_action_entry_link_builder.dart lib/feature/quick_entry/quick_action_deep_link_service.dart lib/feature/transactions/transaction_entry_params.dart test/quick_action_entry_link_builder_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/quick_action_entry_link_builder_test.dart`
- `git diff --check`
- Restricted path check: no changes under `supabase/migrations`, `lib/core/sync`, `.github/workflows`, or SaaS payment/sync/entitlement runtime files.

## Results

- Format passed.
- Targeted analyze passed.
- Quick action entry link builder tests passed.
- Diff whitespace check passed.
- Restricted path check passed.

## Manual Smoke Suggestion

- Open `jive://quick-action?id=template:42` and confirm it resolves to template-backed quick action execution.
- Open a generated `jive://transaction/new?...` URL with amount/category/account/raw text and confirm the structured editor is prefilled.
