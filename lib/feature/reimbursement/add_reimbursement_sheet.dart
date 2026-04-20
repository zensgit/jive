import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/database/account_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/reimbursement_service.dart';
import '../../core/repository/transaction_repository.dart';
import '../../core/repository/isar_transaction_repository.dart';
import '../../core/repository/account_repository.dart';
import '../../core/repository/isar_account_repository.dart';

class AddReimbursementSheet extends StatefulWidget {
  final int sourceTransactionId;

  const AddReimbursementSheet({
    super.key,
    required this.sourceTransactionId,
  });

  @override
  State<AddReimbursementSheet> createState() => _AddReimbursementSheetState();
}

class _AddReimbursementSheetState extends State<AddReimbursementSheet> {
  bool _loading = true;
  JiveTransaction? _sourceTx;
  double _alreadyReimbursed = 0;
  double _remaining = 0;
  List<JiveAccount> _accounts = [];
  int? _selectedAccountId;
  TransactionRepository? _transactionRepo;
  AccountRepository? _accountRepo;

  bool _isFull = true; // toggle: 全额 / 部分
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final isar = await DatabaseService.getInstance();
    _transactionRepo ??= IsarTransactionRepository(isar);
    _accountRepo ??= IsarAccountRepository(isar);
    final tx = await _transactionRepo!.getById(widget.sourceTransactionId);
    if (tx == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final service = ReimbursementService(isar);
    final summary = await service.getSettlementSummary(tx.id);
    final accounts = await _accountRepo!.getAll();
    final visibleAccounts =
        accounts.where((a) => !a.isArchived && !a.isHidden).toList();

    final remaining = tx.amount - summary.reimbursementTotal;

    if (!mounted) return;
    setState(() {
      _sourceTx = tx;
      _alreadyReimbursed = summary.reimbursementTotal;
      _remaining = remaining > 0 ? remaining : 0;
      _accounts = visibleAccounts;
      _selectedAccountId = tx.accountId;
      _amountCtrl.text = _remaining.toStringAsFixed(2);
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final tx = _sourceTx;
    if (tx == null) return;

    final amount = _isFull ? _remaining : (double.tryParse(_amountCtrl.text) ?? 0);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }
    if (amount > _remaining + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('报销金额不能超过剩余 \u00A5${_remaining.toStringAsFixed(2)}')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final isar = await DatabaseService.getInstance();
      final service = ReimbursementService(isar);

      await service.createReimbursement(
        sourceTransactionId: tx.id,
        amount: amount,
        accountId: _selectedAccountId,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      // Update reimbursement status on source transaction
      final updatedSummary = await service.getSettlementSummary(tx.id);
      final newStatus = updatedSummary.reimbursementTotal >= tx.amount - 0.01
          ? 'complete'
          : 'partial';
      tx.reimbursementStatus = newStatus;
      await _transactionRepo!.update(tx);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('报销失败: $e')),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = JiveTheme.isDark(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: JiveTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: JiveTheme.primaryGreen),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: JiveTheme.secondaryTextColor(context)
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        '记录报销',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: JiveTheme.textColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Original expense summary
                      _buildExpenseSummary(),
                      const SizedBox(height: 16),

                      // Toggle: 全额 / 部分
                      _buildToggle(isDark),
                      const SizedBox(height: 16),

                      // Amount input (for partial)
                      if (!_isFull) ...[
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.lato(
                              color: JiveTheme.textColor(context)),
                          decoration: InputDecoration(
                            labelText: '报销金额',
                            labelStyle: GoogleFonts.lato(
                              color: JiveTheme.secondaryTextColor(context),
                            ),
                            prefixText: '\u00A5 ',
                            prefixStyle: GoogleFonts.lato(
                              color: JiveTheme.textColor(context),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: JiveTheme.dividerColor(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Account selector
                      _buildAccountSelector(isDark),
                      const SizedBox(height: 16),

                      // Note
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        style: GoogleFonts.lato(
                            color: JiveTheme.textColor(context)),
                        decoration: InputDecoration(
                          labelText: '备注（可选）',
                          labelStyle: GoogleFonts.lato(
                            color: JiveTheme.secondaryTextColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: JiveTheme.dividerColor(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JiveTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  '确定',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildExpenseSummary() {
    final tx = _sourceTx!;
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('yyyy-MM-dd');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JiveTheme.isDark(context)
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _categoryEmoji(tx.category),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.category ?? '未分类',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        color: JiveTheme.textColor(context),
                      ),
                    ),
                    Text(
                      dateFmt.format(tx.timestamp),
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: JiveTheme.secondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\u00A5${fmt.format(tx.amount)}',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: JiveTheme.textColor(context),
                ),
              ),
            ],
          ),
          if (_alreadyReimbursed > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已报销',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: JiveTheme.secondaryTextColor(context),
                  ),
                ),
                Text(
                  '\u00A5${fmt.format(_alreadyReimbursed)}',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: JiveTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '剩余',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: JiveTheme.secondaryTextColor(context),
                  ),
                ),
                Text(
                  '\u00A5${fmt.format(_remaining)}',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _toggleButton(
            label: '全额报销',
            selected: _isFull,
            isDark: isDark,
            onTap: () {
              setState(() {
                _isFull = true;
                _amountCtrl.text = _remaining.toStringAsFixed(2);
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _toggleButton(
            label: '部分报销',
            selected: !_isFull,
            isDark: isDark,
            onTap: () => setState(() => _isFull = false),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? JiveTheme.primaryGreen.withValues(alpha: isDark ? 0.3 : 0.15)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? JiveTheme.primaryGreen
                : JiveTheme.dividerColor(context),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.w600,
            color: selected
                ? JiveTheme.primaryGreen
                : JiveTheme.secondaryTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector(bool isDark) {
    return DropdownButtonFormField<int>(
      value: _selectedAccountId,
      decoration: InputDecoration(
        labelText: '入账账户',
        labelStyle:
            GoogleFonts.lato(color: JiveTheme.secondaryTextColor(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: JiveTheme.dividerColor(context)),
        ),
      ),
      dropdownColor: JiveTheme.cardColor(context),
      style: GoogleFonts.lato(color: JiveTheme.textColor(context)),
      isExpanded: true,
      items: _accounts.map((a) {
        return DropdownMenuItem(
          value: a.id,
          child: Text(a.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedAccountId = v),
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
