import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/budget_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';

/// Budget progress visualization with ring charts.
class BudgetProgressScreen extends StatefulWidget {
  final int? bookId;

  const BudgetProgressScreen({super.key, this.bookId});

  @override
  State<BudgetProgressScreen> createState() => _BudgetProgressScreenState();
}

class _BudgetProgressScreenState extends State<BudgetProgressScreen> {
  bool _isLoading = true;
  List<BudgetSummary> _summaries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    final service = BudgetService(isar, cs);
    final summaries = await service.getAllBudgetSummaries(bookId: widget.bookId);
    if (mounted) {
      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_summaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('暂无活跃预算', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text('在预算管理中添加预算后，这里会显示进度', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('预算进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildOverallProgress(),
          const SizedBox(height: 20),
          const Text('分项预算', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._summaries.map(_buildBudgetCard),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    double totalBudget = 0;
    double totalUsed = 0;
    for (final s in _summaries) {
      totalBudget += s.effectiveAmount;
      totalUsed += s.usedAmount;
    }
    final percent = totalBudget > 0 ? totalUsed / totalBudget : 0.0;
    final color = percent > 1.0
        ? Colors.red
        : percent > 0.8
            ? Colors.orange
            : const Color(0xFF2E7D32);
    final currency = _summaries.isNotEmpty ? _summaries.first.budget.currency : 'CNY';
    final symbol = CurrencyDefaults.getSymbol(currency);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: percent.clamp(0, 1) * 100,
                    color: color,
                    radius: 18,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: ((1 - percent).clamp(0, 1)) * 100,
                    color: Colors.grey.shade200,
                    radius: 14,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  '已使用 $symbol${_formatAmount(totalUsed)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                Text(
                  '总预算 $symbol${_formatAmount(totalBudget)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                if (totalBudget > totalUsed) ...[
                  const SizedBox(height: 4),
                  Text(
                    '剩余 $symbol${_formatAmount(totalBudget - totalUsed)}',
                    style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetSummary summary) {
    final b = summary.budget;
    final percent = summary.usedPercent / 100;
    final color = summary.isOverBudget
        ? Colors.red
        : summary.isWarning
            ? Colors.orange
            : const Color(0xFF2E7D32);
    final symbol = CurrencyDefaults.getSymbol(b.currency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.name.isNotEmpty ? b.name : (b.categoryKey ?? '总预算'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Text(
                '${summary.daysRemaining}天',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$symbol${_formatAmount(summary.usedAmount)} / $symbol${_formatAmount(summary.effectiveAmount)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 10000) return '${(amount / 10000).toStringAsFixed(1)}万';
    return NumberFormat('#,##0').format(amount);
  }
}
