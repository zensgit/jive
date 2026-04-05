import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/book_model.dart';
import 'package:jive/core/database/budget_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/book_service.dart';
import 'package:jive/core/sync/sync_delete_marker_service.dart';
import 'package:jive/core/sync/sync_tombstone_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late SyncDeleteMarkerService service;
  late JiveBook defaultBook;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pubCache =
        Platform.environment['PUB_CACHE'] ??
        '${Platform.environment['HOME']}/.pub-cache';
    String? libPath;
    if (Platform.isMacOS) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    } else if (Platform.isLinux) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/linux/libisar.so';
    } else if (Platform.isWindows) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/windows/isar.dll';
    }
    if (libPath != null && File(libPath).existsSync()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): libPath});
    } else {
      throw StateError('Isar core library not found for tests.');
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SyncTombstoneStore.clear();

    dir = await Directory.systemTemp.createTemp('jive_sync_delete_marker_');
    isar = await Isar.open([
      JiveBookSchema,
      JiveAccountSchema,
      JiveTransactionSchema,
      JiveBudgetSchema,
    ], directory: dir.path);

    service = SyncDeleteMarkerService(isar);
    final bookService = BookService(isar);
    await bookService.initDefaultBook();
    defaultBook = (await bookService.getDefaultBook())!;
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test(
    'markTransactionDeleted stores account and book keys when cursor exists',
    () async {
      final cursor = DateTime(2026, 4, 5, 10, 0);
      SharedPreferences.setMockInitialValues({
        'sync_cursor_transactions': cursor.toIso8601String(),
      });
      await SyncTombstoneStore.clear();

      final account = JiveAccount()
        ..key = 'acct_cash'
        ..name = '现金'
        ..type = 'asset'
        ..currency = 'CNY'
        ..iconName = 'account_balance_wallet'
        ..order = 0
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = cursor.subtract(const Duration(minutes: 5))
        ..bookId = defaultBook.id;

      final tx = JiveTransaction()
        ..amount = 23.5
        ..source = '微信'
        ..timestamp = DateTime(2026, 4, 5, 8, 0)
        ..type = 'expense'
        ..note = '早餐'
        ..categoryKey = 'food'
        ..updatedAt = cursor.subtract(const Duration(minutes: 2))
        ..bookId = defaultBook.id;

      await isar.writeTxn(() async {
        await isar.jiveAccounts.put(account);
        tx.accountId = account.id;
        await isar.jiveTransactions.put(tx);
      });

      await service.markTransactionDeleted(tx);

      final entries = await SyncTombstoneStore.listForTable('transactions');
      expect(entries, hasLength(1));
      expect(entries.single.entityKey, 'local:${tx.id}');
      expect(entries.single.payload['local_id'], tx.id);
      expect(entries.single.payload['account_key'], 'acct_cash');
      expect(entries.single.payload['book_key'], BookService.defaultBookKey);
      expect(entries.single.payload['amount'], 23.5);
      expect(entries.single.payload['deleted_at'], isA<String>());
    },
  );

  test('markBudgetDeleted stores budget tombstone with book key', () async {
    final cursor = DateTime(2026, 4, 5, 10, 0);
    SharedPreferences.setMockInitialValues({
      'sync_cursor_budgets': cursor.toIso8601String(),
    });
    await SyncTombstoneStore.clear();

    final budget = JiveBudget()
      ..name = '餐饮预算'
      ..amount = 800
      ..currency = 'CNY'
      ..period = 'monthly'
      ..startDate = DateTime(2026, 4, 1)
      ..endDate = DateTime(2026, 4, 30, 23, 59, 59)
      ..bookId = defaultBook.id
      ..updatedAt = cursor.subtract(const Duration(minutes: 3));

    await isar.writeTxn(() async {
      await isar.jiveBudgets.put(budget);
    });

    await service.markBudgetDeleted(budget);

    final entries = await SyncTombstoneStore.listForTable('budgets');
    expect(entries, hasLength(1));
    expect(entries.single.payload['local_id'], budget.id);
    expect(entries.single.payload['name'], '餐饮预算');
    expect(entries.single.payload['book_key'], BookService.defaultBookKey);
    expect(entries.single.payload['deleted_at'], isA<String>());
  });

  test('does not create tombstone when entity changed after cursor', () async {
    final cursor = DateTime(2026, 4, 5, 10, 0);
    SharedPreferences.setMockInitialValues({
      'sync_cursor_transactions': cursor.toIso8601String(),
    });
    await SyncTombstoneStore.clear();

    final tx = JiveTransaction()
      ..amount = 50
      ..source = '支付宝'
      ..timestamp = DateTime(2026, 4, 5, 11, 0)
      ..type = 'expense'
      ..updatedAt = cursor.add(const Duration(minutes: 1))
      ..bookId = defaultBook.id;

    await isar.writeTxn(() async {
      await isar.jiveTransactions.put(tx);
    });

    await service.markTransactionDeleted(tx);

    final entries = await SyncTombstoneStore.listForTable('transactions');
    expect(entries, isEmpty);
  });
}
