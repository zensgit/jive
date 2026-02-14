import 'dart:async';
import 'package:isar/isar.dart';
import '../database/budget_model.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import 'currency_service.dart';

/// 预算服务
class BudgetService {
  final Isar _isar;
  final CurrencyService _currencyService;
  static const Duration _summaryTimeout = Duration(seconds: 4);

  BudgetService(this._isar, this._currencyService);

  /// 创建预算
  Future<JiveBudget> createBudget({
    required String name,
    required double amount,
    required String currency,
    String? categoryKey,
    required DateTime startDate,
    required DateTime endDate,
    String period = 'monthly',
    double? alertThreshold,
    bool alertEnabled = false,
    bool rollover = false,
  }) async {
    final budget = JiveBudget()
      ..name = name
      ..amount = amount
      ..currency = currency
      ..categoryKey = categoryKey
      ..startDate = startDate
      ..endDate = endDate
      ..period = period
      ..alertThreshold = alertThreshold
      ..alertEnabled = alertEnabled
      ..rollover = rollover
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.put(budget);
    });

    return budget;
  }

  /// 获取所有活跃预算
  Future<List<JiveBudget>> getActiveBudgets() async {
    return await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .sortByStartDateDesc()
        .findAll();
  }

  /// 获取预算详情
  Future<JiveBudget?> getBudget(int id) async {
    return await _isar.jiveBudgets.get(id);
  }

  /// 更新预算
  Future<void> updateBudget(JiveBudget budget) async {
    budget.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.put(budget);
    });
  }

  /// 删除预算
  Future<void> deleteBudget(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.delete(id);
      // 同时删除相关使用记录
      await _isar.jiveBudgetUsages.filter().budgetIdEqualTo(id).deleteAll();
    });
  }

  /// 计算预算使用情况
  Future<BudgetSummary> calculateBudgetUsage(JiveBudget budget) async {
    final now = DateTime.now();

    final transactions = await _getBudgetTransactionsInRange(
      budget,
      budget.startDate,
      budget.endDate,
    );

    // 计算总使用金额（转换为预算货币）
    // 目前交易默认按 CNY 存储，因此汇率在预算维度只需查询一次，避免逐笔查询导致卡顿。
    final exchangeRate = await _budgetExchangeRate(budget);
    final usedAmount = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount * exchangeRate,
    );

    final remainingAmount = budget.amount - usedAmount;
    final usedPercent = budget.amount > 0
        ? (usedAmount / budget.amount * 100)
        : 0;

    // 确定状态
    BudgetStatus status;
    if (usedAmount > budget.amount) {
      status = BudgetStatus.exceeded;
    } else if (budget.alertEnabled &&
        budget.alertThreshold != null &&
        usedPercent >= budget.alertThreshold!) {
      status = BudgetStatus.warning;
    } else {
      status = BudgetStatus.normal;
    }

    // Remaining days should be inclusive (same-day budgets still have 1 day).
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );
    final dayDiff = endDay.difference(today).inDays;
    final daysRemaining = dayDiff >= 0 ? dayDiff + 1 : 0;

    return BudgetSummary(
      budget: budget,
      usedAmount: usedAmount,
      remainingAmount: remainingAmount,
      usedPercent: usedPercent.toDouble(),
      status: status,
      daysRemaining: daysRemaining,
    );
  }

  Future<double> _budgetExchangeRate(JiveBudget budget) async {
    // 目前交易默认按 CNY 存储。
    const txCurrency = 'CNY';
    if (txCurrency == budget.currency) return 1.0;
    final rate = await _currencyService.getRate(txCurrency, budget.currency);
    return rate ?? 1.0;
  }

  Future<Set<String>> _getExcludedBudgetCategoryKeys() async {
    final excluded = await _isar
        .collection<JiveCategory>()
        .filter()
        .excludeFromBudgetEqualTo(true)
        .and()
        .isIncomeEqualTo(false)
        .findAll();
    return excluded.map((c) => c.key).toSet();
  }

  Future<List<JiveTransaction>> _getBudgetTransactionsInRange(
    JiveBudget budget,
    DateTime start,
    DateTime end,
  ) async {
    // 获取周期内的交易
    var query = _isar.jiveTransactions
        .filter()
        .timestampBetween(start, end)
        .typeEqualTo('expense')
        .excludeFromBudgetEqualTo(false);

    if (budget.categoryKey != null && budget.categoryKey!.isNotEmpty) {
      final key = budget.categoryKey!;
      // Support both parent & sub category budgets. For parent categories,
      // transactions are stored on `categoryKey`; for sub categories, they are
      // stored on `subCategoryKey`.
      query = query.group(
        (q) => q.categoryKeyEqualTo(key).or().subCategoryKeyEqualTo(key),
      );
    }

    var transactions = await query.findAll();

    // yimu-like behavior: overall budget ignores categories that are marked as "exclude from budget".
    // Only apply this to total budgets (categoryKey == null) to avoid surprising results for
    // category-specific budgets (future feature).
    if (budget.categoryKey == null) {
      final excludedKeys = await _getExcludedBudgetCategoryKeys();
      if (excludedKeys.isNotEmpty) {
        transactions = transactions.where((tx) {
          final parentKey = tx.categoryKey;
          if (parentKey != null && excludedKeys.contains(parentKey)) {
            return false;
          }
          final subKey = tx.subCategoryKey;
          if (subKey != null && excludedKeys.contains(subKey)) return false;
          return true;
        }).toList();
      }
    }

    return transactions;
  }

  /// 获取所有预算摘要
  Future<List<BudgetSummary>> getAllBudgetSummaries() async {
    final budgets = await getActiveBudgets();
    final summaries = <BudgetSummary>[];
    final failed = <String>[];

    for (final budget in budgets) {
      try {
        final summary = await calculateBudgetUsage(budget).timeout(
          _summaryTimeout,
          onTimeout: () => throw TimeoutException('预算计算超时'),
        );
        summaries.add(summary);
      } catch (e) {
        failed.add('${budget.name}: $e');
      }
    }

    if (summaries.isEmpty && budgets.isNotEmpty) {
      throw Exception('预算计算失败，无法读取预算数据（${failed.length}/${budgets.length}）');
    }

    return summaries;
  }

  /// 获取预算在最近 N 天的每日支出趋势（用于折线图展示）
  Future<List<BudgetDailySpending>> getBudgetDailySpendingTrend(
    JiveBudget budget, {
    int days = 14,
    DateTime? referenceDate,
  }) async {
    if (days <= 0) return const [];

    final ref = referenceDate ?? DateTime.now();
    final budgetStartDay = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    );
    final budgetEndDay = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );

    final refDay = DateTime(ref.year, ref.month, ref.day);
    final endDay = refDay.isBefore(budgetStartDay)
        ? budgetStartDay
        : refDay.isAfter(budgetEndDay)
        ? budgetEndDay
        : refDay;

    final startDayCandidate = endDay.subtract(Duration(days: days - 1));
    final startDay = startDayCandidate.isBefore(budgetStartDay)
        ? budgetStartDay
        : startDayCandidate;

    final queryStart = DateTime(startDay.year, startDay.month, startDay.day);
    final queryEnd = DateTime(
      endDay.year,
      endDay.month,
      endDay.day,
      23,
      59,
      59,
      999,
    );

    final transactions = await _getBudgetTransactionsInRange(
      budget,
      queryStart,
      queryEnd,
    );
    final exchangeRate = await _budgetExchangeRate(budget);

    final byDay = <DateTime, double>{};
    for (final tx in transactions) {
      final day = DateTime(
        tx.timestamp.year,
        tx.timestamp.month,
        tx.timestamp.day,
      );
      byDay.update(
        day,
        (v) => v + tx.amount * exchangeRate,
        ifAbsent: () => tx.amount * exchangeRate,
      );
    }

    final result = <BudgetDailySpending>[];
    for (
      var day = startDay;
      !day.isAfter(endDay);
      day = day.add(const Duration(days: 1))
    ) {
      result.add(BudgetDailySpending(day: day, amount: byDay[day] ?? 0));
    }
    return result;
  }

  /// 评估“保存一笔支出”会导致哪些预算从正常变为预警/超支（用于保存前提示）
  Future<List<BudgetTransactionImpact>> evaluateBudgetImpactsForTransaction({
    required JiveTransaction newTransaction,
    JiveTransaction? oldTransaction,
  }) async {
    if (newTransaction.type != 'expense') return const [];
    if (newTransaction.excludeFromBudget) return const [];

    final budgets = await getActiveBudgets();
    if (budgets.isEmpty) return const [];

    final excludedKeys = await _getExcludedBudgetCategoryKeys();
    final impacts = <BudgetTransactionImpact>[];

    for (final budget in budgets) {
      final newContribution = await _transactionContributionInBudgetCurrency(
        newTransaction,
        budget,
        excludedKeys,
      );
      if (newContribution <= 0) continue;

      final oldContribution = oldTransaction == null
          ? 0.0
          : await _transactionContributionInBudgetCurrency(
              oldTransaction,
              budget,
              excludedKeys,
            );
      final delta = newContribution - oldContribution;
      if (delta <= 0) continue;

      final currentSummary = await calculateBudgetUsage(budget);
      final projectedUsed = currentSummary.usedAmount + delta;
      final projectedPercent = budget.amount > 0
          ? (projectedUsed / budget.amount * 100)
          : 0.0;
      final projectedStatus = _statusForProjectedUsage(
        budget,
        projectedUsedAmount: projectedUsed,
        projectedUsedPercent: projectedPercent,
      );

      if (_statusRank(projectedStatus) <= _statusRank(currentSummary.status)) {
        continue;
      }

      impacts.add(
        BudgetTransactionImpact(
          budget: budget,
          currentStatus: currentSummary.status,
          projectedStatus: projectedStatus,
          currentUsedAmount: currentSummary.usedAmount,
          projectedUsedAmount: projectedUsed,
          currentUsedPercent: currentSummary.usedPercent,
          projectedUsedPercent: projectedPercent,
          deltaAmount: delta,
        ),
      );
    }

    impacts.sort((a, b) {
      final rank = _statusRank(
        b.projectedStatus,
      ).compareTo(_statusRank(a.projectedStatus));
      if (rank != 0) return rank;
      return b.projectedUsedPercent.compareTo(a.projectedUsedPercent);
    });
    return impacts;
  }

  BudgetStatus _statusForProjectedUsage(
    JiveBudget budget, {
    required double projectedUsedAmount,
    required double projectedUsedPercent,
  }) {
    if (projectedUsedAmount > budget.amount) return BudgetStatus.exceeded;
    if (budget.alertEnabled &&
        budget.alertThreshold != null &&
        projectedUsedPercent >= budget.alertThreshold!) {
      return BudgetStatus.warning;
    }
    return BudgetStatus.normal;
  }

  int _statusRank(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.normal:
        return 0;
      case BudgetStatus.warning:
        return 1;
      case BudgetStatus.exceeded:
        return 2;
    }
  }

  Future<double> _transactionContributionInBudgetCurrency(
    JiveTransaction tx,
    JiveBudget budget,
    Set<String> excludedCategoryKeys,
  ) async {
    if (tx.type != 'expense') return 0;
    if (tx.excludeFromBudget) return 0;
    final ts = tx.timestamp;
    if (ts.isBefore(budget.startDate) || ts.isAfter(budget.endDate)) return 0;

    final budgetCategoryKey = budget.categoryKey;
    if (budgetCategoryKey != null && budgetCategoryKey.isNotEmpty) {
      if (tx.categoryKey != budgetCategoryKey &&
          tx.subCategoryKey != budgetCategoryKey) {
        return 0;
      }
    } else {
      final parentKey = tx.categoryKey;
      if (parentKey != null && excludedCategoryKeys.contains(parentKey)) {
        return 0;
      }
      final subKey = tx.subCategoryKey;
      if (subKey != null && excludedCategoryKeys.contains(subKey)) return 0;
    }

    final exchangeRate = await _budgetExchangeRate(budget);
    return tx.amount * exchangeRate;
  }

  /// 根据周期获取预算日期范围
  static (DateTime, DateTime) getPeriodDateRange(
    BudgetPeriod period, {
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();

    switch (period) {
      case BudgetPeriod.daily:
        final start = DateTime(ref.year, ref.month, ref.day);
        final end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        return (start, end);

      case BudgetPeriod.weekly:
        final weekday = ref.weekday;
        final start = DateTime(
          ref.year,
          ref.month,
          ref.day,
        ).subtract(Duration(days: weekday - 1));
        final end = start
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1));
        return (start, end);

      case BudgetPeriod.monthly:
        final start = DateTime(ref.year, ref.month, 1);
        final end = DateTime(ref.year, ref.month + 1, 0, 23, 59, 59, 999);
        return (start, end);

      case BudgetPeriod.yearly:
        final start = DateTime(ref.year, 1, 1);
        final end = DateTime(ref.year, 12, 31, 23, 59, 59, 999);
        return (start, end);

      case BudgetPeriod.custom:
        final start = DateTime(ref.year, ref.month, ref.day);
        final end = DateTime(ref.year, ref.month, ref.day, 23, 59, 59, 999);
        return (start, end);
    }
  }

  /// 检查需要预警的预算
  Future<List<BudgetSummary>> checkBudgetAlerts() async {
    final summaries = await getAllBudgetSummaries();
    return summaries
        .where(
          (s) =>
              s.status == BudgetStatus.warning ||
              s.status == BudgetStatus.exceeded,
        )
        .toList();
  }
}

class BudgetDailySpending {
  final DateTime day;
  final double amount;

  const BudgetDailySpending({required this.day, required this.amount});
}

class BudgetTransactionImpact {
  final JiveBudget budget;
  final BudgetStatus currentStatus;
  final BudgetStatus projectedStatus;
  final double currentUsedAmount;
  final double projectedUsedAmount;
  final double currentUsedPercent;
  final double projectedUsedPercent;
  final double deltaAmount;

  const BudgetTransactionImpact({
    required this.budget,
    required this.currentStatus,
    required this.projectedStatus,
    required this.currentUsedAmount,
    required this.projectedUsedAmount,
    required this.currentUsedPercent,
    required this.projectedUsedPercent,
    required this.deltaAmount,
  });
}
