import 'package:flutter/material.dart';

import '../../../core/database/account_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/account_service.dart';

/// Represents one row in a split (composite) transaction.
class TxSplitEntry {
  JiveAccount account;
  double amount;
  double? discount;
  double? fee;

  TxSplitEntry({
    required this.account,
    required this.amount,
    this.discount,
    this.fee,
  });

  double get netAmount => amount - (discount ?? 0) + (fee ?? 0);
}

/// Opens the 组合记账 sheet where a user can pick multiple accounts and
/// specify an amount / discount / fee for each. Returns the edited
/// split list (empty = cancelled / cleared) or null if dismissed.
Future<List<TxSplitEntry>?> showTransactionSplitSheet(
  BuildContext context, {
  required List<JiveAccount> accounts,
  required List<TxSplitEntry> initial,
}) {
  return showModalBottomSheet<List<TxSplitEntry>>(
    context: context,
    backgroundColor: JiveTheme.cardColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) => _SplitSheet(
      accounts: accounts,
      initial: initial,
    ),
  );
}

class _SplitSheet extends StatefulWidget {
  final List<JiveAccount> accounts;
  final List<TxSplitEntry> initial;

  const _SplitSheet({required this.accounts, required this.initial});

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  late List<TxSplitEntry> _splits;

  @override
  void initState() {
    super.initState();
    _splits = widget.initial
        .map((e) => TxSplitEntry(
              account: e.account,
              amount: e.amount,
              discount: e.discount,
              fee: e.fee,
            ))
        .toList();
  }

  double get _totalNet =>
      _splits.fold(0.0, (sum, s) => sum + s.netAmount);

  Future<void> _addSplit() async {
    final entry = await _showSplitEditor(null);
    if (entry != null && mounted) {
      setState(() => _splits.add(entry));
    }
  }

  Future<void> _editSplit(int index) async {
    final entry = await _showSplitEditor(_splits[index]);
    if (entry != null && mounted) {
      setState(() => _splits[index] = entry);
    }
  }

  void _removeSplit(int index) {
    setState(() => _splits.removeAt(index));
  }

  Future<TxSplitEntry?> _showSplitEditor(TxSplitEntry? current) async {
    final accountCtrl = ValueNotifier<JiveAccount?>(
      current?.account ?? widget.accounts.firstOrNull,
    );
    final amountCtrl = TextEditingController(
      text: current != null
          ? current.amount.toStringAsFixed(current.amount % 1 == 0 ? 0 : 2)
          : '',
    );
    final discountCtrl = TextEditingController(
      text: current?.discount != null && current!.discount! > 0
          ? current.discount!.toStringAsFixed(
              current.discount! % 1 == 0 ? 0 : 2)
          : '',
    );
    final feeCtrl = TextEditingController(
      text: current?.fee != null && current!.fee! > 0
          ? current.fee!.toStringAsFixed(current.fee! % 1 == 0 ? 0 : 2)
          : '',
    );

    return showModalBottomSheet<TxSplitEntry>(
      context: context,
      backgroundColor: JiveTheme.cardColor(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setDialog) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  current == null ? '添加账户' : '编辑账户',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: JiveTheme.textColor(ctx),
                  ),
                ),
                const SizedBox(height: 12),
                // Account dropdown
                ValueListenableBuilder<JiveAccount?>(
                  valueListenable: accountCtrl,
                  builder: (_, value, __) => DropdownButtonFormField<int>(
                    initialValue: value?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '账户',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Row(
                              children: [
                                AccountService.buildIcon(
                                  a.iconName,
                                  size: 16,
                                  color: AccountService.parseColorHex(
                                          a.colorHex) ??
                                      JiveTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Text('${a.name} · ${a.currency}'),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      final picked = widget.accounts
                          .firstWhere((a) => a.id == id);
                      accountCtrl.value = picked;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: '金额',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: '优惠',
                          prefixText: '- ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: feeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: '手续费',
                          prefixText: '+ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final account = accountCtrl.value;
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (account == null || amount <= 0) {
                          ScaffoldMessenger.of(ctx)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('请选择账户并输入金额'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          return;
                        }
                        Navigator.pop(
                          ctx,
                          TxSplitEntry(
                            account: account,
                            amount: amount,
                            discount:
                                double.tryParse(discountCtrl.text),
                            fee: double.tryParse(feeCtrl.text),
                          ),
                        );
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '组合记账',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: JiveTheme.textColor(context),
                  ),
                ),
                const Spacer(),
                Text(
                  '合计 ¥${_totalNet.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: JiveTheme.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '把一笔交易拆到多个账户，各自可记优惠和手续费。',
              style: TextStyle(
                fontSize: 12,
                color: JiveTheme.secondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            // Splits list
            Flexible(
              child: _splits.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          '暂无账户，点下方"添加账户"开始',
                          style: TextStyle(
                            color: JiveTheme.secondaryTextColor(context),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _splits.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final split = _splits[index];
                        final color = AccountService.parseColorHex(
                                split.account.colorHex) ??
                            JiveTheme.primaryGreen;
                        final subtitleBits = <String>[
                          '¥${split.amount.toStringAsFixed(2)}',
                          if (split.discount != null && split.discount! > 0)
                            '优惠 -${split.discount!.toStringAsFixed(2)}',
                          if (split.fee != null && split.fee! > 0)
                            '手续费 +${split.fee!.toStringAsFixed(2)}',
                        ];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: AccountService.buildIcon(
                              split.account.iconName,
                              size: 18,
                              color: color,
                            ),
                          ),
                          title: Text(split.account.name),
                          subtitle: Text(subtitleBits.join(' · ')),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeSplit(index),
                          ),
                          onTap: () => _editSplit(index),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addSplit,
              icon: const Icon(Icons.add),
              label: const Text('添加账户'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_splits.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _splits.clear());
                    },
                    child: const Text('清空'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _splits),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
