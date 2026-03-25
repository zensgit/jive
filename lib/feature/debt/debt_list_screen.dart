import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/debt_model.dart';
import '../../core/service/debt_service.dart';
import '../../core/service/database_service.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Isar _isar;
  late DebtService _service;
  bool _isLoading = true;
  List<JiveDebt> _activeDebts = [];
  List<JiveDebt> _settledDebts = [];
  DebtSummary? _summary;

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
    _service = DebtService(_isar);
    await _load();
  }

  Future<void> _load() async {
    final active = await _service.getActiveDebts();
    final settled = await _service.getSettledDebts();
    final summary = await _service.getSummary();
    if (!mounted) return;
    setState(() {
      _activeDebts = active;
      _settledDebts = settled;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _addDebt() async {
    final typeCtrl = ValueNotifier<String>(DebtType.lent);
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? dueDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          title: const Text('新建借贷'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: typeCtrl,
                  builder: (_, type, __) => SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: DebtType.lent, label: Text('我借出')),
                      ButtonSegment(value: DebtType.borrowed, label: Text('我借入')),
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
                      ? '预计还款日: ${DateFormat('yyyy-MM-dd').format(dueDate!)}'
                      : '设置预计还款日（可选）'),
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('创建')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0 || nameCtrl.text.trim().isEmpty) return;

    await _service.createDebt(
      type: typeCtrl.value,
      personName: nameCtrl.text,
      amount: amount,
      borrowDate: DateTime.now(),
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      dueDate: dueDate,
    );
    nameCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
    typeCtrl.dispose();
    await _load();
  }

  Future<void> _recordPayment(JiveDebt debt) async {
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('记录还款 — ${debt.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('剩余: ¥${debt.remainingAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '还款金额',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    amountCtrl.dispose();
    if (amount <= 0) return;

    await _service.recordPayment(
      debt: debt,
      amount: amount,
      paymentDate: DateTime.now(),
    );
    await _load();
  }

  Future<void> _deleteDebt(JiveDebt debt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除借贷'),
        content: Text('确定删除与「${debt.personName}」的借贷记录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteDebt(debt.id);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('借贷管理', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addDebt),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '进行中'), Tab(text: '已结清')],
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
                      _buildDebtList(_activeDebts, isActive: true),
                      _buildDebtList(_settledDebts, isActive: false),
                    ],
                  ),
                ),
              ],
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
          _summaryItem('应收', s.totalLent, Colors.white),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem('应付', s.totalBorrowed, Colors.white),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem('净额', s.netBalance, Colors.white),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '¥${NumberFormat('#,##0.00').format(amount)}',
          style: GoogleFonts.rubik(color: color, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDebtList(List<JiveDebt> debts, {required bool isActive}) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(isActive ? '暂无进行中的借贷' : '暂无已结清的借贷',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: debts.length,
      itemBuilder: (context, index) => _buildDebtTile(debts[index], isActive: isActive),
    );
  }

  Widget _buildDebtTile(JiveDebt debt, {required bool isActive}) {
    final isLent = debt.type == DebtType.lent;
    final color = isLent ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final typeLabel = isLent ? '借出' : '借入';
    final progress = debt.amount > 0 ? debt.paidAmount / debt.amount : 0.0;
    final fmt = NumberFormat('#,##0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Icon(isLent ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.personName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('$typeLabel · ${DateFormat('MM/dd').format(debt.borrowDate)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Text('¥${fmt.format(debt.remainingAmount)}',
                    style: GoogleFonts.rubik(
                        fontSize: 16, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
            if (debt.isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('已逾期',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 11)),
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
              '已还 ¥${fmt.format(debt.paidAmount)} / ¥${fmt.format(debt.amount)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _recordPayment(debt),
                    child: const Text('记录还款'),
                  ),
                  TextButton(
                    onPressed: () => _deleteDebt(debt),
                    child: const Text('删除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
