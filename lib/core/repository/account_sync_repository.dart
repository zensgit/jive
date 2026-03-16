import 'package:isar/isar.dart';

import '../database/account_model.dart';
import 'sync_cursor.dart';
import 'sync_repository_contract.dart';

class AccountSyncRepository implements SyncRepository<JiveAccount> {
  AccountSyncRepository(this.isar);

  final Isar isar;

  @override
  String get entityType => 'account';

  @override
  Future<SyncPage<JiveAccount>> listChangedAfter({
    SyncCursor? cursor,
    int limit = 100,
  }) async {
    _validateCursor(cursor);
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    accounts.sort(_compareAccount);

    final changed = accounts
        .where((account) => _isAfterCursor(account, cursor))
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
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    if (accounts.isEmpty) return null;
    accounts.sort(_compareAccount);
    return _cursorFrom(accounts.last);
  }

  bool _isAfterCursor(JiveAccount account, SyncCursor? cursor) {
    if (cursor == null) return true;
    final updatedAtCompare = account.updatedAt.compareTo(cursor.updatedAt);
    if (updatedAtCompare > 0) return true;
    if (updatedAtCompare < 0) return false;
    return account.id > cursor.lastId;
  }

  int _compareAccount(JiveAccount a, JiveAccount b) {
    final updatedAtCompare = a.updatedAt.compareTo(b.updatedAt);
    if (updatedAtCompare != 0) return updatedAtCompare;
    return a.id.compareTo(b.id);
  }

  SyncCursor _cursorFrom(JiveAccount account) {
    return SyncCursor(
      entityType: entityType,
      updatedAt: account.updatedAt,
      lastId: account.id,
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
