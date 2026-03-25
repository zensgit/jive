import 'dart:async';
import 'package:isar/isar.dart';
import '../database/budget_model.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import 'budget_pref_service.dart';
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
    double carryoverAmount = 0,
    String? categoryKey,
    required DateTime startDate,
    required DateTime endDate,
    String period = 'monthly',
    int positionWeight = 0,
    double? alertThreshold,
    bool alertEnabled = false,
    bool rollover = false,
  }) async {
    final budget = JiveBudget()
      ..name = name
      ..amount = amount
      ..currency = currency
      ..carryoverAmount = carryoverAmount
      ..categoryKey = categoryKey
      ..startDate = startDate
      ..endDate = endDate
      ..period = period
      ..positionWeight = positionWeight
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
        .thenByPositionWeightDesc()
        .findAll();
  }

  /// 在进入新月份时，自动复制上月的月度预算到本月（可通过偏好关闭）。
  ///
  /// - 仅复制 `period == monthly` 的预算
  /// - 若本月已存在同一 (currency + categoryKey) 的预算，则跳过
  /// - 结转金额由偏好控制：不结转 / 仅结转正余额 / 结转正负余额
  Future<int> autoCopyMonthlyBudgetsIfNeeded({DateTime? referenceDate}) async {
    final enabled = await BudgetPrefService.getBudgetMonthlyAutoCopyEnabled();
    if (!enabled) return 0;

    final now = referenceDate ?? DateTime.now();
    final (currentStart, currentEnd) = getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: now,
    );
    final prevRef = DateTime(now.year, now.month - 1, 15);
    final (prevStart, prevEnd) = getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: prevRef,
    );

    final current = await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .periodEqualTo(BudgetPeriod.monthly.value)
        .startDateEqualTo(currentStart)
        .endDateEqualTo(currentEnd)
        .findAll();
    final existingSignatures = current.map(_budgetSignature).toSet();

    final previous = await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .periodEqualTo(BudgetPeriod.monthly.value)
        .startDateEqualTo(prevStart)
        .endDateEqualTo(prevEnd)
        .findAll();
    if (previous.isEmpty) return 0;

    // Enforce the supported combinations:
    // - none
    // - positive only
    // - positive + negative
    final carryoverAddEnabled =
        await BudgetPrefService.getBudgetCarryoverAddEnabled();
    final carryoverReduceEnabled =
        await BudgetPrefService.getBudgetCarryoverReduceEnabled();
    final shouldCarryoverAdd = carryoverAddEnabled || carryoverReduceEnabled;
    final shouldCarryoverReduce = carryoverReduceEnabled;

    final created = <JiveBudget>[];
    for (final prev in previous) {
      final signature = _budgetSignature(prev);
      if (existingSignatures.contains(signature)) continue;

      double carryoverAmount = 0;
      if (shouldCarryoverAdd || shouldCarryoverReduce) {
        final summary = await calculateBudgetUsage(prev);
        final remaining = summary.remainingAmount;
        if (remaining > 0 && shouldCarryoverAdd) {
          carryoverAmount = remaining;
        } else if (remaining < 0 && shouldCarryoverReduce) {
          carryoverAmount = remaining;
        }
      }

      created.add(
        JiveBudget()
          ..name = prev.name
          ..amount = prev.amount
          ..currency = prev.currency
          ..carryoverAmount = carryoverAmount
          ..categoryKey = prev.categoryKey
          ..startDate = currentStart
          ..endDate = currentEnd
          ..period = prev.period
          ..isActive = true
          ..rollover = prev.rollover
          ..positionWeight = prev.positionWeight
          ..alertThreshold = prev.alertThreshold
          ..alertEnabled = prev.alertEnabled
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now(),
      );
    }

    if (created.isEmpty) return 0;
    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.putAll(created);
    });
    return created.length;
  }

  String _budgetSignature(JiveBudget budget) {
    final key = budget.categoryKey ?? '';
    return '${budget.currency}::$key';
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
  Future<BudgetSummary> calculateBudgetUsage(JiveBudget budget, {int? bookId}) async {
    final now = DateTime.now();

    final effectiveDirectAmount = _effectiveDirectAmount(budget);
    final context = budget.categoryKey == null
        ? await _getOverallBudgetYimuContext(budget, effectiveDirectAmount)
        : null;
    final effectiveAmount = context?.effectiveAmount ?? effectiveDirectAmount;

    final transactions = await _getBudgetTransactionsInRange(
      budget,
      budget.startDate,
      budget.endDate,
      excludedKeys: context?.excludedCategoryKeys,
      budgetedParentKeys: context?.budgetedParentKeys,
      budgetedChildKeys: context?.budgetedChildKeys,
      onlyBudgetedCategories: context?.onlyBudgetedCategories ?? false,
      bookId: bookId,
    );

    // 计算总使用金额（转换为预算货币）
    // 目前交易默认按 CNY 存储，因此汇率在预算维度只需查询一次，避免逐笔查询导致卡顿。
    final exchangeRate = await _budgetExchangeRate(budget);
    final usedAmount = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount * exchangeRate,
    );

    final remainingAmount = effectiveAmount - usedAmount;
    final usedPercent = effectiveAmount > 0
        ? (usedAmount / effectiveAmount * 100)
        : 0.0;

    // 确定状态
    BudgetStatus status;
    if (usedAmount > effectiveAmount) {
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
      effectiveAmount: effectiveAmount,
      usedAmount: usedAmount,
      remainingAmount: remainingAmount,
      usedPercent: usedPercent.toDouble(),
      status: status,
      daysRemaining: daysRemaining,
    );
  }

  double _effectiveDirectAmount(JiveBudget budget) {
    final value = budget.amount + budget.carryoverAmount;
    return value < 0 ? 0 : value;
  }

  Future<List<JiveBudget>> _getSiblingCategoryBudgetsForRange(
    JiveBudget budget,
  ) async {
    // Some older data may store month-end as `23:59:59` (without milliseconds).
    // Use "same-day" bounds to treat them as the same range.
    final startDay = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    );
    final startDayEnd = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
      23,
      59,
      59,
      999,
    );
    final endDayStart = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );
    final endDayEnd = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
      23,
      59,
      59,
      999,
    );
    return await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .startDateBetween(startDay, startDayEnd)
        .endDateBetween(endDayStart, endDayEnd)
        .currencyEqualTo(budget.currency)
        .categoryKeyIsNotNull()
        .categoryKeyIsNotEmpty()
        .findAll();
  }

  Future<List<JiveBudget>> _getMonthlyBudgetsForRange(
    DateTime startDate,
    DateTime endDate, {
    required bool includeInactive,
  }) async {
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final startDayEnd = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      23,
      59,
      59,
      999,
    );
    final endDayStart = DateTime(endDate.year, endDate.month, endDate.day);
    final endDayEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    var query = _isar.jiveBudgets
        .filter()
        .periodEqualTo(BudgetPeriod.monthly.value)
        .startDateBetween(startDay, startDayEnd)
        .endDateBetween(endDayStart, endDayEnd);

    if (!includeInactive) {
      query = query.isActiveEqualTo(true);
    }

    return await query.findAll();
  }

  JiveBudget? _findTotalBudget(List<JiveBudget> budgets) {
    for (final b in budgets) {
      final key = b.categoryKey;
      if (key == null || key.isEmpty) return b;
    }
    return null;
  }

  List<JiveBudget> _findCategoryBudgets(List<JiveBudget> budgets) {
    return budgets
        .where((b) => b.categoryKey != null && b.categoryKey!.isNotEmpty)
        .toList();
  }

  Future<double> _carryoverAmountForMonthlyCopy(
    JiveBudget previousBudget, {
    required bool carryoverAddEnabled,
    required bool carryoverReduceEnabled,
  }) async {
    if (!carryoverAddEnabled && !carryoverReduceEnabled) return 0;
    final effectiveDirectAmount = _effectiveDirectAmount(previousBudget);
    if (effectiveDirectAmount <= 0) return 0;

    final summary = await calculateBudgetUsage(previousBudget);
    final used = summary.usedAmount;

    if (carryoverAddEnabled && used < effectiveDirectAmount) {
      return effectiveDirectAmount - used;
    }
    if (carryoverReduceEnabled && used > effectiveDirectAmount) {
      return effectiveDirectAmount - used; // negative
    }
    return 0;
  }

  /// yimu-like: when a new month begins and there are no monthly budgets yet,
  /// auto-copy the previous month's budgets (total + category) and optionally
  /// apply carryover adjustments.
  ///
  /// - If the current month already has any category budgets (active or not),
  ///   we do **not** copy category budgets.
  /// - If the current month already has a total budget (active or not), we do
  ///   **not** create/copy a total budget.
  ///
  /// Returns how many budgets were created.
  Future<int> autoCopyMonthlyBudgetsIfEmpty({
    required DateTime referenceMonth,
    required bool carryoverAddEnabled,
    required bool carryoverReduceEnabled,
  }) async {
    final (currentStart, currentEnd) = getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: referenceMonth,
    );
    final previousRef = DateTime(currentStart.year, currentStart.month, 0);
    final (prevStart, prevEnd) = getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: previousRef,
    );

    final currentBudgetsAll = await _getMonthlyBudgetsForRange(
      currentStart,
      currentEnd,
      includeInactive: true,
    );
    final previousBudgetsActive = await _getMonthlyBudgetsForRange(
      prevStart,
      prevEnd,
      includeInactive: false,
    );

    if (previousBudgetsActive.isEmpty) return 0;

    final currentByCurrency = <String, List<JiveBudget>>{};
    for (final b in currentBudgetsAll) {
      currentByCurrency.putIfAbsent(b.currency, () => []).add(b);
    }
    final previousByCurrency = <String, List<JiveBudget>>{};
    for (final b in previousBudgetsActive) {
      previousByCurrency.putIfAbsent(b.currency, () => []).add(b);
    }

    final now = DateTime.now();
    final toCreate = <JiveBudget>[];

    for (final entry in previousByCurrency.entries) {
      final currency = entry.key;
      final prevBudgets = entry.value;
      final currentBudgets =
          currentByCurrency[currency] ?? const <JiveBudget>[];

      final currentTotal = _findTotalBudget(currentBudgets);
      final prevTotal = _findTotalBudget(prevBudgets);
      if (currentTotal == null && prevTotal != null) {
        var carryover = await _carryoverAmountForMonthlyCopy(
          prevTotal,
          carryoverAddEnabled: carryoverAddEnabled,
          carryoverReduceEnabled: carryoverReduceEnabled,
        );
        if (prevTotal.amount + carryover < 0) {
          carryover = -prevTotal.amount;
        }
        toCreate.add(
          JiveBudget()
            ..name = prevTotal.name
            ..amount = prevTotal.amount
            ..currency = currency
            ..carryoverAmount = carryover
            ..categoryKey = null
            ..startDate = currentStart
            ..endDate = currentEnd
            ..period = BudgetPeriod.monthly.value
            ..isActive = true
            ..rollover = prevTotal.rollover
            ..positionWeight = prevTotal.positionWeight
            ..alertEnabled = prevTotal.alertEnabled
            ..alertThreshold = prevTotal.alertThreshold
            ..createdAt = now
            ..updatedAt = now,
        );
      }

      final currentCategoriesAny = _findCategoryBudgets(currentBudgets);
      final prevCategories = _findCategoryBudgets(prevBudgets);
      if (currentCategoriesAny.isEmpty && prevCategories.isNotEmpty) {
        for (final prevBudget in prevCategories) {
          var carryover = await _carryoverAmountForMonthlyCopy(
            prevBudget,
            carryoverAddEnabled: carryoverAddEnabled,
            carryoverReduceEnabled: carryoverReduceEnabled,
          );
          if (prevBudget.amount + carryover < 0) {
            carryover = -prevBudget.amount;
          }
          toCreate.add(
            JiveBudget()
              ..name = prevBudget.name
              ..amount = prevBudget.amount
              ..currency = currency
              ..carryoverAmount = carryover
              ..categoryKey = prevBudget.categoryKey
              ..startDate = currentStart
              ..endDate = currentEnd
              ..period = BudgetPeriod.monthly.value
              ..isActive = true
              ..rollover = prevBudget.rollover
              ..positionWeight = prevBudget.positionWeight
              ..alertEnabled = prevBudget.alertEnabled
              ..alertThreshold = prevBudget.alertThreshold
              ..createdAt = now
              ..updatedAt = now,
          );
        }
      }
    }

    if (toCreate.isEmpty) return 0;
    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.putAll(toCreate);
    });
    return toCreate.length;
  }

  Future<void> updateBudgetOrder(List<JiveBudget> orderedBudgets) async {
    if (orderedBudgets.isEmpty) return;
    final now = DateTime.now();
    final count = orderedBudgets.length;
    for (var i = 0; i < orderedBudgets.length; i++) {
      final budget = orderedBudgets[i];
      budget.positionWeight = count - i;
      budget.updatedAt = now;
    }
    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.putAll(orderedBudgets);
    });
  }

  Future<Map<String, JiveCategory>> _getCategoryByKey() async {
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    return {for (final c in categories) c.key: c};
  }

  Future<_OverallBudgetYimuContext> _getOverallBudgetYimuContext(
    JiveBudget budget,
    double effectiveDirectAmount,
  ) async {
    final excludedKeys = await _getExcludedBudgetCategoryKeys();
    final categoryBudgets = await _getSiblingCategoryBudgetsForRange(budget);
    if (categoryBudgets.isEmpty) {
      return _OverallBudgetYimuContext(
        effectiveAmount: effectiveDirectAmount,
        categoryBudgetSum: 0,
        onlyBudgetedCategories: false,
        excludedCategoryKeys: excludedKeys,
        budgetedParentKeys: const {},
        budgetedChildKeys: const {},
      );
    }

    final categoryByKey = await _getCategoryByKey();

    final budgetedParentKeys = <String>{};
    final childBudgets = <({String key, String? parentKey, double amount})>[];
    var categoryBudgetSum = 0.0;

    for (final b in categoryBudgets) {
      final amount = _effectiveDirectAmount(b);
      categoryBudgetSum += amount;
      final key = b.categoryKey;
      if (key == null || key.isEmpty) continue;
      final category = categoryByKey[key];
      final parentKey = category?.parentKey;
      if (parentKey == null || parentKey.isEmpty) {
        budgetedParentKeys.add(key);
      } else {
        childBudgets.add((key: key, parentKey: parentKey, amount: amount));
      }
    }

    // yimu-like: if a parent category budget exists, its child budgets are
    // treated as sub-allocation and should not add to the total category sum.
    for (final child in childBudgets) {
      final parentKey = child.parentKey;
      if (parentKey != null && budgetedParentKeys.contains(parentKey)) {
        categoryBudgetSum -= child.amount;
      }
    }

    final effectiveAmount = effectiveDirectAmount > categoryBudgetSum
        ? effectiveDirectAmount
        : categoryBudgetSum;
    final onlyBudgetedCategories =
        categoryBudgetSum > 0 && effectiveDirectAmount <= categoryBudgetSum;

    final budgetedChildKeys = <String>{};
    for (final child in childBudgets) {
      final parentKey = child.parentKey;
      if (parentKey == null || parentKey.isEmpty) {
        budgetedChildKeys.add(child.key);
        continue;
      }
      if (!budgetedParentKeys.contains(parentKey)) {
        budgetedChildKeys.add(child.key);
      }
    }

    return _OverallBudgetYimuContext(
      effectiveAmount: effectiveAmount,
      categoryBudgetSum: categoryBudgetSum,
      onlyBudgetedCategories: onlyBudgetedCategories,
      excludedCategoryKeys: excludedKeys,
      budgetedParentKeys: budgetedParentKeys,
      budgetedChildKeys: budgetedChildKeys,
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
    DateTime end, {
    required Set<String>? excludedKeys,
    required Set<String>? budgetedParentKeys,
    required Set<String>? budgetedChildKeys,
    required bool onlyBudgetedCategories,
    int? bookId,
  }) async {
    // 获取周期内的交易
    var query = _isar.jiveTransactions
        .filter()
        .timestampBetween(start, end)
        .typeEqualTo('expense')
        .excludeFromBudgetEqualTo(false);
    if (bookId != null) {
      query = query.bookIdEqualTo(bookId);
    }

    if (budget.categoryKey != null && budget.categoryKey!.isNotEmpty) {
      final key = budget.categoryKey!;
      // Support both parent & sub category budgets. For parent categories,
      // transactions are stored on `categoryKey`; for sub categories, they are
      // stored on `subCategoryKey`.
      query = query.group(
        (q) => q.categoryKeyEqualTo(key).or().subCategoryKeyEqualTo(key),
      );
      return await query.findAll();
    }

    var transactions = await query.findAll();

    // yimu-like behavior: overall budget ignores categories that are marked as "exclude from budget".
    // Only apply this to total budgets (categoryKey == null) to avoid surprising results for
    // category-specific budgets (future feature).
    if (excludedKeys != null && excludedKeys.isNotEmpty) {
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

    if (onlyBudgetedCategories &&
        (budgetedParentKeys?.isNotEmpty == true ||
            budgetedChildKeys?.isNotEmpty == true)) {
      transactions = transactions.where((tx) {
        final parentKey = tx.categoryKey;
        if (parentKey != null && budgetedParentKeys!.contains(parentKey)) {
          return true;
        }
        final subKey = tx.subCategoryKey;
        if (subKey != null && budgetedChildKeys!.contains(subKey)) return true;
        return false;
      }).toList();
    }

    return transactions;
  }

  /// 获取所有预算摘要
  Future<List<BudgetSummary>> getAllBudgetSummaries({int? bookId}) async {
    final budgets = await getActiveBudgets();
    final summaries = <BudgetSummary>[];
    final failed = <String>[];

    for (final budget in budgets) {
      try {
        final summary = await calculateBudgetUsage(budget, bookId: bookId).timeout(
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

    final effectiveDirectAmount = _effectiveDirectAmount(budget);
    final context = budget.categoryKey == null
        ? await _getOverallBudgetYimuContext(budget, effectiveDirectAmount)
        : null;

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
      excludedKeys: context?.excludedCategoryKeys,
      budgetedParentKeys: context?.budgetedParentKeys,
      budgetedChildKeys: context?.budgetedChildKeys,
      onlyBudgetedCategories: context?.onlyBudgetedCategories ?? false,
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

  /// 按分类聚合预算周期内支出贡献（默认用于“总预算”看板的 TopN）。
  Future<List<BudgetCategoryContribution>> getBudgetCategoryContributions(
    JiveBudget budget, {
    DateTime? referenceDate,
    int limit = 5,
  }) async {
    if (limit <= 0) return const [];

    final effectiveDirectAmount = _effectiveDirectAmount(budget);
    final context = budget.categoryKey == null
        ? await _getOverallBudgetYimuContext(budget, effectiveDirectAmount)
        : null;

    final ref = referenceDate ?? DateTime.now();
    final refEnd = DateTime(ref.year, ref.month, ref.day, 23, 59, 59, 999);
    final queryEnd = refEnd.isAfter(budget.endDate) ? budget.endDate : refEnd;
    if (queryEnd.isBefore(budget.startDate)) return const [];

    final transactions = await _getBudgetTransactionsInRange(
      budget,
      budget.startDate,
      queryEnd,
      excludedKeys: context?.excludedCategoryKeys,
      budgetedParentKeys: context?.budgetedParentKeys,
      budgetedChildKeys: context?.budgetedChildKeys,
      onlyBudgetedCategories: context?.onlyBudgetedCategories ?? false,
    );
    if (transactions.isEmpty) return const [];

    final exchangeRate = await _budgetExchangeRate(budget);
    final amountByCategory = <String, double>{};
    for (final tx in transactions) {
      final key = _contributionCategoryKey(tx);
      amountByCategory.update(
        key,
        (value) => value + tx.amount * exchangeRate,
        ifAbsent: () => tx.amount * exchangeRate,
      );
    }
    if (amountByCategory.isEmpty) return const [];

    final totalAmount = amountByCategory.values.fold<double>(
      0,
      (s, v) => s + v,
    );
    if (totalAmount <= 0) return const [];

    final sorted = amountByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((entry) {
      final ratio = entry.value / totalAmount * 100;
      return BudgetCategoryContribution(
        categoryKey: entry.key,
        amount: entry.value,
        ratioPercent: _finiteValue(ratio),
      );
    }).toList();
  }

  /// 基于日级支出数据识别异常支出日（用于预算看板提示）。
  List<BudgetSpendingAnomalyDay> detectBudgetSpendingAnomaliesFromDaily(
    List<BudgetDailySpending> daily, {
    required double effectiveAmount,
    required DateTime periodStart,
    required DateTime periodEnd,
    DateTime? referenceDate,
    int limit = 3,
  }) {
    if (daily.isEmpty || limit <= 0) return const [];

    final startDay = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final endDay = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    final ref = referenceDate ?? DateTime.now();
    final refDay = DateTime(ref.year, ref.month, ref.day);

    final effectiveEnd = refDay.isBefore(startDay)
        ? startDay.subtract(const Duration(days: 1))
        : refDay.isAfter(endDay)
        ? endDay
        : refDay;
    if (effectiveEnd.isBefore(startDay)) return const [];

    final elapsed = daily.where((e) {
      final day = DateTime(e.day.year, e.day.month, e.day.day);
      return !day.isAfter(effectiveEnd);
    }).toList();
    if (elapsed.length < 3) return const [];

    final totalUsed = elapsed.fold<double>(0, (sum, e) => sum + e.amount);
    final avg = totalUsed / elapsed.length;
    final totalDays = _daysInclusive(startDay, endDay);
    final dailyBudget = totalDays > 0 ? effectiveAmount / totalDays : 0.0;

    var threshold = avg * 2.0;
    final paceThreshold = dailyBudget * 1.8;
    if (paceThreshold > threshold) threshold = paceThreshold;
    if (threshold < 1) threshold = 1;

    final anomalies =
        elapsed
            .where((e) => e.amount > 0 && e.amount >= threshold)
            .map(
              (e) => BudgetSpendingAnomalyDay(
                day: e.day,
                amount: e.amount,
                thresholdAmount: threshold,
                averageAmount: avg,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return anomalies.take(limit).toList();
  }

  /// 基于当前使用进度，计算预算节奏分析（预计月末、进度偏差、建议日均）。
  BudgetPacingInsight buildBudgetPacingInsight(
    BudgetSummary summary, {
    DateTime? referenceDate,
  }) {
    final budget = summary.budget;
    final startDay = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    );
    final endDay = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );
    final totalDays = _daysInclusive(startDay, endDay);

    final ref = referenceDate ?? DateTime.now();
    final refDay = DateTime(ref.year, ref.month, ref.day);

    late final int elapsedDays;
    late final int remainingDays;
    if (refDay.isBefore(startDay)) {
      elapsedDays = 0;
      remainingDays = totalDays;
    } else if (refDay.isAfter(endDay)) {
      elapsedDays = totalDays;
      remainingDays = 0;
    } else {
      elapsedDays = refDay.difference(startDay).inDays + 1;
      remainingDays = endDay.difference(refDay).inDays;
    }

    final effectiveAmount = summary.effectiveAmount;
    final usedAmount = summary.usedAmount;
    final expectedUsedByNow = totalDays > 0
        ? effectiveAmount * (elapsedDays / totalDays)
        : 0.0;
    final paceDelta = usedAmount - expectedUsedByNow;

    final projectedUsedAmount = elapsedDays > 0
        ? (usedAmount / elapsedDays) * totalDays
        : 0.0;
    final projectedUsedPercent = effectiveAmount > 0
        ? (projectedUsedAmount / effectiveAmount * 100)
        : 0.0;
    final projectedRemainingAmount = effectiveAmount - projectedUsedAmount;
    final suggestedDailyLimit = remainingDays > 0
        ? summary.remainingAmount / remainingDays
        : 0.0;

    final projectedStatus = _statusForProjectedUsage(
      budget,
      effectiveAmount: effectiveAmount,
      projectedUsedAmount: projectedUsedAmount,
      projectedUsedPercent: projectedUsedPercent,
    );

    return BudgetPacingInsight(
      totalDays: totalDays,
      elapsedDays: elapsedDays,
      remainingDays: remainingDays,
      expectedUsedByNow: _finiteValue(expectedUsedByNow),
      paceDelta: _finiteValue(paceDelta),
      projectedUsedAmount: _finiteValue(projectedUsedAmount),
      projectedRemainingAmount: _finiteValue(projectedRemainingAmount),
      projectedUsedPercent: _finiteValue(projectedUsedPercent),
      suggestedDailyLimit: _finiteValue(suggestedDailyLimit),
      projectedStatus: projectedStatus,
    );
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
      final effectiveDirectAmount = _effectiveDirectAmount(budget);
      final context = budget.categoryKey == null
          ? await _getOverallBudgetYimuContext(budget, effectiveDirectAmount)
          : null;

      final newContribution = await _transactionContributionInBudgetCurrency(
        newTransaction,
        budget,
        excludedKeys,
        onlyBudgetedCategories: context?.onlyBudgetedCategories ?? false,
        budgetedParentKeys: context?.budgetedParentKeys,
        budgetedChildKeys: context?.budgetedChildKeys,
      );
      if (newContribution <= 0) continue;

      final oldContribution = oldTransaction == null
          ? 0.0
          : await _transactionContributionInBudgetCurrency(
              oldTransaction,
              budget,
              excludedKeys,
              onlyBudgetedCategories: context?.onlyBudgetedCategories ?? false,
              budgetedParentKeys: context?.budgetedParentKeys,
              budgetedChildKeys: context?.budgetedChildKeys,
            );
      final delta = newContribution - oldContribution;
      if (delta <= 0) continue;

      final currentSummary = await calculateBudgetUsage(budget);
      final projectedUsed = currentSummary.usedAmount + delta;
      final projectedPercent = currentSummary.effectiveAmount > 0
          ? (projectedUsed / currentSummary.effectiveAmount * 100)
          : 0.0;
      final projectedStatus = _statusForProjectedUsage(
        budget,
        effectiveAmount: currentSummary.effectiveAmount,
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
          effectiveAmount: currentSummary.effectiveAmount,
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
    required double effectiveAmount,
    required double projectedUsedAmount,
    required double projectedUsedPercent,
  }) {
    if (projectedUsedAmount > effectiveAmount) return BudgetStatus.exceeded;
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

  String _contributionCategoryKey(JiveTransaction tx) {
    final parent = tx.categoryKey;
    if (parent != null && parent.isNotEmpty) return parent;
    final child = tx.subCategoryKey;
    if (child != null && child.isNotEmpty) return child;
    return '__uncategorized__';
  }

  Future<double> _transactionContributionInBudgetCurrency(
    JiveTransaction tx,
    JiveBudget budget,
    Set<String> excludedCategoryKeys, {
    required bool onlyBudgetedCategories,
    required Set<String>? budgetedParentKeys,
    required Set<String>? budgetedChildKeys,
  }) async {
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

      if (onlyBudgetedCategories) {
        final inParent =
            parentKey != null &&
            (budgetedParentKeys?.contains(parentKey) ?? false);
        final inChild =
            subKey != null && (budgetedChildKeys?.contains(subKey) ?? false);
        if (!inParent && !inChild) return 0;
      }
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
  Future<List<BudgetSummary>> checkBudgetAlerts({int? bookId}) async {
    final summaries = await getAllBudgetSummaries(bookId: bookId);
    return summaries
        .where(
          (s) =>
              s.status == BudgetStatus.warning ||
              s.status == BudgetStatus.exceeded,
        )
        .toList();
  }

  int _daysInclusive(DateTime start, DateTime end) {
    final diff = end.difference(start).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  double _finiteValue(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value;
  }
}

class BudgetDailySpending {
  final DateTime day;
  final double amount;

  const BudgetDailySpending({required this.day, required this.amount});
}

class BudgetPacingInsight {
  final int totalDays;
  final int elapsedDays;
  final int remainingDays;
  final double expectedUsedByNow;
  final double paceDelta;
  final double projectedUsedAmount;
  final double projectedRemainingAmount;
  final double projectedUsedPercent;
  final double suggestedDailyLimit;
  final BudgetStatus projectedStatus;

  const BudgetPacingInsight({
    required this.totalDays,
    required this.elapsedDays,
    required this.remainingDays,
    required this.expectedUsedByNow,
    required this.paceDelta,
    required this.projectedUsedAmount,
    required this.projectedRemainingAmount,
    required this.projectedUsedPercent,
    required this.suggestedDailyLimit,
    required this.projectedStatus,
  });
}

class BudgetCategoryContribution {
  final String categoryKey;
  final double amount;
  final double ratioPercent;

  const BudgetCategoryContribution({
    required this.categoryKey,
    required this.amount,
    required this.ratioPercent,
  });
}

class BudgetSpendingAnomalyDay {
  final DateTime day;
  final double amount;
  final double thresholdAmount;
  final double averageAmount;

  const BudgetSpendingAnomalyDay({
    required this.day,
    required this.amount,
    required this.thresholdAmount,
    required this.averageAmount,
  });
}

class _OverallBudgetYimuContext {
  final double effectiveAmount;
  final double categoryBudgetSum;
  final bool onlyBudgetedCategories;
  final Set<String> excludedCategoryKeys;
  final Set<String> budgetedParentKeys;
  final Set<String> budgetedChildKeys;

  const _OverallBudgetYimuContext({
    required this.effectiveAmount,
    required this.categoryBudgetSum,
    required this.onlyBudgetedCategories,
    required this.excludedCategoryKeys,
    required this.budgetedParentKeys,
    required this.budgetedChildKeys,
  });
}

class BudgetTransactionImpact {
  final JiveBudget budget;
  final BudgetStatus currentStatus;
  final BudgetStatus projectedStatus;
  final double effectiveAmount;
  final double currentUsedAmount;
  final double projectedUsedAmount;
  final double currentUsedPercent;
  final double projectedUsedPercent;
  final double deltaAmount;

  const BudgetTransactionImpact({
    required this.budget,
    required this.currentStatus,
    required this.projectedStatus,
    required this.effectiveAmount,
    required this.currentUsedAmount,
    required this.projectedUsedAmount,
    required this.currentUsedPercent,
    required this.projectedUsedPercent,
    required this.deltaAmount,
  });
}
