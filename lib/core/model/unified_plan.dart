/// The type of plan aggregated in the unified plan hub.
enum PlanType { budget, goal, recurring, travel, installment }

/// The current status of a plan.
enum PlanStatus { active, completed, exceeded, paused }

/// A pure-Dart view model that provides a unified representation of all
/// plan-like entities (budgets, savings goals, recurring rules, travel trips).
class UnifiedPlan {
  final String id;
  final String name;
  final PlanType type;
  final String? emoji;
  final double? targetAmount;
  final double? limitAmount;
  final double currentAmount;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;
  final PlanStatus status;

  /// Progress percentage from 0 to 100.
  final double progressPercent;

  const UnifiedPlan({
    required this.id,
    required this.name,
    required this.type,
    this.emoji,
    this.targetAmount,
    this.limitAmount,
    required this.currentAmount,
    this.period,
    this.startDate,
    this.endDate,
    required this.status,
    required this.progressPercent,
  });

  @override
  String toString() =>
      'UnifiedPlan($id, $name, type=$type, status=$status, '
      'progress=$progressPercent%)';
}
