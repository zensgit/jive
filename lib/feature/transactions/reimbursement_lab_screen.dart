import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/bill_relation_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/repository/isar_transaction_repository.dart';
import '../../core/repository/transaction_repository.dart';
import '../../core/service/database_service.dart';
import '../../core/service/reimbursement_service.dart';

class ReimbursementLabScreen extends StatefulWidget {
  const ReimbursementLabScreen({super.key});

  @override
  State<ReimbursementLabScreen> createState() => _ReimbursementLabScreenState();
}

class _ReimbursementLabScreenState extends State<ReimbursementLabScreen> {
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  Isar? _isar;
  ReimbursementService? _service;
  bool _loading = true;
  List<JiveTransaction> _sourceTransactions = [];
  Map<int, BillSettlementSummary> _summaryBySource = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = _isar ?? await DatabaseService.getInstance();
    final service = ReimbursementService(isar);
    final TransactionRepository txRepo = IsarTransactionRepository(isar);
    final all = await txRepo.getAll();
    final source = all.where((tx) {
      final type = (tx.type ?? 'expense').trim();
      return type == 'expense' || type == 'income';
    }).toList();
    source.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final trimmed = source.take(80).toList();

    final summaries = <int, BillSettlementSummary>{};
    for (final tx in trimmed) {
      summaries[tx.id] = await service.getSettlementSummary(tx.id);
    }

    if (!mounted) return;
    setState(() {
      _isar = isar;
      _service = service;
      _sourceTransactions = trimmed;
      _summaryBySource = summaries;
      _loading = false;
    });
  }

  Future<void> _createByType(
    JiveTransaction source,
    BillRelationType relationType,
  ) async {
    final controller = TextEditingController(
      text: source.amount.toStringAsFixed(2),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          relationType == BillRelationType.reimbursement ? '创建报销' : '创建退款',
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: '金额'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final amount = double.tryParse(controller.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }
    final service = _service;
    if (service == null) return;
    try {
      if (relationType == BillRelationType.reimbursement) {
        await service.createReimbursement(
          sourceTransactionId: source.id,
          amount: amount,
          accountId: source.accountId,
        );
      } else {
        await service.createRefund(
          sourceTransactionId: source.id,
          amount: amount,
          accountId: source.accountId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            relationType == BillRelationType.reimbursement
                ? '报销记录已生成'
                : '退款记录已生成',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败：$e')));
    }
  }

  Widget _buildSourceTile(JiveTransaction tx) {
    final summary = _summaryBySource[tx.id];
    final type = (tx.type ?? 'expense').trim();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${tx.id} · ${_dateTimeFormat.format(tx.timestamp)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${type == 'income' ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: type == 'income' ? Colors.green : Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '类型：$type  账户：${tx.accountId ?? '--'}  分类：${tx.categoryKey ?? '--'}',
            ),
            if (summary != null) ...[
              const SizedBox(height: 4),
              Text(
                '报销 ${summary.reimbursementCount}笔 / ${summary.reimbursementTotal.toStringAsFixed(2)}'
                ' · 退款 ${summary.refundCount}笔 / ${summary.refundTotal.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _createByType(tx, BillRelationType.reimbursement),
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                  ),
                  label: const Text('报销'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _createByType(tx, BillRelationType.refund),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('退款'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报销退款工作台')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sourceTransactions.isEmpty
          ? const Center(child: Text('暂无可操作账单'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: _sourceTransactions.length,
                itemBuilder: (context, index) =>
                    _buildSourceTile(_sourceTransactions[index]),
              ),
            ),
    );
  }
}
