import '../transactions/transaction_entry_params.dart';

class QuickActionDeepLinkRequest {
  final String? quickActionId;
  final TransactionEntryParams? transactionParams;

  const QuickActionDeepLinkRequest._({
    this.quickActionId,
    this.transactionParams,
  });

  const QuickActionDeepLinkRequest.quickAction(String id)
    : this._(quickActionId: id);

  const QuickActionDeepLinkRequest.transaction(TransactionEntryParams params)
    : this._(transactionParams: params);

  bool get isQuickAction => quickActionId != null;
  bool get isTransaction => transactionParams != null;
}

/// Parses MoneyThings-style external entry links into the same in-app protocol
/// used by quick actions, widgets, and the structured transaction editor.
class QuickActionDeepLinkService {
  const QuickActionDeepLinkService._();

  static QuickActionDeepLinkRequest? parse(Uri uri) {
    if (uri.scheme != 'jive') return null;

    if (uri.host == 'quick-action') {
      final id = _firstNonEmpty(
        uri.queryParameters['id'],
        uri.pathSegments.isEmpty
            ? null
            : Uri.decodeComponent(uri.pathSegments.join('/')),
      );
      if (id == null) return null;
      return QuickActionDeepLinkRequest.quickAction(id);
    }

    if (uri.host == 'transaction' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'new') {
      return QuickActionDeepLinkRequest.transaction(_parseTransaction(uri));
    }

    return null;
  }

  static int? legacyTemplateId(String quickActionId) {
    if (quickActionId.startsWith('template:')) {
      return int.tryParse(quickActionId.substring('template:'.length));
    }
    return int.tryParse(quickActionId);
  }

  static TransactionEntryParams _parseTransaction(Uri uri) {
    final query = uri.queryParameters;
    final type = _normalizedType(query['type']);
    final amount = double.tryParse(query['amount'] ?? '');
    final accountId = int.tryParse(query['accountId'] ?? '');
    final toAccountId = int.tryParse(
      query['toAccountId'] ?? query['transferAccountId'] ?? '',
    );
    final bookId = int.tryParse(query['bookId'] ?? '');
    final categoryKey = _firstNonEmpty(query['categoryKey'], query['category']);
    final subCategoryKey = _firstNonEmpty(
      query['subCategoryKey'],
      query['leafCategoryKey'],
    );
    final tagKeys = _splitCsv(_firstNonEmpty(query['tagKeys'], query['tags']));
    final date = _parseDate(_firstNonEmpty(query['date'], query['time']));

    return TransactionEntryParams(
      source: TransactionEntrySource.deepLink,
      sourceLabel: _firstNonEmpty(query['sourceLabel'], query['source']),
      prefillAmount: amount,
      prefillType: type,
      prefillCategoryKey: categoryKey,
      prefillSubCategoryKey: subCategoryKey,
      prefillAccountId: accountId,
      prefillToAccountId: toAccountId,
      prefillBookId: bookId,
      prefillNote: _firstNonEmpty(query['note'], query['memo']),
      prefillDate: date,
      prefillTagKeys: tagKeys.isEmpty ? null : tagKeys,
      prefillRawText: _firstNonEmpty(query['rawText'], query['raw']),
      highlightFields: _missingFields(
        type: type,
        amount: amount,
        accountId: accountId,
        toAccountId: toAccountId,
        categoryKey: categoryKey,
        subCategoryKey: subCategoryKey,
      ),
    );
  }

  static String _normalizedType(String? raw) {
    switch (raw?.trim()) {
      case 'income':
      case 'transfer':
      case 'expense':
        return raw!.trim();
      default:
        return 'expense';
    }
  }

  static List<String> _missingFields({
    required String type,
    required double? amount,
    required int? accountId,
    required int? toAccountId,
    required String? categoryKey,
    required String? subCategoryKey,
  }) {
    final missing = <String>[];
    if (amount == null || amount <= 0) {
      missing.add(TransactionHighlightField.amount);
    }
    if (accountId == null) {
      missing.add(TransactionHighlightField.account);
    }
    if (type == 'transfer') {
      if (toAccountId == null) {
        missing.add(TransactionHighlightField.transferAccount);
      }
    } else if (_firstNonEmpty(categoryKey, subCategoryKey) == null) {
      missing.add(TransactionHighlightField.category);
    }
    return missing;
  }

  static List<String> _splitCsv(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  static String? _firstNonEmpty(String? first, String? second) {
    final a = first?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = second?.trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}
