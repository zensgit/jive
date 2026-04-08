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
  final VoidCallback? onOkLongPressStart;
  final VoidCallback? onOkLongPressEnd;
  final VoidCallback? onOkLongPressCancel;
  final bool speechActive;

  const TransactionCalculatorKey({
    super.key,
    required this.keyValue,
    required this.txType,
    required this.onKeyPress,
    this.onOkLongPressStart,
    this.onOkLongPressEnd,
    this.onOkLongPressCancel,
    this.speechActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = keyValue == 'OK';
    final isDel = keyValue == 'DEL';
    final isAgain = keyValue == 'AGAIN';

    if (isOk) {
      final okColor = speechActive
          ? const Color(0xFFFF7043) // orange when holding to talk
          : txType == TransactionType.income
              ? const Color(0xFF4CAF50)
              : txType == TransactionType.transfer
                  ? const Color(0xFF1976D2)
                  : const Color(0xFFEF5350);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onKeyPress(keyValue),
        onLongPressStart: (_) => onOkLongPressStart?.call(),
        onLongPressEnd: (_) => onOkLongPressEnd?.call(),
        onLongPressCancel: () => onOkLongPressCancel?.call(),
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
          child: Center(
            child: Icon(
              speechActive ? Icons.mic : Icons.check,
              color: Colors.white,
              size: 28,
            ),
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
            : isAgain
                ? const Text(
                    '再记',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
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
