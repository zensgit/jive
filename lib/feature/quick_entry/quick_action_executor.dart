import 'package:flutter/material.dart';

import '../../core/model/quick_action.dart';
import '../../core/service/database_service.dart';
import '../../core/service/quick_action_service.dart';
import '../transactions/transaction_entry_params.dart';
import '../transactions/transaction_form_screen.dart';

/// Orchestrates quick-action execution depending on the action's
/// [QuickActionMode].
class QuickActionExecutor {
  /// Executes the given [action] in the appropriate mode.
  ///
  /// - **direct** — saves the transaction immediately and shows a toast.
  /// - **confirm** — presents a lightweight bottom-sheet for amount + note.
  /// - **edit** — navigates to [AddTransactionScreen] with prefilled params.
  static Future<void> execute(
    BuildContext context,
    QuickAction action,
  ) async {
    final isar = await DatabaseService.getInstance();
    final service = QuickActionService(isar);

    switch (action.mode) {
      case QuickActionMode.direct:
        if (!context.mounted) return;
        await _executeDirect(context, action, service);
      case QuickActionMode.confirm:
        if (context.mounted) {
          await _executeConfirm(context, action, service);
        }
      case QuickActionMode.edit:
        if (context.mounted) {
          _executeEdit(context, action, service);
        }
    }
  }

  // ---------------------------------------------------------------------------
  // Direct mode
  // ---------------------------------------------------------------------------

  static Future<void> _executeDirect(
    BuildContext context,
    QuickAction action,
    QuickActionService service,
  ) async {
    await service.executeDirect(action);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已记录 ${action.name} ¥${action.defaultAmount ?? 0}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Confirm mode — lightweight bottom sheet
  // ---------------------------------------------------------------------------

  static Future<void> _executeConfirm(
    BuildContext context,
    QuickAction action,
    QuickActionService service,
  ) async {
    final result = await showModalBottomSheet<_ConfirmResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ConfirmSheet(action: action),
    );

    if (result != null && context.mounted) {
      final patched = action.copyWith(
        defaultAmount: result.amount,
        defaultNote:
            result.note?.isNotEmpty == true ? result.note : action.defaultNote,
      );
      await service.executeDirect(patched);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已记录 ${action.name} ¥${result.amount}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Edit mode — navigate to full editor
  // ---------------------------------------------------------------------------

  /// Opens the form-based transaction editor with fields prefilled from the
  /// action via [TransactionEntryParams].
  static void _executeEdit(
    BuildContext context,
    QuickAction action,
    QuickActionService service,
  ) {
    final params = TransactionEntryParams(
      source: TransactionEntrySource.quickAction,
      sourceLabel: '来自快速动作「${action.name}」',
      quickActionId: action.id?.toString(),
      prefillAmount: action.defaultAmount,
      prefillType: action.transactionType,
      prefillCategoryKey: action.categoryKey,
      prefillAccountId: action.accountId,
      prefillNote: action.defaultNote,
      prefillTagKeys: action.tagKeys,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionFormScreen(params: params),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper types
// ---------------------------------------------------------------------------

class _ConfirmResult {
  final double amount;
  final String? note;
  const _ConfirmResult({required this.amount, this.note});
}

/// A minimal bottom-sheet that asks for amount and an optional note before
/// saving a confirm-mode quick action.
class _ConfirmSheet extends StatefulWidget {
  final QuickAction action;
  const _ConfirmSheet({required this.action});

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.action.defaultAmount?.toString() ?? '',
    );
    _noteCtrl = TextEditingController(
      text: widget.action.defaultNote ?? '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    Navigator.of(context).pop(
      _ConfirmResult(amount: amount, note: _noteCtrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.action.name,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '金额',
              prefixText: '¥ ',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: '备注'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
