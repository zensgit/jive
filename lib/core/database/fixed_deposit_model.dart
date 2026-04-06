import 'package:isar/isar.dart';

part 'fixed_deposit_model.g.dart';

/// 定期存款模型
@collection
class JiveFixedDeposit {
  Id id = Isar.autoIncrement;

  /// 存款名称（如"工行一年期定存"）
  late String name;

  /// 本金
  late double principal;

  /// 年化利率（百分比，如 2.5 表示 2.5%）
  late double annualRate;

  /// 存期（月）
  late int termMonths;

  /// 起存日期
  @Index()
  late DateTime startDate;

  /// 到期日期
  @Index()
  late DateTime maturityDate;

  /// 计息方式: simple | compound
  String interestType = 'simple';

  /// 到期自动续存
  bool autoRenew = false;

  /// 状态: active | matured | withdrawn
  @Index()
  String status = 'active';

  /// 关联账户 ID（可选）
  int? accountId;

  /// 备注
  String? note;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  /// 计算预期利息
  double get expectedInterest {
    final years = termMonths / 12.0;
    final rate = annualRate / 100.0;
    if (interestType == 'compound') {
      // 复利: P * (1 + r)^t - P
      return principal * _pow(1 + rate, years) - principal;
    }
    // 单利: P * r * t
    return principal * rate * years;
  }

  /// 到期总额
  double get maturityAmount => principal + expectedInterest;

  /// 是否已到期
  bool get isMatured {
    final now = DateTime.now();
    return now.isAfter(maturityDate) || now.isAtSameMomentAs(maturityDate);
  }

  /// 距到期天数（负数表示已过期）
  int get daysToMaturity {
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final target = DateTime(
      maturityDate.year,
      maturityDate.month,
      maturityDate.day,
    );
    return target.difference(now).inDays;
  }
}

/// 简单的 pow 实现，避免引入 dart:math 只为一个函数。
double _pow(double base, double exponent) {
  // 使用迭代近似，对于整数月份足够精确
  double result = 1.0;
  final intPart = exponent.floor();
  final fracPart = exponent - intPart;
  for (int i = 0; i < intPart; i++) {
    result *= base;
  }
  if (fracPart > 0) {
    // 使用线性插值近似小数部分
    result *= 1 + fracPart * (base - 1);
  }
  return result;
}
