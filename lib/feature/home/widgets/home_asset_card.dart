import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomeAssetCard extends StatelessWidget {
  final bool compact;
  final bool tight;
  final double totalAssets;
  final double totalLiabilities;
  final double totalCreditLimit;
  final double totalCreditUsed;
  final double totalCreditAvailable;
  final String baseCurrency;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onAddTransfer;
  final VoidCallback onCurrencyConverter;

  const HomeAssetCard({
    super.key,
    this.compact = false,
    this.tight = false,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalCreditLimit,
    required this.totalCreditUsed,
    required this.totalCreditAvailable,
    required this.baseCurrency,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onAddTransfer,
    required this.onCurrencyConverter,
  });

  @override
  Widget build(BuildContext context) {
    final padding = tight ? 16.0 : (compact ? 20.0 : 28.0);
    final amountSize = tight ? 28.0 : (compact ? 32.0 : 40.0);
    final headerGap = tight ? 10.0 : (compact ? 14.0 : 20.0);
    final actionGap = tight ? 12.0 : (compact ? 18.0 : 32.0);
    final titleSize = tight ? 11.0 : (compact ? 12.0 : 14.0);
    final showActionLabels = !tight;
    final netAssets = totalAssets - totalLiabilities;
    final isNegativeNet = netAssets < 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wallet, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                "净资产",
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: titleSize,
                ),
              ),
            ],
          ),
          SizedBox(height: headerGap),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _formatAmount(netAssets, "¥"),
                maxLines: 1,
                style: GoogleFonts.rubik(
                  color: isNegativeNet ? Colors.red.shade400 : Colors.white,
                  fontSize: amountSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!tight) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBalanceMeta("资产", totalAssets),
                const SizedBox(width: 16),
                _buildBalanceMeta("负债", totalLiabilities),
              ],
            ),
            if (totalCreditLimit > 0) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _buildBalanceMeta("信用额度", totalCreditLimit),
                  _buildBalanceMeta("已用", totalCreditUsed),
                  _buildBalanceMeta("可用", totalCreditAvailable),
                ],
              ),
            ],
          ],
          SizedBox(height: actionGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionBtn(
                Icons.arrow_downward,
                "收入",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: onAddIncome,
              ),
              _buildActionBtn(
                Icons.arrow_upward,
                "支出",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: onAddExpense,
              ),
              _buildActionBtn(
                Icons.swap_horiz,
                "转账",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: onAddTransfer,
              ),
              _buildActionBtn(
                Icons.currency_exchange,
                "汇率",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: onCurrencyConverter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    final abs = amount.abs();
    final prefix = amount < 0 ? '-' : '';
    if (abs >= 100000000) {
      return '$prefix${currency}${(abs / 100000000).toStringAsFixed(1)}亿';
    }
    if (abs >= 10000) {
      return '$prefix${currency}${(abs / 10000).toStringAsFixed(1)}万';
    }
    return '$prefix$currency${NumberFormat('#,##0.00').format(abs)}';
  }

  Widget _buildActionBtn(
    IconData icon,
    String label, {
    bool compact = false,
    bool tight = false,
    bool showLabel = true,
    VoidCallback? onTap,
  }) {
    final padding = tight ? 8.0 : (compact ? 10.0 : 12.0);
    final iconSize = tight ? 18.0 : (compact ? 20.0 : 24.0);
    final labelSize = tight ? 10.0 : (compact ? 11.0 : 12.0);
    final gap = tight ? 4.0 : (compact ? 6.0 : 8.0);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          if (showLabel) ...[
            SizedBox(height: gap),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: labelSize),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceMeta(String label, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Text(
          NumberFormat.compactCurrency(
            symbol: "¥",
            decimalDigits: 0,
          ).format(amount),
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
