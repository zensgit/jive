import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/database/account_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';

/// 换汇费用记录
class ExchangeFeeRecord {
  final JiveTransaction transaction;
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double exchangeRate;
  final double fee;
  final String feeType;

  ExchangeFeeRecord({
    required this.transaction,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.exchangeRate,
    required this.fee,
    required this.feeType,
  });
}

/// 换汇费用统计界面
class ExchangeFeeTrackingScreen extends StatefulWidget {
  const ExchangeFeeTrackingScreen({super.key});

  @override
  State<ExchangeFeeTrackingScreen> createState() => _ExchangeFeeTrackingScreenState();
}

class _ExchangeFeeTrackingScreenState extends State<ExchangeFeeTrackingScreen> {
  bool _isLoading = true;
  List<ExchangeFeeRecord> _feeRecords = [];
  double _totalFees = 0;
  int _selectedMonths = 12;
  late Isar _isar;
  Map<int, JiveAccount> _accountMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _isar = await DatabaseService.getInstance();

    // 加载账户映射
    final accounts = await _isar.jiveAccounts.where().findAll();
    _accountMap = {for (final a in accounts) a.id: a};

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - _selectedMonths + 1, 1);

    // 获取有换汇费用的交易
    final transactions = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('transfer')
        .exchangeFeeIsNotNull()
        .exchangeFeeGreaterThan(0)
        .timestampGreaterThan(startDate)
        .sortByTimestampDesc()
        .findAll();

    final feeRecords = <ExchangeFeeRecord>[];
    double totalFees = 0;

    for (final tx in transactions) {
      final fromAccount = _accountMap[tx.accountId];
      final toAccount = _accountMap[tx.toAccountId];

      if (fromAccount == null || toAccount == null) continue;

      feeRecords.add(ExchangeFeeRecord(
        transaction: tx,
        fromCurrency: fromAccount.currency,
        toCurrency: toAccount.currency,
        fromAmount: tx.amount,
        toAmount: tx.toAmount ?? 0,
        exchangeRate: tx.exchangeRate ?? 0,
        fee: tx.exchangeFee ?? 0,
        feeType: tx.exchangeFeeType ?? 'fixed',
      ));

      totalFees += tx.exchangeFee ?? 0;
    }

    if (mounted) {
      setState(() {
        _feeRecords = feeRecords;
        _totalFees = totalFees;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('换汇手续费'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (months) {
              setState(() => _selectedMonths = months);
              _loadData();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 3, child: Text('近3个月${_selectedMonths == 3 ? ' ✓' : ''}')),
              PopupMenuItem(value: 6, child: Text('近6个月${_selectedMonths == 6 ? ' ✓' : ''}')),
              PopupMenuItem(value: 12, child: Text('近12个月${_selectedMonths == 12 ? ' ✓' : ''}')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _feeRecords.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 总费用卡片
                        _buildSummaryCard(),
                        const SizedBox(height: 20),

                        // 说明
                        _buildInfoCard(),
                        const SizedBox(height: 16),

                        // 费用记录列表
                        Text(
                          '手续费记录',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._feeRecords.map(_buildFeeCard),
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
            '暂无换汇手续费记录',
            style: GoogleFonts.lato(
              fontSize: 18,
              color: JiveTheme.secondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '跨币种转账时可记录手续费',
            style: TextStyle(color: JiveTheme.secondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
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
              const Icon(Icons.account_balance, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                '近$_selectedMonths个月换汇费用',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¥ ${_formatAmount(_totalFees)}',
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '共 ${_feeRecords.length} 笔换汇交易',
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '在跨币种转账时可选择记录换汇手续费',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(ExchangeFeeRecord record) {
    final tx = record.transaction;
    final fromData = _getCurrencyData(record.fromCurrency);
    final toData = _getCurrencyData(record.toCurrency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 币种转换
                Text(fromData['flag'] as String? ?? record.fromCurrency,
                    style: const TextStyle(fontSize: 20)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                Text(toData['flag'] as String? ?? record.toCurrency,
                    style: const TextStyle(fontSize: 20)),
                const Spacer(),
                // 手续费
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '费用: ¥${record.fee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    '转出',
                    '${fromData['symbol']} ${_formatAmount(record.fromAmount)}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    '转入',
                    '${toData['symbol']} ${_formatAmount(record.toAmount)}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    '汇率',
                    record.exchangeRate.toStringAsFixed(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(tx.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: JiveTheme.secondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
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

  Map<String, dynamic> _getCurrencyData(String code) {
    return CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'code': code, 'symbol': code},
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
      (match) => '${match[1]},',
    );
  }
}
