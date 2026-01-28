import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme.dart';

class TransactionTagChips extends StatelessWidget {
  final String tags;

  const TransactionTagChips({
    super.key,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final tagList = tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (tagList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.label_outline, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(
            '标签',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: tagList.map((tag) => _buildTagChip(tag)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: JiveTheme.accentLime.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: JiveTheme.accentLime,
          width: 1,
        ),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: JiveTheme.primaryGreen,
        ),
      ),
    );
  }
}
