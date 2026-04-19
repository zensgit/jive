import 'package:flutter/material.dart';

import '../transaction_entry_params.dart';

/// A subtle banner displayed at the top of the transaction editor when the
/// entry source is neither [TransactionEntrySource.manual] nor
/// [TransactionEntrySource.edit].
///
/// Shows an icon and a short label describing where the prefilled data came
/// from (e.g. "来自语音输入", "来自快速动作「午餐」").
class TransactionSourceBanner extends StatelessWidget {
  final TransactionEntryParams params;

  const TransactionSourceBanner({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final bannerText = params.sourceBannerText;

    // Nothing to show for manual / edit sources.
    if (bannerText == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon;
    switch (params.source) {
      case TransactionEntrySource.quickAction:
        icon = Icons.flash_on;
      case TransactionEntrySource.voice:
        icon = Icons.mic;
      case TransactionEntrySource.conversation:
        icon = Icons.chat_bubble_outline;
      case TransactionEntrySource.autoDraft:
        icon = Icons.auto_awesome;
      case TransactionEntrySource.ocrScreenshot:
        icon = Icons.document_scanner_outlined;
      case TransactionEntrySource.shareReceive:
        icon = Icons.share;
      case TransactionEntrySource.deepLink:
        icon = Icons.link;
      case TransactionEntrySource.manual:
      case TransactionEntrySource.edit:
        icon = Icons.info_outline; // unreachable
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bannerText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
