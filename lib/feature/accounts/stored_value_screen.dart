import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/stored_value_service.dart';

/// Screen listing stored-value / gift-voucher cards.
class StoredValueScreen extends StatefulWidget {
  const StoredValueScreen({super.key});

  @override
  State<StoredValueScreen> createState() => _StoredValueScreenState();
}

class _StoredValueScreenState extends State<StoredValueScreen> {
  final StoredValueService _svc = StoredValueService();
  bool _isLoading = true;
  List<StoredValueInfo> _cards = [];
  List<StoredValueInfo> _expiringSoon = [];
  Map<int, JiveAccount> _accountMap = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isar = await DatabaseService.getInstance();
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    final map = <int, JiveAccount>{};
    for (final a in accounts) {
      map[a.id] = a;
    }
    final cards = await _svc.getStoredValues();
    final expiring = await _svc.getExpiringCards(30);
    if (mounted) {
      setState(() {
        _accountMap = map;
        _cards = cards;
        _expiringSoon = expiring;
        _isLoading = false;
      });
    }
  }

  void _showCreateDialog() {
    final balanceCtrl = TextEditingController();
    final cardNumCtrl = TextEditingController();
    int? selectedAccountId;
    DateTime? selectedExpiry;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final accountOptions = _accountMap.values.toList();
            return AlertDialog(
              title: const Text('新增储值卡'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: '关联账户'),
                      items: accountOptions
                          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                          .toList(),
                      onChanged: (v) => selectedAccountId = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceCtrl,
                      decoration: const InputDecoration(labelText: '初始余额'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cardNumCtrl,
                      decoration: const InputDecoration(labelText: '卡号 (可选)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedExpiry != null
                                ? '到期: ${selectedExpiry.toString().substring(0, 10)}'
                                : '到期日期 (可选)',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedExpiry = picked);
                            }
                          },
                          child: const Text('选择'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                FilledButton(
                  onPressed: () async {
                    final balance = double.tryParse(balanceCtrl.text);
                    if (selectedAccountId == null || balance == null || balance <= 0) return;
                    await _svc.createStoredValue(
                      selectedAccountId!,
                      balance,
                      expiryDate: selectedExpiry,
                      cardNumber: cardNumCtrl.text.isEmpty ? null : cardNumCtrl.text,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('储值卡 / 礼品卡'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('暂无储值卡'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('新增'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_expiringSoon.isNotEmpty) ...[
                      _buildSectionHeader('即将到期', Colors.orange),
                      ..._expiringSoon.map((c) => _buildCardTile(c, highlight: true)),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionHeader('全部储值卡', JiveTheme.primaryGreen),
                    ..._cards.map((c) => _buildCardTile(c)),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildCardTile(StoredValueInfo card, {bool highlight = false}) {
    final acct = _accountMap[card.accountId];
    final name = acct?.name ?? '账户 #${card.accountId}';
    final usedPct = card.originalBalance > 0
        ? ((card.originalBalance - card.currentBalance) / card.originalBalance).clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = card.expiryDate?.difference(DateTime.now()).inDays;

    final borderColor = highlight ? Colors.orange : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, size: 20, color: highlight ? Colors.orange : JiveTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              if (card.cardNumber != null)
                Text(card.cardNumber!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usedPct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                usedPct > 0.8 ? Colors.red : JiveTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '余额 \u00a5${card.currentBalance.toStringAsFixed(2)} / \u00a5${card.originalBalance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (daysLeft != null)
                Text(
                  daysLeft > 0 ? '$daysLeft 天后到期' : '已过期',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: daysLeft <= 30 ? Colors.orange : Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
