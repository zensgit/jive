import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/widget_data_service.dart';

void main() {
  group('WidgetSummary', () {
    test('can be created with typical values', () {
      const summary = WidgetSummary(
        todayExpense: 150.0,
        todayIncome: 8000.0,
        todayCount: 3,
        monthExpense: 4500.0,
        monthBudgetRemaining: 1500.0,
      );

      expect(summary.todayExpense, 150.0);
      expect(summary.todayIncome, 8000.0);
      expect(summary.todayCount, 3);
      expect(summary.monthExpense, 4500.0);
      expect(summary.monthBudgetRemaining, 1500.0);
    });

    test('monthBudgetRemaining defaults to null', () {
      const summary = WidgetSummary(
        todayExpense: 100.0,
        todayIncome: 0.0,
        todayCount: 1,
        monthExpense: 100.0,
      );

      expect(summary.monthBudgetRemaining, isNull);
    });

    test('handles zero amounts', () {
      const summary = WidgetSummary(
        todayExpense: 0.0,
        todayIncome: 0.0,
        todayCount: 0,
        monthExpense: 0.0,
        monthBudgetRemaining: 0.0,
      );

      expect(summary.todayExpense, 0.0);
      expect(summary.todayIncome, 0.0);
      expect(summary.todayCount, 0);
      expect(summary.monthExpense, 0.0);
      expect(summary.monthBudgetRemaining, 0.0);
    });

    test('handles negative budget remaining (over budget)', () {
      const summary = WidgetSummary(
        todayExpense: 200.0,
        todayIncome: 0.0,
        todayCount: 5,
        monthExpense: 6000.0,
        monthBudgetRemaining: -1000.0,
      );

      expect(summary.monthBudgetRemaining, -1000.0);
    });

    test('handles large amounts', () {
      const summary = WidgetSummary(
        todayExpense: 999999.99,
        todayIncome: 1000000.0,
        todayCount: 100,
        monthExpense: 50000.0,
        monthBudgetRemaining: 950000.0,
      );

      expect(summary.todayExpense, 999999.99);
      expect(summary.todayIncome, 1000000.0);
      expect(summary.todayCount, 100);
      expect(summary.monthExpense, 50000.0);
      expect(summary.monthBudgetRemaining, 950000.0);
    });

    test('handles fractional amounts', () {
      const summary = WidgetSummary(
        todayExpense: 0.01,
        todayIncome: 0.99,
        todayCount: 2,
        monthExpense: 123.45,
        monthBudgetRemaining: 876.55,
      );

      expect(summary.todayExpense, 0.01);
      expect(summary.todayIncome, 0.99);
      expect(summary.monthExpense, 123.45);
      expect(summary.monthBudgetRemaining, 876.55);
    });
  });
}
