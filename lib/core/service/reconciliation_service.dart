import 'package:isar/isar.dart';

import '../database/transaction_model.dart';

/// 账单对账摘要
class ReconciliationSummary {
  final int totalTransactions;
  final int reconciledCount;
  final int unreconciledCount;
  final double totalAmount;
  final double reconciledAmount;
  final double difference;

  const ReconciliationSummary({
    required this.totalTransactions,
    required this.reconciledCount,
    required this.unreconciledCount,
    required this.totalAmount,
    required this.reconciledAmount,
    required this.difference,
  });
}

/// 信用卡账单对账/结算服务
///
/// 使用 transaction.note 中的 [reconciled] 标记来追踪对账状态。
/// 结算使用 [settled:YYYY-MM] 标记。
class ReconciliationService {
  final Isar isar;

  static const String _reconciledTag = '[reconciled]';
  static const String _settledPrefix = '[settled:';

  ReconciliationService(this.isar);

  /// 获取指定账期内未对账的交易
  Future<List<JiveTransaction>> getUnreconciledTransactions(
    int accountId,
    DateTime billingStart,
    DateTime billingEnd,
  ) async {
    final all = await _getTransactionsInPeriod(accountId, billingStart, billingEnd);
    return all.where((tx) => !_isReconciled(tx)).toList();
  }

  /// 标记交易为已对账
  Future<void> markReconciled(List<int> transactionIds) async {
    if (transactionIds.isEmpty) return;
    await isar.writeTxn(() async {
      for (final id in transactionIds) {
        final tx = await isar.jiveTransactions.get(id);
        if (tx == null || _isReconciled(tx)) continue;
        tx.note = _appendTag(tx.note, _reconciledTag);
        TransactionService._touchUpdatedAt(tx);
        await isar.jiveTransactions.put(tx);
      }
    });
  }

  /// 取消对账标记
  Future<void> unmarkReconciled(List<int> transactionIds) async {
    if (transactionIds.isEmpty) return;
    await isar.writeTxn(() async {
      for (final id in transactionIds) {
        final tx = await isar.jiveTransactions.get(id);
        if (tx == null || !_isReconciled(tx)) continue;
        tx.note = _removeTag(tx.note, _reconciledTag);
        TransactionService._touchUpdatedAt(tx);
        await isar.jiveTransactions.put(tx);
      }
    });
  }

  /// 获取对账摘要
  Future<ReconciliationSummary> getReconciliationSummary(
    int accountId,
    DateTime billingStart,
    DateTime billingEnd,
  ) async {
    final all = await _getTransactionsInPeriod(accountId, billingStart, billingEnd);
    var totalAmount = 0.0;
    var reconciledAmount = 0.0;
    var reconciledCount = 0;

    for (final tx in all) {
      totalAmount += tx.amount;
      if (_isReconciled(tx)) {
        reconciledCount++;
        reconciledAmount += tx.amount;
      }
    }

    return ReconciliationSummary(
      totalTransactions: all.length,
      reconciledCount: reconciledCount,
      unreconciledCount: all.length - reconciledCount,
      totalAmount: totalAmount,
      reconciledAmount: reconciledAmount,
      difference: totalAmount - reconciledAmount,
    );
  }

  /// 确认结算：标记该账期所有交易为已对账并打上结算标记
  Future<void> confirmSettlement(
    int accountId,
    DateTime billingStart,
    DateTime billingEnd,
  ) async {
    final all = await _getTransactionsInPeriod(accountId, billingStart, billingEnd);
    final periodKey =
        '${billingStart.year}-${billingStart.month.toString().padLeft(2, '0')}';
    final settledTag = '$_settledPrefix$periodKey]';

    await isar.writeTxn(() async {
      for (final tx in all) {
        var changed = false;
        if (!_isReconciled(tx)) {
          tx.note = _appendTag(tx.note, _reconciledTag);
          changed = true;
        }
        if (tx.note == null || !tx.note!.contains(settledTag)) {
          tx.note = _appendTag(tx.note, settledTag);
          changed = true;
        }
        if (changed) {
          TransactionService._touchUpdatedAt(tx);
          await isar.jiveTransactions.put(tx);
        }
      }
    });
  }

  /// 检查某账期是否已结算
  Future<bool> isPeriodSettled(
    int accountId,
    DateTime billingStart,
    DateTime billingEnd,
  ) async {
    final periodKey =
        '${billingStart.year}-${billingStart.month.toString().padLeft(2, '0')}';
    final settledTag = '$_settledPrefix$periodKey]';
    final all = await _getTransactionsInPeriod(accountId, billingStart, billingEnd);
    if (all.isEmpty) return false;
    return all.every((tx) => tx.note != null && tx.note!.contains(settledTag));
  }

  // --- helpers ---

  Future<List<JiveTransaction>> _getTransactionsInPeriod(
    int accountId,
    DateTime start,
    DateTime end,
  ) async {
    return isar.jiveTransactions
        .filter()
        .accountIdEqualTo(accountId)
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();
  }

  bool _isReconciled(JiveTransaction tx) {
    return tx.note != null && tx.note!.contains(_reconciledTag);
  }

  String _appendTag(String? note, String tag) {
    if (note == null || note.trim().isEmpty) return tag;
    return '$note $tag';
  }

  String _removeTag(String? note, String tag) {
    if (note == null) return '';
    return note.replaceAll(tag, '').trim();
  }
}

/// Helper to update sync metadata on transactions
class TransactionService {
  static void _touchUpdatedAt(JiveTransaction tx) {
    tx.updatedAt = DateTime.now();
  }
}
