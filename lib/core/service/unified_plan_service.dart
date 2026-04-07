import 'dart:math';

import 'package:isar/isar.dart';

import '../database/budget_model.dart';
import '../database/recurring_rule_model.dart';
import '../database/savings_goal_model.dart';
import '../database/travel_trip_model.dart';
import '../model/unified_plan.dart';
import 'budget_service.dart';
import 'currency_service.dart';

/// Aggregates all plan-like entities into a single [UnifiedPlan] list.
class UnifiedPlanService {
  final Isar _isar;
  final BudgetService _budgetService;

  UnifiedPlanService(this._isar, this._budgetService);

  /// Factory that creates the service with default dependencies.
  factory UnifiedPlanService.create(Isar isar, CurrencyService cs) {
    return UnifiedPlanService(isar, BudgetService(isar, cs));
  }

  /// Returns all plan-like objects mapped to [UnifiedPlan], sorted with active
  /// plans first and then grouped by type.
  Future<List<UnifiedPlan>> getAllPlans() async {
    final plans = <UnifiedPlan>[];

    plans.addAll(await _budgetPlans());
    plans.addAll(await _goalPlans());
    plans.addAll(await _recurringPlans());
    plans.addAll(await _travelPlans());

    // Sort: active first, then by type ordinal.
    plans.sort((a, b) {
      final aActive = a.status == PlanStatus.active ? 0 : 1;
      final bActive = b.status == PlanStatus.active ? 0 : 1;
      final cmp = aActive.compareTo(bActive);
      if (cmp != 0) return cmp;
      return a.type.index.compareTo(b.type.index);
    });

    return plans;
  }

  // ---------------------------------------------------------------------------
  // Budget
  // ---------------------------------------------------------------------------

  Future<List<UnifiedPlan>> _budgetPlans() async {
    final summaries = await _budgetService.getAllBudgetSummaries();
    return summaries.map((s) {
      final b = s.budget;
      final PlanStatus status;
      if (s.status == BudgetStatus.exceeded) {
        status = PlanStatus.exceeded;
      } else if (!b.isActive) {
        status = PlanStatus.paused;
      } else {
        status = PlanStatus.active;
      }

      return UnifiedPlan(
        id: 'budget_${b.id}',
        name: b.name,
        type: PlanType.budget,
        emoji: '\u{1F4B0}', // 💰
        limitAmount: s.effectiveAmount,
        currentAmount: s.usedAmount,
        period: b.period,
        startDate: b.startDate,
        endDate: b.endDate,
        status: status,
        progressPercent: s.usedPercent.clamp(0, 100),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Savings Goal
  // ---------------------------------------------------------------------------

  Future<List<UnifiedPlan>> _goalPlans() async {
    final goals = await _isar.jiveSavingsGoals
        .filter()
        .statusEqualTo('active')
        .findAll();

    return goals.map((g) {
      final progress = g.targetAmount > 0
          ? (g.currentAmount / g.targetAmount * 100)
          : 0.0;

      final PlanStatus status;
      if (g.currentAmount >= g.targetAmount && g.targetAmount > 0) {
        status = PlanStatus.completed;
      } else {
        status = PlanStatus.active;
      }

      return UnifiedPlan(
        id: 'goal_${g.id}',
        name: g.name,
        type: PlanType.goal,
        emoji: g.emoji ?? '\u{1F3AF}', // 🎯
        targetAmount: g.targetAmount,
        currentAmount: g.currentAmount,
        startDate: g.createdAt,
        endDate: g.deadline,
        status: status,
        progressPercent: min(progress, 100),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Recurring Rule
  // ---------------------------------------------------------------------------

  Future<List<UnifiedPlan>> _recurringPlans() async {
    final rules = await _isar.jiveRecurringRules
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    return rules.map((r) {
      return UnifiedPlan(
        id: 'recurring_${r.id}',
        name: r.name,
        type: PlanType.recurring,
        emoji: '\u{1F504}', // 🔄
        targetAmount: r.amount,
        currentAmount: r.amount,
        period: r.intervalType,
        startDate: r.startDate,
        endDate: r.endDate,
        status: PlanStatus.active,
        // Recurring rules are always "on track" while active.
        progressPercent: 100,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Travel Trip
  // ---------------------------------------------------------------------------

  Future<List<UnifiedPlan>> _travelPlans() async {
    final trips = await _isar.jiveTravelTrips
        .filter()
        .group((q) => q
            .statusEqualTo('active')
            .or()
            .statusEqualTo('planning'))
        .findAll();

    return trips.map((t) {
      final PlanStatus status;
      if (t.status == 'completed' || t.status == 'reviewed') {
        status = PlanStatus.completed;
      } else {
        status = PlanStatus.active;
      }

      // Progress: we don't have spent amount without querying transactions,
      // so show 0 for planning trips, 50 for active.
      final progress = t.status == 'active' ? 50.0 : 0.0;

      return UnifiedPlan(
        id: 'travel_${t.id}',
        name: t.name,
        type: PlanType.travel,
        emoji: '\u{2708}\u{FE0F}', // ✈️
        limitAmount: t.budget,
        currentAmount: 0,
        startDate: t.startDate,
        endDate: t.endDate,
        status: status,
        progressPercent: progress,
      );
    }).toList();
  }
}
