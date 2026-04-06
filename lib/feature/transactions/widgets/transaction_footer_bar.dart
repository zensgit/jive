import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../transaction_entry_params.dart';

/// Fixed bottom action bar for the transaction editor.
///
/// The primary button text and color adapt based on the [source] and
/// [transactionType]. Includes a continuous-mode toggle and a secondary
/// "save and new" button.
class TransactionFooterBar extends StatelessWidget {
  /// The entry source determines the primary button label.
  final TransactionEntrySource source;

  /// Called when the primary save button is pressed.
  final VoidCallback? onSave;

  /// Called when the "save and new" button is pressed.
  final VoidCallback? onSaveAndNew;

  /// Whether continuous recording mode is enabled.
  final bool isContinuousMode;

  /// Called when the continuous-mode icon is toggled.
  final VoidCallback? onToggleContinuous;

  /// Transaction type: "expense", "income", or "transfer".
  /// Controls the primary button color.
  final String transactionType;

  /// Whether the save buttons should be enabled.
  final bool enabled;

  const TransactionFooterBar({
    super.key,
    required this.source,
    this.onSave,
    this.onSaveAndNew,
    this.isContinuousMode = false,
    this.onToggleContinuous,
    this.transactionType = 'expense',
    this.enabled = true,
  });

  /// Returns the submit button label based on the entry source.
  String get _submitLabel {
    switch (source) {
      case TransactionEntrySource.manual:
        return '保存';
      case TransactionEntrySource.quickAction:
        return '立即记录';
      case TransactionEntrySource.voice:
      case TransactionEntrySource.conversation:
      case TransactionEntrySource.autoDraft:
      case TransactionEntrySource.ocrScreenshot:
      case TransactionEntrySource.shareReceive:
      case TransactionEntrySource.deepLink:
        return '确认入账';
      case TransactionEntrySource.edit:
        return '保存修改';
    }
  }

  /// Returns the primary button color based on the transaction type.
  Color get _primaryColor {
    switch (transactionType) {
      case 'income':
        return const Color(0xFF4CAF50);
      case 'transfer':
        return const Color(0xFF1976D2);
      case 'expense':
      default:
        return const Color(0xFFEF5350);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = source == TransactionEntrySource.edit;
    final primaryColor = _primaryColor;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: JiveTheme.cardColor(context),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? JiveTheme.darkDivider
                  : Colors.grey.shade200,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Continuous-mode toggle (hidden in edit mode)
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '连续记账',
                      style: TextStyle(
                        fontSize: 12,
                        color: JiveTheme.secondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onToggleContinuous,
                      child: Icon(
                        isContinuousMode
                            ? Icons.repeat_on
                            : Icons.repeat,
                        size: 20,
                        color: isContinuousMode
                            ? JiveTheme.primaryGreen
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            // Button row
            Row(
              children: [
                // Save & New (hidden in edit mode)
                if (!isEditing) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: enabled ? onSaveAndNew : null,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('保存并新建'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Primary save
                Expanded(
                  flex: isEditing ? 1 : 2,
                  child: FilledButton.icon(
                    onPressed: enabled ? onSave : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(_submitLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
