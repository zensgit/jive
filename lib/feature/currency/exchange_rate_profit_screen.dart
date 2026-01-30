import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/account_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';

/// 汇率损益分析数据
class ExchangeRateProfitLoss {
  final String currency;
  final String currencyName;
  final String? flag;
  final double originalAmount; // 原币种金额
  final double originalRate; // 原汇率（30天前）
  final double currentRate; // 当前汇率
  final double originalValue; // 原价值（主币种）
  final double currentValue; // 当前价值（主币种）
  final double profitLoss; // 盈亏金额
  final double profitLossPercent; // 盈亏百分比

  ExchangeRateProfitLoss({
    required this.currency,
    required this.currencyName,
    this.flag,
    required this.originalAmount,
    required this.originalRate,
    required this.currentRate,
    required this.originalValue,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercent,
  });

  bool get isProfit => profitLoss > 0;
  bool get isLoss => profitLoss < 0;
}

/// 汇率损益分析界面
class ExchangeRateProfitScreen extends StatefulWidget {
  const ExchangeRateProfitScreen({super.key});

  @override
  State<ExchangeRateProfitScreen> createState() => _ExchangeRateProfitScreenState();
}

class _ExchangeRateProfitScreenState extends State<ExchangeRateProfitScreen> {
  bool _isLoading = true;
  String _baseCurrency = 'CNY';
  List<ExchangeRateProfitLoss> _profitLossList = [];
  double _totalProfitLoss = 0;
  int _analysisDays = 30;
  late Isar _isar;
  late CurrencyService _currencyService;
  late AccountService _accountService;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);
    _accountService = AccountService(_isar);

    _baseCurrency = await _currencyService.getBaseCurrency();

    // 获取所有账户和余额
    final accounts = await _accountService.getActiveAccounts();
    final balances = await _accountService.computeBalances(accounts: accounts);

    // 按币种汇总资产
    final currencyAmounts = <String, double>{};
    for (final account in accounts) {
      if (account.isHidden || account.isArchived || !account.includeInBalance) continue;
      if (account.type == 'liability') continue; // 只分析资产

      final currency = account.currency;
      final balance = balances[account.id] ?? account.openingBalance;
      if (balance > 0) {
        currencyAmounts[currency] = (currencyAmounts[currency] ?? 0) + balance;
      }
    }

    // 计算每个非主币种的损益
    final profitLossList = <ExchangeRateProfitLoss>[];
    double totalProfitLoss = 0;

    for (final entry in currencyAmounts.entries) {
      final currency = entry.key;
      final amount = entry.value;

      if (currency == _baseCurrency) continue; // 跳过主币种

      // 获取当前汇率和历史汇率
      final currentRate = await _currencyService.getRate(currency, _baseCurrency);
      final historicalRate = await _currencyService.getHistoricalRate(
        currency,
        _baseCurrency,
        DateTime.now().subtract(Duration(days: _analysisDays)),
      );

      if (currentRate == null) continue;

      final effectiveHistoricalRate = historicalRate ?? currentRate;
      final originalValue = amount * effectiveHistoricalRate;
      final currentValue = amount * currentRate;
      final profitLoss = currentValue - originalValue;
      final profitLossPercent = originalValue > 0
          ? (profitLoss / originalValue * 100)
          : 0.0;

      final currencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
        (c) => c['code'] == currency,
        orElse: () => {'code': currency, 'nameZh': currency},
      );

      profitLossList.add(ExchangeRateProfitLoss(
        currency: currency,
        currencyName: currencyData['nameZh'] as String,
        flag: currencyData['flag'] as String?,
        originalAmount: amount,
        originalRate: effectiveHistoricalRate,
        currentRate: currentRate,
        originalValue: originalValue,
        currentValue: currentValue,
        profitLoss: profitLoss,
        profitLossPercent: profitLossPercent,
      ));

      totalProfitLoss += profitLoss;
    }

    // 按盈亏金额排序
    profitLossList.sort((a, b) => b.profitLoss.abs().compareTo(a.profitLoss.abs()));

    if (mounted) {
      setState(() {
        _profitLossList = profitLossList;
        _totalProfitLoss = totalProfitLoss;
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
        title: const Text('汇率损益分析'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (days) {
              setState(() => _analysisDays = days);
              _loadData();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 7, child: Text('近7天${_analysisDays == 7 ? ' ✓' : ''}')),
              PopupMenuItem(value: 30, child: Text('近30天${_analysisDays == 30 ? ' ✓' : ''}')),
              PopupMenuItem(value: 90, child: Text('近90天${_analysisDays == 90 ? ' ✓' : ''}')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _profitLossList.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 总损益卡片
                        _buildSummaryCard(symbol),
                        const SizedBox(height: 20),

                        // 分析说明
                        _buildInfoCard(),
                        const SizedBox(height: 16),

                        // 各币种损益
                        Text(
                          '各币种损益明细',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._profitLossList.map((item) => _buildProfitLossCard(item, symbol)),
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
          Icon(Icons.trending_flat, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无外币资产',
            style: GoogleFonts.lato(
              fontSize: 18,
              color: JiveTheme.secondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加外币账户后可查看汇率损益',
            style: TextStyle(color: JiveTheme.secondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String symbol) {
    final isProfit = _totalProfitLoss >= 0;
    final color = isProfit ? JiveTheme.primaryGreen : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [JiveTheme.primaryGreen, const Color(0xFF388E3C)]
              : [Colors.red.shade600, Colors.red.shade800],
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
              Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '近$_analysisDays天汇率${isProfit ? '收益' : '损失'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${isProfit ? '+' : ''}$symbol ${_formatAmount(_totalProfitLoss)}',
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '基于 ${_profitLossList.length} 种外币资产计算',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '损益计算基于$_analysisDays天前的汇率与当前汇率对比，仅供参考',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossCard(ExchangeRateProfitLoss item, String baseSymbol) {
    final color = item.isProfit
        ? JiveTheme.primaryGreen
        : item.isLoss
            ? Colors.red
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.flag ?? item.currency, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.currency,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        item.currencyName,
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
                      '${item.isProfit ? '+' : ''}$baseSymbol ${_formatAmount(item.profitLoss)}',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${item.isProfit ? '+' : ''}${item.profitLossPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRateInfo(
                    '持有金额',
                    '${_getCurrencySymbol(item.currency)} ${_formatAmount(item.originalAmount)}',
                  ),
                ),
                Expanded(
                  child: _buildRateInfo(
                    '$_analysisDays天前汇率',
                    item.originalRate.toStringAsFixed(4),
                  ),
                ),
                Expanded(
                  child: _buildRateInfo(
                    '当前汇率',
                    item.currentRate.toStringAsFixed(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: JiveTheme.secondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbol(String code) {
    final data = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'symbol': code},
    );
    return data['symbol'] as String;
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
      (match) => '${match[1]},',
    );
  }
}
