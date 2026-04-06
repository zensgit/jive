import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/receivable_model.dart';
import '../../core/service/receivable_service.dart';
import '../../core/service/database_service.dart';

class ReceivableScreen extends StatefulWidget {
  const ReceivableScreen({super.key});

  @override
  State<ReceivableScreen> createState() => _ReceivableScreenState();
}

class _ReceivableScreenState extends State<ReceivableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Isar _isar;
  late ReceivableService _service;
  bool _isLoading = true;
  List<JiveReceivable> _receivables = [];
  List<JiveReceivable> _payables = [];
  ReceivableSummary? _summary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    _service = ReceivableService(_isar);
    await _load();
  }

  Future<void> _load() async {
    final receivables = await _service.getByType(ReceivableType.receivable);
    final payables = await _service.getByType(ReceivableType.payable);
    final summary = await _service.getSummary();
    if (!mounted) return;
    setState(() {
      _receivables = receivables;
      _payables = payables;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    final typeCtrl = ValueNotifier<String>(ReceivableType.receivable);
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? dueDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          title: const Text('新建应收/应付'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: typeCtrl,
                  builder: (_, type, __) => SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: ReceivableType.receivable,
                        label: Text('应收'),
                      ),
                      ButtonSegment(
                        value: ReceivableType.payable,
                        label: Text('应付'),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) => typeCtrl.value = s.first,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '对方姓名 *',
                    border: OutlineInputBorder(),
                  ),
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
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dueDate != null
                      ? '到期日: ${DateFormat('yyyy-MM-dd').format(dueDate!)}'
                      : '设置到期日（可选）'),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLS(() => dueDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0 || nameCtrl.text.trim().isEmpty) return;

    await _service.create(
      personName: nameCtrl.text,
      amount: amount,
      type: typeCtrl.value,
      dueDate: dueDate,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    nameCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
    typeCtrl.dispose();
    await _load();
  }

  Future<void> _recordPayment(JiveReceivable item) async {
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('记录付款 — ${item.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('剩余: ¥${item.remainingAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '付款金额',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
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
    if (ok != true || !mounted) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    amountCtrl.dispose();
    if (amount <= 0) return;

    await _service.recordPayment(item.id, amount);
    await _load();
  }

  Future<void> _markBadDebt(JiveReceivable item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('标记坏账'),
        content: Text('确定将「${item.personName}」的欠款标记为坏账？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.markBadDebt(item.id);
    if (mounted) await _load();
  }

  String _statusLabel(String status) {
    switch (status) {
      case ReceivableStatus.pending:
        return '待结算';
      case ReceivableStatus.partial:
        return '部分结算';
      case ReceivableStatus.completed:
        return '已结清';
      case ReceivableStatus.badDebt:
        return '坏账';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case ReceivableStatus.pending:
        return Colors.orange;
      case ReceivableStatus.partial:
        return Colors.blue;
      case ReceivableStatus.completed:
        return Colors.green;
      case ReceivableStatus.badDebt:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('应收应付', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '应收'), Tab(text: '应付')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_summary != null) _buildSummaryCard(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_receivables, isReceivable: true),
                      _buildList(_payables, isReceivable: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final s = _summary!;
    final fmt = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('应收', fmt.format(s.totalReceivable)),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem('应付', fmt.format(s.totalPayable)),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem('逾期', '${s.overdueCount} 笔'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.rubik(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<JiveReceivable> items, {required bool isReceivable}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              isReceivable ? '暂无应收记录' : '暂无应付记录',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(JiveReceivable item) {
    final fmt = NumberFormat('#,##0.00');
    final progress = item.amount > 0 ? item.paidAmount / item.amount : 0.0;
    final isReceivable = item.type == ReceivableType.receivable;
    final color = isReceivable ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Dismissible(
      key: ValueKey(item.id),
      direction: item.isCompleted || item.status == ReceivableStatus.badDebt
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _recordPayment(item);
        return false; // We handle reload ourselves
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: Colors.green.shade50,
        child: const Icon(Icons.payment, color: Colors.green),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: item.status == ReceivableStatus.badDebt || item.isCompleted
              ? null
              : () => _markBadDebt(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(
                        isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.personName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (item.dueDate != null)
                            Text(
                              '到期: ${DateFormat('yyyy-MM-dd').format(item.dueDate!)}',
                              style: TextStyle(
                                color: item.isOverdue
                                    ? Colors.red.shade600
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '¥${fmt.format(item.remainingAmount)}',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(item.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _statusLabel(item.status),
                            style: TextStyle(
                              color: _statusColor(item.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '已逾期',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                const SizedBox(height: 4),
                Text(
                  '已付 ¥${fmt.format(item.paidAmount)} / ¥${fmt.format(item.amount)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
