import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/billing_cycle_model.dart';
import '../../core/database/account_model.dart';
import '../../core/service/database_service.dart';

/// 账单周期管理 —— 跟踪信用卡账单日/还款日
class BillingCycleScreen extends StatefulWidget {
  const BillingCycleScreen({super.key});

  @override
  State<BillingCycleScreen> createState() => _BillingCycleScreenState();
}

class _BillingCycleScreenState extends State<BillingCycleScreen> {
  List<JiveBillingCycle> _cycles = [];
  Map<int, JiveAccount> _accountMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = await DatabaseService.getInstance();
    final cycles =
        await isar.collection<JiveBillingCycle>().where().findAll();
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    if (!mounted) return;
    setState(() {
      _cycles = cycles..sort((a, b) => a.accountName.compareTo(b.accountName));
      _accountMap = {for (final a in accounts) a.id: a};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单周期'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(null),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cycles.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cycles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildCycleCard(_cycles[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('还没有账单周期',
              style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('添加信用卡账单日和还款日，不再错过还款',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _showEditDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('添加账单周期'),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleCard(JiveBillingCycle cycle) {
    final daysUntilDue = _daysUntilNext(cycle.dueDay);
    final daysUntilBilling = _daysUntilNext(cycle.billingDay);
    final isUrgent = daysUntilDue <= cycle.reminderDaysBefore;
    final cycleLength = _cycleLengthDays(cycle.billingDay, cycle.dueDay);
    final daysPassed = cycleLength - daysUntilDue;
    final progress =
        cycleLength > 0 ? (daysPassed / cycleLength).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUrgent ? Colors.orange.shade300 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showEditDialog(cycle),
        onLongPress: () => _confirmDelete(cycle),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (cycle.isEnabled
                              ? Colors.blue
                              : Colors.grey)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.credit_card, size: 20,
                        color: cycle.isEnabled ? Colors.blue : Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cycle.accountName,
                            style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '账单日: ${cycle.billingDay}号 · 还款日: ${cycle.dueDay}号',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$daysUntilDue 天',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isUrgent ? Colors.orange.shade700 : Colors.blue,
                        ),
                      ),
                      Text('距还款日',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Visual timeline
              _buildTimeline(cycle, progress, daysUntilBilling, daysUntilDue),
              if (!cycle.isEnabled) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('已暂停',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(JiveBillingCycle cycle, double progress,
      int daysUntilBilling, int daysUntilDue) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('账单日 ${cycle.billingDay}号',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            Text('还款日 ${cycle.dueDay}号',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.8 ? Colors.orange : Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$daysUntilBilling 天后出账',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            Text('$daysUntilDue 天后还款',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // ── Create/Edit dialog ────────────────────────────────────────────────────

  Future<void> _showEditDialog(JiveBillingCycle? existing) async {
    final isEdit = existing != null;
    int? selectedAccountId = existing?.accountId;
    String accountName = existing?.accountName ?? '';
    int billingDay = existing?.billingDay ?? 1;
    int dueDay = existing?.dueDay ?? 20;
    int reminder = existing?.reminderDaysBefore ?? 3;
    bool isEnabled = existing?.isEnabled ?? true;

    final accounts = _accountMap.values
        .where((a) => a.type == 'liability' && a.subType == 'credit')
        .toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) {
          return AlertDialog(
            title: Text(isEdit ? '编辑账单周期' : '添加账单周期'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(labelText: '信用卡账户'),
                    items: accounts
                        .map((a) => DropdownMenuItem(
                            value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (v) {
                      setLS(() {
                        selectedAccountId = v;
                        accountName = accounts
                            .firstWhere((a) => a.id == v,
                                orElse: () => accounts.first)
                            .name;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DayPicker(
                          label: '账单日',
                          value: billingDay,
                          onChanged: (v) => setLS(() => billingDay = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DayPicker(
                          label: '还款日',
                          value: dueDay,
                          onChanged: (v) => setLS(() => dueDay = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DayPicker(
                    label: '提前提醒天数',
                    value: reminder,
                    maxDay: 15,
                    onChanged: (v) => setLS(() => reminder = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('启用'),
                    value: isEnabled,
                    onChanged: (v) => setLS(() => isEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: selectedAccountId == null
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: Text(isEdit ? '保存' : '添加')),
            ],
          );
        },
      ),
    );

    if (ok != true || selectedAccountId == null) return;

    final isar = await DatabaseService.getInstance();
    final cycle = existing ?? JiveBillingCycle();
    cycle
      ..accountId = selectedAccountId!
      ..accountName = accountName
      ..billingDay = billingDay
      ..dueDay = dueDay
      ..reminderDaysBefore = reminder
      ..isEnabled = isEnabled
      ..updatedAt = DateTime.now();
    if (!isEdit) cycle.createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveBillingCycle>().put(cycle);
    });
    _load();
  }

  Future<void> _confirmDelete(JiveBillingCycle cycle) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账单周期'),
        content: Text('确定删除 ${cycle.accountName} 的账单周期吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;

    final isar = await DatabaseService.getInstance();
    await isar.writeTxn(() async {
      await isar.collection<JiveBillingCycle>().delete(cycle.id);
    });
    _load();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _daysUntilNext(int day) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, day);
    if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      next = DateTime(now.year, now.month + 1, day);
    }
    return next.difference(now).inDays;
  }

  int _cycleLengthDays(int billingDay, int dueDay) {
    final now = DateTime.now();
    final billing = DateTime(now.year, now.month, billingDay);
    var due = DateTime(now.year, now.month, dueDay);
    if (due.isBefore(billing)) {
      due = DateTime(now.year, now.month + 1, dueDay);
    }
    return due.difference(billing).inDays.clamp(1, 62);
  }
}

// ── Day Picker ──────────────────────────────────────────────────────────────

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxDay = 31,
  });
  final String label;
  final int value;
  final int maxDay;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value.clamp(1, maxDay),
      decoration: InputDecoration(labelText: label),
      items: List.generate(
        maxDay,
        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
      ),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
