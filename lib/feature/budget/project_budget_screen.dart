import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/budget_model.dart';
import '../../core/database/project_model.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/project_service.dart';

/// 项目预算管理 — 按项目维度查看/创建预算
class ProjectBudgetScreen extends StatefulWidget {
  const ProjectBudgetScreen({super.key});

  @override
  State<ProjectBudgetScreen> createState() => _ProjectBudgetScreenState();
}

class _ProjectBudgetScreenState extends State<ProjectBudgetScreen> {
  bool _loading = true;
  Isar? _isar;
  List<_ProjectBudgetItem> _items = [];
  double _totalAllocated = 0;
  double _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Isar> _ensureIsar() async {
    return _isar ??= await DatabaseService.getInstance();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = await _ensureIsar();
    final projectService = ProjectService(isar);
    final currencyService = CurrencyService(isar);
    final budgetService = BudgetService(isar, currencyService);

    final projects = await projectService.getActiveProjects();

    // 加载每个项目绑定的预算
    final projectBudgets = await isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .projectIdIsNotNull()
        .findAll();
    final budgetByProject = <int, JiveBudget>{};
    for (final b in projectBudgets) {
      if (b.projectId != null) budgetByProject[b.projectId!] = b;
    }

    final items = <_ProjectBudgetItem>[];
    double totalAllocated = 0;
    double totalSpent = 0;

    for (final project in projects) {
      final budget = budgetByProject[project.id];
      final budgetAmount = budget?.amount ?? project.budget;
      final spent = await projectService.calculateProjectSpending(project.id);

      items.add(_ProjectBudgetItem(
        project: project,
        budget: budget,
        budgetAmount: budgetAmount,
        spent: spent,
      ));

      totalAllocated += budgetAmount;
      totalSpent += spent;
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _totalAllocated = totalAllocated;
      _totalSpent = totalSpent;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('项目预算')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open,
                          size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('暂无项目预算',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.outline)),
                      const SizedBox(height: 8),
                      Text('点击右下角按钮创建项目预算',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(theme),
                      const SizedBox(height: 16),
                      ..._items.map((item) => _buildProjectCard(theme, item)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final remaining = _totalAllocated - _totalSpent;
    final percent =
        _totalAllocated > 0 ? (_totalSpent / _totalAllocated) : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('预算总览',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryTile(
                      theme, '已分配', _totalAllocated, Colors.blue),
                ),
                Expanded(
                  child:
                      _summaryTile(theme, '已支出', _totalSpent, Colors.orange),
                ),
                Expanded(
                  child: _summaryTile(
                    theme,
                    '剩余',
                    remaining,
                    remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                    percent > 1.0 ? Colors.red : Colors.blue),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(
      ThemeData theme, String label, double value, Color color) {
    final formatted = NumberFormat('#,##0.00').format(value.abs());
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value < 0 ? '-$formatted' : formatted,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(ThemeData theme, _ProjectBudgetItem item) {
    final remaining = item.budgetAmount - item.spent;
    final percent =
        item.budgetAmount > 0 ? (item.spent / item.budgetAmount) : 0.0;
    final colorHex = item.project.colorHex;
    final projectColor = colorHex != null && colorHex.isNotEmpty
        ? Color(int.parse(colorHex.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: projectColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.folder, color: projectColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.project.name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (item.project.description != null &&
                          item.project.description!.isNotEmpty)
                        Text(item.project.description!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (item.budget == null)
                  Chip(
                    label: const Text('未绑定预算'),
                    labelStyle: theme.textTheme.labelSmall,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricColumn(theme, '预算',
                    NumberFormat('#,##0').format(item.budgetAmount)),
                _metricColumn(
                    theme, '已用', NumberFormat('#,##0').format(item.spent)),
                _metricColumn(
                  theme,
                  '剩余',
                  NumberFormat('#,##0').format(remaining.abs()),
                  color: remaining >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                    percent > 0.8 ? Colors.red : projectColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.budget != null)
                  Text(
                    '${BudgetPeriod.fromValue(item.budget!.period).label}预算',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  const SizedBox.shrink(),
                Text('${(percent * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricColumn(ThemeData theme, String label, String value,
      {Color? color}) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }

  Future<void> _showCreateDialog() async {
    final isar = await _ensureIsar();
    final projects = await ProjectService(isar).getActiveProjects();
    if (!mounted) return;

    // 过滤掉已经有项目预算的项目
    final existingProjectIds = _items
        .where((i) => i.budget != null)
        .map((i) => i.project.id)
        .toSet();
    final availableProjects =
        projects.where((p) => !existingProjectIds.contains(p.id)).toList();

    if (availableProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有项目已设置预算')),
      );
      return;
    }

    JiveProject? selectedProject = availableProjects.first;
    final amountController = TextEditingController();
    String selectedPeriod = 'monthly';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('创建项目预算'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<JiveProject>(
                  decoration: const InputDecoration(labelText: '选择项目'),
                  initialValue: selectedProject,
                  items: availableProjects
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedProject = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '预算金额',
                    prefixText: '\u00A5 ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '预算周期'),
                  initialValue: selectedPeriod,
                  items: BudgetPeriod.values
                      .where((p) => p != BudgetPeriod.custom)
                      .map((p) => DropdownMenuItem(
                          value: p.value, child: Text(p.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedPeriod = v);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (result == true &&
        selectedProject != null &&
        amountController.text.isNotEmpty) {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) return;

      final period = BudgetPeriod.fromValue(selectedPeriod);
      final (start, end) = BudgetService.getPeriodDateRange(period);

      final currencyService = CurrencyService(isar);
      final budgetService = BudgetService(isar, currencyService);
      await budgetService.createProjectBudget(
        projectId: selectedProject!.id,
        name: '${selectedProject!.name}预算',
        amount: amount,
        currency: 'CNY',
        period: selectedPeriod,
        startDate: start,
        endDate: end,
      );
      await _load();
    }
  }
}

class _ProjectBudgetItem {
  final JiveProject project;
  final JiveBudget? budget;
  final double budgetAmount;
  final double spent;

  _ProjectBudgetItem({
    required this.project,
    required this.budget,
    required this.budgetAmount,
    required this.spent,
  });
}
