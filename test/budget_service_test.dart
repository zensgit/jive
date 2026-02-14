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
    'budget subcategory filter counts matching expense transactions by subCategoryKey',
    () async {
      await budgetService.createBudget(
        name: '咖啡预算',
        amount: 500,
        currency: 'CNY',
        categoryKey: 'coffee',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 31, 23, 59, 59, 999),
        period: 'monthly',
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().putAll([
          JiveTransaction()
            ..amount = 30
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 5, 5, 10)
            ..type = 'expense'
            ..categoryKey = 'food'
            ..subCategoryKey = 'coffee',
          JiveTransaction()
            ..amount = 80
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 5, 6, 10)
            ..type = 'expense'
            ..categoryKey = 'food'
            ..subCategoryKey = 'lunch',
        ]);
      });

      final summaries = await budgetService.getAllBudgetSummaries();

      expect(summaries.length, 1);
      expect(summaries.first.usedAmount, 30);
      expect(summaries.first.remainingAmount, 470);
    },
  );

  test(
    'calculateBudgetUsage returns inclusive daysRemaining when endDate is today',
    () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final budget = JiveBudget()
        ..name = '日预算'
        ..amount = 100
        ..currency = 'CNY'
        ..categoryKey = null
        ..startDate = start
        ..endDate = end
        ..period = 'daily'
        ..alertEnabled = false
        ..createdAt = now
        ..updatedAt = now;

      final summary = await budgetService.calculateBudgetUsage(budget);
      expect(summary.daysRemaining, 1);
    },
  );

  test('overall budget ignores transactions in excluded categories', () async {
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
  });

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

  test(
    'evaluateBudgetImpactsForTransaction returns warning when an expense crosses alert threshold',
    () async {
      await budgetService.createBudget(
        name: '月度预算',
        amount: 100,
        currency: 'CNY',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 31, 23, 59, 59, 999),
        period: 'monthly',
        alertEnabled: true,
        alertThreshold: 80,
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().put(
          JiveTransaction()
            ..amount = 70
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 5, 5, 10)
            ..type = 'expense',
        );
      });

      final newTx = JiveTransaction()
        ..amount = 15
        ..source = 'Preview'
        ..timestamp = DateTime(2024, 5, 6, 10)
        ..type = 'expense';

      final impacts = await budgetService.evaluateBudgetImpactsForTransaction(
        newTransaction: newTx,
      );

      expect(impacts.length, 1);
      expect(impacts.first.currentStatus, BudgetStatus.normal);
      expect(impacts.first.projectedStatus, BudgetStatus.warning);
    },
  );

  test(
    'evaluateBudgetImpactsForTransaction does not return when budget stays warning',
    () async {
      await budgetService.createBudget(
        name: '月度预算',
        amount: 100,
        currency: 'CNY',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 31, 23, 59, 59, 999),
        period: 'monthly',
        alertEnabled: true,
        alertThreshold: 80,
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().put(
          JiveTransaction()
            ..amount = 85
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 5, 5, 10)
            ..type = 'expense',
        );
      });

      final newTx = JiveTransaction()
        ..amount = 5
        ..source = 'Preview'
        ..timestamp = DateTime(2024, 5, 6, 10)
        ..type = 'expense';

      final impacts = await budgetService.evaluateBudgetImpactsForTransaction(
        newTransaction: newTx,
      );

      expect(impacts, isEmpty);
    },
  );

  test(
    'evaluateBudgetImpactsForTransaction returns exceeded when warning budget crosses amount',
    () async {
      await budgetService.createBudget(
        name: '月度预算',
        amount: 100,
        currency: 'CNY',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 31, 23, 59, 59, 999),
        period: 'monthly',
        alertEnabled: true,
        alertThreshold: 80,
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().put(
          JiveTransaction()
            ..amount = 85
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 5, 5, 10)
            ..type = 'expense',
        );
      });

      final newTx = JiveTransaction()
        ..amount = 20
        ..source = 'Preview'
        ..timestamp = DateTime(2024, 5, 6, 10)
        ..type = 'expense';

      final impacts = await budgetService.evaluateBudgetImpactsForTransaction(
        newTransaction: newTx,
      );

      expect(impacts.length, 1);
      expect(impacts.first.currentStatus, BudgetStatus.warning);
      expect(impacts.first.projectedStatus, BudgetStatus.exceeded);
    },
  );

  test(
    'evaluateBudgetImpactsForTransaction ignores expenses in excluded categories for total budgets',
    () async {
      await budgetService.createBudget(
        name: '总预算',
        amount: 100,
        currency: 'CNY',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 30, 23, 59, 59, 999),
        period: 'monthly',
        alertEnabled: true,
        alertThreshold: 80,
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveCategory>().put(
          JiveCategory()
            ..key = 'coffee'
            ..name = '咖啡'
            ..iconName = 'coffee'
            ..order = 0
            ..isSystem = false
            ..isHidden = false
            ..isIncome = false
            ..excludeFromBudget = true
            ..updatedAt = DateTime(2024, 6, 1),
        );
      });

      final newTx = JiveTransaction()
        ..amount = 90
        ..source = 'Preview'
        ..timestamp = DateTime(2024, 6, 6, 10)
        ..type = 'expense'
        ..categoryKey = 'coffee';

      final impacts = await budgetService.evaluateBudgetImpactsForTransaction(
        newTransaction: newTx,
      );

      expect(impacts, isEmpty);
    },
  );

  test(
    'getBudgetDailySpendingTrend returns daily sums (including zeros) for recent days',
    () async {
      final budget = await budgetService.createBudget(
        name: '月度预算',
        amount: 1000,
        currency: 'CNY',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 31, 23, 59, 59, 999),
        period: 'monthly',
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().putAll([
          JiveTransaction()
            ..amount = 10
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 5, 5, 9)
            ..type = 'expense',
          JiveTransaction()
            ..amount = 20
            ..source = 'Seed'
            ..timestamp = DateTime(2024, 5, 6, 9)
            ..type = 'expense',
        ]);
      });

      final trend = await budgetService.getBudgetDailySpendingTrend(
        budget,
        days: 3,
        referenceDate: DateTime(2024, 5, 6, 12),
      );

      expect(trend.length, 3);
      expect(trend[0].day, DateTime(2024, 5, 4));
      expect(trend[0].amount, 0);
      expect(trend[1].day, DateTime(2024, 5, 5));
      expect(trend[1].amount, 10);
      expect(trend[2].day, DateTime(2024, 5, 6));
      expect(trend[2].amount, 20);
    },
  );

  test('getPeriodDateRange returns monthly start and end boundaries', () {
    final (start, end) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: DateTime(2025, 2, 15, 14, 30),
    );

    expect(start, DateTime(2025, 2, 1));
    expect(end, DateTime(2025, 2, 28, 23, 59, 59, 999));
  });
}
