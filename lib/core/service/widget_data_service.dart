import 'package:isar/isar.dart';

import '../database/budget_model.dart';
import '../database/transaction_model.dart';
import 'database_service.dart';

/// Widget display data for the home screen widget.
class WidgetSummary {
  /// Total expense amount today.
  final double todayExpense;

  /// Total income amount today.
  final double todayIncome;

  /// Number of transactions today.
  final int todayCount;

  /// Total expense this calendar month.
  final double monthExpense;

  /// Remaining budget for the current period, or `null` when no active budget
  /// covers today.
  final double? monthBudgetRemaining;

  const WidgetSummary({
    required this.todayExpense,
    required this.todayIncome,
    required this.todayCount,
    required this.monthExpense,
    this.monthBudgetRemaining,
  });
}

/// Service that computes data for the Android home screen widget.
class WidgetDataService {
  final Isar _isar;

  WidgetDataService(this._isar);

  /// Create an instance using the shared [DatabaseService].
  static Future<WidgetDataService> create() async {
    final isar = await DatabaseService.getInstance();
    return WidgetDataService(isar);
  }

  /// Compute today's spending summary for the widget.
  Future<WidgetSummary> getTodaySummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month);

    // --- Today queries ---
    final todayTransactions = await _isar.jiveTransactions
        .filter()
        .timestampBetween(todayStart, todayEnd, includeUpper: false)
        .findAll();

    double todayExpense = 0;
    double todayIncome = 0;
    for (final tx in todayTransactions) {
      if (tx.type == 'expense') {
        todayExpense += tx.amount;
      } else if (tx.type == 'income') {
        todayIncome += tx.amount;
      }
    }

    // --- Month expense ---
    final monthTransactions = await _isar.jiveTransactions
        .filter()
        .timestampBetween(monthStart, todayEnd, includeUpper: false)
        .typeEqualTo('expense')
        .findAll();

    double monthExpense = 0;
    for (final tx in monthTransactions) {
      monthExpense += tx.amount;
    }

    // --- Active budget remaining ---
    double? budgetRemaining;
    final activeBudgets = await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .startDateLessThan(todayEnd)
        .endDateGreaterThan(todayStart)
        .findAll();

    if (activeBudgets.isNotEmpty) {
      // Pick the first overall budget (no category), or fall back to the first
      // active budget found.
      final budget = activeBudgets
              .where((b) => b.categoryKey == null)
              .firstOrNull ??
          activeBudgets.first;

      final effectiveAmount = budget.amount + budget.carryoverAmount;

      // Sum expenses within the budget period.
      final periodExpenses = await _isar.jiveTransactions
          .filter()
          .timestampBetween(budget.startDate, budget.endDate,
              includeUpper: false)
          .typeEqualTo('expense')
          .findAll();

      double periodUsed = 0;
      for (final tx in periodExpenses) {
        periodUsed += tx.amount;
      }

      budgetRemaining = effectiveAmount - periodUsed;
    }

    return WidgetSummary(
      todayExpense: todayExpense,
      todayIncome: todayIncome,
      todayCount: todayTransactions.length,
      monthExpense: monthExpense,
      monthBudgetRemaining: budgetRemaining,
    );
  }
}
