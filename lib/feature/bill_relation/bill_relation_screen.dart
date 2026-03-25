import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/bill_relation_model.dart';
import '../../core/database/transaction_model.dart';

/// 报销 & 退款管理页面
class BillRelationScreen extends StatefulWidget {
  const BillRelationScreen({super.key});

  @override
  State<BillRelationScreen> createState() => _BillRelationScreenState();
}

class _BillRelationScreenState extends State<BillRelationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<JiveBillRelation> _reimbursement = [];
  List<JiveBillRelation> _refund = [];
  Map<int, JiveTransaction> _txCache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = Isar.getInstance()!;
    final all = await isar.collection<JiveBillRelation>().where().findAll();

    final txIds = <int>{};
    for (final r in all) {
      if (r.sourceTransactionId != 0) txIds.add(r.sourceTransactionId);
      if (r.linkedTransactionId != 0) txIds.add(r.linkedTransactionId);
    }

    final txs = txIds.isEmpty
        ? <JiveTransaction>[]
        : await isar.collection<JiveTransaction>()
            .filter()
            .anyOf(txIds.toList(), (q, id) => q.idEqualTo(id))
            .findAll();

    if (mounted) {
      setState(() {
        _reimbursement = all
            .where((r) => r.relationType == BillRelationType.reimbursement.value)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _refund = all
            .where((r) => r.relationType == BillRelationType.refund.value)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _txCache = {for (final tx in txs) tx.id: tx};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingReimburse =
        _reimbursement.where((r) => !r.isSettled).fold<double>(0, (s, r) => s + r.amount);
    final pendingRefund =
        _refund.where((r) => !r.isSettled).fold<double>(0, (s, r) => s + r.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('报销 & 退款'),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('报销'),
                  if (pendingReimburse > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('¥${pendingReimburse.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('退款'),
                  if (pendingRefund > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('¥${pendingRefund.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_reimbursement, type: BillRelationType.reimbursement.value),
                _buildList(_refund, type: BillRelationType.refund.value),
              ],
            ),
    );
  }

  Widget _buildList(List<JiveBillRelation> items, {required String type}) {
    final isReimburse = type == BillRelationType.reimbursement.value;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isReimburse ? Icons.receipt_long_outlined : Icons.undo_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isReimburse ? '没有报销记录' : '没有退款记录',
              style: GoogleFonts.lato(
                  fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isReimburse ? '记录公司报销，追踪待收款项' : '记录退款，关联原始消费',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showAddDialog(type: type),
              icon: const Icon(Icons.add),
              label: Text(isReimburse ? '新建报销' : '新建退款'),
            ),
          ],
        ),
      );
    }

    // Group by settled status
    final pending = items.where((r) => !r.isSettled).toList();
    final settled = items.where((r) => r.isSettled).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _SectionHeader(
            title: '待处理 (${pending.length})',
            color: isReimburse ? Colors.blue.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(height: 8),
          for (final item in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RelationCard(
                relation: item,
                txCache: _txCache,
                onMarkSettled: () => _markSettled(item),
                onDelete: () => _delete(item),
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (settled.isNotEmpty) ...[
          _SectionHeader(title: '已结清 (${settled.length})', color: Colors.grey),
          const SizedBox(height: 8),
          for (final item in settled)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RelationCard(
                relation: item,
                txCache: _txCache,
                onMarkSettled: () => _markSettled(item),
                onDelete: () => _delete(item),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _markSettled(JiveBillRelation r) async {
    r.isSettled = true;
    r.settledAt = DateTime.now();
    r.updatedAt = DateTime.now();
    await Isar.getInstance()!.writeTxn(() async {
      await Isar.getInstance()!.collection<JiveBillRelation>().put(r);
    });
    _load();
  }

  Future<void> _delete(JiveBillRelation r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除此记录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Isar.getInstance()!.writeTxn(() async {
        await Isar.getInstance()!.collection<JiveBillRelation>().delete(r.id);
      });
      _load();
    }
  }

  Future<void> _showAddDialog({String type = 'reimbursement'}) async {
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedType = type;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          title: const Text('新建记录'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'reimbursement', label: Text('报销')),
                    ButtonSegment(value: 'refund', label: Text('退款')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) => setLS(() => selectedType = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '金额 *',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    border: OutlineInputBorder(),
                    hintText: '公司报销 / 商品退款...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    final relation = JiveBillRelation()
      ..relationType = selectedType
      ..sourceTransactionId = 0
      ..linkedTransactionId = 0
      ..amount = amount
      ..currency = 'CNY'
      ..note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()
      ..isSettled = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await Isar.getInstance()!.writeTxn(() async {
      await Isar.getInstance()!.collection<JiveBillRelation>().put(relation);
    });
    _load();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}

class _RelationCard extends StatelessWidget {
  const _RelationCard({
    required this.relation,
    required this.txCache,
    required this.onMarkSettled,
    required this.onDelete,
  });

  final JiveBillRelation relation;
  final Map<int, JiveTransaction> txCache;
  final VoidCallback onMarkSettled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isReimburse = relation.relationType == BillRelationType.reimbursement.value;
    final color = isReimburse ? Colors.blue.shade700 : Colors.orange.shade700;
    final sourceTx = relation.sourceTransactionId != 0
        ? txCache[relation.sourceTransactionId]
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: relation.isSettled ? Colors.grey.shade200 : color.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: relation.isSettled ? Colors.grey.shade100 : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReimburse ? Icons.receipt_long : Icons.undo,
                size: 18,
                color: relation.isSettled ? Colors.grey : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isReimburse ? '报销' : '退款',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: relation.isSettled ? Colors.grey.shade500 : color,
                            fontSize: 14),
                      ),
                      if (relation.isSettled) ...[
                        const SizedBox(width: 6),
                        Text('已结清',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ],
                  ),
                  if (sourceTx != null)
                    Text(
                      sourceTx.note ?? sourceTx.category ?? '关联交易',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  if (relation.note != null)
                    Text(relation.note!,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    relation.isSettled && relation.settledAt != null
                        ? '结清于 ${DateFormat('MM/dd').format(relation.settledAt!)}'
                        : DateFormat('yyyy/MM/dd').format(relation.createdAt),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${relation.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: relation.isSettled ? Colors.grey : color,
                      fontSize: 15),
                ),
                if (!relation.isSettled) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onMarkSettled,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('结清',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade400),
              onSelected: (v) { if (v == 'delete') onDelete(); },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

