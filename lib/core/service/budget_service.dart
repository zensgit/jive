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

    // 获取周期内的交易
    var query = _isar.jiveTransactions
        .filter()
        .timestampBetween(budget.startDate, budget.endDate)
        .typeEqualTo('expense')
        .excludeFromBudgetEqualTo(false);

    if (budget.categoryKey != null) {
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
      final excluded = await _isar.collection<JiveCategory>()
          .filter()
          .excludeFromBudgetEqualTo(true)
          .and()
          .isIncomeEqualTo(false)
          .findAll();
      if (excluded.isNotEmpty) {
        final excludedKeys = excluded.map((c) => c.key).toSet();
        transactions = transactions
            .where((tx) {
              final parentKey = tx.categoryKey;
              if (parentKey != null && excludedKeys.contains(parentKey)) return false;
              final subKey = tx.subCategoryKey;
              if (subKey != null && excludedKeys.contains(subKey)) return false;
              return true;
            })
            .toList();
      }
    }

    // 计算总使用金额（转换为预算货币）
    // 目前交易默认按 CNY 存储，因此汇率在预算维度只需查询一次，避免逐笔查询导致卡顿。
    const txCurrency = 'CNY';
    double exchangeRate = 1.0;
    if (txCurrency != budget.currency) {
      final rate = await _currencyService.getRate(txCurrency, budget.currency);
      exchangeRate = rate ?? 1.0;
    }
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
