import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/service/mortgage_service.dart';

/// 房贷管理 —— 创建、查看进度、分期还款表
class MortgageScreen extends StatefulWidget {
  const MortgageScreen({super.key});

  @override
  State<MortgageScreen> createState() => _MortgageScreenState();
}

class _MortgageScreenState extends State<MortgageScreen> {
  List<MortgageInfo> _mortgages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await MortgageService.loadAll();
    if (!mounted) return;
    setState(() {
      _mortgages = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('房贷管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mortgages.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mortgages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) =>
                        _MortgageDashboardCard(
                          info: _mortgages[i],
                          onDelete: () => _delete(_mortgages[i].id),
                          onViewSchedule: () =>
                              _showSchedule(_mortgages[i]),
                        ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('还没有房贷记录',
              style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('添加房贷信息，追踪还款进度',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加房贷'),
          ),
        ],
      ),
    );
  }

  // ── Create dialog ─────────────────────────────────────────────────────────

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController(text: '房贷');
    final principalCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '3.5');
    final termCtrl = TextEditingController(text: '360');
    var method = MortgageMethod.equalPayment;
    var startDate = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          title: const Text('添加房贷'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: principalCtrl,
                  decoration: const InputDecoration(
                      labelText: '贷款本金', suffixText: '元'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: rateCtrl,
                  decoration: const InputDecoration(
                      labelText: '年利率', suffixText: '%'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: termCtrl,
                  decoration:
                      const InputDecoration(labelText: '期限', suffixText: '个月'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                SegmentedButton<MortgageMethod>(
                  segments: MortgageMethod.values
                      .map((m) =>
                          ButtonSegment(value: m, label: Text(m.label)))
                      .toList(),
                  selected: {method},
                  onSelectionChanged: (s) =>
                      setLS(() => method = s.first),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开始日期'),
                  trailing: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) setLS(() => startDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('添加')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final principal = double.tryParse(principalCtrl.text) ?? 0;
    final rate = (double.tryParse(rateCtrl.text) ?? 0) / 100;
    final term = int.tryParse(termCtrl.text) ?? 0;
    if (principal <= 0 || term <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请填写有效的贷款信息')));
      }
      return;
    }

    final monthly = method == MortgageMethod.equalPayment
        ? MortgageService.calcEqualPaymentMonthly(principal, rate, term)
        : MortgageService.calcEqualPrincipalFirstMonthly(principal, rate, term);

    final info = MortgageInfo(
      id: const Uuid().v4(),
      name: nameCtrl.text.trim().isEmpty ? '房贷' : nameCtrl.text.trim(),
      principal: principal,
      annualRate: rate,
      termMonths: term,
      monthlyPayment: monthly,
      method: method,
      startDate: startDate,
    );

    await MortgageService.addMortgage(info);
    _load();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除房贷'),
        content: const Text('确定删除这条房贷记录吗？'),
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
    await MortgageService.removeMortgage(id);
    _load();
  }

  void _showSchedule(MortgageInfo info) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _AmortizationScreen(info: info)),
    );
  }
}

// ── Dashboard Card ──────────────────────────────────────────────────────────

class _MortgageDashboardCard extends StatelessWidget {
  const _MortgageDashboardCard({
    required this.info,
    required this.onDelete,
    required this.onViewSchedule,
  });
  final MortgageInfo info;
  final VoidCallback onDelete;
  final VoidCallback onViewSchedule;

  @override
  Widget build(BuildContext context) {
    final progress = MortgageService.calculateProgress(info);
    final progressRatio = info.termMonths > 0
        ? progress.paidMonths / info.termMonths
        : 0.0;
    final schedule = MortgageService.getAmortizationSchedule(info);
    final nextPayment =
        progress.paidMonths < schedule.length
            ? schedule[progress.paidMonths]
            : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                    color: Colors.indigo.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home, size: 22, color: Colors.indigo),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.name,
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(info.method.label,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'schedule') onViewSchedule();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'schedule', child: Text('还款计划表')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('删除')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress ring
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progressRatio.clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.indigo),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progressRatio * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Text('已还',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                Expanded(
                    child: _StatTile(
                        label: '已还本金',
                        value:
                            '\u00a5${_fmt(progress.paidPrincipal)}')),
                Expanded(
                    child: _StatTile(
                        label: '剩余本金',
                        value:
                            '\u00a5${_fmt(progress.remainingPrincipal)}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _StatTile(
                        label: '已付利息',
                        value:
                            '\u00a5${_fmt(progress.paidInterest)}')),
                Expanded(
                    child: _StatTile(
                        label: '总利息',
                        value:
                            '\u00a5${_fmt(progress.totalInterest)}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _StatTile(
                        label: '已还期数',
                        value:
                            '${progress.paidMonths}/${info.termMonths}')),
                Expanded(
                    child: _StatTile(
                        label: '剩余期数',
                        value: '${progress.remainingMonths}')),
              ],
            ),

            // Next payment
            if (nextPayment != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text('下期还款',
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '本金 \u00a5${nextPayment.principal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '利息 \u00a5${nextPayment.interest.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '合计 \u00a5${nextPayment.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewSchedule,
                child: const Text('查看还款计划表 >'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(2)}万';
    return v.toStringAsFixed(2);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
  }
}

// ── Amortization Schedule Screen ────────────────────────────────────────────

class _AmortizationScreen extends StatelessWidget {
  const _AmortizationScreen({required this.info});
  final MortgageInfo info;

  @override
  Widget build(BuildContext context) {
    final schedule = MortgageService.getAmortizationSchedule(info);
    final progress = MortgageService.calculateProgress(info);

    return Scaffold(
      appBar: AppBar(title: Text('${info.name} - 还款计划')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.withValues(alpha: 0.05),
            child: Text(
              '${info.method.label} · 已还 ${progress.paidMonths}/${info.termMonths} 期',
              style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('期数', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Expanded(child: Text('本金', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                Expanded(child: Text('利息', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                Expanded(child: Text('月供', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                Expanded(child: Text('剩余本金', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: schedule.length,
              itemBuilder: (_, i) {
                final p = schedule[i];
                final isPaid = i < progress.paidMonths;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.04)
                        : null,
                    border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade200, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${p.month}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isPaid ? Colors.green.shade600 : null,
                            fontWeight:
                                isPaid ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Text(p.principal.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(p.interest.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(p.total.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(
                              _fmtRemaining(p.remainingPrincipal),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmtRemaining(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(2)}万';
    return v.toStringAsFixed(2);
  }
}
