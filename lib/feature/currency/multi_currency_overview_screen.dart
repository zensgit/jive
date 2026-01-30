import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import '../../core/database/account_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/account_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';

/// 多币种资产总览界面
class MultiCurrencyOverviewScreen extends StatefulWidget {
  const MultiCurrencyOverviewScreen({super.key});

  @override
  State<MultiCurrencyOverviewScreen> createState() => _MultiCurrencyOverviewScreenState();
}

class _MultiCurrencyOverviewScreenState extends State<MultiCurrencyOverviewScreen> {
  bool _isLoading = true;
  MultiCurrencyAssetOverview? _overview;
  late Isar _isar;
  late CurrencyService _currencyService;
  late AccountService _accountService;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);
    _accountService = AccountService(_isar);

    // 获取所有账户和余额
    final accounts = await _accountService.getActiveAccounts();
    final balances = await _accountService.computeBalances(accounts: accounts);

    // 计算多币种资产总览
    final overview = await _currencyService.calculateMultiCurrencyOverview(
      accounts,
      balances,
      null, // 使用默认主币种
    );

    if (mounted) {
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('资产总览')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_overview == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('资产总览')),
        body: const Center(child: Text('无法加载数据')),
      );
    }

    final overview = _overview!;
    final baseCurrencyData = _getCurrencyData(overview.baseCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('资产总览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总资产卡片
              _buildSummaryCard(overview, baseCurrencyData),
              const SizedBox(height: 20),

              // 资产分布
              if (overview.assetGroups.isNotEmpty) ...[
                _buildSectionTitle('资产分布', Icons.account_balance_wallet),
                const SizedBox(height: 12),
                _buildCurrencyPieChart(overview.assetGroups, overview.totalAssets),
                const SizedBox(height: 12),
                ...overview.assetGroups.map((group) => _buildCurrencyGroupCard(
                  group,
                  overview.totalAssets,
                  isLiability: false,
                )),
                const SizedBox(height: 20),
              ],

              // 负债分布
              if (overview.liabilityGroups.isNotEmpty) ...[
                _buildSectionTitle('负债分布', Icons.credit_card),
                const SizedBox(height: 12),
                ...overview.liabilityGroups.map((group) => _buildCurrencyGroupCard(
                  group,
                  overview.totalLiabilities,
                  isLiability: true,
                )),
                const SizedBox(height: 20),
              ],

              // 汇率说明
              _buildRateInfoCard(overview),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MultiCurrencyAssetOverview overview, Map<String, dynamic> baseCurrencyData) {
    final symbol = baseCurrencyData['symbol'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [JiveTheme.primaryGreen, Color(0xFF388E3C)],
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
              Text(
                baseCurrencyData['flag'] as String? ?? '💰',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                '以 ${overview.baseCurrency} 计',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '净资产',
            style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '$symbol ${_formatNumber(overview.netWorth)}',
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '总资产',
                  '$symbol ${_formatNumber(overview.totalAssets)}',
                  Colors.white,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildSummaryItem(
                  '总负债',
                  '$symbol ${_formatNumber(overview.totalLiabilities)}',
                  Colors.red.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.rubik(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: JiveTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: JiveTheme.textColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyPieChart(List<CurrencyAssetGroup> groups, double total) {
    if (groups.isEmpty || total <= 0) return const SizedBox();

    // 简化的饼图显示
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: groups.map((group) {
          final percentage = group.percentageOf(total);
          if (percentage < 1) return const SizedBox();
          return Expanded(
            flex: percentage.round().clamp(1, 100),
            child: Container(
              color: _getCurrencyColor(group.currency),
              child: Center(
                child: percentage >= 10
                    ? Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrencyGroupCard(
    CurrencyAssetGroup group,
    double total,
    {required bool isLiability}
  ) {
    final percentage = group.percentageOf(total);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Text(group.flag ?? group.currency, style: const TextStyle(fontSize: 24)),
        title: Row(
          children: [
            Text(
              group.currency,
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              group.currencyName,
              style: TextStyle(
                fontSize: 13,
                color: JiveTheme.secondaryTextColor(context),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${group.symbol} ${_formatNumber(group.totalAmount)} • ${group.accountCount} 个账户',
          style: TextStyle(
            fontSize: 12,
            color: JiveTheme.secondaryTextColor(context),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: GoogleFonts.rubik(
                fontWeight: FontWeight.bold,
                color: isLiability ? Colors.red : JiveTheme.primaryGreen,
              ),
            ),
            if (group.currency != _overview!.baseCurrency)
              Text(
                '≈ ¥${_formatNumber(group.convertedAmount)}',
                style: TextStyle(
                  fontSize: 11,
                  color: JiveTheme.secondaryTextColor(context),
                ),
              ),
          ],
        ),
        children: group.accounts.map((account) => ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade100,
            child: Text(
              account.accountName.isNotEmpty ? account.accountName[0] : '?',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          title: Text(account.accountName, style: const TextStyle(fontSize: 14)),
          trailing: Text(
            '${group.symbol} ${_formatNumber(account.balance)}',
            style: GoogleFonts.rubik(fontSize: 13),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildRateInfoCard(MultiCurrencyAssetOverview overview) {
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
              '数据基于当前汇率换算，仅供参考',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCurrencyData(String code) {
    return CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'code': code, 'nameZh': code, 'symbol': code, 'flag': null},
    );
  }

  Color _getCurrencyColor(String code) {
    final colors = {
      'CNY': const Color(0xFFE53935),
      'USD': const Color(0xFF43A047),
      'EUR': const Color(0xFF1E88E5),
      'GBP': const Color(0xFF8E24AA),
      'JPY': const Color(0xFFE91E63),
      'HKD': const Color(0xFFFF9800),
      'TWD': const Color(0xFF00BCD4),
      'SGD': const Color(0xFF795548),
      'KRW': const Color(0xFF3F51B5),
      'AUD': const Color(0xFFFFC107),
    };
    return colors[code] ?? Colors.grey;
  }

  String _formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    }
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
      (match) => '${match[1]},',
    );
  }
}
