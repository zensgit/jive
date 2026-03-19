import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/currency_model.dart';
import '../../core/service/stats_aggregation_service.dart';

class MonthlyOverviewScreen extends StatefulWidget {
  final String? currencyCode;
  const MonthlyOverviewScreen({super.key, this.currencyCode});

  @override
  State<MonthlyOverviewScreen> createState() => _MonthlyOverviewScreenState();
}

class _MonthlyOverviewScreenState extends State<MonthlyOverviewScreen> {
  bool _isLoading = true;
  MonthComparison? _comparison;
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final service = await StatsAggregationService.create();
    final comparison = await service.getMonthComparison(
      _currentMonth,
      currencyCode: widget.currencyCode,
    );
    if (mounted) {
      setState(() {
        _comparison = comparison;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final c = _comparison!;
    final symbol = CurrencyDefaults.getSymbol(widget.currencyCode ?? 'CNY');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          _buildMonthSelector(),
          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: [
              Expanded(child: _buildSummaryCard('收入', c.current.totalIncome, symbol, Colors.green, c.incomeChangePercent)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('支出', c.current.totalExpense, symbol, Colors.redAccent, c.expenseChangePercent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSimpleCard('结余', c.current.balance, symbol, c.current.balance >= 0 ? Colors.green : Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildSimpleCard('日均支出', c.current.dailyAverage, symbol, Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),

          // Extra info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本月详情', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _buildDetailRow('交易笔数', '${c.current.transactionCount} 笔'),
                _buildDetailRow('月天数', '${c.current.daysInMonth} 天'),
                const Divider(height: 20),
                Text('上月对比', style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                _buildDetailRow('上月收入', '$symbol${_fmt(c.previous.totalIncome)}'),
                _buildDetailRow('上月支出', '$symbol${_fmt(c.previous.totalExpense)}'),
                _buildDetailRow('上月交易', '${c.previous.transactionCount} 笔'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final label = DateFormat('yyyy年M月').format(_currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
        Text(label, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, double amount, String symbol, Color color, double changePercent) {
    final isUp = changePercent > 0;
    final changeText = changePercent == 0
        ? '与上月持平'
        : '${isUp ? "↑" : "↓"} ${changePercent.abs().toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '$symbol${_fmt(amount)}',
            style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(changeText, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSimpleCard(String label, double amount, String symbol, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '$symbol${_fmt(amount)}',
            style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  String _fmt(double v) => NumberFormat.compact().format(v);
}
