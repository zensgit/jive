import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/budget_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/currency_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/budget_service.dart';
import 'package:jive/core/service/currency_service.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late BudgetService budgetService;

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
    dir = await Directory.systemTemp.createTemp('jive_budget_test_');
    isar = await Isar.open([
      JiveBudgetSchema,
      JiveBudgetUsageSchema,
      JiveTransactionSchema,
      JiveCategorySchema,
      JiveCategoryOverrideSchema,
      JiveCurrencySchema,
      JiveExchangeRateSchema,
      JiveCurrencyPreferenceSchema,
      JiveExchangeRateHistorySchema,
    ], directory: dir.path);
    final currencyService = CurrencyService(isar);
    budgetService = BudgetService(isar, currencyService);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test(
    'getAllBudgetSummaries returns usage summary for active budget',
    () async {
      await budgetService.createBudget(
        name: '月度预算',
        amount: 1000,
        currency: 'CNY',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31, 23, 59, 59),
        period: 'monthly',
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().putAll([
          JiveTransaction()
            ..amount = 200
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 1, 10, 9)
            ..type = 'expense',
          JiveTransaction()
            ..amount = 100
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 1, 15, 9)
            ..type = 'expense'
            ..excludeFromBudget = true,
          JiveTransaction()
            ..amount = 50
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 1, 20, 9)
            ..type = 'expense',
          JiveTransaction()
            ..amount = 999
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 1, 25, 9)
            ..type = 'income',
        ]);
      });

      final summaries = await budgetService.getAllBudgetSummaries();

      expect(summaries.length, 1);
      expect(summaries.first.usedAmount, 250);
      expect(summaries.first.remainingAmount, 750);
      expect(summaries.first.status, BudgetStatus.normal);
    },
  );

  test(
    'budget category filter only counts matching expense transactions',
    () async {
      await budgetService.createBudget(
        name: '餐饮预算',
        amount: 500,
        currency: 'CNY',
        categoryKey: 'food',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 29, 23, 59, 59),
        period: 'monthly',
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().putAll([
          JiveTransaction()
            ..amount = 120
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 2, 5, 10)
            ..type = 'expense'
            ..categoryKey = 'food',
          JiveTransaction()
            ..amount = 60
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 2, 5, 12)
            ..type = 'expense'
            ..categoryKey = 'food'
            ..excludeFromBudget = true,
          JiveTransaction()
            ..amount = 80
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 2, 6, 10)
            ..type = 'expense'
            ..categoryKey = 'transport',
        ]);
      });

      final summaries = await budgetService.getAllBudgetSummaries();

      expect(summaries.length, 1);
      expect(summaries.first.usedAmount, 120);
      expect(summaries.first.remainingAmount, 380);
    },
  );

  test(
    'overall budget ignores transactions in excluded categories',
    () async {
      await budgetService.createBudget(
        name: '月度预算',
        amount: 1000,
        currency: 'CNY',
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 31, 23, 59, 59),
        period: 'monthly',
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveCategory>().putAll([
          JiveCategory()
            ..key = 'food'
            ..name = '餐饮'
            ..iconName = 'food'
            ..order = 0
            ..isSystem = false
            ..isHidden = false
            ..isIncome = false
            ..excludeFromBudget = true
            ..updatedAt = DateTime(2024, 3, 1),
          JiveCategory()
            ..key = 'transport'
            ..name = '交通'
            ..iconName = 'transport'
            ..order = 1
            ..isSystem = false
            ..isHidden = false
            ..isIncome = false
            ..excludeFromBudget = false
            ..updatedAt = DateTime(2024, 3, 1),
        ]);

        await isar.collection<JiveTransaction>().putAll([
          JiveTransaction()
            ..amount = 200
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 3, 10, 9)
            ..type = 'expense'
            ..categoryKey = 'food',
          JiveTransaction()
            ..amount = 50
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 3, 11, 9)
            ..type = 'expense'
            ..categoryKey = 'transport',
        ]);
      });

      final summaries = await budgetService.getAllBudgetSummaries();

      expect(summaries.length, 1);
      expect(summaries.first.usedAmount, 50);
      expect(summaries.first.remainingAmount, 950);
    },
  );

  test(
    'overall budget ignores transactions in excluded subcategories only',
    () async {
      await budgetService.createBudget(
        name: '月度预算',
        amount: 1000,
        currency: 'CNY',
        startDate: DateTime(2024, 4, 1),
        endDate: DateTime(2024, 4, 30, 23, 59, 59),
        period: 'monthly',
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveCategory>().putAll([
          JiveCategory()
            ..key = 'food'
            ..name = '餐饮'
            ..iconName = 'food'
            ..order = 0
            ..isSystem = false
            ..isHidden = false
            ..isIncome = false
            ..excludeFromBudget = false
            ..updatedAt = DateTime(2024, 4, 1),
          JiveCategory()
            ..key = 'coffee'
            ..name = '咖啡'
            ..iconName = 'coffee'
            ..parentKey = 'food'
            ..order = 0
            ..isSystem = false
            ..isHidden = false
            ..isIncome = false
            ..excludeFromBudget = true
            ..updatedAt = DateTime(2024, 4, 1),
          JiveCategory()
            ..key = 'lunch'
            ..name = '午餐'
            ..iconName = 'lunch'
            ..parentKey = 'food'
            ..order = 1
            ..isSystem = false
            ..isHidden = false
            ..isIncome = false
            ..excludeFromBudget = false
            ..updatedAt = DateTime(2024, 4, 1),
        ]);

        await isar.collection<JiveTransaction>().putAll([
          JiveTransaction()
            ..amount = 100
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 4, 10, 9)
            ..type = 'expense'
            ..categoryKey = 'food'
            ..subCategoryKey = 'coffee',
          JiveTransaction()
            ..amount = 50
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 4, 11, 9)
            ..type = 'expense'
            ..categoryKey = 'food'
            ..subCategoryKey = 'lunch',
        ]);
      });

      final summaries = await budgetService.getAllBudgetSummaries();

      expect(summaries.length, 1);
      expect(summaries.first.usedAmount, 50);
      expect(summaries.first.remainingAmount, 950);
    },
  );

  test('getPeriodDateRange returns monthly start and end boundaries', () {
    final (start, end) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: DateTime(2025, 2, 15, 14, 30),
    );

    expect(start, DateTime(2025, 2, 1));
    expect(end, DateTime(2025, 2, 28, 23, 59, 59));
  });
}
