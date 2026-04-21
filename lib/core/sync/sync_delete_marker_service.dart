import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/account_model.dart';
import '../database/book_model.dart';
import '../database/budget_model.dart';
import '../database/transaction_model.dart';
import '../service/book_service.dart';
import 'sync_budget_payload.dart';
import 'sync_key_generator.dart';
import 'sync_tombstone_entry.dart';
import 'sync_tombstone_store.dart';

class SyncDeleteMarkerService {
  static const _cursorPrefix = 'sync_cursor_';

  final Isar _isar;

  SyncDeleteMarkerService(this._isar);

  Future<void> markTransactionDeleted(JiveTransaction tx) async {
    await markTransactionsDeleted([tx]);
  }

  Future<void> markTransactionsDeleted(
    Iterable<JiveTransaction> transactions,
  ) async {
    if (!await _hasSyncCursor('transactions')) return;

    final items = transactions.toList(growable: false);
    if (items.isEmpty) return;

    final userId = _currentUserIdOrNull();
    final bookKeyById = await _loadBookKeyById();
    final accountSyncKeyById = await _loadAccountSyncKeyById(userId);
    final deletedAt = DateTime.now();

    await SyncTombstoneStore.upsertAll(
      items.map(
        (tx) => _buildTransactionTombstone(
          tx,
          userId: userId,
          deletedAt: deletedAt,
          bookKeyById: bookKeyById,
          accountSyncKeyById: accountSyncKeyById,
        ),
      ),
    );
  }

  Future<void> markBudgetDeleted(JiveBudget budget) async {
    if (!await _hasSyncCursor('budgets')) return;

    final userId = _currentUserIdOrNull();
    final bookKeyById = await _loadBookKeyById();
    final deletedAt = DateTime.now();
    final syncKey = _stableSyncKey(
      explicit: budget.syncKey,
      prefix: 'budget',
      table: 'budgets',
      userId: userId,
      localId: budget.id,
    );

    await SyncTombstoneStore.upsert(
      SyncTombstoneEntry(
        table: 'budgets',
        entityKey: _entityKey(syncKey, budget.id),
        deletedAt: deletedAt,
        payload: {
          'local_id': budget.id,
          'sync_key': syncKey,
          'name': budget.name,
          'amount': budget.amount,
          'period': budget.period,
          'start_date': budget.startDate.toIso8601String(),
          'end_date': budget.endDate.toIso8601String(),
          'category_keys': syncBudgetCategoryKeys(budget.categoryKey),
          'is_active': budget.isActive,
          'carry_over': budget.rollover,
          'book_key': _bookKeyFor(budget.bookId, bookKeyById),
          'deleted_at': deletedAt.toIso8601String(),
          'updated_at': deletedAt.toIso8601String(),
        },
      ),
    );
  }

  SyncTombstoneEntry _buildTransactionTombstone(
    JiveTransaction tx, {
    required String? userId,
    required DateTime deletedAt,
    required Map<int, String> bookKeyById,
    required Map<int, String?> accountSyncKeyById,
  }) {
    final syncKey = _stableSyncKey(
      explicit: tx.syncKey,
      prefix: 'tx',
      table: 'transactions',
      userId: userId,
      localId: tx.id,
    );

    return SyncTombstoneEntry(
      table: 'transactions',
      entityKey: _entityKey(syncKey, tx.id),
      deletedAt: deletedAt,
      payload: {
        'local_id': tx.id,
        'sync_key': syncKey,
        'amount': tx.amount,
        'source': tx.source,
        'type': tx.type,
        'timestamp': tx.timestamp.toIso8601String(),
        'category_key': tx.categoryKey,
        'sub_category_key': tx.subCategoryKey,
        'category': tx.category,
        'sub_category': tx.subCategory,
        'note': tx.note,
        'account_id': tx.accountId,
        'account_sync_key': _accountSyncKeyFor(
          tx.accountId,
          accountSyncKeyById,
        ),
        'to_account_id': tx.toAccountId,
        'to_account_sync_key': _accountSyncKeyFor(
          tx.toAccountId,
          accountSyncKeyById,
        ),
        'book_key': _bookKeyFor(tx.bookId, bookKeyById),
        'raw_text': tx.rawText,
        'deleted_at': deletedAt.toIso8601String(),
        'updated_at': deletedAt.toIso8601String(),
      },
    );
  }

  Future<bool> _hasSyncCursor(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_cursorPrefix$table');
    if (stored == null || stored.isEmpty) return false;

    return DateTime.tryParse(stored) != null;
  }

  Future<Map<int, String>> _loadBookKeyById() async {
    var books = await _isar.jiveBooks.where().findAll();
    if (books.isEmpty) {
      await BookService(_isar).initDefaultBook();
      books = await _isar.jiveBooks.where().findAll();
    }
    return {for (final book in books) book.id: book.key};
  }

  Future<Map<int, String?>> _loadAccountSyncKeyById(String? userId) async {
    final accounts = await _isar.jiveAccounts.where().findAll();
    return {
      for (final account in accounts)
        account.id: _stableSyncKey(
          explicit: account.syncKey,
          prefix: 'acct',
          table: 'accounts',
          userId: userId,
          localId: account.id,
        ),
    };
  }

  String _bookKeyFor(int? bookId, Map<int, String> bookKeyById) {
    if (bookId == null) return BookService.defaultBookKey;
    return bookKeyById[bookId] ?? BookService.defaultBookKey;
  }

  String? _accountSyncKeyFor(
    int? accountId,
    Map<int, String?> accountSyncKeyById,
  ) {
    if (accountId == null) return null;
    return accountSyncKeyById[accountId];
  }

  String? _stableSyncKey({
    required String explicit,
    required String prefix,
    required String table,
    required String? userId,
    required int localId,
  }) {
    if (explicit.trim().isNotEmpty) return explicit;
    if (userId == null || userId.trim().isEmpty) return null;
    return SyncKeyGenerator.generateDeterministic(
      prefix,
      '$table:$userId:$localId',
    );
  }

  String _entityKey(String? syncKey, int localId) {
    if (syncKey != null && syncKey.trim().isNotEmpty) {
      return 'sync:$syncKey';
    }
    return 'local:$localId';
  }

  String? _currentUserIdOrNull() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
}
