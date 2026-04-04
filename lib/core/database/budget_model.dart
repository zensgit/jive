import 'package:isar/isar.dart';

part 'budget_model.g.dart';

/// 预算模型 - 支持多币种
@collection
class JiveBudget {
  Id id = Isar.autoIncrement;

  late String name; // 预算名称
  late double amount; // 预算金额
  late String currency; // 货币代码

  /// 结转调整（多余预算累加/超额支出扣除），会叠加到 [amount] 上作为本期有效预算。
  ///
  /// - 正数：增加本期预算
  /// - 负数：扣减本期预算
  double carryoverAmount = 0;

  @Index()
  String? categoryKey; // 关联的分类（可选，null 表示总预算）

  @Index()
  late DateTime startDate; // 开始日期
  late DateTime endDate; // 结束日期

  String period = 'monthly'; // 周期: daily, weekly, monthly, yearly, custom
  bool isActive = true; // 是否启用
  bool rollover = false; // 是否将未用完的额度滚动到下一周期

  /// 排序权重（主要用于“分类预算”列表拖拽排序）。数值越大越靠前。
  int positionWeight = 0;

  double? alertThreshold; // 预警阈值（百分比，如 80 表示 80%）
  bool alertEnabled = false; // 是否启用预警

  @Index()
  int? bookId; // 关联账本（null = 全局预算）

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

/// 预算使用记录
@collection
class JiveBudgetUsage {
  Id id = Isar.autoIncrement;

  @Index()
  late int budgetId; // 关联的预算 ID

  late double usedAmount; // 已使用金额
  late String usedCurrency; // 使用时的货币
  double? convertedAmount; // 转换后的金额（转换为预算货币）

  @Index()
  late DateTime recordDate; // 记录日期

  int? transactionId; // 关联的交易 ID（可选）
}

/// 预算周期枚举
enum BudgetPeriod {
  daily('daily', '每日'),
  weekly('weekly', '每周'),
  monthly('monthly', '每月'),
  yearly('yearly', '每年'),
  custom('custom', '自定义');

  final String value;
  final String label;

  const BudgetPeriod(this.value, this.label);

  static BudgetPeriod fromValue(String value) {
    return BudgetPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BudgetPeriod.monthly,
    );
  }
}

/// 预算状态
enum BudgetStatus {
  normal, // 正常
  warning, // 接近预算
  exceeded, // 超出预算
}

/// 预算摘要数据
class BudgetSummary {
  final JiveBudget budget;
  /// 本期有效预算金额（包含结转调整，以及总预算的 yimu 口径修正）。
  final double effectiveAmount;
  final double usedAmount;
  final double remainingAmount;
  final double usedPercent;
  final BudgetStatus status;
  final int daysRemaining;

  BudgetSummary({
    required this.budget,
    required this.effectiveAmount,
    required this.usedAmount,
    required this.remainingAmount,
    required this.usedPercent,
    required this.status,
    required this.daysRemaining,
  });

  bool get isOverBudget => usedAmount > effectiveAmount;
  bool get isWarning => budget.alertEnabled &&
      budget.alertThreshold != null &&
      usedPercent >= budget.alertThreshold!;
}
