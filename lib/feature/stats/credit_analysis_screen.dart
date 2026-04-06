import 'package:flutter/material.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/credit_analysis_service.dart';
import '../../core/service/database_service.dart';

/// Screen showing credit-card utilization and payment-rate analysis.
class CreditAnalysisScreen extends StatefulWidget {
  const CreditAnalysisScreen({super.key});

  @override
  State<CreditAnalysisScreen> createState() => _CreditAnalysisScreenState();
}

class _CreditAnalysisScreenState extends State<CreditAnalysisScreen> {
  bool _isLoading = true;
  List<CreditAnalysis> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isar = await DatabaseService.getInstance();
    final svc = CreditAnalysisService(isar);
    final cards = await svc.getAllCreditAnalysis();
    if (mounted) setState(() { _cards = cards; _isLoading = false; });
  }

  double get _totalUtilization {
    double totalBalance = 0;
    double totalLimit = 0;
    for (final c in _cards) {
      totalBalance += c.currentBalance.abs();
      totalLimit += c.creditLimit;
    }
    return totalLimit > 0 ? (totalBalance / totalLimit).clamp(0.0, 1.0) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('信用卡分析'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('暂无信用卡数据'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTotalCard(),
                    const SizedBox(height: 16),
                    ..._cards.map(_buildCardTile),
                  ],
                ),
    );
  }

  Widget _buildTotalCard() {
    final pct = (_totalUtilization * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('总信用额度使用率', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          _GaugeBar(rate: _totalUtilization),
          const SizedBox(height: 8),
          Text('$pct%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCardTile(CreditAnalysis card) {
    final utilPct = (card.utilizationRate * 100).toStringAsFixed(1);
    final payPct = (card.paymentRate * 100).toStringAsFixed(0);
    final color = card.utilizationRate > 0.8
        ? Colors.red
        : card.utilizationRate > 0.5
            ? Colors.orange
            : JiveTheme.primaryGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.accountName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text('$utilPct%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          _GaugeBar(rate: card.utilizationRate),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricChip(label: '额度', value: '\u00a5${card.creditLimit.toStringAsFixed(0)}'),
              const SizedBox(width: 12),
              _MetricChip(label: '月均消费', value: '\u00a5${card.avgMonthlySpend.toStringAsFixed(0)}'),
              const SizedBox(width: 12),
              _MetricChip(label: '还款率', value: '$payPct%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugeBar extends StatelessWidget {
  final double rate;
  const _GaugeBar({required this.rate});

  @override
  Widget build(BuildContext context) {
    final color = rate > 0.8
        ? Colors.red
        : rate > 0.5
            ? Colors.orange
            : JiveTheme.primaryGreen;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: rate.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
