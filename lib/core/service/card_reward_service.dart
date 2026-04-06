import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../database/card_reward_model.dart';

class CardRewardService {
  final Isar _isar;

  CardRewardService(this._isar);

  /// 计算某笔交易对应的奖励金额（考虑月度上限）
  Future<double> calculateReward(int accountId, double transactionAmount) async {
    final reward = await _isar.jiveCardRewards
        .filter()
        .accountIdEqualTo(accountId)
        .findFirst();
    if (reward == null || !reward.isEnabled) return 0;

    await resetMonthlyIfNeeded(accountId);
    // re-read after potential reset
    final current = await _isar.jiveCardRewards
        .filter()
        .accountIdEqualTo(accountId)
        .findFirst();
    if (current == null) return 0;

    double earned = transactionAmount.abs() * current.rewardRate;

    if (current.monthlyCapAmount != null) {
      final remaining = current.monthlyCapAmount! - current.monthEarned;
      if (remaining <= 0) return 0;
      if (earned > remaining) earned = remaining;
    }

    return double.parse(earned.toStringAsFixed(2));
  }

  /// 记录奖励到累计和月度
  Future<void> recordReward(int accountId, double amount) async {
    final reward = await _isar.jiveCardRewards
        .filter()
        .accountIdEqualTo(accountId)
        .findFirst();
    if (reward == null) return;

    await resetMonthlyIfNeeded(accountId);

    reward.totalEarned += amount;
    reward.monthEarned += amount;
    reward.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveCardRewards.put(reward);
    });
  }

  /// 如果进入新月份，重置 monthEarned
  Future<void> resetMonthlyIfNeeded(int accountId) async {
    final reward = await _isar.jiveCardRewards
        .filter()
        .accountIdEqualTo(accountId)
        .findFirst();
    if (reward == null) return;

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    if (reward.lastResetMonth != currentMonth) {
      reward.monthEarned = 0;
      reward.lastResetMonth = currentMonth;
      reward.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.jiveCardRewards.put(reward);
      });
    }
  }

  /// 获取单张卡的奖励摘要
  Future<RewardSummary?> getRewardSummary(int accountId) async {
    final reward = await _isar.jiveCardRewards
        .filter()
        .accountIdEqualTo(accountId)
        .findFirst();
    if (reward == null) return null;

    await resetMonthlyIfNeeded(accountId);
    // re-read
    final current = await _isar.jiveCardRewards
        .filter()
        .accountIdEqualTo(accountId)
        .findFirst();
    if (current == null) return null;

    return RewardSummary(
      totalEarned: current.totalEarned,
      monthEarned: current.monthEarned,
      monthlyRemaining: current.monthlyRemaining,
      rate: current.rewardRate,
      rewardType: current.rewardType,
    );
  }

  /// 获取所有奖励配置，按 totalEarned 降序
  Future<List<JiveCardReward>> getAllRewards() async {
    final all = await _isar.jiveCardRewards
        .where()
        .findAll();
    // Reset monthly for each, then re-fetch
    for (final r in all) {
      await resetMonthlyIfNeeded(r.accountId);
    }
    final results = await _isar.jiveCardRewards
        .where()
        .findAll();
    results.sort((a, b) => b.totalEarned.compareTo(a.totalEarned));
    return results;
  }

  /// 创建奖励配置
  Future<JiveCardReward> createReward({
    required int accountId,
    required String accountName,
    required double rewardRate,
    required String rewardType,
    double? monthlyCapAmount,
  }) async {
    final now = DateTime.now();
    final reward = JiveCardReward()
      ..accountId = accountId
      ..accountName = accountName
      ..rewardRate = rewardRate
      ..rewardType = rewardType
      ..monthlyCapAmount = monthlyCapAmount
      ..lastResetMonth = DateFormat('yyyy-MM').format(now)
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveCardRewards.put(reward);
    });
    return reward;
  }

  /// 更新奖励配置
  Future<void> updateReward(JiveCardReward reward) async {
    reward.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveCardRewards.put(reward);
    });
  }

  /// 删除奖励配置
  Future<void> deleteReward(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveCardRewards.delete(id);
    });
  }
}

class RewardSummary {
  final double totalEarned;
  final double monthEarned;
  final double monthlyRemaining;
  final double rate;
  final String rewardType;

  const RewardSummary({
    required this.totalEarned,
    required this.monthEarned,
    required this.monthlyRemaining,
    required this.rate,
    required this.rewardType,
  });
}
