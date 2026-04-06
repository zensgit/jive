import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Large currency symbol + amount text display for the transaction editor.
///
/// Colors by transaction type:
/// - expense: red (EF5350)
/// - income: green (4CAF50)
/// - transfer: blue (1976D2)
///
/// Supports a compact mode for landscape orientation (smaller font sizes).
class TransactionAmountDisplay extends StatelessWidget {
  /// The amount string to display (e.g. "0", "123.45", "1+2").
  final String amountStr;

  /// Currency symbol (e.g. "¥", "$").
  final String currencySymbol;

  /// Transaction type: "expense", "income", or "transfer".
  final String transactionType;

  /// When true, uses smaller font sizes suitable for landscape layout.
  final bool compact;

  const TransactionAmountDisplay({
    super.key,
    required this.amountStr,
    required this.currencySymbol,
    required this.transactionType,
    this.compact = false,
  });

  /// Returns the color corresponding to the transaction type.
  Color get _amountColor {
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
    final amountFontSize = compact ? 48.0 : 72.0;
    final currencyFontSize = compact ? 22.0 : 32.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          currencySymbol,
          style: GoogleFonts.rubik(
            color: Colors.black87,
            fontSize: currencyFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            amountStr,
            style: GoogleFonts.rubik(
              color: _amountColor,
              fontSize: amountFontSize,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
