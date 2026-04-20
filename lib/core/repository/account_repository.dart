import '../database/account_model.dart';

/// Abstract account repository — database-agnostic interface.
abstract class AccountRepository {
  /// Return all accounts, optionally filtered by [bookId].
  Future<List<JiveAccount>> getAll({int? bookId});

  /// Return a single account by its local [id], or null.
  Future<JiveAccount?> getById(int id);

  /// Look up an account by its unique [key].
  Future<JiveAccount?> getByKey(String key);

  /// Insert a new account. Returns the generated id.
  Future<int> insert(JiveAccount item);

  /// Bulk-insert accounts. Returns the list of generated ids.
  Future<List<int>> insertAll(List<JiveAccount> items);

  /// Update an existing account.
  Future<void> update(JiveAccount item);

  /// Delete an account by [id].
  Future<void> delete(int id);

  /// Return only visible (non-hidden, non-archived) accounts.
  Future<List<JiveAccount>> getVisible({int? bookId});

  /// Bulk-insert accounts, replacing existing ones. Returns generated ids.
  Future<List<int>> putAll(List<JiveAccount> items);

  /// Delete every account in the collection.
  Future<void> clearAll();

  /// Return accounts matching a given [type] (e.g. 'liability').
  Future<List<JiveAccount>> getByType(String type);

  /// Count of accounts, optionally scoped to a book.
  Future<int> count({int? bookId});

  /// Watch all accounts as a reactive stream.
  Stream<List<JiveAccount>> watchAll({int? bookId});
}
