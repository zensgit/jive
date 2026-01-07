import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/service/account_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  List<JiveAccount> _accounts = [];
  Map<int, double> _balances = {};
  AccountTotals _totals = const AccountTotals(assets: 0, liabilities: 0);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
    } else {
      _isar = await Isar.open(
        [JiveTransactionSchema, JiveCategorySchema, JiveAccountSchema, JiveAutoDraftSchema],
        directory: dir.path,
      );
    }

    final service = AccountService(_isar);
    await service.initDefaultAccounts();
    final accounts = await service.getActiveAccounts();
    final balances = await service.computeBalances(accounts: accounts);
    final totals = service.calculateTotals(accounts, balances);

    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _balances = balances;
      _totals = totals;
      _isLoading = false;
    });
  }

  Future<void> _showCreateAccountDialog() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    var type = AccountService.typeAsset;
    var subType = 'cash';
    var includeInBalance = true;

    final result = await showDialog<_AccountDraft>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final subTypes = _subTypesFor(type);
            if (!subTypes.any((item) => item.key == subType)) {
              subType = subTypes.first.key;
            }
            return AlertDialog(
              title: const Text("新增账户"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "账户名称"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: "账户类型"),
                    items: const [
                      DropdownMenuItem(value: AccountService.typeAsset, child: Text("资产")),
                      DropdownMenuItem(value: AccountService.typeLiability, child: Text("负债")),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        type = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: subType,
                    decoration: const InputDecoration(labelText: "账户子类"),
                    items: [
                      for (final item in _subTypesFor(type))
                        DropdownMenuItem(value: item.key, child: Text(item.label)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        subType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "期初余额"),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: includeInBalance,
                    title: const Text("计入净资产"),
                    onChanged: (value) => setDialogState(() => includeInBalance = value),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final amount = double.tryParse(balanceController.text.trim()) ?? 0;
                    Navigator.pop(
                      context,
                      _AccountDraft(
                        name: name,
                        type: type,
                        subType: subType,
                        openingBalance: amount,
                        includeInBalance: includeInBalance,
                      ),
                    );
                  },
                  child: const Text("保存"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final openingBalance = result.type == AccountService.typeLiability
        ? -result.openingBalance.abs()
        : result.openingBalance;

    await AccountService(_isar).createAccount(
      name: result.name,
      type: result.type,
      subType: result.subType,
      openingBalance: openingBalance,
      includeInBalance: result.includeInBalance,
    );

    if (!mounted) return;
    _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final assetAccounts = _accounts
        .where((account) => account.type == AccountService.typeAsset)
        .toList();
    final liabilityAccounts = _accounts
        .where((account) => account.type == AccountService.typeLiability)
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAccounts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("资产", style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _showCreateAccountDialog,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildSection("资产账户", assetAccounts),
            const SizedBox(height: 16),
            _buildSection("负债账户", liabilityAccounts),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final netAssets = _totals.net;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("净资产", style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: "¥").format(netAssets),
            style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetaStat("资产", _totals.assets, JiveTheme.primaryGreen),
              const SizedBox(width: 16),
              _buildMetaStat("负债", _totals.liabilities, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaStat(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        "$label ${NumberFormat.compactCurrency(symbol: "¥", decimalDigits: 0).format(value)}",
        style: GoogleFonts.lato(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSection(String title, List<JiveAccount> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (accounts.isEmpty)
          Text("暂无账户", style: GoogleFonts.lato(color: Colors.grey.shade500))
        else
          Column(
            children: [
              for (final account in accounts) _buildAccountItem(account),
            ],
          ),
      ],
    );
  }

  Widget _buildAccountItem(JiveAccount account) {
    final balance = _balances[account.id] ?? account.openingBalance;
    final displayBalance = account.type == AccountService.typeLiability ? balance.abs() : balance;
    final amountColor = account.type == AccountService.typeLiability ? Colors.redAccent : JiveTheme.primaryGreen;
    final color = AccountService.parseColorHex(account.colorHex) ?? JiveTheme.primaryGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: AccountService.buildIcon(account.iconName, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  account.type == AccountService.typeLiability ? "负债账户" : "资产账户",
                  style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: "¥").format(displayBalance),
            style: GoogleFonts.rubik(color: amountColor, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<_SubTypeOption> _subTypesFor(String type) {
    if (type == AccountService.typeLiability) {
      return const [
        _SubTypeOption('credit', '信用卡'),
        _SubTypeOption('loan', '借入'),
        _SubTypeOption('other_liability', '其他负债'),
      ];
    }
    return const [
      _SubTypeOption('cash', '现金'),
      _SubTypeOption('bank', '银行卡'),
      _SubTypeOption('wallet', '电子钱包'),
      _SubTypeOption('other_asset', '其他资产'),
    ];
  }
}

class _AccountDraft {
  final String name;
  final String type;
  final String subType;
  final double openingBalance;
  final bool includeInBalance;

  const _AccountDraft({
    required this.name,
    required this.type,
    required this.subType,
    required this.openingBalance,
    required this.includeInBalance,
  });
}

class _SubTypeOption {
  final String key;
  final String label;

  const _SubTypeOption(this.key, this.label);
}
