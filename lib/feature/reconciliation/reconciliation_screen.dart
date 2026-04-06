import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/reconciliation_service.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  late Isar _isar;
  late ReconciliationService _service;
  bool _isLoading = true;

  List<JiveAccount> _creditCards = [];
  JiveAccount? _selectedAccount;
  DateTime _billingStart = DateTime.now();
  DateTime _billingEnd = DateTime.now();

  List<JiveTransaction> _transactions = [];
  Set<int> _reconciledIds = {};
  ReconciliationSummary? _summary;
  bool _isSettled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    _service = ReconciliationService(_isar);

    // 加载信用卡账户
    final accounts = await _isar.jiveAccounts
        .filter()
        .subTypeEqualTo('credit_card')
        .findAll();

    if (!mounted) return;
    setState(() {
      _creditCards = accounts;
      _isLoading = false;
    });

    if (accounts.isNotEmpty) {
      _selectAccount(accounts.first);
    }
  }

  void _selectAccount(JiveAccount account) {
    _selectedAccount = account;
    _computeBillingPeriod(account, 0); // current month
    _loadTransactions();
  }

  void _computeBillingPeriod(JiveAccount account, int monthOffset) {
    final billingDay = account.billingDay ?? 1;
    final now = DateTime.now();
    final baseMonth = DateTime(now.year, now.month + monthOffset, 1);

    _billingStart = DateTime(baseMonth.year, baseMonth.month, billingDay);
    // 如果 billingDay 是 1，则 end 是下月 1 日前一天
    final nextMonth = DateTime(baseMonth.year, baseMonth.month + 1, billingDay);
    _billingEnd = nextMonth.subtract(const Duration(seconds: 1));
  }

  Future<void> _loadTransactions() async {
    if (_selectedAccount == null) return;

    setState(() => _isLoading = true);

    final txs = await _isar.jiveTransactions
        .filter()
        .accountIdEqualTo(_selectedAccount!.id)
        .timestampBetween(_billingStart, _billingEnd)
        .sortByTimestamp()
        .findAll();

    final reconciled = <int>{};
    for (final tx in txs) {
      if (tx.note != null && tx.note!.contains('[reconciled]')) {
        reconciled.add(tx.id);
      }
    }

    final summary = await _service.getReconciliationSummary(
      _selectedAccount!.id,
      _billingStart,
      _billingEnd,
    );

    final settled = await _service.isPeriodSettled(
      _selectedAccount!.id,
      _billingStart,
      _billingEnd,
    );

    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _reconciledIds = reconciled;
      _summary = summary;
      _isSettled = settled;
      _isLoading = false;
    });
  }

  Future<void> _toggleReconciled(JiveTransaction tx) async {
    if (_isSettled) return;
    final id = tx.id;
    if (_reconciledIds.contains(id)) {
      await _service.unmarkReconciled([id]);
      _reconciledIds.remove(id);
    } else {
      await _service.markReconciled([id]);
      _reconciledIds.add(id);
    }
    // reload summary
    final summary = await _service.getReconciliationSummary(
      _selectedAccount!.id,
      _billingStart,
      _billingEnd,
    );
    if (!mounted) return;
    setState(() => _summary = summary);
  }

  Future<void> _confirmSettlement() async {
    if (_selectedAccount == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认结算'),
        content: Text(
          _summary != null && _summary!.unreconciledCount > 0
              ? '还有 ${_summary!.unreconciledCount} 笔未对账交易，'
                  '差额 ${_summary!.difference.toStringAsFixed(2)}。\n确认结算本期账单？'
              : '所有交易已对账。确认结算本期账单？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认结算'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.confirmSettlement(
        _selectedAccount!.id,
        _billingStart,
        _billingEnd,
      );
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('账期已结算')),
        );
      }
    }
  }

  void _switchPeriod(int offset) {
    if (_selectedAccount == null) return;
    _computeBillingPeriod(_selectedAccount!, offset);
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单对账'),
      ),
      body: _isLoading && _creditCards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _creditCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.credit_card_off,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('暂无信用卡账户',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Account picker
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedAccount?.id,
                        decoration: const InputDecoration(
                          labelText: '信用卡',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _creditCards
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final acc =
                              _creditCards.firstWhere((a) => a.id == id);
                          _selectAccount(acc);
                        },
                      ),
                    ),
                    // Billing period selector
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _switchPeriod(-1),
                          ),
                          Expanded(
                            child: Text(
                              '${DateFormat('MM/dd').format(_billingStart)} - '
                              '${DateFormat('MM/dd').format(_billingEnd)}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _switchPeriod(1),
                          ),
                        ],
                      ),
                    ),
                    // Summary bar
                    if (_summary != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSettled
                              ? Colors.green.withValues(alpha: 0.08)
                              : _summary!.difference > 0
                                  ? Colors.orange.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '已对账 ${_summary!.reconciledCount}/${_summary!.totalTransactions}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '对账额 ${_summary!.reconciledAmount.toStringAsFixed(2)}'
                                    ' / 总额 ${_summary!.totalAmount.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (_summary!.difference > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '差额 ${_summary!.difference.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (_isSettled)
                              const Chip(
                                label: Text('已结算',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.green)),
                                backgroundColor:
                                    Color(0x1A4CAF50), // green 10%
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Transaction list
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _transactions.isEmpty
                              ? Center(
                                  child: Text('本期暂无交易',
                                      style:
                                          TextStyle(color: Colors.grey[500])),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 80),
                                  itemCount: _transactions.length,
                                  itemBuilder: (ctx, i) {
                                    final tx = _transactions[i];
                                    final checked =
                                        _reconciledIds.contains(tx.id);
                                    return CheckboxListTile(
                                      value: checked,
                                      onChanged: _isSettled
                                          ? null
                                          : (_) => _toggleReconciled(tx),
                                      secondary: Icon(
                                        checked
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: checked
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      title: Text(
                                        '${tx.category ?? '未分类'}  '
                                        '${tx.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        '${DateFormat('MM-dd HH:mm').format(tx.timestamp)}'
                                        '${tx.note != null && tx.note!.isNotEmpty ? '  ${tx.note!.replaceAll('[reconciled]', '').replaceAll(RegExp(r'\[settled:[^\]]*\]'), '').trim()}' : ''}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      dense: true,
                                    );
                                  },
                                ),
                    ),
                    // Confirm button
                    if (!_isSettled && _transactions.isNotEmpty)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _confirmSettlement,
                              icon: const Icon(Icons.done_all),
                              label: const Text('确认结算'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
