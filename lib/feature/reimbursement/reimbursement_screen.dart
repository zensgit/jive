import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/reimbursement_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/reimbursement_workflow_service.dart';

class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({super.key});

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Isar _isar;
  late ReimbursementWorkflowService _service;
  bool _isLoading = true;

  List<JiveReimbursement> _pending = [];
  List<JiveReimbursement> _submitted = [];
  List<JiveReimbursement> _received = [];
  List<JiveReimbursement> _rejected = [];
  ReimbursementSummary? _summary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    _service = ReimbursementWorkflowService(_isar);
    await _load();
  }

  Future<void> _load() async {
    final pending = await _service.getByStatus(ReimbursementStatus.pending);
    final submitted = await _service.getByStatus(ReimbursementStatus.submitted);
    // 已到账 tab combines approved + received
    final approved = await _service.getByStatus(ReimbursementStatus.approved);
    final received = await _service.getByStatus(ReimbursementStatus.received);
    final rejected = await _service.getByStatus(ReimbursementStatus.rejected);
    final summary = await _service.getSummary();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _submitted = submitted;
      _received = [...approved, ...received];
      _rejected = rejected;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _addReimbursement() async {
    // 获取所有支出交易供选择
    final expenses = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .sortByTimestampDesc()
        .limit(100)
        .findAll();

    if (!mounted) return;
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无支出交易可选择')),
      );
      return;
    }

    JiveTransaction? selectedTx;
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          title: const Text('新建报销'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<JiveTransaction>(
                  decoration: const InputDecoration(
                    labelText: '选择交易 *',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: expenses.map((tx) {
                    final date =
                        DateFormat('MM/dd').format(tx.timestamp);
                    final cat = tx.category ?? '';
                    return DropdownMenuItem(
                      value: tx,
                      child: Text(
                        '$date  $cat  ¥${tx.amount.toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (tx) {
                    if (tx == null) return;
                    setLS(() {
                      selectedTx = tx;
                      amountCtrl.text = tx.amount.toStringAsFixed(2);
                      if (titleCtrl.text.isEmpty) {
                        titleCtrl.text = tx.category ?? '报销';
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '标题 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '金额 *',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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

    if (ok != true || !mounted || selectedTx == null) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0 || titleCtrl.text.trim().isEmpty) return;

    await _service.createReimbursement(
      transactionId: selectedTx!.id,
      amount: amount,
      title: titleCtrl.text,
      description:
          descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );

    titleCtrl.dispose();
    amountCtrl.dispose();
    descCtrl.dispose();
    await _load();
  }

  Future<void> _advanceStatus(JiveReimbursement item) async {
    String? nextStatus;
    switch (item.status) {
      case ReimbursementStatus.pending:
        nextStatus = ReimbursementStatus.submitted;
      case ReimbursementStatus.submitted:
        nextStatus = ReimbursementStatus.approved;
      case ReimbursementStatus.approved:
        nextStatus = ReimbursementStatus.received;
      default:
        return;
    }

    await _service.updateStatus(item.id, nextStatus);
    await _load();
  }

  Future<void> _rejectItem(JiveReimbursement item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('拒绝报销'),
        content: Text('确定将「${item.title}」标记为已拒绝？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('拒绝', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.updateStatus(item.id, ReimbursementStatus.rejected);
    if (mounted) await _load();
  }

  Future<void> _deleteItem(JiveReimbursement item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除报销'),
        content: Text('确定删除「${item.title}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.delete(item.id);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '报销管理',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '待报销'),
            Tab(text: '已提交'),
            Tab(text: '已到账'),
            Tab(text: '已拒绝'),
          ],
        ),
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
                      _buildList(_pending, canAdvance: true),
                      _buildList(_submitted, canAdvance: true),
                      _buildList(_received, canAdvance: false),
                      _buildList(_rejected, canAdvance: false),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReimbursement,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final s = _summary!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('待报销', s.pendingAmount, s.pendingCount),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem('已到账', s.receivedAmount, s.receivedCount),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem('总计', s.totalAmount, null),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, int? count) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${NumberFormat('#,##0.00').format(amount)}',
          style: GoogleFonts.rubik(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null)
          Text(
            '$count 笔',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildList(
    List<JiveReimbursement> items, {
    required bool canAdvance,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('暂无记录', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildTile(items[i], canAdvance: canAdvance),
      ),
    );
  }

  Widget _buildTile(
    JiveReimbursement item, {
    required bool canAdvance,
  }) {
    final dateStr = DateFormat('yyyy-MM-dd').format(item.createdAt);
    return Dismissible(
      key: ValueKey(item.id),
      direction: canAdvance
          ? DismissDirection.startToEnd
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green,
        child: const Icon(Icons.arrow_forward, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        if (canAdvance) await _advanceStatus(item);
        return false; // don't remove the widget, we reload
      },
      child: Card(
        child: ListTile(
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('$dateStr  ${item.description ?? ''}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¥${item.amount.toStringAsFixed(2)}',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(item.status),
            ],
          ),
          onLongPress: () => _showActions(item, canAdvance: canAdvance),
        ),
      ),
    );
  }

  void _showActions(JiveReimbursement item, {required bool canAdvance}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canAdvance)
              ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: Text('推进到 ${_nextStatusLabel(item.status)}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _advanceStatus(item);
                },
              ),
            if (item.status != ReimbursementStatus.rejected &&
                item.status != ReimbursementStatus.received)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.orange),
                title: const Text('标记拒绝'),
                onTap: () {
                  Navigator.pop(ctx);
                  _rejectItem(item);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteItem(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      ReimbursementStatus.pending => ('待报销', Colors.orange),
      ReimbursementStatus.submitted => ('已提交', Colors.blue),
      ReimbursementStatus.approved => ('已批准', Colors.teal),
      ReimbursementStatus.received => ('已到账', Colors.green),
      ReimbursementStatus.rejected => ('已拒绝', Colors.red),
      _ => ('未知', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _nextStatusLabel(String status) {
    return switch (status) {
      ReimbursementStatus.pending => '已提交',
      ReimbursementStatus.submitted => '已批准',
      ReimbursementStatus.approved => '已到账',
      _ => '',
    };
  }
}
