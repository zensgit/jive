import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/installment_model.dart';
import '../../core/database/account_model.dart';
import '../../core/service/database_service.dart';
import 'installment_form_screen.dart';

/// 分期仪表盘 —— 概览活跃分期进度、即将到期还款、已完成分期
class InstallmentDashboardScreen extends StatefulWidget {
  const InstallmentDashboardScreen({super.key});

  @override
  State<InstallmentDashboardScreen> createState() =>
      _InstallmentDashboardScreenState();
}

class _InstallmentDashboardScreenState
    extends State<InstallmentDashboardScreen> {
  List<JiveInstallment> _active = [];
  List<JiveInstallment> _completed = [];
  Map<int, String> _acctNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = await DatabaseService.getInstance();
    final all = await isar.collection<JiveInstallment>().where().findAll();
    final accts = await isar.collection<JiveAccount>().where().findAll();
    if (!mounted) return;
    setState(() {
      _active = all.where((i) => i.isActive).toList()
        ..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));
      _completed = all.where((i) => !i.isActive).toList()
        ..sort(
            (a, b) => (b.finishedAt ?? b.updatedAt).compareTo(a.finishedAt ?? a.updatedAt));
      _acctNames = {for (final a in accts) a.id: a.name};
      _loading = false;
    });
  }

  JiveInstallment? get _upcoming {
    if (_active.isEmpty) return null;
    return _active.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('分期总览')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Upcoming payment card ──
                  if (_upcoming != null) _buildUpcomingCard(theme),
                  if (_upcoming != null) const SizedBox(height: 20),

                  // ── Active installments ──
                  if (_active.isNotEmpty) ...[
                    Text('进行中的分期',
                        style: GoogleFonts.lato(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ..._active
                        .map((item) => _buildActiveCard(item, theme)),
                    const SizedBox(height: 20),
                  ],

                  // ── Completed ──
                  if (_completed.isNotEmpty) ...[
                    Text('已完成',
                        style: GoogleFonts.lato(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ..._completed
                        .map((item) => _buildCompletedTile(item)),
                  ],

                  // ── Empty state ──
                  if (_active.isEmpty && _completed.isEmpty)
                    _buildEmptyState(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Upcoming payment highlight ────────────────────────────────────────────

  Widget _buildUpcomingCard(ThemeData theme) {
    final item = _upcoming!;
    final daysLeft = item.nextDueAt.difference(DateTime.now()).inDays;
    final monthlyAmount = item.totalPeriods > 0
        ? (item.principalAmount + item.totalFee) / item.totalPeriods
        : 0.0;
    final isUrgent = daysLeft <= 3;

    return Card(
      elevation: isUrgent ? 2 : 0,
      color: isUrgent
          ? Colors.orange.shade50
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active,
                    size: 20,
                    color: isUrgent ? Colors.orange : theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('即将到期还款',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.name,
                style:
                    GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              _acctNames[item.accountId] ?? '未知账户',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('下次还款日',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(DateFormat('yyyy-MM-dd').format(item.nextDueAt),
                        style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('还款金额',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '\u00a5${monthlyAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isUrgent ? Colors.orange.shade700 : null),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              daysLeft >= 0 ? '还剩 $daysLeft 天' : '已逾期 ${-daysLeft} 天',
              style: TextStyle(
                  color: isUrgent ? Colors.orange.shade700 : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active installment card ───────────────────────────────────────────────

  Widget _buildActiveCard(JiveInstallment item, ThemeData theme) {
    final progress = item.totalPeriods > 0
        ? item.executedPeriods / item.totalPeriods
        : 0.0;
    final remaining = item.totalPeriods - item.executedPeriods;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _toForm(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Text(
                      '\u00a5${item.principalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF2E7D32)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_acctNames[item.accountId] ?? "未知账户"} · 第 ${item.executedPeriods}/${item.totalPeriods} 期 · 剩余 $remaining 期',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% 完成 · 下次 ${DateFormat('MM/dd').format(item.nextDueAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Completed installments ────────────────────────────────────────────────

  Widget _buildCompletedTile(JiveInstallment item) {
    final statusLabel = InstallmentStatus.fromValue(item.status) ==
            InstallmentStatus.prepaid
        ? '提前还清'
        : '已完成';
    return ListTile(
      dense: true,
      leading: Icon(Icons.check_circle, color: Colors.green.shade400),
      title: Text(item.name),
      subtitle: Text(
        '${_acctNames[item.accountId] ?? "未知账户"} · $statusLabel',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '\u00a5${item.principalAmount.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () => _toForm(item),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.credit_card_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('还没有分期',
              style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('记录信用卡分期，掌控每月还款',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _toForm,
            icon: const Icon(Icons.add),
            label: const Text('新建分期'),
          ),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _toForm([JiveInstallment? item]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => InstallmentFormScreen(installment: item)),
    );
    if (result == true) _load();
  }
}
