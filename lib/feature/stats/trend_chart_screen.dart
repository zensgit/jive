import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/currency_model.dart';
import '../../core/service/stats_aggregation_service.dart';

class TrendChartScreen extends StatefulWidget {
  final String? currencyCode;
  final int? bookId;
  const TrendChartScreen({super.key, this.currencyCode, this.bookId});

  @override
  State<TrendChartScreen> createState() => _TrendChartScreenState();
}

class _TrendChartScreenState extends State<TrendChartScreen> {
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
    final trends = await service.getMonthlyTrend(_monthCount, currencyCode: widget.currencyCode, bookId: widget.bookId);
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
          // Period selector
          Row(
            children: [
              Text('趋势分析', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ToggleButtons(
                isSelected: [_monthCount == 6, _monthCount == 12],
                onPressed: (i) {
                  _monthCount = i == 0 ? 6 : 12;
                  _load();
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 56),
                textStyle: const TextStyle(fontSize: 13),
                children: const [Text('6个月'), Text('12个月')],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Line chart
          SizedBox(
            height: 260,
            child: _trends.isEmpty
                ? Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey.shade400)))
                : _buildLineChart(symbol),
          ),
          const SizedBox(height: 24),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.redAccent, '支出'),
              const SizedBox(width: 24),
              _legendDot(Colors.green, '收入'),
            ],
          ),
          const SizedBox(height: 24),

          // Data table
          ..._trends.reversed.map((t) => _buildTrendRow(t, symbol)),
        ],
      ),
    );
  }

  Widget _buildLineChart(String symbol) {
    final maxY = _trends.fold<double>(0, (m, t) {
      final v = t.totalExpense > t.totalIncome ? t.totalExpense : t.totalIncome;
      return v > m ? v : m;
    });
    final ceiling = maxY > 0 ? maxY * 1.2 : 1000.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: ceiling / 4,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 0.8),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compact().format(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _trends.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('M月').format(_trends[idx].month),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: ceiling,
        lineBarsData: [
          // Expense
          LineChartBarData(
            spots: List.generate(_trends.length, (i) => FlSpot(i.toDouble(), _trends[i].totalExpense)),
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) =>
                  FlDotCirclePainter(radius: 3, color: Colors.redAccent, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(show: true, color: Colors.redAccent.withValues(alpha: 0.08)),
          ),
          // Income
          LineChartBarData(
            spots: List.generate(_trends.length, (i) => FlSpot(i.toDouble(), _trends[i].totalIncome)),
            isCurved: true,
            color: Colors.green,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) =>
                  FlDotCirclePainter(radius: 3, color: Colors.green, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.08)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final color = s.barIndex == 0 ? Colors.redAccent : Colors.green;
              final label = s.barIndex == 0 ? '支出' : '收入';
              return LineTooltipItem(
                '$label: $symbol${NumberFormat.compact().format(s.y)}',
                TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildTrendRow(MonthTrend t, String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(DateFormat('M月').format(t.month), style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: Row(
              children: [
                Text('收 $symbol${NumberFormat.compact().format(t.totalIncome)}',
                    style: const TextStyle(color: Colors.green, fontSize: 13)),
                const SizedBox(width: 16),
                Text('支 $symbol${NumberFormat.compact().format(t.totalExpense)}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ),
          ),
          Text(
            '${t.totalIncome >= t.totalExpense ? "+" : ""}$symbol${NumberFormat.compact().format(t.totalIncome - t.totalExpense)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: t.totalIncome >= t.totalExpense ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
