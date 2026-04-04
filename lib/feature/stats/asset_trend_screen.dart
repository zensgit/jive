import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/currency_model.dart';
import '../../core/service/stats_aggregation_service.dart';

/// Asset trend chart showing net worth, assets, and liabilities over time.
class AssetTrendScreen extends StatefulWidget {
  final String? currencyCode;
  final int? bookId;

  const AssetTrendScreen({super.key, this.currencyCode, this.bookId});

  @override
  State<AssetTrendScreen> createState() => _AssetTrendScreenState();
}

class _AssetTrendScreenState extends State<AssetTrendScreen> {
  bool _isLoading = true;
  List<AssetTrendPoint> _points = [];
  int _monthCount = 6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final service = await StatsAggregationService.create();
    final points = await service.getAssetTrend(_monthCount, bookId: widget.bookId);
    if (mounted) {
      setState(() {
        _points = points;
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
          const SizedBox(height: 20),
          _buildSummaryCards(symbol),
          const SizedBox(height: 20),
          _buildChart(symbol),
          const SizedBox(height: 20),
          _buildDataTable(symbol),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Text('资产趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3月')),
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
            textStyle: WidgetStatePropertyAll(
              const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(String symbol) {
    if (_points.isEmpty) return const SizedBox.shrink();
    final latest = _points.last;
    final first = _points.first;
    final change = latest.netWorth - first.netWorth;
    final changePercent = first.netWorth != 0 ? change / first.netWorth.abs() * 100 : 0.0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: '当前净资产',
            value: '$symbol${_formatAmount(latest.netWorth)}',
            valueColor: latest.netWorth >= 0 ? const Color(0xFF2E7D32) : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '期间变化',
            value: '${change >= 0 ? '+' : ''}$symbol${_formatAmount(change)}',
            subtitle: '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
            valueColor: change >= 0 ? const Color(0xFF2E7D32) : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(String symbol) {
    if (_points.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('数据不足，至少需要2个月', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    final netWorthSpots = <FlSpot>[];
    final assetSpots = <FlSpot>[];
    final liabilitySpots = <FlSpot>[];

    for (int i = 0; i < _points.length; i++) {
      netWorthSpots.add(FlSpot(i.toDouble(), _points[i].netWorth));
      assetSpots.add(FlSpot(i.toDouble(), _points[i].assets));
      liabilitySpots.add(FlSpot(i.toDouble(), _points[i].liabilities));
    }

    final allValues = _points.expand((p) => [p.netWorth, p.assets, p.liabilities]);
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.1 : 1000;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : 1000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 55,
                getTitlesWidget: (value, meta) => Text(
                  _compactNumber(value),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M月').format(_points[idx].date),
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
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            _lineBarData(netWorthSpots, const Color(0xFF2E7D32), '净资产'),
            _lineBarData(assetSpots, Colors.blue, '资产', dashed: true),
            _lineBarData(liabilitySpots, Colors.red.shade300, '负债', dashed: true),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final color = spot.bar.color ?? Colors.grey;
                return LineTooltipItem(
                  '$symbol${_formatAmount(spot.y)}',
                  TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineBarData(List<FlSpot> spots, Color color, String label, {bool dashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: dashed ? 1.5 : 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: dashed ? null : BarAreaData(
        show: true,
        color: color.withAlpha(25),
      ),
      dashArray: dashed ? [5, 5] : null,
    );
  }

  Widget _buildDataTable(String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('详细数据', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        // Legend
        Row(
          children: [
            _legendDot(const Color(0xFF2E7D32), '净资产'),
            const SizedBox(width: 16),
            _legendDot(Colors.blue, '资产'),
            const SizedBox(width: 16),
            _legendDot(Colors.red.shade300, '负债'),
          ],
        ),
        const SizedBox(height: 12),
        ..._points.reversed.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  DateFormat('yy/MM').format(p.date),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: Text(
                  '$symbol${_formatAmount(p.netWorth)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.netWorth >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '$symbol${_formatAmount(p.assets)}',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '$symbol${_formatAmount(p.liabilities)}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade300),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 100000000) return '${(amount / 100000000).toStringAsFixed(1)}亿';
    if (amount.abs() >= 10000) return '${(amount / 10000).toStringAsFixed(1)}万';
    return NumberFormat('#,##0.00').format(amount);
  }

  String _compactNumber(double value) {
    if (value.abs() >= 100000000) return '${(value / 100000000).toStringAsFixed(1)}亿';
    if (value.abs() >= 10000) return '${(value / 10000).toStringAsFixed(0)}万';
    return NumberFormat('#,##0').format(value);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 12, color: valueColor.withAlpha(180))),
          ],
        ],
      ),
    );
  }
}
