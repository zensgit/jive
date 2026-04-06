import 'package:isar/isar.dart';

part 'card_reward_model.g.dart';

/// 奖励类型
class RewardType {
  static const String cashback = 'cashback';
  static const String points = 'points';
  static const String miles = 'miles';
}

@collection
class JiveCardReward {
  Id id = Isar.autoIncrement;

  /// 关联的账户 ID
  @Index()
  late int accountId;

  /// 账户名称（冗余，方便展示）
  late String accountName;

  /// 回馈比率，例如 0.01 = 1%
  late double rewardRate;

  /// 奖励类型: cashback | points | miles
  late String rewardType;

  /// 月度回馈上限（null 表示无上限）
  double? monthlyCapAmount;

  /// 累计已获得的奖励
  double totalEarned = 0;

  /// 当月已获得的奖励
  double monthEarned = 0;

  /// 上次重置月份 (yyyy-MM)
  late String lastResetMonth;

  /// 是否启用
  bool isEnabled = true;

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  late DateTime updatedAt;

  /// 当月剩余可获得额度
  double get monthlyRemaining {
    if (monthlyCapAmount == null) return double.infinity;
    return (monthlyCapAmount! - monthEarned).clamp(0, double.infinity);
  }
}
