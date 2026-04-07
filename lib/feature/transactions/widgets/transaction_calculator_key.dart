import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../add_transaction_screen.dart' show TransactionType;

/// Single button on the custom number-pad keyboard at the bottom of the
/// transaction editor. Renders differently for digits, operators, the date
/// picker icon, the delete key, and the OK confirm button (which adapts its
/// color to the current transaction type).
///
/// Extracted from `add_transaction_screen.dart` to reduce monolith size.
class TransactionCalculatorKey extends StatelessWidget {
  final String keyValue;
  final TransactionType txType;
  final ValueChanged<String> onKeyPress;

  const TransactionCalculatorKey({
    super.key,
    required this.keyValue,
    required this.txType,
    required this.onKeyPress,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = keyValue == 'OK';
    final isDel = keyValue == 'DEL';

    if (isOk) {
      final okColor = txType == TransactionType.income
          ? const Color(0xFF4CAF50)
          : txType == TransactionType.transfer
              ? const Color(0xFF1976D2)
              : const Color(0xFFEF5350);
      return InkWell(
        onTap: () => onKeyPress(keyValue),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            color: okColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: okColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.check, color: Colors.white, size: 28),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onKeyPress(keyValue),
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: isDel
            ? const Icon(
                Icons.backspace_rounded,
                size: 22,
                color: Colors.black54,
              )
            : ['+', '-', 'date'].contains(keyValue)
                ? _OpIcon(keyValue: keyValue)
                : Text(
                    keyValue,
                    style: GoogleFonts.rubik(
                      fontSize: 26,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
      ),
    );
  }
}

class _OpIcon extends StatelessWidget {
  final String keyValue;
  const _OpIcon({required this.keyValue});

  @override
  Widget build(BuildContext context) {
    if (keyValue == 'date') {
      return const Icon(
        Icons.calendar_today_rounded,
        size: 20,
        color: Colors.black45,
      );
    }
    return Text(
      keyValue,
      style: const TextStyle(fontSize: 24, color: Colors.black45),
    );
  }
}
