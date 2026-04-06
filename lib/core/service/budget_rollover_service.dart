import 'package:isar/isar.dart';

import '../database/budget_model.dart';
import 'budget_service.dart';
import 'currency_service.dart';
import 'database_service.dart';

/// 单月结转记录
class RolloverRecord {
  final DateTime month;
  final double budgetAmount;
  final double usedAmount;
  final double rolloverAmount; // 正 = 结余转入；负 = 超支扣减

  const RolloverRecord({
    required this.month,
    required this.budgetAmount,
    required this.usedAmount,
    required this.rolloverAmount,
  });
}

/// 预算结转服务 —— 管理跨月度的预算额度转移
class BudgetRolloverService {
  final Isar _isar;
  final CurrencyService _currencyService;

  BudgetRolloverService(this._isar, this._currencyService);

  /// 从 DatabaseService 单例创建
  static Future<BudgetRolloverService> create() async {
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    return BudgetRolloverService(isar, cs);
  }

  /// 计算结转金额
  ///
  /// 如果当月有余额则正数转入下月，如果超支则负数从下月扣除。
  double calculateRollover(JiveBudget budget, double usedAmount) {
    final effectiveAmount = budget.amount + budget.carryoverAmount;
    final remaining = effectiveAmount - usedAmount;
    return remaining; // 正 = 结余；负 = 超支
  }

  /// 将未使用的额度应用到下个月的预算
  ///
  /// 找到同 currency + categoryKey 的下月预算，更新其 carryoverAmount。
  Future<bool> applyRollover(int budgetId) async {
    final budget = await _isar.jiveBudgets.get(budgetId);
    if (budget == null) return false;
    if (!budget.rollover) return false;

    final budgetService = BudgetService(_isar, _currencyService);
    final summary = await budgetService.calculateBudgetUsage(budget);
    final rolloverAmount = calculateRollover(budget, summary.usedAmount);

    // 查找下月预算
    final nextMonth = DateTime(
      budget.startDate.year,
      budget.startDate.month + 1,
      1,
    );
    final (nextStart, nextEnd) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: nextMonth,
    );

    final candidates = await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .currencyEqualTo(budget.currency)
        .startDateEqualTo(nextStart)
        .endDateEqualTo(nextEnd)
        .findAll();

    // 匹配同一分类（或同为总预算）
    final target = candidates.where((b) {
      if (budget.categoryKey == null) return b.categoryKey == null;
      return b.categoryKey == budget.categoryKey;
    }).firstOrNull;

    if (target == null) return false;

    target.carryoverAmount += rolloverAmount;
    target.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.put(target);
    });

    return true;
  }

  /// 获取结转历史（最近 N 个月）
  ///
  /// 回溯 [months] 个月，查找同 currency + categoryKey 的预算并计算每月结转。
  Future<List<RolloverRecord>> getRolloverHistory(
    int budgetId, {
    int months = 6,
  }) async {
    final budget = await _isar.jiveBudgets.get(budgetId);
    if (budget == null) return [];

    final budgetService = BudgetService(_isar, _currencyService);
    final records = <RolloverRecord>[];

    for (int i = 0; i < months; i++) {
      final refDate = DateTime(
        budget.startDate.year,
        budget.startDate.month - i,
        1,
      );
      final (periodStart, periodEnd) = BudgetService.getPeriodDateRange(
        BudgetPeriod.monthly,
        referenceDate: refDate,
      );

      // 查找该月同类型预算
      final monthBudgets = await _isar.jiveBudgets
          .filter()
          .currencyEqualTo(budget.currency)
          .startDateEqualTo(periodStart)
          .endDateEqualTo(periodEnd)
          .findAll();

      final matched = monthBudgets.where((b) {
        if (budget.categoryKey == null) return b.categoryKey == null;
        return b.categoryKey == budget.categoryKey;
      }).firstOrNull;

      if (matched == null) continue;

      final summary = await budgetService.calculateBudgetUsage(matched);
      final rollover = calculateRollover(matched, summary.usedAmount);

      records.add(RolloverRecord(
        month: periodStart,
        budgetAmount: summary.effectiveAmount,
        usedAmount: summary.usedAmount,
        rolloverAmount: rollover,
      ));
    }

    return records;
  }
}
