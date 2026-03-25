import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/installment_model.dart';
import '../../core/database/account_model.dart';
import 'installment_form_screen.dart';

/// 分期管理主页 —— 显示活跃/已结束分期，进度、下次还款日
class InstallmentListScreen extends StatefulWidget {
  const InstallmentListScreen({super.key});

  @override
  State<InstallmentListScreen> createState() => _InstallmentListScreenState();
}

class _InstallmentListScreenState extends State<InstallmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<JiveInstallment> _active = [];
  List<JiveInstallment> _finished = [];
  Map<int, String> _acctNames = {};
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
    final all = await isar.collection<JiveInstallment>().where().findAll();
    final accts = await isar.collection<JiveAccount>().where().findAll();
    if (mounted) {
      setState(() {
        _active = all.where((i) => i.isActive).toList()
          ..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));
        _finished = all.where((i) => !i.isActive).toList();
        _acctNames = {for (final a in accts) a.id: a.name};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分期管理'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '进行中'), Tab(text: '已结束')],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _toForm),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_active, finished: false),
                _buildList(_finished, finished: true),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toForm,
        icon: const Icon(Icons.add),
        label: const Text('新建分期'),
      ),
    );
  }

  Widget _buildList(List<JiveInstallment> items, {required bool finished}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              finished ? '没有已结束的分期' : '还没有分期',
              style: GoogleFonts.lato(
                  fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
            if (!finished) ...[
              const SizedBox(height: 8),
              Text('记录信用卡分期，掌控每月还款',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: _toForm, icon: const Icon(Icons.add), label: const Text('新建分期')),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _InstallmentCard(
          item: items[i],
          acctName: _acctNames[items[i].accountId] ?? '未知账户',
          onTap: () => _toForm(items[i]),
        ),
      ),
    );
  }

  Future<void> _toForm([JiveInstallment? item]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => InstallmentFormScreen(installment: item)),
    );
    if (result == true) _load();
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.item,
    required this.acctName,
    required this.onTap,
  });

  final JiveInstallment item;
  final String acctName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = item.totalPeriods > 0
        ? item.executedPeriods / item.totalPeriods
        : 0.0;
    final remaining = item.totalPeriods - item.executedPeriods;
    final isDue = item.nextDueAt.isBefore(DateTime.now().add(const Duration(days: 3)));

    final monthlyPrincipal = item.totalPeriods > 0
        ? item.principalAmount / item.totalPeriods
        : 0.0;
    final monthlyFee = item.totalPeriods > 0
        ? item.totalFee / item.totalPeriods
        : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDue && item.isActive
              ? Colors.orange.shade300
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.credit_card, size: 20, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(acctName,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${item.principalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2E7D32)),
                      ),
                      Text('总本金',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '第 ${item.executedPeriods}/${item.totalPeriods} 期',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    '剩余 $remaining 期',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 10),
              // Footer
              Row(
                children: [
                  _InfoPill(
                    icon: Icons.event,
                    label: '下次 ${DateFormat('MM/dd').format(item.nextDueAt)}',
                    color: isDue ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  _InfoPill(
                    icon: Icons.payments_outlined,
                    label: '月还 ¥${(monthlyPrincipal + monthlyFee).toStringAsFixed(0)}',
                    color: Colors.blue,
                  ),
                  if (item.commitMode == InstallmentCommitMode.draft.value) ...[
                    const SizedBox(width: 8),
                    _InfoPill(icon: Icons.drafts_outlined, label: '草稿', color: Colors.purple),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
