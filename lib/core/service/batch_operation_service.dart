import 'package:isar/isar.dart';

import '../database/transaction_model.dart';
import 'transaction_service.dart';

/// Enhanced batch operations for transactions.
class BatchOperationService {
  final Isar _isar;

  BatchOperationService(this._isar);

  /// Batch-update merchant (note + rawText) for selected transactions.
  Future<int> batchUpdateMerchant(List<int> txIds, String merchant) async {
    if (txIds.isEmpty) return 0;
    final txs = await _fetchTransactions(txIds);
    if (txs.isEmpty) return 0;

    for (final tx in txs) {
      tx.note = merchant;
      tx.rawText = merchant;
    }
    TransactionService.touchSyncMetadataForAll(txs);

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll(txs);
    });
    return txs.length;
  }

  /// Batch-set tags for selected transactions.
  Future<int> batchUpdateTags(List<int> txIds, List<String> tagKeys) async {
    if (txIds.isEmpty) return 0;
    final txs = await _fetchTransactions(txIds);
    if (txs.isEmpty) return 0;

    for (final tx in txs) {
      tx.tagKeys = List<String>.from(tagKeys);
    }
    TransactionService.touchSyncMetadataForAll(txs);

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll(txs);
    });
    return txs.length;
  }

  /// Batch-change account for selected transactions.
  Future<int> batchUpdateAccount(List<int> txIds, int accountId) async {
    if (txIds.isEmpty) return 0;
    final txs = await _fetchTransactions(txIds);
    if (txs.isEmpty) return 0;

    for (final tx in txs) {
      tx.accountId = accountId;
    }
    TransactionService.touchSyncMetadataForAll(txs);

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll(txs);
    });
    return txs.length;
  }

  /// Batch-clear a specific field for selected transactions.
  ///
  /// Supported fields: `note`, `tags`, `merchant` (clears note + rawText).
  Future<int> batchClearField(List<int> txIds, String field) async {
    if (txIds.isEmpty) return 0;
    final txs = await _fetchTransactions(txIds);
    if (txs.isEmpty) return 0;

    for (final tx in txs) {
      switch (field) {
        case 'note':
          tx.note = null;
        case 'tags':
          tx.tagKeys = [];
        case 'merchant':
          tx.note = null;
          tx.rawText = null;
        default:
          continue;
      }
    }
    TransactionService.touchSyncMetadataForAll(txs);

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll(txs);
    });
    return txs.length;
  }

  // ── helpers ──────────────────────────────────────────────────────────

  Future<List<JiveTransaction>> _fetchTransactions(List<int> ids) async {
    final results = <JiveTransaction>[];
    for (final id in ids) {
      final tx = await _isar.jiveTransactions.get(id);
      if (tx != null) results.add(tx);
    }
    return results;
  }
}
