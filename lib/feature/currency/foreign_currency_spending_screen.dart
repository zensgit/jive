import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/database/account_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/currency_spending_analytics_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';

/// 外币消费趋势界面
class ForeignCurrencySpendingScreen extends StatefulWidget {
  const ForeignCurrencySpendingScreen({super.key});

  @override
  State<ForeignCurrencySpendingScreen> createState() =>
      _ForeignCurrencySpendingScreenState();
}

class _ForeignCurrencySpendingScreenState
    extends State<ForeignCurrencySpendingScreen> {
  bool _isLoading = true;
  String _baseCurrency = 'CNY';
  List<CurrencySpendingData> _spendingData = [];
  double _totalConvertedSpending = 0;
  int _selectedMonths = 6;
  late Isar _isar;
  late CurrencyService _currencyService;
  final CurrencySpendingAnalyticsService _spendingAnalyticsService =
      const CurrencySpendingAnalyticsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);
    _baseCurrency = await _currencyService.getBaseCurrency();
    final accounts = await _isar.jiveAccounts.where().findAll();
    final accountById = <int, JiveAccount>{
      for (final account in accounts) account.id: account,
    };

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - _selectedMonths + 1, 1);

    // 获取指定时间范围内的支出交易
    final transactions = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampGreaterThan(startDate)
        .findAll();

    final analytics = await _spendingAnalyticsService.buildSpendingData(
      transactions: transactions,
      accountById: accountById,
      baseCurrency: _baseCurrency,
      selectedMonths: _selectedMonths,
      now: now,
      converter: _currencyService.convert,
    );

    if (mounted) {
      setState(() {
        _spendingData = analytics.spendingByCurrency;
        _totalConvertedSpending = analytics.totalConvertedSpending;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseCurrencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == _baseCurrency,
      orElse: () => {'symbol': '¥'},
    );
    final symbol = baseCurrencyData['symbol'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('消费趋势'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (months) {
              setState(() => _selectedMonths = months);
              _loadData();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 3,
                child: Text('近3个月${_selectedMonths == 3 ? ' ✓' : ''}'),
              ),
              PopupMenuItem(
                value: 6,
                child: Text('近6个月${_selectedMonths == 6 ? ' ✓' : ''}'),
              ),
              PopupMenuItem(
                value: 12,
                child: Text('近12个月${_selectedMonths == 12 ? ' ✓' : ''}'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _spendingData.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 总消费卡片
                        _buildSummaryCard(symbol),
                        const SizedBox(height: 20),

                        // 各币种消费
                        Text(
                          '各币种消费明细',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._spendingData.map(
                          (item) => _buildSpendingCard(item, symbol),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无消费数据',
            style: GoogleFonts.lato(
              fontSize: 18,
              color: JiveTheme.secondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String symbol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                '近$_selectedMonths个月总消费',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$symbol ${_formatAmount(_totalConvertedSpending)}',
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '涉及 ${_spendingData.length} 种货币',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingCard(CurrencySpendingData item, String baseSymbol) {
    final maxMonthlyAmount = item.monthlyData
        .map((m) => m.amount)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item.flag ?? item.currency,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.currency} - ${item.currencyName}',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${item.transactionCount} 笔交易',
                        style: TextStyle(
                          fontSize: 12,
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.symbol} ${_formatAmount(item.totalAmount)}',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.currency != _baseCurrency)
                      Text(
                        '≈ $baseSymbol ${_formatAmount(item.convertedAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 月度趋势图
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: item.monthlyData.map((monthly) {
                  final height = maxMonthlyAmount > 0
                      ? (monthly.amount / maxMonthlyAmount * 50).clamp(
                          4.0,
                          50.0,
                        )
                      : 4.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: JiveTheme.primaryGreen.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('M月').format(monthly.month),
                            style: TextStyle(
                              fontSize: 9,
                              color: JiveTheme.secondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (match) => '${match[1]},',
        );
  }
}
