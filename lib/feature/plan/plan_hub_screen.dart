import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/model/unified_plan.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/unified_plan_service.dart';
import '../budget/budget_manager_screen.dart';
import '../recurring/recurring_rule_list_screen.dart';
import '../savings/savings_goal_screen.dart';
import '../travel/travel_screen.dart';

/// Unified hub screen that aggregates all plan-like objects (budgets, savings
/// goals, recurring rules, travel trips) into a single scrollable list.
class PlanHubScreen extends StatefulWidget {
  const PlanHubScreen({super.key});

  @override
  State<PlanHubScreen> createState() => _PlanHubScreenState();
}

class _PlanHubScreenState extends State<PlanHubScreen> {
  List<UnifiedPlan> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final isar = Isar.getInstance()!;
      final cs = CurrencyService(isar);
      final service = UnifiedPlanService.create(isar, cs);
      final plans = await service.getAllPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('计划中心')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(theme),
                      const SizedBox(height: 16),
                      ..._buildGroupedSections(theme),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard(ThemeData theme) {
    final active = _plans.where((p) => p.status == PlanStatus.active).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '全部计划',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '共 ${_plans.length} 项，$active 项进行中',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.event_note, size: 40, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grouped sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildGroupedSections(ThemeData theme) {
    final groups = <PlanType, List<UnifiedPlan>>{};
    for (final p in _plans) {
      groups.putIfAbsent(p.type, () => []).add(p);
    }

    final widgets = <Widget>[];
    for (final type in PlanType.values) {
      final items = groups[type];
      if (items == null || items.isEmpty) continue;
      widgets.add(_buildSectionHeader(type, theme));
      for (final plan in items) {
        widgets.add(_buildPlanCard(plan, theme));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  Widget _buildSectionHeader(PlanType type, ThemeData theme) {
    final label = switch (type) {
      PlanType.budget => '\u{1F4B0} 预算',
      PlanType.goal => '\u{1F3AF} 目标',
      PlanType.recurring => '\u{1F504} 定期',
      PlanType.travel => '\u{2708}\u{FE0F} 旅行',
      PlanType.installment => '\u{1F4B3} 分期',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label, style: theme.textTheme.titleSmall),
    );
  }

  // ---------------------------------------------------------------------------
  // Plan card
  // ---------------------------------------------------------------------------

  Widget _buildPlanCard(UnifiedPlan plan, ThemeData theme) {
    final statusColor = switch (plan.status) {
      PlanStatus.active => Colors.green,
      PlanStatus.completed => Colors.blue,
      PlanStatus.exceeded => Colors.red,
      PlanStatus.paused => Colors.grey,
    };
    final statusLabel = switch (plan.status) {
      PlanStatus.active => '进行中',
      PlanStatus.completed => '已完成',
      PlanStatus.exceeded => '已超额',
      PlanStatus.paused => '已暂停',
    };

    final amountText = _amountText(plan);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(plan),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (plan.emoji != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(plan.emoji!, style: const TextStyle(fontSize: 20)),
                    ),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11),
                    ),
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (plan.progressPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: statusColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(amountText, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  String _amountText(UnifiedPlan plan) {
    if (plan.targetAmount != null) {
      return '${plan.currentAmount.toStringAsFixed(0)} / '
          '${plan.targetAmount!.toStringAsFixed(0)}';
    }
    if (plan.limitAmount != null) {
      return '${plan.currentAmount.toStringAsFixed(0)} / '
          '${plan.limitAmount!.toStringAsFixed(0)}';
    }
    return plan.currentAmount.toStringAsFixed(0);
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _navigateToDetail(UnifiedPlan plan) {
    final Widget screen = switch (plan.type) {
      PlanType.budget => const BudgetManagerScreen(),
      PlanType.goal => const SavingsGoalScreen(),
      PlanType.recurring => const RecurringRuleListScreen(),
      PlanType.travel => const TravelScreen(),
      PlanType.installment => const BudgetManagerScreen(), // fallback
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _loadPlans());
  }

  // ---------------------------------------------------------------------------
  // FAB create sheet
  // ---------------------------------------------------------------------------

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('创建新计划', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Text('\u{1F4B0}', style: TextStyle(fontSize: 24)),
              title: const Text('预算'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetManagerScreen()))
                    .then((_) => _loadPlans());
              },
            ),
            ListTile(
              leading: const Text('\u{1F3AF}', style: TextStyle(fontSize: 24)),
              title: const Text('储蓄目标'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalScreen()))
                    .then((_) => _loadPlans());
              },
            ),
            ListTile(
              leading: const Text('\u{1F504}', style: TextStyle(fontSize: 24)),
              title: const Text('定期记账'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringRuleListScreen()))
                    .then((_) => _loadPlans());
              },
            ),
            ListTile(
              leading: const Text('\u{2708}\u{FE0F}', style: TextStyle(fontSize: 24)),
              title: const Text('旅行'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelScreen()))
                    .then((_) => _loadPlans());
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('暂无计划', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('点击右下角 + 创建新计划', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
