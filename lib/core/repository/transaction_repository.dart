import '../database/transaction_model.dart';

/// Abstract transaction repository — database-agnostic interface.
///
/// Implementations back onto Isar (current) or Drift (target).
abstract class TransactionRepository {
  /// Return all transactions, optionally filtered by [bookId].
  Future<List<JiveTransaction>> getAll({int? bookId});

  /// Return a single transaction by its local [id], or null.
  Future<JiveTransaction?> getById(int id);

  /// Bulk-fetch transactions by a list of [ids]. Nulls for missing ids.
  Future<List<JiveTransaction?>> getByIds(List<int> ids);

  /// Insert a new transaction. Returns the generated id.
  Future<int> insert(JiveTransaction item);

  /// Bulk-insert a list of transactions. Returns the list of generated ids.
  Future<List<int>> insertAll(List<JiveTransaction> items);

  /// Update an existing transaction.
  Future<void> update(JiveTransaction item);

  /// Bulk-update a list of transactions (put semantics).
  Future<void> updateAll(List<JiveTransaction> items);

  /// Delete a transaction by [id].
  Future<void> delete(int id);

  /// Delete all transactions matching [ids].
  Future<void> deleteAll(List<int> ids);

  /// Delete every transaction in the collection.
  Future<void> clearAll();

  /// Return transactions within a date range, optionally filtered by [bookId].
  Future<List<JiveTransaction>> getByDateRange({
    required DateTime start,
    required DateTime end,
    int? bookId,
    bool includeUpper = true,
  });

  /// Return transactions for a specific account (from or to).
  Future<List<JiveTransaction>> getByAccountId(int accountId);

  /// Return transactions matching a category key.
  Future<List<JiveTransaction>> getByCategoryKey(String categoryKey);

  /// Return transactions matching a sub-category key.
  Future<List<JiveTransaction>> getBySubCategoryKey(String subCategoryKey);

  /// Return transactions updated after [since] (for incremental sync).
  Future<List<JiveTransaction>> getUpdatedSince(DateTime since);

  /// Return a page of transactions sorted by timestamp descending.
  Future<List<JiveTransaction>> getPage({
    int? bookId,
    required int offset,
    required int limit,
  });

  /// Count of transactions, optionally scoped to a book.
  Future<int> count({int? bookId});

  /// Count transactions matching a category or sub-category key.
  Future<int> countByCategoryKey(String categoryKey, {bool isSub = false});

  /// Return transactions that have the given [tagKey] in their tagKeys list.
  Future<List<JiveTransaction>> getByTagKey(String tagKey);

  /// Return transactions matching a [reimbursementStatus] value.
  Future<List<JiveTransaction>> getByReimbursementStatus(String status);

  /// Return transactions belonging to a split group.
  Future<List<JiveTransaction>> getBySplitGroupKey(String splitGroupKey);

  /// Return transactions for a given project, optionally filtered by [type].
  Future<List<JiveTransaction>> getByProjectId(int projectId, {String? type});

  /// Return transactions linked to a specific quick action.
  Future<List<JiveTransaction>> getByQuickActionId(int actionId);

  /// Return transactions for an account within a date range.
  Future<List<JiveTransaction>> getByAccountIdAndDateRange({
    required int accountId,
    required DateTime start,
    required DateTime end,
  });

  /// Return transactions where toAccountId matches.
  Future<List<JiveTransaction>> getByToAccountId(int toAccountId, {String? type});

  /// Flexible query: filter by type, date range, bookId, categoryKey, etc.
  /// All parameters are optional — omitted ones impose no filter.
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
  });

  /// Return transactions where categoryKey is null/empty (uncategorized).
  Future<List<JiveTransaction>> getUncategorized({int limit = 50});

  /// Return transactions with smart-tag opt-out flags set.
  Future<List<JiveTransaction>> getSmartTagOptOuts();

  /// Return expense transactions with non-null reimbursementStatus == null
  /// (i.e. unreimbursed expenses) — used for the "pick expense to reimburse" flow.
  Future<List<JiveTransaction>> getUnreimbursedExpenses({int limit = 100});

  /// Watch all transactions as a reactive stream (optional — Drift-only).
  Stream<List<JiveTransaction>> watchAll({int? bookId});
}
