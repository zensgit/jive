import 'package:isar/isar.dart';

import '../database/quick_action_model.dart';
import '../database/transaction_model.dart';

/// Analytics helpers for [JiveQuickAction] — surfaces top/recent actions,
/// suggests new actions based on transaction patterns, and provides per-action
/// stats.
class QuickActionAnalyticsService {
  final Isar _isar;

  QuickActionAnalyticsService(this._isar);

  /// Returns the top [limit] quick actions sorted by [usageCount] descending.
  Future<List<JiveQuickAction>> getTopActions({int limit = 10}) async {
    return _isar.jiveQuickActions
        .where()
        .sortByUsageCountDesc()
        .limit(limit)
        .findAll();
  }

  /// Returns the most recently used [limit] actions sorted by [lastUsedAt]
  /// descending.
  Future<List<JiveQuickAction>> getRecentActions({int limit = 5}) async {
    return _isar.jiveQuickActions
        .where()
        .filter()
        .lastUsedAtIsNotNull()
        .sortByLastUsedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// Suggests new quick actions by finding transaction patterns that repeat
  /// 5+ times (same categoryKey + accountId) but don't yet have a matching
  /// [JiveQuickAction].
  Future<List<QuickActionSuggestion>> suggestNewActions() async {
    final allTx = await _isar.jiveTransactions.where().findAll();

    // Count occurrences of (categoryKey, accountId) pairs.
    final counts = <String, _TxPattern>{};
    for (final tx in allTx) {
      if (tx.categoryKey == null || tx.accountId == null) continue;
      final key = '${tx.categoryKey}|${tx.accountId}';
      counts.putIfAbsent(
        key,
        () => _TxPattern(
          categoryKey: tx.categoryKey!,
          accountId: tx.accountId!,
          type: tx.type ?? 'expense',
        ),
      );
      counts[key]!.count += 1;
      counts[key]!.totalAmount += tx.amount.abs();
    }

    // Keep only patterns with 5+ occurrences.
    final frequent =
        counts.values.where((p) => p.count >= 5).toList();

    if (frequent.isEmpty) return [];

    // Load existing quick actions to exclude matches.
    final existingActions = await _isar.jiveQuickActions.where().findAll();
    final existingKeys = <String>{};
    for (final a in existingActions) {
      if (a.categoryKey != null && a.accountId != null) {
        existingKeys.add('${a.categoryKey}|${a.accountId}');
      }
    }

    final suggestions = <QuickActionSuggestion>[];
    for (final pattern in frequent) {
      final key = '${pattern.categoryKey}|${pattern.accountId}';
      if (existingKeys.contains(key)) continue;

      suggestions.add(QuickActionSuggestion(
        categoryKey: pattern.categoryKey,
        accountId: pattern.accountId,
        transactionType: pattern.type,
        occurrenceCount: pattern.count,
        averageAmount: pattern.totalAmount / pattern.count,
      ));
    }

    // Sort by frequency descending.
    suggestions.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));
    return suggestions;
  }

  /// Returns usage statistics for a specific quick action.
  Future<QuickActionStats> getActionStats(int actionId) async {
    final action = await _isar.jiveQuickActions.get(actionId);

    // Count transactions linked to this action.
    final linkedTx = await _isar.jiveTransactions
        .filter()
        .quickActionIdEqualTo(actionId)
        .findAll();

    double totalAmount = 0;
    for (final tx in linkedTx) {
      totalAmount += tx.amount.abs();
    }

    return QuickActionStats(
      actionId: actionId,
      usageCount: action?.usageCount ?? 0,
      lastUsedAt: action?.lastUsedAt,
      totalAmountSaved: totalAmount,
      linkedTransactionCount: linkedTx.length,
    );
  }
}

/// Internal helper for counting transaction patterns.
class _TxPattern {
  final String categoryKey;
  final int accountId;
  final String type;
  int count = 0;
  double totalAmount = 0;

  _TxPattern({
    required this.categoryKey,
    required this.accountId,
    required this.type,
  });
}

/// Represents a suggested quick action based on frequent transaction patterns.
class QuickActionSuggestion {
  final String categoryKey;
  final int accountId;
  final String transactionType;
  final int occurrenceCount;
  final double averageAmount;

  const QuickActionSuggestion({
    required this.categoryKey,
    required this.accountId,
    required this.transactionType,
    required this.occurrenceCount,
    required this.averageAmount,
  });

  @override
  String toString() =>
      'QuickActionSuggestion($categoryKey, account=$accountId, '
      'count=$occurrenceCount, avg=$averageAmount)';
}

/// Usage statistics for a single quick action.
class QuickActionStats {
  final int actionId;
  final int usageCount;
  final DateTime? lastUsedAt;
  final double totalAmountSaved;
  final int linkedTransactionCount;

  const QuickActionStats({
    required this.actionId,
    required this.usageCount,
    this.lastUsedAt,
    required this.totalAmountSaved,
    required this.linkedTransactionCount,
  });
}
