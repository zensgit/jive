import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../add_transaction_screen.dart' show TransactionType;

/// Pill-shaped segmented control for choosing the transaction type
/// (expense / income / transfer) at the top of the editor app bar.
///
/// Extracted from `add_transaction_screen.dart` to reduce monolith size.
class TransactionTypeSelector extends StatelessWidget {
  final TransactionType currentType;
  final ValueChanged<TransactionType> onChanged;

  const TransactionTypeSelector({
    super.key,
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypeChip(
              type: TransactionType.expense,
              icon: Icons.arrow_upward,
              label: '支出',
              isSelected: currentType == TransactionType.expense,
              onTap: () => onChanged(TransactionType.expense),
            ),
            _TypeChip(
              type: TransactionType.income,
              icon: Icons.arrow_downward,
              label: '收入',
              isSelected: currentType == TransactionType.income,
              onTap: () => onChanged(TransactionType.income),
            ),
            _TypeChip(
              type: TransactionType.transfer,
              icon: Icons.swap_horiz,
              label: '转账',
              isSelected: currentType == TransactionType.transfer,
              onTap: () => onChanged(TransactionType.transfer),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final TransactionType type;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black87 : Colors.black38,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                color: isSelected ? Colors.black87 : Colors.black45,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
