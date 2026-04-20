import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/database/bill_relation_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/reimbursement_service.dart';
import '../../core/repository/transaction_repository.dart';
import '../../core/repository/isar_transaction_repository.dart';
import 'add_reimbursement_sheet.dart';

class ReimbursementDetailScreen extends StatefulWidget {
  final int sourceTransactionId;

  const ReimbursementDetailScreen({
    super.key,
    required this.sourceTransactionId,
  });

  @override
  State<ReimbursementDetailScreen> createState() =>
      _ReimbursementDetailScreenState();
}

class _ReimbursementDetailScreenState extends State<ReimbursementDetailScreen> {
  bool _loading = true;
  JiveTransaction? _sourceTx;
  BillSettlementSummary? _summary;
  List<JiveBillRelation> _relations = [];
  bool _hasChanges = false;
  TransactionRepository? _transactionRepo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isar = await DatabaseService.getInstance();
    _transactionRepo ??= IsarTransactionRepository(isar);
    final tx = await _transactionRepo!.getById(widget.sourceTransactionId);
    if (tx == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    final service = ReimbursementService(isar);
    final summary = await service.getSettlementSummary(tx.id);
    final relations = await service.getRelationsForSource(tx.id);
    // Filter to only reimbursement relations
    final reimbursementRelations = relations
        .where((r) => r.relationType == BillRelationType.reimbursement.value)
        .toList();

    if (!mounted) return;
    setState(() {
      _sourceTx = tx;
      _summary = summary;
      _relations = reimbursementRelations;
      _loading = false;
    });
  }

  double get _progress {
    final tx = _sourceTx;
    final summary = _summary;
    if (tx == null || summary == null || tx.amount <= 0) return 0;
    return (summary.reimbursementTotal / tx.amount).clamp(0.0, 1.0);
  }

  Future<void> _continueReimbursement() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReimbursementSheet(
        sourceTransactionId: widget.sourceTransactionId,
      ),
    );
    if (result == true) {
      _hasChanges = true;
      await _loadData();
    }
  }

  Future<void> _markComplete() async {
    final tx = _sourceTx;
    if (tx == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JiveTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '标记完成',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: JiveTheme.textColor(context),
          ),
        ),
        content: Text(
          '确定将此报销标记为已完成？',
          style: GoogleFonts.lato(color: JiveTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '取消',
              style: GoogleFonts.lato(
                  color: JiveTheme.secondaryTextColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: JiveTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('确定', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    tx.reimbursementStatus = 'complete';
    await _transactionRepo!.update(tx);
    _hasChanges = true;
    await _loadData();
  }

  Future<void> _cancelReimbursement() async {
    final tx = _sourceTx;
    if (tx == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JiveTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '取消报销',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: JiveTheme.textColor(context),
          ),
        ),
        content: Text(
          '取消报销状态标记？已记录的报销入账不会被删除。',
          style: GoogleFonts.lato(color: JiveTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '取消',
              style: GoogleFonts.lato(
                  color: JiveTheme.secondaryTextColor(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '确认取消',
              style: GoogleFonts.lato(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    tx.reimbursementStatus = null;
    await _transactionRepo!.update(tx);
    _hasChanges = true;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        backgroundColor: JiveTheme.surfaceColor(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: Text(
            '报销详情',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: JiveTheme.textColor(context),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'cancel':
                    _cancelReimbursement();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text('取消报销标记'),
                ),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: JiveTheme.primaryGreen))
            : _sourceTx == null
                ? Center(
                    child: Text(
                      '找不到交易记录',
                      style: GoogleFonts.lato(
                        color: JiveTheme.secondaryTextColor(context),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: JiveTheme.primaryGreen,
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildExpenseHeader(),
                        const SizedBox(height: 16),
                        _buildProgressSection(),
                        const SizedBox(height: 16),
                        _buildTimelineSection(),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildExpenseHeader() {
    final tx = _sourceTx!;
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('yyyy-MM-dd');
    final isDark = JiveTheme.isDark(context);
    final status = tx.reimbursementStatus ?? 'pending';

    return Card(
      color: JiveTheme.cardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: JiveTheme.primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _categoryEmoji(tx.category),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.category ?? '未分类',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: JiveTheme.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFmt.format(tx.timestamp),
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status, isDark),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                '\u00A5${fmt.format(tx.amount)}',
                style: GoogleFonts.rubik(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: JiveTheme.textColor(context),
                ),
              ),
            ),
            if (tx.note != null && tx.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tx.note!.trim(),
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: JiveTheme.secondaryTextColor(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final tx = _sourceTx!;
    final summary = _summary!;
    final fmt = NumberFormat('#,##0.00');
    final isDark = JiveTheme.isDark(context);
    final percentage = (_progress * 100).toStringAsFixed(1);

    return Card(
      color: JiveTheme.cardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '报销进度',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: JiveTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\u00A5${fmt.format(summary.reimbursementTotal)} / \u00A5${fmt.format(tx.amount)}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: JiveTheme.secondaryTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: JiveTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                backgroundColor:
                    isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    JiveTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(
                  Icons.receipt_long,
                  '${summary.reimbursementCount} 笔报销',
                  isDark,
                ),
                const SizedBox(width: 8),
                if (summary.reimbursementTotal < tx.amount)
                  _infoChip(
                    Icons.pending_actions,
                    '剩余 \u00A5${fmt.format(tx.amount - summary.reimbursementTotal)}',
                    isDark,
                    accent: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark,
      {bool accent = false}) {
    final color = accent
        ? Colors.orange
        : JiveTheme.secondaryTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    if (_relations.isEmpty) {
      return Card(
        color: JiveTheme.cardColor(context),
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.timeline_outlined,
                size: 40,
                color: JiveTheme.secondaryTextColor(context)
                    .withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                '暂无报销记录',
                style: GoogleFonts.lato(
                  color: JiveTheme.secondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final numFmt = NumberFormat('#,##0.00');
    final isDark = JiveTheme.isDark(context);

    return Card(
      color: JiveTheme.cardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '报销记录',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: JiveTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_relations.length, (i) {
              final relation = _relations[i];
              final isLast = i == _relations.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: JiveTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: JiveTheme.primaryGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: JiveTheme.dividerColor(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '报销入账',
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.w600,
                                    color: JiveTheme.textColor(context),
                                  ),
                                ),
                                Text(
                                  '+\u00A5${numFmt.format(relation.amount)}',
                                  style: GoogleFonts.rubik(
                                    fontWeight: FontWeight.w600,
                                    color: JiveTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFmt.format(relation.createdAt),
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color:
                                    JiveTheme.secondaryTextColor(context),
                              ),
                            ),
                            if (relation.note != null &&
                                relation.note!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                relation.note!,
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: JiveTheme.secondaryTextColor(
                                      context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final tx = _sourceTx!;
    final status = tx.reimbursementStatus ?? 'pending';
    final isComplete = status == 'complete';

    return Row(
      children: [
        if (!isComplete) ...[
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _continueReimbursement,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  '继续报销',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JiveTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _markComplete,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  '标记完成',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: JiveTheme.primaryGreen,
                  side: const BorderSide(color: JiveTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (isComplete)
          Expanded(
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: JiveTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: JiveTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '报销已完成',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
                      color: JiveTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status, bool isDark) {
    final (label, color) = switch (status) {
      'pending' => ('待报销', Colors.orange),
      'partial' => ('进行中', Colors.blue),
      'complete' => ('已完成', JiveTheme.primaryGreen),
      _ => ('未知', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _categoryEmoji(String? category) {
    if (category == null) return '\u{1F4B0}';
    final map = {
      '餐饮': '\u{1F35C}',
      '交通': '\u{1F68C}',
      '购物': '\u{1F6CD}',
      '住房': '\u{1F3E0}',
      '娱乐': '\u{1F3AE}',
      '医疗': '\u{1F3E5}',
      '教育': '\u{1F4DA}',
      '通讯': '\u{1F4F1}',
      '旅行': '\u2708\uFE0F',
      '办公': '\u{1F4BC}',
    };
    for (final entry in map.entries) {
      if (category.contains(entry.key)) return entry.value;
    }
    return '\u{1F4B0}';
  }
}
