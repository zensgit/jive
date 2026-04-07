import 'package:flutter/material.dart';

import '../../../core/database/account_model.dart';
import '../../../core/database/currency_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/account_service.dart';
import '../add_transaction_screen.dart' show TransactionType;

/// Account selector for the transaction editor.
///
/// Renders either a single account chip (expense/income) or a from→to pair
/// (transfer), with an optional cross-currency conversion card when the two
/// transfer accounts use different currencies.
///
/// Extracted from `add_transaction_screen.dart` to reduce monolith size.
class AccountSelectorSection extends StatelessWidget {
  final TransactionType txType;
  final JiveAccount? selectedAccount;
  final JiveAccount? selectedToAccount;
  final bool isLandscape;
  final TextEditingController toAmountController;
  final double? crossCurrencyRate;
  final String? crossCurrencyRateSource;
  final void Function(bool pickTo) onPickAccount;
  final ValueChanged<String> onToAmountChanged;
  final VoidCallback onRecalculateRate;

  const AccountSelectorSection({
    super.key,
    required this.txType,
    required this.selectedAccount,
    required this.selectedToAccount,
    required this.isLandscape,
    required this.toAmountController,
    required this.crossCurrencyRate,
    required this.crossCurrencyRateSource,
    required this.onPickAccount,
    required this.onToAmountChanged,
    required this.onRecalculateRate,
  });

  @override
  Widget build(BuildContext context) {
    final textSize = isLandscape ? 11.0 : 12.0;

    if (txType == TransactionType.transfer) {
      final fromCurrency = selectedAccount?.currency ?? 'CNY';
      final toCurrency = selectedToAccount?.currency ?? 'CNY';
      final isCrossCurrency = selectedAccount != null &&
          selectedToAccount != null &&
          fromCurrency != toCurrency;

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AccountChip(
                  label: '从',
                  account: selectedAccount,
                  textSize: textSize,
                  expand: true,
                  onTap: () => onPickAccount(false),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: AccountChip(
                  label: '到',
                  account: selectedToAccount,
                  textSize: textSize,
                  expand: true,
                  onTap: () => onPickAccount(true),
                ),
              ),
            ],
          ),
          if (isCrossCurrency) ...[
            const SizedBox(height: 8),
            _CrossCurrencyCard(
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              rate: crossCurrencyRate,
              rateSource: crossCurrencyRateSource,
              toAmountController: toAmountController,
              onToAmountChanged: onToAmountChanged,
              onRecalculate: onRecalculateRate,
            ),
          ],
        ],
      );
    }

    return Center(
      child: AccountChip(
        label: '账户',
        account: selectedAccount,
        textSize: textSize,
        expand: false,
        onTap: () => onPickAccount(false),
      ),
    );
  }
}

/// Compact pill chip showing an account name with its icon and brand color.
class AccountChip extends StatelessWidget {
  final String label;
  final JiveAccount? account;
  final double textSize;
  final bool expand;
  final VoidCallback onTap;

  const AccountChip({
    super.key,
    required this.label,
    required this.account,
    required this.textSize,
    required this.expand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AccountService.parseColorHex(account?.colorHex) ??
        JiveTheme.primaryGreen;
    final name = account?.name ?? '请选择';

    final inner = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        AccountService.buildIcon(
          account?.iconName ?? 'account_balance_wallet',
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        if (expand)
          Expanded(
            child: Text(
              '$label $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: textSize, color: Colors.black87),
            ),
          )
        else
          Text(
            '$label $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: textSize, color: Colors.black87),
          ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: inner,
        ),
      ),
    );
  }
}

/// Tiny status badge that indicates where the FX rate came from.
class RateSourceBadge extends StatelessWidget {
  final String source;

  const RateSourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (source) {
      case 'frankfurter':
      case 'exchangerate.host':
        color = Colors.green;
        label = '在线';
        break;
      case 'manual':
        color = Colors.orange;
        label = '手动';
        break;
      case 'default':
      default:
        color = Colors.grey;
        label = '默认';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Cross-currency conversion card shown under the transfer pair.
class _CrossCurrencyCard extends StatelessWidget {
  final String fromCurrency;
  final String toCurrency;
  final double? rate;
  final String? rateSource;
  final TextEditingController toAmountController;
  final ValueChanged<String> onToAmountChanged;
  final VoidCallback onRecalculate;

  const _CrossCurrencyCard({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.rateSource,
    required this.toAmountController,
    required this.onToAmountChanged,
    required this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.currency_exchange,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                '跨币种转账',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (rate != null) ...[
                RateSourceBadge(source: rateSource ?? 'default'),
                const SizedBox(width: 6),
                Text(
                  '1 $fromCurrency = ${rate!.toStringAsFixed(4)} $toCurrency',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // To-amount input
          Row(
            children: [
              Text(
                '转入金额',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Text(
                        CurrencyDefaults.getSymbol(toCurrency),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: toAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '0.00',
                          ),
                          onChanged: onToAmountChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Recalculate button
              InkWell(
                onTap: onRecalculate,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.orange.shade700,
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
