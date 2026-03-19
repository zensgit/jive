import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jive/core/database/budget_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/service/budget_service.dart';
import 'package:jive/feature/budget/budget_manager_screen.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Budget insight drilldown opens filtered transaction pages', (
    tester,
  ) async {
    final anomalyDay = DateTime(2026, 2, 14);
    const topCategoryKey = 'it_budget_drilldown_top';
    const topKey = Key('budget_top_category_it_budget_drilldown_top');
    const anomalyKey = Key('budget_anomaly_day_20260214');

    final debugData = BudgetManagerDebugData(
      totalSummary: _buildSummary(),
      month: DateTime(2026, 2, 1),
      currency: 'CNY',
      totalTopCategories: const [
        BudgetCategoryContribution(
          categoryKey: topCategoryKey,
          amount: 180,
          ratioPercent: 60,
        ),
      ],
      totalAnomalyDays: [
        BudgetSpendingAnomalyDay(
          day: anomalyDay,
          amount: 220,
          thresholdAmount: 100,
          averageAmount: 60,
        ),
      ],
      categoryByKey: {
        topCategoryKey: _buildCategory(key: topCategoryKey, name: '测试分类'),
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: BudgetManagerScreen(debugData: debugData)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(topKey), findsOneWidget);
    await tester.tap(find.byKey(topKey));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('账单 ·'), findsOneWidget);

    final filterButton = find.byKey(
      const Key('transaction_filter_open_button'),
    );
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    expect(find.text('查找账单（按条件）'), findsOneWidget);
    final dateRangeTile = find.byKey(
      const Key('transaction_filter_date_range_tile'),
    );
    expect(dateRangeTile, findsOneWidget);
    expect(
      find.descendant(of: dateRangeTile, matching: find.text('不限')),
      findsNothing,
    );

    final closeSheet = find.byTooltip('关闭');
    if (closeSheet.evaluate().isNotEmpty) {
      await tester.tap(closeSheet.first);
      await tester.pumpAndSettle();
    }

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('预算管理'), findsOneWidget);
    expect(find.byKey(anomalyKey), findsOneWidget);

    await tester.tap(find.byKey(anomalyKey));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('账单 · 异常日 2/14'), findsOneWidget);
  });
}
