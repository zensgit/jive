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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypeChip(
            type: TransactionType.expense,
            label: '支出',
            isSelected: currentType == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _TypeChip(
            type: TransactionType.income,
            label: '收入',
            isSelected: currentType == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
          ),
          _TypeChip(
            type: TransactionType.transfer,
            label: '转账',
            isSelected: currentType == TransactionType.transfer,
            onTap: () => onChanged(TransactionType.transfer),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final TransactionType type;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
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
            Text(
              label,
              style: GoogleFonts.lato(
                color: isSelected ? Colors.black87 : Colors.black54,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
