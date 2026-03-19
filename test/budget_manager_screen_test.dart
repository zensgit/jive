import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/budget_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/service/budget_service.dart';
import 'package:jive/feature/budget/budget_manager_screen.dart';
import 'package:jive/feature/category/category_transactions_screen.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;
  Route<dynamic>? lastPushedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    lastPushedRoute = route;
    super.didPush(route, previousRoute);
  }
}

BudgetSummary _buildSummary() {
  final now = DateTime(2026, 2, 14);
  final budget = JiveBudget()
    ..name = '总预算'
    ..amount = 1200
    ..currency = 'CNY'
    ..startDate = DateTime(2026, 2, 1)
    ..endDate = DateTime(2026, 2, 28, 23, 59, 59, 999)
    ..period = BudgetPeriod.monthly.value
    ..isActive = true
    ..createdAt = now
    ..updatedAt = now;

  return BudgetSummary(
    budget: budget,
    effectiveAmount: 1200,
    usedAmount: 300,
    remainingAmount: 900,
    usedPercent: 25,
    status: BudgetStatus.normal,
    daysRemaining: 14,
  );
}

JiveCategory _buildCategory({
  required String key,
  required String name,
  String? parentKey,
}) {
  return JiveCategory()
    ..key = key
    ..name = name
    ..iconName = 'restaurant'
    ..parentKey = parentKey
    ..order = 1
    ..isSystem = false
    ..isHidden = false
    ..isIncome = false
    ..updatedAt = DateTime(2026, 2, 14);
}

BudgetManagerDebugData _buildDebugData({
  required List<BudgetCategoryContribution> topCategories,
  required List<BudgetSpendingAnomalyDay> anomalyDays,
}) {
  return BudgetManagerDebugData(
    totalSummary: _buildSummary(),
    month: DateTime(2026, 2, 1),
    currency: 'CNY',
    totalTopCategories: topCategories,
    totalAnomalyDays: anomalyDays,
    categoryByKey: {
      'food': _buildCategory(key: 'food', name: '餐饮'),
      'sub_food': _buildCategory(
        key: 'sub_food',
        name: '早餐',
        parentKey: 'food',
      ),
    },
  );
}

void main() {
  testWidgets('top category row opens transaction screen', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _RecordingNavigatorObserver();
    final debugData = _buildDebugData(
      topCategories: const [
        BudgetCategoryContribution(
          categoryKey: 'food',
          amount: 120,
          ratioPercent: 40,
        ),
      ],
      anomalyDays: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        home: BudgetManagerScreen(debugData: debugData),
      ),
    );

    final baselinePushes = observer.pushCount;
    final topCategoryRow = find.byKey(const Key('budget_top_category_food'));
    expect(topCategoryRow, findsOneWidget);

    await tester.tap(topCategoryRow);
    await tester.pump();

    expect(observer.pushCount, baselinePushes + 1);
    final route = observer.lastPushedRoute;
    expect(route, isA<MaterialPageRoute<dynamic>>());
    final built = (route as MaterialPageRoute<dynamic>).builder(
      navigatorKey.currentContext!,
    );
    expect(built, isA<CategoryTransactionsScreen>());
    final screen = built as CategoryTransactionsScreen;
    expect(screen.title, contains('账单 ·'));

    Navigator.of(navigatorKey.currentContext!).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('anomaly row opens transaction screen with 异常日 title', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _RecordingNavigatorObserver();
    final anomalyDay = DateTime(2026, 2, 14);
    final dayKey =
        '${anomalyDay.year.toString().padLeft(4, '0')}${anomalyDay.month.toString().padLeft(2, '0')}${anomalyDay.day.toString().padLeft(2, '0')}';
    final debugData = _buildDebugData(
      topCategories: const [
        BudgetCategoryContribution(
          categoryKey: 'food',
          amount: 180,
          ratioPercent: 60,
        ),
      ],
      anomalyDays: [
        BudgetSpendingAnomalyDay(
          day: anomalyDay,
          amount: 220,
          thresholdAmount: 100,
          averageAmount: 60,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        home: BudgetManagerScreen(debugData: debugData),
      ),
    );

    final baselinePushes = observer.pushCount;
    final anomalyRow = find.byKey(Key('budget_anomaly_day_$dayKey'));
    expect(anomalyRow, findsOneWidget);

    await tester.tap(anomalyRow);
    await tester.pump();

    expect(observer.pushCount, baselinePushes + 1);
    final route = observer.lastPushedRoute;
    expect(route, isA<MaterialPageRoute<dynamic>>());
    final built = (route as MaterialPageRoute<dynamic>).builder(
      navigatorKey.currentContext!,
    );
    expect(built, isA<CategoryTransactionsScreen>());
    final screen = built as CategoryTransactionsScreen;
    expect(screen.title, contains('异常日'));

    Navigator.of(navigatorKey.currentContext!).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('uncategorized row shows snackbar', (tester) async {
    final observer = _RecordingNavigatorObserver();
    final debugData = _buildDebugData(
      topCategories: const [
        BudgetCategoryContribution(
          categoryKey: '__uncategorized__',
          amount: 90,
          ratioPercent: 30,
        ),
      ],
      anomalyDays: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: BudgetManagerScreen(debugData: debugData),
      ),
    );

    final baselinePushes = observer.pushCount;
    const uncategorizedRow = Key('budget_top_category___uncategorized__');
    expect(find.byKey(uncategorizedRow), findsOneWidget);

    await tester.tap(find.byKey(uncategorizedRow));
    await tester.pump();

    expect(find.text('未分类暂不支持快捷钻取'), findsOneWidget);
    expect(observer.pushCount, baselinePushes);
  });
}
