# MoneyThings Account Group Paths - Speech Candidates

## Summary

This slice continues the MoneyThings-inspired account group rollout for voice,
clipboard, and structured speech entry. Users can say compact sub-account paths
such as `中国银行活期` instead of only the raw child account name.

## Changes

- Added `AccountSpeechAliasService` to build account aliases from:
  - raw account name
  - account group + account name combinations
  - visual display path, for example `中国银行 / 活期 / CNY`
  - compact display paths, for example `中国银行活期`
  - existing wallet/payment aliases such as `微信`, `支付宝`, `现金`, `信用卡`
- `SpeechCaptureService` now passes grouped account aliases into
  `SpeechIntentParser`.
- `AssistantScreen` clipboard recognition now uses the same grouped aliases.
- `AddTransactionScreen` speech preview and speech fill now share the same alias
  source.
- `SpeechEntryParamsBuilder` resolves compact account group path hints back to
  concrete `JiveAccount.id` values.

## Compatibility

- No migration.
- No sync, payment, entitlement, or workflow changes.
- Transaction saving still uses concrete `accountId` and `toAccountId`.
- Existing single-account aliases continue to work.

## Validation

- `dart format lib/core/service/account_speech_alias_service.dart lib/core/service/speech_capture_service.dart lib/feature/assistant/assistant_screen.dart lib/feature/transactions/add_transaction_screen.dart lib/feature/transactions/speech_entry_params_builder.dart test/speech_intent_parser_test.dart test/moneythings_alignment_services_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/account_speech_alias_service.dart lib/core/service/speech_capture_service.dart lib/feature/assistant/assistant_screen.dart lib/feature/transactions/add_transaction_screen.dart lib/feature/transactions/speech_entry_params_builder.dart test/speech_intent_parser_test.dart test/moneythings_alignment_services_test.dart`
- `flutter test test/speech_intent_parser_test.dart test/moneythings_alignment_services_test.dart`
- `git diff --check`
- Restricted path check confirms no changes under:
  `supabase/migrations`, `lib/core/sync`, `.github/workflows`
