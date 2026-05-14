import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/service/account_group_service.dart';

class AccountGroupSummaryHeader extends StatelessWidget {
  final AccountGroupSummary group;

  const AccountGroupSummaryHeader({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final currencies = group.currencies.toList()..sort();
    final currencyLabel = currencies.join(' / ');
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: JiveTheme.primaryGreen.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_outlined,
            color: JiveTheme.primaryGreen,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${group.accounts.length} 个子账户 · $currencyLabel',
                style: GoogleFonts.lato(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
