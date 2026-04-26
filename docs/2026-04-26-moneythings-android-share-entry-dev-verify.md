# MoneyThings Android Share Entry Development & Verification

Date: 2026-04-26
Branch: `feature/moneythings-android-share-entry`
Base: stacked on `feature/moneythings-voice-editor-bridge` / PR #205

## Summary

This slice adds the first native system-share bridge for the MoneyThings entry-unification TODO:

`Android ACTION_SEND text/plain -> jive://transaction/new -> QuickActionDeepLinkService -> TransactionEntryParams -> TransactionFormScreen`

Completed:

- Android `MainActivity` now accepts `ACTION_SEND` with `text/plain`.
- Shared text is normalized into the existing `jive://transaction/new` deep-link contract.
- Shared text marks `entrySource = shareReceive`, preserving a user-visible source banner.
- `QuickActionDeepLinkService` can parse share-receive text through `SpeechIntentParser` when no explicit amount is supplied.
- The transaction editor remains the only save path for shared text.

## Design

### Android Share Receiver

The native receiver intentionally does not save data and does not emit an auto-capture event.

It only converts system share text into a normal Jive transaction deep link:

- `entrySource=shareReceive`
- `sourceLabel=来自系统分享`
- `rawText=<shared text>`
- `note=<shared text>`

This keeps platform handling thin and lets Flutter own parsing, validation, highlighting, and saving.

### Deep Link Parsing

`QuickActionDeepLinkService` preserves the existing explicit `jive://transaction/new?...` behavior.

For `entrySource=shareReceive` links with raw text and no explicit amount, it uses the same speech-text parser as voice/clipboard entry to infer:

- amount
- type
- date
- note
- missing-field highlights

Account/category still remain highlighted unless a future route supplies trusted IDs.

## Preserved Boundaries

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement/payment/sync logic changes.
- No direct transaction save from Android native code.
- Existing `jive://quick-action` and explicit `jive://transaction/new` deep links remain supported.

## Verification

Commands run:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart test/speech_intent_parser_test.dart
/Users/chauhua/development/flutter/bin/flutter build apk --debug --no-pub
```

Results:

- `flutter test` passed for MoneyThings protocol and speech parser coverage, including Android share text parsing.
- `flutter analyze --no-fatal-infos` completed successfully with existing info-level lints only.
- `flutter build apk --debug --no-pub` completed Gradle/Kotlin compilation and produced flavor APKs under `build/app/outputs/flutter-apk/`.
- The Flutter wrapper exited non-zero because it expected a single default debug APK, while this project generated `app-dev-debug.apk`, `app-auto-debug.apk`, and `app-prod-debug.apk`.
- `git diff --check` passed.
- Restricted directories were checked separately: no `supabase/migrations`, `lib/core/sync`, `.github/workflows`, SaaS entitlement, payment, or sync logic changes.

## Manual Smoke Checklist

- On Android, share a payment/receipt text snippet to Jive.
- Confirm Jive opens the transaction editor, not the calculator page.
- Confirm the banner says it came from system share.
- Confirm amount is prefilled when the text contains an amount.
- Confirm account/category are highlighted for user confirmation.
