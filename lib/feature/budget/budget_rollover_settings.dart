import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/budget_model.dart';
import '../../core/service/budget_rollover_service.dart';

/// 预算结转设置组件
class BudgetRolloverSettings extends StatefulWidget {
  final int budgetId;

  const BudgetRolloverSettings({super.key, required this.budgetId});

  @override
  State<BudgetRolloverSettings> createState() => _BudgetRolloverSettingsState();
}

class _BudgetRolloverSettingsState extends State<BudgetRolloverSettings> {
  JiveBudget? _budget;
  List<RolloverRecord> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = Isar.getInstance()!;
    final budget = await isar.jiveBudgets.get(widget.budgetId);
    List<RolloverRecord> history = [];

    if (budget != null) {
      final service = await BudgetRolloverService.create();
      history = await service.getRolloverHistory(widget.budgetId, months: 6);
    }

    if (mounted) {
      setState(() {
        _budget = budget;
        _history = history;
        _loading = false;
      });
    }
  }

  Future<void> _toggleRollover(bool value) async {
    final budget = _budget;
    if (budget == null) return;

    budget.rollover = value;
    budget.updatedAt = DateTime.now();

    final isar = Isar.getInstance()!;
    await isar.writeTxn(() async {
      await isar.jiveBudgets.put(budget);
    });

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final budget = _budget;
    if (budget == null) {
      return Center(
        child: Text('预算不存在', style: TextStyle(color: Colors.grey[500])),
      );
    }

    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('yyyy-MM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 结转开关 ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '预算结转',
                          style: GoogleFonts.notoSansSc(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '将未用完的额度自动转入下月，超支则从下月扣除',
                          style: GoogleFonts.notoSansSc(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: budget.rollover,
                    onChanged: _toggleRollover,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 当前结转余额
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '当前结转金额',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\u00a5${fmt.format(budget.carryoverAmount)}',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: budget.carryoverAmount >= 0
                            ? const Color(0xFF43A047)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── 结转历史 ──
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '结转历史（近6个月）',
            style: GoogleFonts.notoSansSc(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _history.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey[200]),
                  _buildHistoryItem(_history[i], fmt, dateFmt),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryItem(
    RolloverRecord record,
    NumberFormat fmt,
    DateFormat dateFmt,
  ) {
    final isPositive = record.rolloverAmount >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF43A047).withValues(alpha: 0.1)
                  : const Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isPositive
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFmt.format(record.month),
                  style: GoogleFonts.notoSansSc(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '预算 \u00a5${fmt.format(record.budgetAmount)}  '
                  '支出 \u00a5${fmt.format(record.usedAmount)}',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}\u00a5${fmt.format(record.rolloverAmount)}',
            style: GoogleFonts.notoSansSc(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}
