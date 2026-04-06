import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/fixed_deposit_model.dart';

/// 定期存款管理主页
class FixedDepositScreen extends StatefulWidget {
  const FixedDepositScreen({super.key});

  @override
  State<FixedDepositScreen> createState() => _FixedDepositScreenState();
}

class _FixedDepositScreenState extends State<FixedDepositScreen> {
  List<JiveFixedDeposit> _active = [];
  List<JiveFixedDeposit> _matured = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = Isar.getInstance()!;
    final all =
        await isar.collection<JiveFixedDeposit>().where().findAll();
    if (mounted) {
      setState(() {
        _active = all.where((d) => d.status == 'active').toList()
          ..sort((a, b) => a.maturityDate.compareTo(b.maturityDate));
        _matured = all.where((d) => d.status != 'active').toList()
          ..sort((a, b) => b.maturityDate.compareTo(a.maturityDate));
        _loading = false;
      });
    }
  }

  double get _totalDeposited {
    final allDeposits = [..._active, ..._matured];
    return allDeposits.fold<double>(0, (sum, d) => sum + d.principal);
  }

  double get _totalActiveDeposited {
    return _active.fold<double>(0, (sum, d) => sum + d.principal);
  }

  double get _totalExpectedInterest {
    return _active.fold<double>(0, (sum, d) => sum + d.expectedInterest);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('定期存款'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── 总览卡片 ──
                  _buildSummaryCard(fmt),
                  const SizedBox(height: 20),

                  // ── 活跃存款 ──
                  if (_active.isNotEmpty) ...[
                    Text(
                      '活跃存款',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._active.map((d) => _buildDepositCard(d, fmt)),
                    const SizedBox(height: 20),
                  ],

                  // ── 已到期/已提取 ──
                  if (_matured.isNotEmpty) ...[
                    Text(
                      '已到期/已提取',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._matured.map((d) => _buildDepositCard(d, fmt)),
                  ],

                  if (_active.isEmpty && _matured.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(Icons.savings_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              '暂无定期存款',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新建存款'),
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '存款总览',
            style: GoogleFonts.notoSansSc(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u00a5${fmt.format(_totalActiveDeposited)}',
            style: GoogleFonts.notoSansSc(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '活跃本金',
            style: GoogleFonts.notoSansSc(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem('预期利息', '\u00a5${fmt.format(_totalExpectedInterest)}'),
              const SizedBox(width: 24),
              _summaryItem('活跃笔数', '${_active.length}'),
              const SizedBox(width: 24),
              _summaryItem('累计本金', '\u00a5${fmt.format(_totalDeposited)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.notoSansSc(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.notoSansSc(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildDepositCard(JiveFixedDeposit deposit, NumberFormat fmt) {
    final isActive = deposit.status == 'active';
    final days = deposit.daysToMaturity;
    final countdownText = isActive
        ? (days > 0 ? '$days 天后到期' : '已到期')
        : (deposit.status == 'matured' ? '已到期' : '已提取');

    final countdownColor = isActive
        ? (days > 30
            ? Colors.green
            : days > 0
                ? Colors.orange
                : Colors.red)
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deposit.name,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: countdownColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    countdownText,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 12,
                      color: countdownColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _detailItem('本金', '\u00a5${fmt.format(deposit.principal)}'),
                _detailItem('利率', '${deposit.annualRate}%'),
                _detailItem(
                    '到期日', DateFormat('yyyy-MM-dd').format(deposit.maturityDate)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _detailItem(
                    '预期利息', '\u00a5${fmt.format(deposit.expectedInterest)}'),
                _detailItem('期限', '${deposit.termMonths}个月'),
                _detailItem(
                  '计息',
                  deposit.interestType == 'compound' ? '复利' : '单利',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.notoSansSc(fontSize: 11, color: Colors.grey[500])),
          Text(value,
              style: GoogleFonts.notoSansSc(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── 新建存款对话框 ──

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final principalCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final termCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    String interestType = 'simple';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('新建定期存款'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: '存款名称'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: principalCtrl,
                      decoration: const InputDecoration(labelText: '本金'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rateCtrl,
                      decoration:
                          const InputDecoration(labelText: '年利率 (%)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: termCtrl,
                      decoration: const InputDecoration(labelText: '期限(月)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('起存日期: ',
                            style: GoogleFonts.notoSansSc(fontSize: 14)),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => startDate = picked);
                            }
                          },
                          child: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: interestType,
                      decoration: const InputDecoration(labelText: '计息方式'),
                      items: const [
                        DropdownMenuItem(value: 'simple', child: Text('单利')),
                        DropdownMenuItem(
                            value: 'compound', child: Text('复利')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => interestType = v);
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
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final name = nameCtrl.text.trim();
    final principal = double.tryParse(principalCtrl.text.trim());
    final rate = double.tryParse(rateCtrl.text.trim());
    final term = int.tryParse(termCtrl.text.trim());

    if (name.isEmpty || principal == null || rate == null || term == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写完整信息')),
        );
      }
      return;
    }

    final maturity = DateTime(
      startDate.year,
      startDate.month + term,
      startDate.day,
    );

    final deposit = JiveFixedDeposit()
      ..name = name
      ..principal = principal
      ..annualRate = rate
      ..termMonths = term
      ..startDate = startDate
      ..maturityDate = maturity
      ..interestType = interestType
      ..status = 'active'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final isar = Isar.getInstance()!;
    await isar.writeTxn(() async {
      await isar.collection<JiveFixedDeposit>().put(deposit);
    });

    await _load();
  }
}
