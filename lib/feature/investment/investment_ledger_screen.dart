import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/investment_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/investment_ledger_service.dart';
import '../../core/service/investment_service.dart';

/// 投资明细账本页面
class InvestmentLedgerScreen extends StatefulWidget {
  final int securityId;
  final int? accountId;

  const InvestmentLedgerScreen({
    super.key,
    required this.securityId,
    this.accountId,
  });

  @override
  State<InvestmentLedgerScreen> createState() => _InvestmentLedgerScreenState();
}

class _InvestmentLedgerScreenState extends State<InvestmentLedgerScreen> {
  late Isar _isar;
  late InvestmentLedgerService _ledgerService;
  late InvestmentService _investmentService;

  bool _isLoading = true;
  JiveSecurity? _security;
  CostBasis? _costBasis;
  double _realizedGain = 0;
  double _marketValue = 0;
  double _unrealizedPL = 0;
  List<JiveInvestmentTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _isar = await DatabaseService.getInstance();
    _ledgerService = InvestmentLedgerService(_isar);
    _investmentService = InvestmentService(_isar);
    await _loadData();
  }

  Future<void> _loadData() async {
    final security = await _isar.jiveSecuritys.get(widget.securityId);
    final txs = await _ledgerService.getInvestmentHistory(
      widget.securityId,
      accountId: widget.accountId,
    );
    final costBasis = _ledgerService.calculateCostBasis(txs);
    final realizedGain = _ledgerService.calculateRealizedGain(txs);

    final currentPrice = security?.latestPrice ?? costBasis.avgCostPerShare;
    final mv = costBasis.totalShares * currentPrice;
    final unrealized = mv - costBasis.totalCost;

    if (!mounted) return;
    setState(() {
      _security = security;
      _costBasis = costBasis;
      _realizedGain = realizedGain;
      _marketValue = mv;
      _unrealizedPL = unrealized;
      _transactions = txs.reversed.toList(); // newest first for display
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_security?.name ?? '...')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(theme, isDark),
                  const SizedBox(height: 16),
                  _buildStatsRow(theme, isDark),
                  const SizedBox(height: 16),
                  _buildActionButtons(theme),
                  const SizedBox(height: 24),
                  _buildTransactionList(theme, isDark),
                ],
              ),
            ),
    );
  }

  // ── Header: security name + ticker + current price ──

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final security = _security;
    if (security == null) return const SizedBox.shrink();

    final price = security.latestPrice;
    final priceText = price != null
        ? '${security.currency} ${price.toStringAsFixed(2)}'
        : '--';

    return Card(
      elevation: 0,
      color: isDark ? JiveTheme.darkCard : JiveTheme.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    security.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: JiveTheme.primaryGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    security.ticker,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: JiveTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  SecurityType.label(security.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (security.exchange != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    security.exchange!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              priceText,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: JiveTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ──

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    final cb = _costBasis;
    if (cb == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: isDark ? JiveTheme.darkCard : JiveTheme.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _statItem(theme, '成本', cb.totalCost),
                _statItem(theme, '市值', _marketValue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statItem(theme, '未实现盈亏', _unrealizedPL, showSign: true),
                _statItem(theme, '已实现盈亏', _realizedGain, showSign: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    ThemeData theme,
    String label,
    double value, {
    bool showSign = false,
  }) {
    Color valueColor = theme.colorScheme.onSurface;
    if (showSign) {
      if (value > 0) {
        valueColor = Colors.red;
      } else if (value < 0) {
        valueColor = JiveTheme.primaryGreen;
      }
    }

    final prefix = showSign && value > 0 ? '+' : '';

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$prefix${value.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ──

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        _actionButton(theme, '买入', Icons.add_circle_outline, Colors.red, () {
          _showBuySellDialog(isBuy: true);
        }),
        const SizedBox(width: 8),
        _actionButton(
          theme,
          '卖出',
          Icons.remove_circle_outline,
          JiveTheme.primaryGreen,
          () {
            _showBuySellDialog(isBuy: false);
          },
        ),
        const SizedBox(width: 8),
        _actionButton(
          theme,
          '分红',
          Icons.monetization_on_outlined,
          Colors.orange,
          _showDividendDialog,
        ),
        const SizedBox(width: 8),
        _actionButton(
          theme,
          '拆股',
          Icons.call_split,
          Colors.blue,
          _showSplitDialog,
        ),
      ],
    );
  }

  Widget _actionButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(100)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // ── Transaction list ──

  Widget _buildTransactionList(ThemeData theme, bool isDark) {
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '暂无交易记录',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '交易记录',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_transactions.length, (i) {
          return _buildTransactionTile(theme, isDark, _transactions[i]);
        }),
      ],
    );
  }

  Widget _buildTransactionTile(
    ThemeData theme,
    bool isDark,
    JiveInvestmentTransaction tx,
  ) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final action = _actionFromString(tx.action);
    final icon = _iconForAction(action);
    final color = _colorForAction(action);

    String subtitle;
    String amountText;

    switch (action) {
      case InvestmentAction.buy:
        subtitle =
            '${tx.quantity.toStringAsFixed(2)} 股 @ ${tx.price.toStringAsFixed(2)}';
        amountText = '-${tx.totalAmount.toStringAsFixed(2)}';
      case InvestmentAction.sell:
        subtitle =
            '${tx.quantity.toStringAsFixed(2)} 股 @ ${tx.price.toStringAsFixed(2)}';
        amountText = '+${tx.totalAmount.toStringAsFixed(2)}';
      case InvestmentAction.dividend:
        subtitle = '现金分红';
        amountText = '+${tx.price.toStringAsFixed(2)}';
      case InvestmentAction.split:
        subtitle = '拆股比例 ${tx.quantity.toStringAsFixed(0)}:1';
        amountText = '--';
      case InvestmentAction.fee:
        subtitle = tx.note ?? '费用';
        amountText = '-${tx.fee.toStringAsFixed(2)}';
    }

    return Card(
      elevation: 0,
      color: isDark ? JiveTheme.darkCard : JiveTheme.cardWhite,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(25),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          action.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${dateFmt.format(tx.transactionDate)}  $subtitle',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          amountText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  InvestmentAction _actionFromString(String action) {
    switch (action) {
      case 'buy':
        return InvestmentAction.buy;
      case 'sell':
        return InvestmentAction.sell;
      case 'dividend':
        return InvestmentAction.dividend;
      case 'split':
        return InvestmentAction.split;
      case 'fee':
        return InvestmentAction.fee;
      default:
        return InvestmentAction.buy;
    }
  }

  IconData _iconForAction(InvestmentAction action) {
    switch (action) {
      case InvestmentAction.buy:
        return Icons.add_circle_outline;
      case InvestmentAction.sell:
        return Icons.remove_circle_outline;
      case InvestmentAction.dividend:
        return Icons.monetization_on_outlined;
      case InvestmentAction.split:
        return Icons.call_split;
      case InvestmentAction.fee:
        return Icons.receipt_long_outlined;
    }
  }

  Color _colorForAction(InvestmentAction action) {
    switch (action) {
      case InvestmentAction.buy:
        return Colors.red;
      case InvestmentAction.sell:
        return JiveTheme.primaryGreen;
      case InvestmentAction.dividend:
        return Colors.orange;
      case InvestmentAction.split:
        return Colors.blue;
      case InvestmentAction.fee:
        return Colors.grey;
    }
  }

  // ── Dialogs ──

  Future<void> _showBuySellDialog({required bool isBuy}) async {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '0');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBuy ? '买入' : '卖出'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '数量'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '单价'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: feeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '手续费'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final qty = double.tryParse(qtyCtrl.text);
    final price = double.tryParse(priceCtrl.text);
    final fee = double.tryParse(feeCtrl.text) ?? 0;

    if (qty == null || qty <= 0 || price == null || price <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入有效的数量和价格')));
      }
      return;
    }

    try {
      await _investmentService.recordTransaction(
        securityId: widget.securityId,
        action: isBuy ? 'buy' : 'sell',
        quantity: qty,
        price: price,
        fee: fee,
        accountId: widget.accountId,
      );
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  Future<void> _showDividendDialog() async {
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('记录分红'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '分红金额'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日期'),
                trailing: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountCtrl.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入有效的分红金额')));
      }
      return;
    }

    try {
      await _ledgerService.recordDividend(
        securityId: widget.securityId,
        amount: amount,
        accountId: widget.accountId,
        date: selectedDate,
      );
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  Future<void> _showSplitDialog() async {
    final ratioCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录拆股'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ratioCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '拆股比例',
                hintText: '例: 2 表示 2:1 拆股',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ratio = double.tryParse(ratioCtrl.text);
    if (ratio == null || ratio <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入有效的拆股比例')));
      }
      return;
    }

    try {
      await _ledgerService.recordSplit(
        securityId: widget.securityId,
        ratio: ratio,
        accountId: widget.accountId,
      );
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }
}
