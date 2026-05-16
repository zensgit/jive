# MoneyThings Deep Link Source Coverage Dev Verify

## Summary

This branch continues the MoneyThings entry-system TODO by widening `jive://transaction/new` source coverage. External callers can now describe the same structured-entry sources that `TransactionEntryParams` already supports, without bypassing the editor or creating transactions directly.

- Branch: `codex/moneythings-deeplink-source-coverage`
- Base: `origin/main`
- PR: https://github.com/zensgit/jive/pull/257
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-deeplink-source-coverage`

## Implementation

- Extended `QuickActionDeepLinkService` transaction-link parsing for:
  - `entrySource=quickAction`
  - `entrySource=voice`
  - `entrySource=conversation`
  - `entrySource=autoDraft` / `auto_draft`
  - `entrySource=ocrScreenshot` / `ocr`
  - existing `shareReceive` and default `deepLink`
- Added quick-action metadata support on transaction links:
  - `quickActionId` / `quickAction` / `id`
  - `mode=direct`
  - `canDirectSubmit=true`
- Kept all transaction links routed into `TransactionEntryParams`; no external source saves directly.
- Updated MoneyThings entry-system docs and regression tests.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not alter transaction persistence.
- Did not add a second quick-action storage model.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/quick_entry/quick_action_deep_link_service.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name QuickActionDeepLinkService`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/quick_entry/quick_action_deep_link_service.dart test/moneythings_alignment_services_test.dart`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Manual Smoke Checklist

- Open `jive://transaction/new?entrySource=quickAction&quickActionId=template:<id>&mode=direct&type=expense&amount=15&categoryKey=<key>&accountId=<id>`.
- Confirm the structured editor shows the quick-action source banner and receives quick-action metadata.
- Open `jive://transaction/new?entrySource=voice&rawText=<text>` and confirm it lands in the structured editor with missing fields highlighted.
- Open `jive://transaction/new?entrySource=ocr&rawText=<text>` and confirm the OCR source banner is used.
