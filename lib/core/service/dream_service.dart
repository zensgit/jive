import 'package:isar/isar.dart';

import '../database/dream_log_model.dart';
import '../database/savings_goal_model.dart';

/// Statistics for a single savings goal.
class GoalStats {
  final double totalDeposits;
  final double avgMonthlyDeposit;
  final DateTime? projectedCompletionDate;

  const GoalStats({
    required this.totalDeposits,
    required this.avgMonthlyDeposit,
    this.projectedCompletionDate,
  });
}

/// Aggregated summary across all active savings goals.
class DreamSummary {
  final double totalSaved;
  final double totalTarget;
  final double overallProgressPercent;

  const DreamSummary({
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgressPercent,
  });
}

class DreamService {
  final Isar _isar;

  DreamService(this._isar);

  /// Add a deposit (or withdrawal when [amount] is negative) to a goal and
  /// create an accompanying log entry.
  Future<void> addDeposit({
    required int goalId,
    required double amount,
    String note = '',
  }) async {
    await _isar.writeTxn(() async {
      final goal = await _isar.jiveSavingsGoals.get(goalId);
      if (goal == null) return;

      goal
        ..currentAmount = goal.currentAmount + amount
        ..updatedAt = DateTime.now();
      await _isar.jiveSavingsGoals.put(goal);

      final log = JiveDreamLog()
        ..goalId = goalId
        ..amount = amount
        ..note = note
        ..createdAt = DateTime.now();
      await _isar.jiveDreamLogs.put(log);
    });
  }

  /// Return all deposit logs for [goalId], newest first.
  Future<List<JiveDreamLog>> getDepositHistory(int goalId) async {
    return _isar.jiveDreamLogs
        .filter()
        .goalIdEqualTo(goalId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Compute stats for a single goal.
  Future<GoalStats> getGoalStats(int goalId) async {
    final logs = await _isar.jiveDreamLogs
        .filter()
        .goalIdEqualTo(goalId)
        .sortByCreatedAt()
        .findAll();

    final totalDeposits =
        logs.fold<double>(0, (sum, l) => sum + (l.amount > 0 ? l.amount : 0));

    double avgMonthly = 0;
    DateTime? projectedDate;

    if (logs.isNotEmpty) {
      final earliest = logs.first.createdAt;
      final now = DateTime.now();
      final monthsElapsed =
          now.difference(earliest).inDays / 30.44; // avg days per month
      if (monthsElapsed > 0) {
        avgMonthly = totalDeposits / monthsElapsed;
      }

      final goal = await _isar.jiveSavingsGoals.get(goalId);
      if (goal != null && avgMonthly > 0) {
        final remaining = goal.targetAmount - goal.currentAmount;
        if (remaining > 0) {
          final monthsLeft = remaining / avgMonthly;
          projectedDate =
              now.add(Duration(days: (monthsLeft * 30.44).ceil()));
        } else {
          // Already achieved.
          projectedDate = now;
        }
      }
    }

    return GoalStats(
      totalDeposits: totalDeposits,
      avgMonthlyDeposit: avgMonthly,
      projectedCompletionDate: projectedDate,
    );
  }

  /// Aggregate summary across all active goals.
  Future<DreamSummary> getDreamSummary() async {
    final goals = await _isar.jiveSavingsGoals
        .filter()
        .statusEqualTo('active')
        .findAll();

    double totalSaved = 0;
    double totalTarget = 0;
    for (final g in goals) {
      totalSaved += g.currentAmount;
      totalTarget += g.targetAmount;
    }

    final progress = totalTarget > 0 ? (totalSaved / totalTarget * 100) : 0.0;

    return DreamSummary(
      totalSaved: totalSaved,
      totalTarget: totalTarget,
      overallProgressPercent: progress,
    );
  }
}
