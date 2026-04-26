# MoneyThings Voice Editor Bridge Development & Verification

Date: 2026-04-26
Branch: `feature/moneythings-voice-editor-bridge`
Base: stacked on `feature/moneythings-category-path-io` / PR #202

## Summary

This slice moves Assistant-origin voice-like entries onto the unified transaction editor contract without changing the default manual-entry microphone behavior.

Completed:

- Added `SpeechEntryParamsBuilder`.
- AI Assistant clipboard recognition now opens `TransactionFormScreen` with `source = shareReceive`.
- AI Assistant voice entry launches `AddTransactionScreen` in an editor-bridge mode.
- When that bridge mode receives a valid speech preview, it opens `TransactionFormScreen` with `source = voice`.
- Normal `AddTransactionScreen` speech fill remains unchanged unless `openSpeechResultInEditor` is explicitly enabled.

## Design

### SpeechEntryParamsBuilder

`SpeechEntryParamsBuilder` converts `SpeechIntent` into `TransactionEntryParams`.

It maps:

- amount
- type
- date
- note from cleaned text
- raw speech text
- source label
- account hints to concrete `JiveAccount.id` when possible
- missing-field highlights for amount, account, category, and transfer target

The builder does not save transactions. It only prepares the editor contract.

### Assistant Voice

The Assistant voice card still uses the existing speech capture UI, but it passes `openSpeechResultInEditor: true` to `AddTransactionScreen`.

That keeps microphone permission, quota, fallback, and preview behavior in one place. After the user confirms the speech preview, the structured editor opens for final confirmation.

### Clipboard Recognition

Clipboard recognition is treated as a share-like external entry:

`Clipboard -> SpeechIntentParser -> SpeechEntryParamsBuilder -> TransactionFormScreen`

This prevents clipboard-derived entries from silently filling the calculator screen.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync logic changes.
- Default AddTransactionScreen speech behavior is unchanged.
- Existing speech parser tests remain valid.

## Verification

Commands run:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart test/speech_intent_parser_test.dart test/add_transaction_screen_entry_ux_test.dart test/transaction_entry_widget_regression_test.dart
```

Results:

- `flutter test` passed for MoneyThings protocol tests, speech parser tests, transaction entry UX tests, and transaction entry widget regressions.
- `flutter analyze --no-fatal-infos` completed successfully with existing info-level lints only.
- `git diff --check` passed.
- Restricted directories were checked separately: no `supabase/migrations`, `lib/core/sync`, `.github/workflows`, SaaS entitlement, payment, or sync logic changes.

## Manual Smoke Checklist

- Open AI Assistant -> `语音记账`, speak or type a phrase such as `今天午餐花了 35 元 微信`.
- Confirm the speech preview and verify the structured transaction editor opens.
- Save from the editor and verify the Assistant closes with a changed result.
- Open AI Assistant -> `剪贴板识别` with payment text in clipboard and verify it opens the structured editor.
- Open the normal manual add transaction page and confirm its microphone still fills the calculator page as before.
