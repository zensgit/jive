import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/book_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/database_service.dart';
import 'package:jive/feature/transactions/transaction_entry_params.dart';
import 'package:jive/feature/transactions/transaction_form_screen.dart';

import 'test_helpers.dart';

void main() {
  late _TransactionFormHarness harness;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupGoogleFontsForTests();
    await _initializeIsarCore();
  });

  setUp(() async {
    harness = await _TransactionFormHarness.open();
    await harness.seed();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('shared book context asks before form transaction save', (
    tester,
  ) async {
    var saveCount = 0;
    JiveTransaction? savedTransaction;

    await tester.pumpWidget(
      _wrapForm(
        TransactionEntryParams(
          source: TransactionEntrySource.shareReceive,
          prefillAmount: 12,
          prefillType: 'expense',
          prefillCategoryKey: harness.category.key,
          prefillAccountId: harness.account.id,
          prefillBookId: harness.sharedBook.id,
        ),
        harness,
        onSave: (tx) async {
          saveCount += 1;
          savedTransaction = tx;
        },
      ),
    );

    await _pumpUntilFound(tester, find.text('确认入账'));

    expect(find.text('将保存到共享场景「家庭共享」'), findsOneWidget);

    await tester.tap(find.text('确认入账'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(TransactionFormScreen.sharedSceneSaveDialogKey),
      findsOneWidget,
    );
    expect(find.text('保存到共享场景？'), findsOneWidget);
    expect(find.textContaining('其他成员也能看到'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(saveCount, 0);
    expect(find.text('确认入账'), findsOneWidget);

    await tester.tap(find.text('确认入账'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('继续保存'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(saveCount, 1);
    expect(savedTransaction?.bookId, harness.sharedBook.id);
    expect(savedTransaction?.amount, 12);
  });

  testWidgets(
    'local book context saves form transaction without shared prompt',
    (tester) async {
      var saveCount = 0;
      JiveTransaction? savedTransaction;

      await tester.pumpWidget(
        _wrapForm(
          TransactionEntryParams(
            source: TransactionEntrySource.deepLink,
            prefillAmount: 8,
            prefillType: 'expense',
            prefillCategoryKey: harness.category.key,
            prefillAccountId: harness.account.id,
            prefillBookId: harness.localBook.id,
          ),
          harness,
          onSave: (tx) async {
            saveCount += 1;
            savedTransaction = tx;
          },
        ),
      );

      await _pumpUntilFound(tester, find.text('确认入账'));

      expect(find.text('将保存到账本「日常」'), findsOneWidget);

      await tester.tap(find.text('确认入账'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byKey(TransactionFormScreen.sharedSceneSaveDialogKey),
        findsNothing,
      );
      expect(saveCount, 1);
      expect(savedTransaction?.bookId, harness.localBook.id);
      expect(savedTransaction?.amount, 8);
    },
  );
}

Widget _wrapForm(
  TransactionEntryParams params,
  _TransactionFormHarness harness, {
  TransactionFormSaver? onSave,
}) {
  return MaterialApp(
    home: TransactionFormScreen(
      isar: harness.isar,
      params: params,
      transactionSaver: onSave,
    ),
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> _initializeIsarCore() async {
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
    return;
  }
  throw StateError('Isar core library not found for tests.');
}

class _TransactionFormHarness {
  final Directory dir;
  final Isar isar;
  late JiveAccount account;
  late JiveCategory category;
  late JiveBook localBook;
  late JiveBook sharedBook;

  _TransactionFormHarness({required this.dir, required this.isar});

  static Future<_TransactionFormHarness> open() async {
    final dir = await Directory.systemTemp.createTemp(
      'jive_transaction_form_test_',
    );
    final isar = await Isar.open(
      DatabaseService.schemas,
      name: 'transaction_form_${DateTime.now().microsecondsSinceEpoch}',
      directory: dir.path,
    ).timeout(const Duration(seconds: 5));
    return _TransactionFormHarness(dir: dir, isar: isar);
  }

  Future<void> seed() async {
    final now = DateTime(2026, 5, 7);
    account = JiveAccount()
      ..key = 'cash'
      ..name = '现金'
      ..type = 'asset'
      ..subType = 'cash'
      ..groupName = '现金'
      ..currency = 'CNY'
      ..iconName = 'account_balance_wallet'
      ..order = 0
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..openingBalance = 0
      ..updatedAt = now;
    category = JiveCategory()
      ..key = 'food'
      ..name = '餐饮'
      ..iconName = 'restaurant'
      ..order = 0
      ..isSystem = false
      ..isHidden = false
      ..isIncome = false
      ..updatedAt = now;
    localBook = JiveBook()
      ..key = 'book_daily'
      ..name = '日常'
      ..currency = 'CNY'
      ..order = 0
      ..isDefault = true
      ..isArchived = false
      ..isShared = false
      ..memberCount = 1
      ..createdAt = now
      ..updatedAt = now;
    sharedBook = JiveBook()
      ..key = 'book_family'
      ..name = '家庭共享'
      ..currency = 'CNY'
      ..order = 1
      ..isDefault = false
      ..isArchived = false
      ..isShared = true
      ..sharedLedgerKey = 'ledger_family'
      ..memberCount = 2
      ..createdAt = now
      ..updatedAt = now;

    await isar.writeTxn(() async {
      account.id = await isar.jiveAccounts.put(account);
      await isar.jiveCategorys.put(category);
      localBook.id = await isar.jiveBooks.put(localBook);
      sharedBook.id = await isar.jiveBooks.put(sharedBook);
    });
  }

  Future<void> dispose() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}
