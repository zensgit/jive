import 'package:isar/isar.dart';

import '../database/account_model.dart';
import 'account_repository.dart';

/// Isar-backed implementation of [AccountRepository].
class IsarAccountRepository implements AccountRepository {
  final Isar _isar;

  IsarAccountRepository(this._isar);

  @override
  Future<List<JiveAccount>> getAll({int? bookId}) async {
    if (bookId != null) {
      return _isar.jiveAccounts
          .filter()
          .bookIdEqualTo(bookId)
          .sortByOrder()
          .findAll();
    }
    return _isar.jiveAccounts.where().sortByOrder().findAll();
  }

  @override
  Future<JiveAccount?> getById(int id) async {
    return _isar.jiveAccounts.get(id);
  }

  @override
  Future<JiveAccount?> getByKey(String key) async {
    return _isar.jiveAccounts.filter().keyEqualTo(key).findFirst();
  }

  @override
  Future<int> insert(JiveAccount item) async {
    late int id;
    await _isar.writeTxn(() async {
      id = await _isar.jiveAccounts.put(item);
    });
    return id;
  }

  @override
  Future<List<int>> insertAll(List<JiveAccount> items) async {
    late List<int> ids;
    await _isar.writeTxn(() async {
      ids = await _isar.jiveAccounts.putAll(items);
    });
    return ids;
  }

  @override
  Future<void> update(JiveAccount item) async {
    await _isar.writeTxn(() async {
      await _isar.jiveAccounts.put(item);
    });
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveAccounts.delete(id);
    });
  }

  @override
  Future<List<JiveAccount>> getVisible({int? bookId}) async {
    var query = _isar.jiveAccounts
        .filter()
        .isHiddenEqualTo(false)
        .isArchivedEqualTo(false);
    if (bookId != null) {
      query = query.bookIdEqualTo(bookId);
    }
    return query.sortByOrder().findAll();
  }

  @override
  Future<List<int>> putAll(List<JiveAccount> items) async {
    late List<int> ids;
    await _isar.writeTxn(() async {
      ids = await _isar.jiveAccounts.putAll(items);
    });
    return ids;
  }

  @override
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.jiveAccounts.clear();
    });
  }

  @override
  Future<List<JiveAccount>> getByType(String type) async {
    return _isar.jiveAccounts
        .filter()
        .typeEqualTo(type)
        .findAll();
  }

  @override
  Future<int> count({int? bookId}) async {
    if (bookId != null) {
      return _isar.jiveAccounts
          .filter()
          .bookIdEqualTo(bookId)
          .count();
    }
    return _isar.jiveAccounts.count();
  }

  @override
  Stream<List<JiveAccount>> watchAll({int? bookId}) {
    if (bookId != null) {
      return _isar.jiveAccounts
          .filter()
          .bookIdEqualTo(bookId)
          .sortByOrder()
          .watch(fireImmediately: true);
    }
    return _isar.jiveAccounts
        .where()
        .sortByOrder()
        .watch(fireImmediately: true);
  }
}
