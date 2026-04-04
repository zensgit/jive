import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/book_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/book_service.dart';
import '../../core/service/database_service.dart';

/// Per-book statistics comparison screen.
class BookStatsScreen extends StatefulWidget {
  const BookStatsScreen({super.key});

  @override
  State<BookStatsScreen> createState() => _BookStatsScreenState();
}

class _BookStatsScreenState extends State<BookStatsScreen> {
  bool _isLoading = true;
  List<_BookStat> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final isar = await DatabaseService.getInstance();
    final bookService = BookService(isar);
    final books = await bookService.getActiveBooks();
    final accountService = AccountService(isar);

    final stats = <_BookStat>[];
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (final book in books) {
      // Get accounts for this book
      final accounts = await accountService.getActiveAccounts(bookId: book.id);
      final balances = await accountService.computeBalances(accounts: accounts);
      final totals = accountService.calculateTotals(accounts, balances);

      // Get this month's transactions
      final txs = await isar.jiveTransactions
          .filter()
          .bookIdEqualTo(book.id)
          .timestampGreaterThan(monthStart)
          .findAll();

      double monthIncome = 0;
      double monthExpense = 0;
      int txCount = txs.length;

      for (final tx in txs) {
        final type = tx.type ?? 'expense';
        if (type == 'income') monthIncome += tx.amount;
        if (type == 'expense') monthExpense += tx.amount;
      }

      stats.add(_BookStat(
        book: book,
        assets: totals.assets,
        liabilities: totals.liabilities,
        netWorth: totals.assets - totals.liabilities,
        monthIncome: monthIncome,
        monthExpense: monthExpense,
        transactionCount: txCount,
        accountCount: accounts.length,
      ));
    }

    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('账本统计', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? Center(child: Text('暂无账本', style: TextStyle(color: Colors.grey.shade500)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildComparisonChart(),
        const SizedBox(height: 16),
        ..._stats.map(_buildBookCard),
      ],
    );
  }

  Widget _buildComparisonChart() {
    if (_stats.length < 2) return const SizedBox.shrink();

    final maxVal = _stats.fold<double>(0, (prev, s) {
      final m = s.netWorth.abs();
      return m > prev ? m : prev;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('净资产对比', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.3,
                minY: 0,
                barGroups: _stats.asMap().entries.map((e) {
                  final color = e.value.netWorth >= 0 ? const Color(0xFF4CAF50) : Colors.red;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.netWorth.abs(),
                        color: color,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _stats.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _stats[idx].book.name,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
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
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(_BookStat stat) {
    final symbol = CurrencyDefaults.getSymbol(stat.book.currency);
    final netColor = stat.netWorth >= 0 ? const Color(0xFF2E7D32) : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (stat.book.isDefault)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('默认', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
                ),
              Expanded(
                child: Text(
                  stat.book.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Text(
                '${stat.accountCount}个账户 · ${stat.transactionCount}笔',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCell('净资产', '$symbol${_formatAmount(stat.netWorth)}', netColor)),
              Expanded(child: _statCell('资产', '$symbol${_formatAmount(stat.assets)}', Colors.blue)),
              Expanded(child: _statCell('负债', '$symbol${_formatAmount(stat.liabilities)}', Colors.red.shade300)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCell('本月收入', '+$symbol${_formatAmount(stat.monthIncome)}', const Color(0xFF4CAF50)),
              ),
              Expanded(
                child: _statCell('本月支出', '-$symbol${_formatAmount(stat.monthExpense)}', const Color(0xFFEF5350)),
              ),
              Expanded(
                child: _statCell(
                  '本月结余',
                  '$symbol${_formatAmount(stat.monthIncome - stat.monthExpense)}',
                  stat.monthIncome >= stat.monthExpense ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
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

class _BookStat {
  final JiveBook book;
  final double assets;
  final double liabilities;
  final double netWorth;
  final double monthIncome;
  final double monthExpense;
  final int transactionCount;
  final int accountCount;

  const _BookStat({
    required this.book,
    required this.assets,
    required this.liabilities,
    required this.netWorth,
    required this.monthIncome,
    required this.monthExpense,
    required this.transactionCount,
    required this.accountCount,
  });
}
