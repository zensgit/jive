import '../transactions/transaction_entry_params.dart';

/// Builds the MoneyThings-style entry links that [QuickActionDeepLinkService]
/// parses back into the unified transaction-entry protocol.
class QuickActionEntryLinkBuilder {
  const QuickActionEntryLinkBuilder._();

  static Uri quickAction(String id) {
    return Uri(
      scheme: 'jive',
      host: 'quick-action',
      queryParameters: {'id': id},
    );
  }

  static Uri templateQuickAction(int templateId) {
    return quickAction('template:$templateId');
  }

  static Uri transaction(TransactionEntryParams params) {
    final query = <String, String>{};

    _put(query, 'type', params.prefillType);
    _put(query, 'amount', _formatAmount(params.prefillAmount));
    _put(query, 'categoryKey', params.prefillCategoryKey);
    _put(query, 'subCategoryKey', params.prefillSubCategoryKey);
    _put(query, 'accountId', params.prefillAccountId?.toString());
    _put(query, 'toAccountId', params.prefillToAccountId?.toString());
    _put(query, 'bookId', params.prefillBookId?.toString());
    _put(query, 'note', params.prefillNote);
    _put(query, 'rawText', params.prefillRawText);
    _put(query, 'tagKeys', _formatTagKeys(params.prefillTagKeys));
    _put(query, 'date', params.prefillDate?.toIso8601String());
    _put(query, 'entrySource', _entrySourceValue(params.source));
    _put(query, 'sourceLabel', params.sourceLabel);

    return Uri(
      scheme: 'jive',
      host: 'transaction',
      path: '/new',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  static void _put(Map<String, String> query, String key, String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return;
    query[key] = text;
  }

  static String? _formatAmount(double? amount) {
    if (amount == null) return null;
    if (!amount.isFinite) return null;
    if (amount == amount.truncateToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  static String? _formatTagKeys(List<String>? tagKeys) {
    final keys = tagKeys
        ?.map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
    if (keys == null || keys.isEmpty) return null;
    return keys.join(',');
  }

  static String? _entrySourceValue(TransactionEntrySource source) {
    switch (source) {
      case TransactionEntrySource.shareReceive:
        return 'shareReceive';
      case TransactionEntrySource.ocrScreenshot:
        return 'ocrScreenshot';
      case TransactionEntrySource.deepLink:
        return null;
      case TransactionEntrySource.manual:
      case TransactionEntrySource.quickAction:
      case TransactionEntrySource.voice:
      case TransactionEntrySource.conversation:
      case TransactionEntrySource.autoDraft:
      case TransactionEntrySource.edit:
        return null;
    }
  }
}
