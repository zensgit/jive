import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/service/investment_service.dart';

/// Pie chart showing portfolio allocation by security type.
class PortfolioChartWidget extends StatelessWidget {
  final PortfolioSummary portfolio;

  const PortfolioChartWidget({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    if (portfolio.holdings.isEmpty) return const SizedBox.shrink();

    final byType = <String, double>{};
    for (final h in portfolio.holdings) {
      final type = h.security.type;
      byType[type] = (byType[type] ?? 0) + h.marketValueInBase;
    }

    if (byType.isEmpty || byType.values.every((v) => v <= 0)) {
      return const SizedBox.shrink();
    }

    final total = byType.values.fold<double>(0, (a, b) => a + b);
    final entries = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('持仓分布', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: entries.asMap().entries.map((e) {
                      final pct = e.value.value / total * 100;
                      return PieChartSectionData(
                        value: e.value.value,
                        color: _typeColor(e.value.key, e.key),
                        radius: 22,
                        showTitle: pct > 8,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) {
                    final pct = e.value.value / total * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _typeColor(e.value.key, e.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _typeLabel(e.value.key),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type, int index) {
    const colors = [
      Color(0xFF2196F3), // stock - blue
      Color(0xFF4CAF50), // fund - green
      Color(0xFFFF9800), // bond - orange
      Color(0xFF9C27B0), // crypto - purple
      Color(0xFF607D8B), // other - grey
    ];
    switch (type) {
      case 'stock': return colors[0];
      case 'fund': return colors[1];
      case 'bond': return colors[2];
      case 'crypto': return colors[3];
      default: return colors[index % colors.length];
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'stock': return '股票';
      case 'fund': return '基金';
      case 'bond': return '债券';
      case 'crypto': return '加密货币';
      default: return '其他';
    }
  }
}
