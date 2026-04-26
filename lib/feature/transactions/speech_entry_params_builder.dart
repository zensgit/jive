import '../../core/database/account_model.dart';
import '../../core/service/speech_intent_parser.dart';
import 'transaction_entry_params.dart';

/// Converts parsed speech text into the unified transaction editor contract.
///
/// This keeps the calculator-based AddTransactionScreen free to preserve its
/// existing fast-fill behavior while external voice-like entries can fall back
/// to the structured editor.
class SpeechEntryParamsBuilder {
  const SpeechEntryParamsBuilder();

  TransactionEntryParams build(
    SpeechIntent intent, {
    Iterable<JiveAccount> accounts = const [],
    TransactionEntrySource source = TransactionEntrySource.voice,
    String? sourceLabel,
  }) {
    final type = _normalizeType(intent.type);
    final fromAccount = _resolveAccount(intent.accountHint, accounts);
    final toAccount = type == 'transfer'
        ? _resolveAccount(
            intent.toAccountHint,
            accounts,
            excludeId: fromAccount?.id,
          )
        : null;
    return TransactionEntryParams(
      source: source,
      sourceLabel: sourceLabel,
      prefillAmount: intent.amount,
      prefillType: type,
      prefillAccountId: fromAccount?.id,
      prefillToAccountId: type == 'transfer' ? toAccount?.id : null,
      prefillNote: _noteFromIntent(intent),
      prefillDate: intent.timestamp,
      prefillRawText: intent.rawText,
      highlightFields: _highlightFields(
        intent,
        type: type,
        fromAccount: fromAccount,
        toAccount: toAccount,
      ),
    );
  }

  String _normalizeType(String? type) {
    if (type == 'income' || type == 'transfer' || type == 'expense') {
      return type!;
    }
    return 'expense';
  }

  String? _noteFromIntent(SpeechIntent intent) {
    final cleaned = intent.cleanedText?.trim();
    if (cleaned != null && cleaned.isNotEmpty) return cleaned;
    final raw = intent.rawText.trim();
    return raw.isEmpty ? null : raw;
  }

  List<String> _highlightFields(
    SpeechIntent intent, {
    required String type,
    required JiveAccount? fromAccount,
    required JiveAccount? toAccount,
  }) {
    final fields = <String>{};
    if (intent.amount == null || intent.amount! <= 0) {
      fields.add(TransactionHighlightField.amount);
    }
    if (fromAccount == null) {
      fields.add(TransactionHighlightField.account);
    }
    if (type == 'transfer') {
      if (toAccount == null) {
        fields.add(TransactionHighlightField.transferAccount);
      }
    } else {
      fields.add(TransactionHighlightField.category);
    }
    return fields.toList(growable: false);
  }

  JiveAccount? _resolveAccount(
    String? hint,
    Iterable<JiveAccount> accounts, {
    int? excludeId,
  }) {
    final normalizedHint = _normalize(hint);
    if (normalizedHint.isEmpty) return null;
    for (final account in accounts) {
      if (account.id == excludeId) continue;
      for (final alias in _accountAliases(account)) {
        final normalizedAlias = _normalize(alias);
        if (normalizedAlias.isEmpty) continue;
        if (normalizedAlias.contains(normalizedHint) ||
            normalizedHint.contains(normalizedAlias)) {
          return account;
        }
      }
    }
    return null;
  }

  List<String> _accountAliases(JiveAccount account) {
    final values = <String>[account.name, account.type, account.currency];
    if (account.subType != null) values.add(account.subType!);
    final tailMatch = RegExp(r'(\d{3,4})').firstMatch(account.name);
    if (tailMatch != null) values.add(tailMatch.group(1)!);
    return values;
  }

  String _normalize(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-·•]+'), '')
        .trim();
  }
}
