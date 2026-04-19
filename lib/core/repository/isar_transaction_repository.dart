import 'package:isar/isar.dart';

import '../database/transaction_model.dart';
import 'transaction_repository.dart';

/// Isar-backed implementation of [TransactionRepository].
///
/// This is the current production implementation. Once the Drift migration
/// is complete, this class will be removed.
class IsarTransactionRepository implements TransactionRepository {
  final Isar _isar;

  IsarTransactionRepository(this._isar);

  @override
  Future<List<JiveTransaction>> getAll({int? bookId}) async {
    if (bookId != null) {
      return _isar.jiveTransactions
          .filter()
          .bookIdEqualTo(bookId)
          .sortByTimestampDesc()
          .findAll();
    }
    return _isar.jiveTransactions.where().sortByTimestampDesc().findAll();
  }

  @override
  Future<JiveTransaction?> getById(int id) async {
    return _isar.jiveTransactions.get(id);
  }

  @override
  Future<List<JiveTransaction?>> getByIds(List<int> ids) async {
    return _isar.jiveTransactions.getAll(ids);
  }

  @override
  Future<int> insert(JiveTransaction item) async {
    late int id;
    await _isar.writeTxn(() async {
      id = await _isar.jiveTransactions.put(item);
    });
    return id;
  }

  @override
  Future<List<int>> insertAll(List<JiveTransaction> items) async {
    late List<int> ids;
    await _isar.writeTxn(() async {
      ids = await _isar.jiveTransactions.putAll(items);
    });
    return ids;
  }

  @override
  Future<void> update(JiveTransaction item) async {
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(item);
    });
  }

  @override
  Future<void> updateAll(List<JiveTransaction> items) async {
    if (items.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll(items);
    });
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.delete(id);
    });
  }

  @override
  Future<void> deleteAll(List<int> ids) async {
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.deleteAll(ids);
    });
  }

  @override
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.clear();
    });
  }

  @override
  Future<List<JiveTransaction>> getByDateRange({
    required DateTime start,
    required DateTime end,
    int? bookId,
    bool includeUpper = true,
  }) async {
    var query = _isar.jiveTransactions
        .filter()
        .timestampBetween(start, end, includeUpper: includeUpper);
    if (bookId != null) {
      query = query.bookIdEqualTo(bookId);
    }
    return query.sortByTimestampDesc().findAll();
  }

  @override
  Future<List<JiveTransaction>> getByAccountId(int accountId) async {
    return _isar.jiveTransactions
        .filter()
        .accountIdEqualTo(accountId)
        .or()
        .toAccountIdEqualTo(accountId)
        .sortByTimestampDesc()
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getByCategoryKey(String categoryKey) async {
    return _isar.jiveTransactions
        .filter()
        .categoryKeyEqualTo(categoryKey)
        .sortByTimestampDesc()
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getBySubCategoryKey(
      String subCategoryKey) async {
    return _isar.jiveTransactions
        .filter()
        .subCategoryKeyEqualTo(subCategoryKey)
        .sortByTimestampDesc()
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getUpdatedSince(DateTime since) async {
    return _isar.jiveTransactions
        .filter()
        .updatedAtGreaterThan(since)
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getPage({
    int? bookId,
    required int offset,
    required int limit,
  }) async {
    if (bookId != null) {
      return _isar.jiveTransactions
          .where()
          .filter()
          .bookIdEqualTo(bookId)
          .sortByTimestampDesc()
          .offset(offset)
          .limit(limit)
          .findAll();
    }
    return _isar.jiveTransactions
        .where()
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  @override
  Future<int> count({int? bookId}) async {
    if (bookId != null) {
      return _isar.jiveTransactions
          .filter()
          .bookIdEqualTo(bookId)
          .count();
    }
    return _isar.jiveTransactions.count();
  }

  @override
  Future<int> countByCategoryKey(String categoryKey,
      {bool isSub = false}) async {
    if (isSub) {
      return _isar.jiveTransactions
          .filter()
          .subCategoryKeyEqualTo(categoryKey)
          .count();
    }
    return _isar.jiveTransactions
        .filter()
        .categoryKeyEqualTo(categoryKey)
        .count();
  }

  @override
  Future<List<JiveTransaction>> getByTagKey(String tagKey) async {
    return _isar.jiveTransactions
        .filter()
        .tagKeysElementEqualTo(tagKey)
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getByReimbursementStatus(
      String status) async {
    return _isar.jiveTransactions
        .filter()
        .reimbursementStatusEqualTo(status)
        .sortByTimestampDesc()
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getBySplitGroupKey(
      String splitGroupKey) async {
    return _isar.jiveTransactions
        .filter()
        .splitGroupKeyEqualTo(splitGroupKey)
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getByProjectId(int projectId,
      {String? type}) async {
    var query =
        _isar.jiveTransactions.filter().projectIdEqualTo(projectId);
    if (type != null) {
      query = query.typeEqualTo(type);
    }
    return query.sortByTimestampDesc().findAll();
  }

  @override
  Future<List<JiveTransaction>> getByQuickActionId(int actionId) async {
    return _isar.jiveTransactions
        .filter()
        .quickActionIdEqualTo(actionId)
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getByAccountIdAndDateRange({
    required int accountId,
    required DateTime start,
    required DateTime end,
  }) async {
    return _isar.jiveTransactions
        .filter()
        .accountIdEqualTo(accountId)
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getByToAccountId(int toAccountId,
      {String? type}) async {
    var query =
        _isar.jiveTransactions.filter().toAccountIdEqualTo(toAccountId);
    if (type != null) {
      query = query.typeEqualTo(type);
    }
    return query.findAll();
  }

  @override
  Future<List<JiveTransaction>> query({
    int? bookId,
    DateTime? start,
    DateTime? end,
    bool includeUpper = true,
    String? categoryKey,
    String? subCategoryKey,
    String? type,
    int? accountId,
    int? projectId,
    bool? excludeFromBudget,
    int limit = 0,
    int offset = 0,
    bool sortDescending = true,
  }) async {
    var q = _isar.jiveTransactions.filter().idGreaterThan(-1);

    if (bookId != null) {
      q = q.bookIdEqualTo(bookId);
    }
    if (start != null && end != null) {
      q = q.timestampBetween(start, end, includeUpper: includeUpper);
    } else if (start != null) {
      q = q.timestampGreaterThan(start);
    } else if (end != null) {
      q = q.timestampLessThan(end);
    }
    if (type != null) {
      q = q.typeEqualTo(type);
    }
    if (categoryKey != null) {
      q = q.group(
        (inner) => inner
            .categoryKeyEqualTo(categoryKey)
            .or()
            .subCategoryKeyEqualTo(categoryKey),
      );
    }
    if (subCategoryKey != null) {
      q = q.subCategoryKeyEqualTo(subCategoryKey);
    }
    if (accountId != null) {
      q = q.accountIdEqualTo(accountId);
    }
    if (projectId != null) {
      q = q.projectIdEqualTo(projectId);
    }
    if (excludeFromBudget != null) {
      q = q.excludeFromBudgetEqualTo(excludeFromBudget);
    }

    QueryBuilder<JiveTransaction, JiveTransaction, QAfterSortBy> sorted;
    if (sortDescending) {
      sorted = q.sortByTimestampDesc();
    } else {
      sorted = q.sortByTimestamp();
    }

    if (offset > 0 && limit > 0) {
      return sorted.offset(offset).limit(limit).findAll();
    } else if (offset > 0) {
      return sorted.offset(offset).findAll();
    } else if (limit > 0) {
      return sorted.limit(limit).findAll();
    }

    return sorted.findAll();
  }

  @override
  Future<List<JiveTransaction>> getUncategorized({int limit = 50}) async {
    return _isar.jiveTransactions
        .filter()
        .categoryKeyIsNull()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getSmartTagOptOuts() async {
    return _isar.jiveTransactions
        .filter()
        .group(
          (q) => q
              .smartTagOptOutAllEqualTo(true)
              .or()
              .smartTagOptOutKeysIsNotEmpty(),
        )
        .sortByTimestampDesc()
        .findAll();
  }

  @override
  Future<List<JiveTransaction>> getUnreimbursedExpenses(
      {int limit = 100}) async {
    return _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .reimbursementStatusIsNull()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }

  @override
  Stream<List<JiveTransaction>> watchAll({int? bookId}) {
    if (bookId != null) {
      return _isar.jiveTransactions
          .filter()
          .bookIdEqualTo(bookId)
          .sortByTimestampDesc()
          .watch(fireImmediately: true);
    }
    return _isar.jiveTransactions
        .where()
        .sortByTimestampDesc()
        .watch(fireImmediately: true);
  }
}
