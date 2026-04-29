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

  static final RegExp _accountTailPattern = RegExp(r'(\d{3,4})');
  static final RegExp _normalizePattern = RegExp(r'[\s_\-·•]+');

  TransactionEntryParams build(
    SpeechIntent intent, {
    Iterable<JiveAccount> accounts = const [],
    TransactionEntrySource source = TransactionEntrySource.voice,
    String? sourceLabel,
  }) {
    final type = _normalizeType(intent.type);
    final accountAliases = _normalizedAccountAliases(accounts);
    final fromAccount = _resolveAccount(intent.accountHint, accountAliases);
    final toAccount = type == 'transfer'
        ? _resolveAccount(
            intent.toAccountHint,
            accountAliases,
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
    List<_AccountAlias> accounts, {
    int? excludeId,
  }) {
    final normalizedHint = _normalize(hint);
    if (normalizedHint.isEmpty) return null;
    for (final entry in accounts) {
      final account = entry.account;
      if (account.id == excludeId) {
        continue;
      }
      for (final normalizedAlias in entry.normalizedAliases) {
        if (normalizedAlias.isEmpty) continue;
        if (normalizedAlias.contains(normalizedHint) ||
            normalizedHint.contains(normalizedAlias)) {
          return account;
        }
      }
    }
    return null;
  }

  List<_AccountAlias> _normalizedAccountAliases(Iterable<JiveAccount> accounts) {
    return accounts
        .map(
          (account) => _AccountAlias(
            account,
            _accountAliases(account)
                .map(_normalize)
                .where((alias) => alias.isNotEmpty)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  List<String> _accountAliases(JiveAccount account) {
    final values = <String>[account.name, account.type, account.currency];
    if (account.subType != null) values.add(account.subType!);
    final tailMatch = _accountTailPattern.firstMatch(account.name);
    if (tailMatch != null) values.add(tailMatch.group(1)!);
    return values;
  }

  String _normalize(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll(_normalizePattern, '')
        .trim();
  }
}

class _AccountAlias {
  final JiveAccount account;
  final List<String> normalizedAliases;

  const _AccountAlias(this.account, this.normalizedAliases);
}
