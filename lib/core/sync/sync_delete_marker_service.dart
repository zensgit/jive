import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/account_model.dart';
import '../database/book_model.dart';
import '../database/budget_model.dart';
import '../database/transaction_model.dart';
import '../service/book_service.dart';
import 'sync_account_scope.dart';
import 'sync_book_scope.dart';
import 'sync_tombstone_entry.dart';
import 'sync_tombstone_store.dart';

class SyncDeleteMarkerService {
  static const _cursorPrefix = 'sync_cursor_';

  final Isar _isar;

  SyncDeleteMarkerService(this._isar);

  Future<void> markTransactionDeleted(JiveTransaction tx) async {
    if (!await _shouldRecord('transactions', tx.updatedAt)) return;

    final bookScope = await _loadBookScope();
    final accountScope = await _loadAccountScope();
    final deletedAt = DateTime.now();

    await SyncTombstoneStore.upsert(
      SyncTombstoneEntry(
        table: 'transactions',
        entityKey: _localEntityKey(tx.id),
        deletedAt: deletedAt,
        payload: {
          'local_id': tx.id,
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
          'account_key': accountScope.accountKey(tx.accountId),
          'to_account_id': tx.toAccountId,
          'to_account_key': accountScope.accountKey(tx.toAccountId),
          'book_key': bookScope.transactionBookKey(tx.bookId),
          'raw_text': tx.rawText,
          'deleted_at': deletedAt.toIso8601String(),
          'updated_at': deletedAt.toIso8601String(),
        },
      ),
    );
  }

  Future<void> markTransactionsDeleted(
    Iterable<JiveTransaction> transactions,
  ) async {
    for (final tx in transactions) {
      await markTransactionDeleted(tx);
    }
  }

  Future<void> markBudgetDeleted(JiveBudget budget) async {
    if (!await _shouldRecord('budgets', budget.updatedAt)) return;

    final bookScope = await _loadBookScope();
    final deletedAt = DateTime.now();

    await SyncTombstoneStore.upsert(
      SyncTombstoneEntry(
        table: 'budgets',
        entityKey: _localEntityKey(budget.id),
        deletedAt: deletedAt,
        payload: {
          'local_id': budget.id,
          'name': budget.name,
          'amount': budget.amount,
          'period': budget.period,
          'start_date': budget.startDate.toIso8601String(),
          'end_date': budget.endDate.toIso8601String(),
          'category_keys': budget.categoryKey ?? '',
          'is_active': budget.isActive,
          'book_key': bookScope.budgetBookKey(budget.bookId),
          'deleted_at': deletedAt.toIso8601String(),
          'updated_at': deletedAt.toIso8601String(),
        },
      ),
    );
  }

  Future<bool> _shouldRecord(String table, DateTime updatedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_cursorPrefix$table');
    if (stored == null || stored.isEmpty) return false;

    final cursor = DateTime.tryParse(stored);
    if (cursor == null) return false;
    return !updatedAt.isAfter(cursor);
  }

  Future<SyncBookScope> _loadBookScope() async {
    await BookService(_isar).initDefaultBook();
    final books = await _isar.jiveBooks.where().findAll();

    JiveBook? defaultBook;
    for (final book in books) {
      if (book.key == BookService.defaultBookKey || book.isDefault) {
        defaultBook = book;
        break;
      }
    }

    return SyncBookScope(
      bookKeyById: {for (final book in books) book.id: book.key},
      bookIdByKey: {for (final book in books) book.key: book.id},
      defaultBookId: defaultBook?.id,
      defaultBookKey: defaultBook?.key ?? BookService.defaultBookKey,
    );
  }

  Future<SyncAccountScope> _loadAccountScope() async {
    final accounts = await _isar.jiveAccounts.where().findAll();
    return SyncAccountScope(
      accountKeyById: {for (final account in accounts) account.id: account.key},
      accountIdByKey: {for (final account in accounts) account.key: account.id},
    );
  }

  String _localEntityKey(int localId) => 'local:$localId';
}
