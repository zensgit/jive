import 'package:flutter/material.dart';

import '../../core/model/quick_action.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/database_service.dart';
import '../../core/service/quick_action_service.dart';
import '../transactions/transaction_entry_params.dart';
import '../transactions/transaction_form_screen.dart';

typedef QuickActionCompleted = void Function();

/// Single UI execution path for app quick actions, template chips, widgets, and
/// future deep-link/AppIntent entry points.
class QuickActionExecutor {
  const QuickActionExecutor._();

  static Future<void> execute(
    BuildContext context,
    QuickAction action, {
    QuickActionCompleted? onCompleted,
  }) async {
    switch (action.mode) {
      case QuickActionMode.direct:
        await _saveDirect(context, action, onCompleted: onCompleted);
      case QuickActionMode.confirm:
        await _showConfirmSheet(context, action, onCompleted: onCompleted);
      case QuickActionMode.edit:
        await _openEditor(context, action, onCompleted: onCompleted);
    }
  }

  static Future<void> _saveDirect(
    BuildContext context,
    QuickAction action, {
    QuickActionCompleted? onCompleted,
  }) async {
    final isar = await DatabaseService.getInstance();
    final service = QuickActionService(isar);
    await service.saveTransaction(action);
    DataReloadBus.notify();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记账: ${action.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
    onCompleted?.call();
  }

  static Future<void> _showConfirmSheet(
    BuildContext context,
    QuickAction action, {
    QuickActionCompleted? onCompleted,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _QuickActionConfirmSheet(action: action),
    );
    if (saved == true) {
      DataReloadBus.notify();
      onCompleted?.call();
    }
  }

  static Future<void> _openEditor(
    BuildContext context,
    QuickAction action, {
    QuickActionCompleted? onCompleted,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(params: _paramsFor(action)),
      ),
    );
    if (result == true) onCompleted?.call();
  }

  static TransactionEntryParams _paramsFor(QuickAction action) {
    final missing = QuickActionService.missingFields(action);
    return TransactionEntryParams(
      source: TransactionEntrySource.quickAction,
      sourceLabel: '来自快速动作「${action.name}」',
      quickActionId: action.id,
      prefillAmount: action.defaultAmount,
      prefillType: action.transactionType,
      prefillCategoryKey: action.categoryKey,
      prefillSubCategoryKey: action.subCategoryKey,
      prefillAccountId: action.accountId,
      prefillToAccountId: action.toAccountId,
      prefillNote: action.defaultNote,
      prefillTagKeys: action.tagKeys,
      highlightFields: missing,
    );
  }
}

class _QuickActionConfirmSheet extends StatefulWidget {
  final QuickAction action;

  const _QuickActionConfirmSheet({required this.action});

  @override
  State<_QuickActionConfirmSheet> createState() =>
      _QuickActionConfirmSheetState();
}

class _QuickActionConfirmSheetState extends State<_QuickActionConfirmSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final amount = widget.action.defaultAmount;
    _amountController = TextEditingController(
      text: amount != null && amount > 0 ? amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: widget.action.defaultNote);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入金额')));
      return;
    }

    setState(() => _isSaving = true);
    final isar = await DatabaseService.getInstance();
    await QuickActionService(isar).saveTransaction(
      widget.action,
      amount: amount,
      note: _noteController.text,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记账: ${widget.action.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '快速记录「${widget.action.name}」',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flash_on),
              label: const Text('立即入账'),
            ),
          ],
        ),
      ),
    );
  }
}
