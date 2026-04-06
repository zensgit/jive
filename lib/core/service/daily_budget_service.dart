import 'package:isar/isar.dart';

import '../database/budget_model.dart';
import 'budget_service.dart';
import 'currency_service.dart';
import 'database_service.dart';

/// 每日可用预算状态
enum DailyBudgetStatus {
  safe, // dailyAvailable > 平均日预算
  tight, // dailyAvailable > 0 但低于平均
  exceeded, // 已超支
}

/// 每日可用预算信息
class DailyBudgetInfo {
  final double monthlyBudget;
  final double spent;
  final double remaining;
  final int daysLeft;
  final double dailyAvailable;
  final DailyBudgetStatus status;

  const DailyBudgetInfo({
    required this.monthlyBudget,
    required this.spent,
    required this.remaining,
    required this.daysLeft,
    required this.dailyAvailable,
    required this.status,
  });
}

/// 每日可用预算服务 —— 基于当前活跃预算和月度支出计算每日可用额度
class DailyBudgetService {
  final Isar _isar;
  final CurrencyService _currencyService;

  DailyBudgetService(this._isar, this._currencyService);

  /// 从 DatabaseService 单例创建
  static Future<DailyBudgetService> create() async {
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    return DailyBudgetService(isar, cs);
  }

  /// 获取每日可用预算
  ///
  /// 查找当前月度活跃的总预算（categoryKey == null），计算剩余额度 / 剩余天数。
  Future<DailyBudgetInfo?> getDailyBudget({int? bookId}) async {
    final budgetService = BudgetService(_isar, _currencyService);

    // 获取当前月度总预算（无分类 = 总预算）
    final now = DateTime.now();
    final (monthStart, monthEnd) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: now,
    );

    final budgets = await _isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .periodEqualTo(BudgetPeriod.monthly.value)
        .startDateEqualTo(monthStart)
        .endDateEqualTo(monthEnd)
        .categoryKeyIsNull()
        .findAll();

    if (budgets.isEmpty) return null;

    // 使用第一个匹配的总预算
    final budget = budgets.first;
    final summary = await budgetService.calculateBudgetUsage(
      budget,
      bookId: bookId,
    );

    final monthlyBudget = summary.effectiveAmount;
    final spent = summary.usedAmount;
    final remaining = summary.remainingAmount;
    final daysLeft = summary.daysRemaining;
    final dailyAvailable = daysLeft > 0 ? remaining / daysLeft : 0.0;

    // 计算平均日预算
    final daysInMonth = monthEnd.difference(monthStart).inDays + 1;
    final avgDaily = daysInMonth > 0 ? monthlyBudget / daysInMonth : 0.0;

    DailyBudgetStatus status;
    if (remaining <= 0) {
      status = DailyBudgetStatus.exceeded;
    } else if (dailyAvailable < avgDaily) {
      status = DailyBudgetStatus.tight;
    } else {
      status = DailyBudgetStatus.safe;
    }

    return DailyBudgetInfo(
      monthlyBudget: monthlyBudget,
      spent: spent,
      remaining: remaining,
      daysLeft: daysLeft,
      dailyAvailable: dailyAvailable,
      status: status,
    );
  }
}
