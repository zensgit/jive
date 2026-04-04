import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/currency_model.dart';
import '../../core/service/stats_aggregation_service.dart';

/// Monthly income vs expense grouped bar chart.
class IncomeExpenseBarScreen extends StatefulWidget {
  final String? currencyCode;
  final int? bookId;

  const IncomeExpenseBarScreen({super.key, this.currencyCode, this.bookId});

  @override
  State<IncomeExpenseBarScreen> createState() => _IncomeExpenseBarScreenState();
}

class _IncomeExpenseBarScreenState extends State<IncomeExpenseBarScreen> {
  bool _isLoading = true;
  List<MonthTrend> _trends = [];
  int _monthCount = 6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final service = await StatsAggregationService.create();
    final trends = await service.getMonthlyTrend(
      _monthCount,
      currencyCode: widget.currencyCode,
      bookId: widget.bookId,
    );
    if (mounted) {
      setState(() {
        _trends = trends;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final symbol = CurrencyDefaults.getSymbol(widget.currencyCode ?? 'CNY');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildBarChart(symbol),
          const SizedBox(height: 20),
          _buildBalanceCard(symbol),
          const SizedBox(height: 16),
          _buildDataList(symbol),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Text('收支对比', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 6, label: Text('6月')),
            ButtonSegment(value: 12, label: Text('1年')),
          ],
          selected: {_monthCount},
          onSelectionChanged: (v) {
            _monthCount = v.first;
            _load();
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(const Color(0xFF4CAF50), '收入'),
        const SizedBox(width: 20),
        _legendDot(const Color(0xFFEF5350), '支出'),
        const SizedBox(width: 20),
        _legendDot(Colors.grey.shade400, '结余'),
      ],
    );
  }

  Widget _buildBarChart(String symbol) {
    if (_trends.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('暂无数据', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    final maxVal = _trends.fold<double>(0, (prev, t) {
      final m = [t.totalIncome, t.totalExpense].reduce((a, b) => a > b ? a : b);
      return m > prev ? m : prev;
    });

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barGroups: _buildBarGroups(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) => Text(
                  _compactNumber(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _trends.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M月').format(_trends[idx].month),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                final label = rodIdx == 0 ? '收入' : '支出';
                return BarTooltipItem(
                  '$label: $symbol${_formatAmount(rod.toY)}',
                  TextStyle(
                    color: rodIdx == 0 ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_trends.length, (i) {
      final t = _trends[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: t.totalIncome,
            color: const Color(0xFF4CAF50),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: t.totalExpense,
            color: const Color(0xFFEF5350),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Widget _buildBalanceCard(String symbol) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in _trends) {
      totalIncome += t.totalIncome;
      totalExpense += t.totalExpense;
    }
    final balance = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? balance / totalIncome * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: balance >= 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('期间结余', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(
                  '$symbol${_formatAmount(balance)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('储蓄率', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(
                '${savingsRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: savingsRate >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataList(String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('月度明细', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._trends.reversed.map((t) {
          final balance = t.totalIncome - t.totalExpense;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 55,
                  child: Text(
                    DateFormat('yy/MM').format(t.month),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child: Text(
                    '+$symbol${_formatAmount(t.totalIncome)}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4CAF50)),
                  ),
                ),
                Expanded(
                  child: Text(
                    '-$symbol${_formatAmount(t.totalExpense)}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFEF5350)),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$symbol${_formatAmount(balance)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: balance >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 10000) return '${(amount / 10000).toStringAsFixed(1)}万';
    return NumberFormat('#,##0').format(amount);
  }

  String _compactNumber(double value) {
    if (value.abs() >= 10000) return '${(value / 10000).toStringAsFixed(0)}万';
    return NumberFormat('#,##0').format(value);
  }
}
