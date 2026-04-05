import 'package:isar/isar.dart';

import '../database/transaction_model.dart';
import 'database_service.dart';

// ── Data classes ──

/// Aggregated stats for a single merchant.
class MerchantStat {
  final String merchantName;
  final double totalAmount;
  final int transactionCount;
  final double avgAmount;
  final DateTime lastVisitDate;

  const MerchantStat({
    required this.merchantName,
    required this.totalAmount,
    required this.transactionCount,
    required this.avgAmount,
    required this.lastVisitDate,
  });
}

/// Monthly spending amount.
class MonthAmount {
  final int year;
  final int month;
  final double amount;

  const MonthAmount({
    required this.year,
    required this.month,
    required this.amount,
  });

  String get label =>
      '${year.toString().substring(2)}/${month.toString().padLeft(2, '0')}';
}

// ── Service ──

/// Merchant analytics service — aggregates transaction data by merchant.
class MerchantAnalyticsService {
  final Isar _isar;

  MerchantAnalyticsService(this._isar);

  /// Create from DatabaseService singleton.
  static Future<MerchantAnalyticsService> create() async {
    final isar = await DatabaseService.getInstance();
    return MerchantAnalyticsService(isar);
  }

  /// Extract merchant name from a transaction (same logic as MerchantMemoryService).
  static String? extractMerchantName(JiveTransaction tx) {
    if (tx.note != null && tx.note!.isNotEmpty) {
      return tx.note!.split(RegExp(r'[-–—·•|]')).first.trim();
    }
    if (tx.rawText != null && tx.rawText!.isNotEmpty) {
      return tx.rawText!.split(RegExp(r'[-–—·•|]')).first.trim();
    }
    return null;
  }

  /// Normalize merchant name for grouping.
  static String _normalize(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  /// Aggregate transactions by merchant within the last [months] months,
  /// sorted by total amount descending.
  Future<List<MerchantStat>> getMerchantRanking(int months) async {
    final txs = await _fetchExpenses(months);
    return _aggregate(txs);
  }

  /// Get all transactions for a specific merchant.
  Future<List<JiveTransaction>> getMerchantHistory(
    String merchantName, {
    int? limit,
  }) async {
    final normalized = _normalize(merchantName);
    final all = await _isar.jiveTransactions
        .where()
        .sortByTimestampDesc()
        .findAll();

    final matched = all.where((tx) {
      final name = extractMerchantName(tx);
      if (name == null) return false;
      return _normalize(name) == normalized;
    }).toList();

    if (limit != null && matched.length > limit) {
      return matched.sublist(0, limit);
    }
    return matched;
  }

  /// Monthly spending trend at a specific merchant over the last [months] months.
  Future<List<MonthAmount>> getMerchantTrend(
    String merchantName,
    int months,
  ) async {
    final normalized = _normalize(merchantName);
    final txs = await _fetchExpenses(months);

    final matched = txs.where((tx) {
      final name = extractMerchantName(tx);
      if (name == null) return false;
      return _normalize(name) == normalized;
    }).toList();

    // Group by year-month
    final map = <String, double>{};
    final now = DateTime.now();
    for (var i = months - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month}';
      map[key] = 0;
    }

    for (final tx in matched) {
      final key = '${tx.timestamp.year}-${tx.timestamp.month}';
      map[key] = (map[key] ?? 0) + tx.amount.abs();
    }

    return map.entries.map((e) {
      final parts = e.key.split('-');
      return MonthAmount(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        amount: e.value,
      );
    }).toList();
  }

  /// Top merchants by visit frequency.
  Future<List<MerchantStat>> getTopMerchants({int limit = 20}) async {
    final txs = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .findAll();
    final stats = _aggregate(txs);
    stats.sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
    if (stats.length > limit) return stats.sublist(0, limit);
    return stats;
  }

  // ── Helpers ──

  Future<List<JiveTransaction>> _fetchExpenses(int months) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);
    return _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampGreaterThan(start)
        .findAll();
  }

  List<MerchantStat> _aggregate(List<JiveTransaction> txs) {
    final map = <String, _MerchantAccum>{};

    for (final tx in txs) {
      final name = extractMerchantName(tx);
      if (name == null || name.isEmpty) continue;
      final key = _normalize(name);
      final accum = map.putIfAbsent(
        key,
        () => _MerchantAccum(displayName: name),
      );
      accum.total += tx.amount.abs();
      accum.count += 1;
      if (accum.lastDate == null ||
          tx.timestamp.isAfter(accum.lastDate!)) {
        accum.lastDate = tx.timestamp;
        accum.displayName = name; // keep most recent display name
      }
    }

    final stats = map.values
        .where((a) => a.count > 0)
        .map(
          (a) => MerchantStat(
            merchantName: a.displayName,
            totalAmount: a.total,
            transactionCount: a.count,
            avgAmount: a.total / a.count,
            lastVisitDate: a.lastDate ?? DateTime.now(),
          ),
        )
        .toList();
    stats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return stats;
  }
}

class _MerchantAccum {
  String displayName;
  double total = 0;
  int count = 0;
  DateTime? lastDate;

  _MerchantAccum({required this.displayName});
}
