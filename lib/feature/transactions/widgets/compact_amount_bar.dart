import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/database/currency_model.dart';
import '../../../core/design_system/theme.dart';
import '../add_transaction_screen.dart' show TransactionType;

/// Compact amount bar shown above the calculator keyboard, mirroring iCost's
/// layout: large colored amount on the left, time + note hint on the right,
/// and an optional collapse arrow.
///
/// The amount color follows the transaction type:
/// - expense → red
/// - income → green
/// - transfer → blue
class CompactAmountBar extends StatelessWidget {
  final String amountStr;
  final String currency;
  final TransactionType txType;
  final DateTime selectedTime;
  final String? note;
  final VoidCallback onTapNote;
  final VoidCallback onTapTime;
  final VoidCallback? onTapCurrency;
  final double? expressionResult;
  final String? accountName;
  final VoidCallback? onTapAccount;

  const CompactAmountBar({
    super.key,
    required this.amountStr,
    required this.currency,
    required this.txType,
    required this.selectedTime,
    required this.note,
    required this.onTapNote,
    required this.onTapTime,
    this.onTapCurrency,
    this.expressionResult,
    this.accountName,
    this.onTapAccount,
  });

  Color _amountColor() {
    switch (txType) {
      case TransactionType.income:
        return const Color(0xFF4CAF50);
      case TransactionType.transfer:
        return const Color(0xFF1976D2);
      case TransactionType.expense:
        return const Color(0xFFEF5350);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = JiveTheme.isDark(context);
    final symbol = CurrencyDefaults.getSymbol(currency);
    final now = DateTime.now();
    final isToday = selectedTime.year == now.year &&
        selectedTime.month == now.month &&
        selectedTime.day == now.day;
    final timeText = isToday
        ? DateFormat('HH:mm').format(selectedTime)
        : DateFormat('MM-dd HH:mm').format(selectedTime);
    final hasNote = note != null && note!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? JiveTheme.darkCard : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark ? JiveTheme.darkDivider : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: account pill (left) + amount+currency (right-aligned)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (accountName != null)
                InkWell(
                  onTap: onTapAccount,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      accountName!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: JiveTheme.secondaryTextColor(context),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              // Amount (large, colored) + expression preview
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$symbol $amountStr',
                        style: GoogleFonts.rubik(
                          color: _amountColor(),
                          fontSize: expressionResult != null ? 18 : 28,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onTapCurrency,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currency,
                                style: GoogleFonts.rubik(
                                  color: _amountColor().withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (onTapCurrency != null)
                                Icon(
                                  Icons.unfold_more,
                                  size: 12,
                                  color: _amountColor().withValues(alpha: 0.6),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (expressionResult != null)
                    Text(
                      '= $symbol ${expressionResult!.toStringAsFixed(2)}',
                      style: GoogleFonts.rubik(
                        color: _amountColor(),
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: time + note (full width)
          Row(
            children: [
              InkWell(
                onTap: onTapTime,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: JiveTheme.secondaryTextColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: onTapNote,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      hasNote ? note! : '点击填写备注',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasNote
                            ? JiveTheme.textColor(context)
                            : JiveTheme.secondaryTextColor(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
