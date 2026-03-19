import 'package:isar/isar.dart';

import '../database/transaction_model.dart';
import 'sync_cursor.dart';
import 'sync_repository_contract.dart';

class TransactionSyncRepository implements SyncRepository<JiveTransaction> {
  TransactionSyncRepository(this.isar);

  final Isar isar;

  @override
  String get entityType => 'transaction';

  @override
  Future<SyncPage<JiveTransaction>> listChangedAfter({
    SyncCursor? cursor,
    int limit = 100,
  }) async {
    _validateCursor(cursor);
    final transactions = await isar
        .collection<JiveTransaction>()
        .where()
        .findAll();
    transactions.sort(_compareTransaction);

    final changed = transactions
        .where((transaction) => _isAfterCursor(transaction, cursor))
        .toList(growable: false);
    final items = changed.take(limit).toList(growable: false);

    return SyncPage(
      items: items,
      nextCursor: items.isEmpty ? cursor : _cursorFrom(items.last),
      hasMore: changed.length > items.length,
    );
  }

  @override
  Future<SyncCursor?> latestCursor() async {
    final transactions = await isar
        .collection<JiveTransaction>()
        .where()
        .findAll();
    if (transactions.isEmpty) return null;
    transactions.sort(_compareTransaction);
    return _cursorFrom(transactions.last);
  }

  bool _isAfterCursor(JiveTransaction transaction, SyncCursor? cursor) {
    if (cursor == null) return true;
    final updatedAtCompare = transaction.updatedAt.compareTo(cursor.updatedAt);
    if (updatedAtCompare > 0) return true;
    if (updatedAtCompare < 0) return false;
    return transaction.id > cursor.lastId;
  }

  int _compareTransaction(JiveTransaction a, JiveTransaction b) {
    final updatedAtCompare = a.updatedAt.compareTo(b.updatedAt);
    if (updatedAtCompare != 0) return updatedAtCompare;
    return a.id.compareTo(b.id);
  }

  SyncCursor _cursorFrom(JiveTransaction transaction) {
    return SyncCursor(
      entityType: entityType,
      updatedAt: transaction.updatedAt,
      lastId: transaction.id,
    );
  }

  void _validateCursor(SyncCursor? cursor) {
    if (cursor != null && cursor.entityType != entityType) {
      throw StateError(
        'sync cursor entityType=${cursor.entityType} 不能用于 $entityType repository',
      );
    }
  }
}
