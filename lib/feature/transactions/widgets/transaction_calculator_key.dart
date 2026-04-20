import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme.dart';
import '../add_transaction_screen.dart' show TransactionType;

class TransactionCalculatorKey extends StatelessWidget {
  final String keyValue;
  final TransactionType txType;
  final ValueChanged<String> onKeyPress;
  final VoidCallback? onOkLongPressStart;
  final VoidCallback? onOkLongPressEnd;
  final VoidCallback? onOkLongPressCancel;
  final bool speechActive;

  /// 当 keyValue == '+' 时，显示的实际标签（'+' 或 '×'）
  final String? plusLabel;

  /// 当 keyValue == '-' 时，显示的实际标签（'-' 或 '÷'）
  final String? minusLabel;

  /// 长按运算符键时的回调（用于切换 +↔× 或 -↔÷）
  final VoidCallback? onOperatorToggle;

  const TransactionCalculatorKey({
    super.key,
    required this.keyValue,
    required this.txType,
    required this.onKeyPress,
    this.onOkLongPressStart,
    this.onOkLongPressEnd,
    this.onOkLongPressCancel,
    this.speechActive = false,
    this.plusLabel,
    this.minusLabel,
    this.onOperatorToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = keyValue == 'OK';
    final isDel = keyValue == 'DEL';
    final isAgain = keyValue == 'AGAIN';
    final isPlus = keyValue == '+';
    final isMinus = keyValue == '-';
    final textColor = JiveTheme.textColor(context);
    final secondary = JiveTheme.secondaryTextColor(context);

    // ── OK button ──
    if (isOk) {
      final okColor = speechActive
          ? const Color(0xFFFF7043)
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

    // ── +/× 和 -/÷ 可切换运算符键 ──
    if (isPlus || isMinus) {
      final displayLabel = isPlus ? (plusLabel ?? '+') : (minusLabel ?? '-');
      final altLabel = isPlus ? '长按×' : '长按÷';
      final isShowingAlt = isPlus ? displayLabel == '×' : displayLabel == '÷';
      final activeColor = JiveTheme.primaryGreen;
      final activeBackground = activeColor.withValues(alpha: 0.10);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onKeyPress(keyValue),
        onLongPress: onOperatorToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isShowingAlt ? activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isShowingAlt
                  ? activeColor.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 22,
                    color: activeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // 小字提示另一个运算符，同时在 ×/÷ 状态下给出更明显的反馈。
                Text(
                  isShowingAlt ? (isPlus ? '当前×' : '当前÷') : altLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: isShowingAlt
                        ? activeColor.withValues(alpha: 0.78)
                        : secondary.withValues(alpha: 0.5),
                    fontWeight: isShowingAlt
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── 普通键 ──
    return InkWell(
      onTap: () => onKeyPress(keyValue),
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: isDel
            ? Icon(Icons.backspace_rounded, size: 22, color: secondary)
            : isAgain
            ? Text(
                '再记',
                style: TextStyle(
                  fontSize: 14,
                  color: secondary,
                  fontWeight: FontWeight.w500,
                ),
              )
            : Text(
                keyValue,
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }
}
