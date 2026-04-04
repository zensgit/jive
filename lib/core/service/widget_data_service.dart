import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/budget_model.dart';
import '../database/recurring_rule_model.dart';
import '../database/reimbursement_model.dart';
import '../database/savings_goal_model.dart';
import '../database/transaction_model.dart';
import 'database_service.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

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

/// Calendar widget: daily expense map for a month.
class CalendarWidgetData {
  /// Day-of-month (1..31) mapped to total expense that day.
  final Map<int, double> dailyExpense;
  final double totalMonthExpense;
  final double totalMonthIncome;

  const CalendarWidgetData({
    required this.dailyExpense,
    required this.totalMonthExpense,
    required this.totalMonthIncome,
  });
}

/// A single day's expense / income totals for the weekly widget.
class DayAmount {
  final DateTime date;
  final double expense;
  final double income;

  const DayAmount({
    required this.date,
    required this.expense,
    required this.income,
  });
}

/// Weekly widget: last 7 days breakdown.
class WeeklyWidgetData {
  final List<DayAmount> last7Days;
  final double weekTotal;

  const WeeklyWidgetData({
    required this.last7Days,
    required this.weekTotal,
  });
}

/// Dream / savings-goal widget.
class DreamWidgetData {
  final String name;
  final String emoji;
  final double progress;
  final double currentAmount;
  final double targetAmount;

  const DreamWidgetData({
    required this.name,
    required this.emoji,
    required this.progress,
    required this.currentAmount,
    required this.targetAmount,
  });
}

/// A single upcoming repayment entry.
class UpcomingRepayment {
  final String name;
  final double amount;
  final DateTime dueDate;

  const UpcomingRepayment({
    required this.name,
    required this.amount,
    required this.dueDate,
  });
}

/// Repayment widget: recurring rules due in the next 7 days.
class RepaymentWidgetData {
  final List<UpcomingRepayment> upcoming;
  final int count;

  const RepaymentWidgetData({
    required this.upcoming,
    required this.count,
  });
}

/// Quick-info widget: net worth, budget remaining, unread reimbursements.
class QuickInfoWidgetData {
  final double netWorth;
  final double? monthBudgetRemaining;
  final int unreadReimbursementCount;

  const QuickInfoWidgetData({
    required this.netWorth,
    this.monthBudgetRemaining,
    required this.unreadReimbursementCount,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Service that computes data for the Android home screen widget.
class WidgetDataService {
  final Isar _isar;

  WidgetDataService(this._isar);

  /// Create an instance using the shared [DatabaseService].
  static Future<WidgetDataService> create() async {
    final isar = await DatabaseService.getInstance();
    return WidgetDataService(isar);
  }

  // -----------------------------------------------------------------------
  // 1. Today summary (existing)
  // -----------------------------------------------------------------------

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

  // -----------------------------------------------------------------------
  // 2. Calendar widget
  // -----------------------------------------------------------------------

  /// Return daily expense/income totals for [month].
  Future<CalendarWidgetData> getCalendarWidgetData(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final transactions = await _isar.jiveTransactions
        .filter()
        .timestampBetween(start, end, includeUpper: false)
        .findAll();

    final Map<int, double> dailyExpense = {};
    double totalExpense = 0;
    double totalIncome = 0;

    for (final tx in transactions) {
      if (tx.type == 'expense') {
        final day = tx.timestamp.day;
        dailyExpense[day] = (dailyExpense[day] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      } else if (tx.type == 'income') {
        totalIncome += tx.amount;
      }
    }

    return CalendarWidgetData(
      dailyExpense: dailyExpense,
      totalMonthExpense: totalExpense,
      totalMonthIncome: totalIncome,
    );
  }

  // -----------------------------------------------------------------------
  // 3. Weekly widget
  // -----------------------------------------------------------------------

  /// Return expense/income breakdown for the last 7 days.
  Future<WeeklyWidgetData> getWeeklyWidgetData() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));
    final dayAfterToday = todayStart.add(const Duration(days: 1));

    final transactions = await _isar.jiveTransactions
        .filter()
        .timestampBetween(weekStart, dayAfterToday, includeUpper: false)
        .findAll();

    // Bucket by day offset (0 = weekStart, 6 = today).
    final expenseByDay = List<double>.filled(7, 0);
    final incomeByDay = List<double>.filled(7, 0);

    for (final tx in transactions) {
      final dayOffset = DateTime(
        tx.timestamp.year,
        tx.timestamp.month,
        tx.timestamp.day,
      )
          .difference(weekStart)
          .inDays;
      if (dayOffset < 0 || dayOffset > 6) continue;
      if (tx.type == 'expense') {
        expenseByDay[dayOffset] += tx.amount;
      } else if (tx.type == 'income') {
        incomeByDay[dayOffset] += tx.amount;
      }
    }

    double weekTotal = 0;
    final List<DayAmount> days = [];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      days.add(DayAmount(
        date: date,
        expense: expenseByDay[i],
        income: incomeByDay[i],
      ));
      weekTotal += expenseByDay[i];
    }

    return WeeklyWidgetData(last7Days: days, weekTotal: weekTotal);
  }

  // -----------------------------------------------------------------------
  // 4. Dream / savings-goal widget
  // -----------------------------------------------------------------------

  /// Return the best active savings goal, or `null` if none exists.
  Future<DreamWidgetData?> getDreamWidgetData() async {
    final goals = await _isar.jiveSavingsGoals
        .filter()
        .statusEqualTo('active')
        .findAll();

    if (goals.isEmpty) return null;

    // Pick the goal closest to completion (highest progress).
    JiveSavingsGoal best = goals.first;
    double bestProgress = best.targetAmount > 0
        ? best.currentAmount / best.targetAmount
        : 0.0;

    for (final g in goals.skip(1)) {
      final double p = g.targetAmount > 0 ? g.currentAmount / g.targetAmount : 0;
      if (p > bestProgress) {
        best = g;
        bestProgress = p;
      }
    }

    return DreamWidgetData(
      name: best.name,
      emoji: best.emoji ?? '\u{1F3AF}', // 🎯 default
      progress: bestProgress.clamp(0.0, 1.0).toDouble(),
      currentAmount: best.currentAmount,
      targetAmount: best.targetAmount,
    );
  }

  // -----------------------------------------------------------------------
  // 5. Repayment widget
  // -----------------------------------------------------------------------

  /// Return recurring rules whose next run is within the next 7 days.
  Future<RepaymentWidgetData> getRepaymentWidgetData() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final horizon = todayStart.add(const Duration(days: 7));

    final rules = await _isar.jiveRecurringRules
        .filter()
        .isActiveEqualTo(true)
        .nextRunAtBetween(todayStart, horizon)
        .findAll();

    final upcoming = rules.map((r) {
      return UpcomingRepayment(
        name: r.name,
        amount: r.amount,
        dueDate: r.nextRunAt,
      );
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return RepaymentWidgetData(upcoming: upcoming, count: upcoming.length);
  }

  // -----------------------------------------------------------------------
  // 6. Quick-info widget
  // -----------------------------------------------------------------------

  /// Return net worth, budget remaining, and unread reimbursement count.
  Future<QuickInfoWidgetData> getQuickInfoWidgetData() async {
    // --- Net worth: sum of account balances ---
    final accounts = await _isar.jiveAccounts
        .filter()
        .isArchivedEqualTo(false)
        .includeInBalanceEqualTo(true)
        .findAll();

    // Compute running balance per account from opening + transactions.
    double netWorth = 0;
    for (final acct in accounts) {
      double balance = acct.openingBalance;
      final txns = await _isar.jiveTransactions
          .filter()
          .accountIdEqualTo(acct.id)
          .findAll();
      for (final tx in txns) {
        if (tx.type == 'expense') {
          balance -= tx.amount;
        } else if (tx.type == 'income') {
          balance += tx.amount;
        } else if (tx.type == 'transfer') {
          balance -= tx.amount;
        }
      }
      // Incoming transfers
      final incomingTxns = await _isar.jiveTransactions
          .filter()
          .toAccountIdEqualTo(acct.id)
          .typeEqualTo('transfer')
          .findAll();
      for (final tx in incomingTxns) {
        balance += tx.toAmount ?? tx.amount;
      }
      netWorth += balance;
    }

    // --- Budget remaining (reuse logic from getTodaySummary) ---
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    double? budgetRemaining;
    final activeBudgets = await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .startDateLessThan(todayEnd)
        .endDateGreaterThan(todayStart)
        .findAll();

    if (activeBudgets.isNotEmpty) {
      final budget = activeBudgets
              .where((b) => b.categoryKey == null)
              .firstOrNull ??
          activeBudgets.first;
      final effectiveAmount = budget.amount + budget.carryoverAmount;
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

    // --- Unread reimbursements (pending or submitted) ---
    final unreadCount = await _isar.jiveReimbursements
        .filter()
        .group((q) => q
            .statusEqualTo(ReimbursementStatus.pending)
            .or()
            .statusEqualTo(ReimbursementStatus.submitted))
        .count();

    return QuickInfoWidgetData(
      netWorth: netWorth,
      monthBudgetRemaining: budgetRemaining,
      unreadReimbursementCount: unreadCount,
    );
  }
}
