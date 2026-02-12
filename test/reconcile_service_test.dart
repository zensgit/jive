import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/auto_draft_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/reconcile_service.dart';

void main() {
  late Isar isar;
  late Directory dir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pubCache =
        Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache';
    String? libPath;
    if (Platform.isMacOS) {
      libPath = '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    } else if (Platform.isLinux) {
      libPath = '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/linux/libisar.so';
    } else if (Platform.isWindows) {
      libPath = '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/windows/isar.dll';
    }
    if (libPath != null && File(libPath).existsSync()) {
      await Isar.initializeIsarCore(
        libraries: {Abi.current(): libPath},
      );
    } else {
      throw StateError('Isar core library not found for tests.');
    }
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('jive_reconcile_test_');
    isar = await Isar.open(
      [
        JiveTransactionSchema,
        JiveCategorySchema,
        JiveCategoryOverrideSchema,
        JiveAccountSchema,
        JiveAutoDraftSchema,
      ],
      directory: dir.path,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('reconcile computes running balance and summary', () async {
    final account = JiveAccount()
      ..key = 'acct_main'
      ..name = '现金'
      ..type = 'asset'
      ..currency = 'CNY'
      ..iconName = 'account_balance_wallet'
      ..order = 0
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..openingBalance = 1000
      ..updatedAt = DateTime(2024, 1, 1);

    final other = JiveAccount()
      ..key = 'acct_other'
      ..name = '银行卡'
      ..type = 'asset'
      ..currency = 'CNY'
      ..iconName = 'account_balance_wallet'
      ..order = 1
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..openingBalance = 0
      ..updatedAt = DateTime(2024, 1, 1);

    await isar.writeTxn(() async {
      await isar.jiveAccounts.putAll([account, other]);
    });

    final beforeRange = JiveTransaction()
      ..amount = 20
      ..source = 'Seed'
      ..type = 'expense'
      ..accountId = account.id
      ..timestamp = DateTime(2024, 1, 9, 10);

    final expense = JiveTransaction()
      ..amount = 100
      ..source = 'Seed'
      ..type = 'expense'
      ..accountId = account.id
      ..timestamp = DateTime(2024, 1, 10, 9);

    final income = JiveTransaction()
      ..amount = 50
      ..source = 'Seed'
      ..type = 'income'
      ..accountId = account.id
      ..timestamp = DateTime(2024, 1, 10, 12);

    final transferOut = JiveTransaction()
      ..amount = 200
      ..source = 'Seed'
      ..type = 'transfer'
      ..accountId = account.id
      ..toAccountId = other.id
      ..timestamp = DateTime(2024, 1, 10, 15);

    final transferIn = JiveTransaction()
      ..amount = 30
      ..source = 'Seed'
      ..type = 'transfer'
      ..accountId = other.id
      ..toAccountId = account.id
      ..timestamp = DateTime(2024, 1, 10, 17);

    final afterRange = JiveTransaction()
      ..amount = 10
      ..source = 'Seed'
      ..type = 'income'
      ..accountId = account.id
      ..timestamp = DateTime(2024, 1, 11, 9);

    await isar.writeTxn(() async {
      await isar.jiveTransactions.putAll([
        beforeRange,
        expense,
        income,
        transferOut,
        transferIn,
        afterRange,
      ]);
    });

    final result = await ReconcileService(isar).reconcileAccount(
      accountId: account.id,
      start: DateTime(2024, 1, 10),
      end: DateTime(2024, 1, 10, 23, 59, 59),
    );

    expect(result.summary.startBalance, 980);
    expect(result.summary.endBalance, 760);
    expect(result.summary.income, 50);
    expect(result.summary.expense, 100);
    expect(result.summary.transferIn, 30);
    expect(result.summary.transferOut, 200);
    expect(result.summary.netChange, -220);
    expect(result.entries.length, 4);
    expect(result.balanceSeries.length, 5);
    expect(result.balanceSeries.last, 760);
  });
}
