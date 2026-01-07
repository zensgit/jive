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
  bool _showInactive = false;
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
    final accounts = await service.getAllAccounts();
    final activeAccounts = accounts.where((account) => !account.isHidden && !account.isArchived).toList();
    final balances = await service.computeBalances(accounts: accounts);
    final totals = service.calculateTotals(activeAccounts, balances);

    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _balances = balances;
      _totals = totals;
      _isLoading = false;
    });
  }

  Future<void> _showCreateAccountDialog() async {
    final result = await _showAccountDialog();
    if (result == null) return;
    final openingBalance = result.type == AccountService.typeLiability
        ? -result.openingBalance.abs()
        : result.openingBalance;

    await AccountService(_isar).createAccount(
      name: result.name,
      type: result.type,
      subType: result.subType,
      openingBalance: openingBalance,
      groupName: result.groupName,
      billingDay: result.billingDay,
      repaymentDay: result.repaymentDay,
      creditLimit: result.creditLimit,
      includeInBalance: result.includeInBalance,
      isHidden: result.isHidden,
      isArchived: result.isArchived,
    );

    if (!mounted) return;
    _loadAccounts();
  }

  Future<void> _showEditAccountDialog(JiveAccount account) async {
    final result = await _showAccountDialog(account: account);
    if (result == null) return;
    account
      ..name = result.name
      ..type = result.type
      ..subType = result.subType
      ..groupName = result.groupName
      ..includeInBalance = result.includeInBalance
      ..isHidden = result.isHidden
      ..isArchived = result.isArchived
      ..billingDay = result.billingDay
      ..repaymentDay = result.repaymentDay
      ..creditLimit = result.creditLimit;
    final openingBalance = result.type == AccountService.typeLiability
        ? -result.openingBalance.abs()
        : result.openingBalance;
    account.openingBalance = openingBalance;

    await AccountService(_isar).updateAccount(account);

    if (!mounted) return;
    _loadAccounts();
  }

  Future<_AccountDraft?> _showAccountDialog({JiveAccount? account}) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final billDayController = TextEditingController();
    final repayDayController = TextEditingController();
    final creditLimitController = TextEditingController();
    var type = account?.type ?? AccountService.typeAsset;
    var subType = account?.subType ?? 'cash';
    var includeInBalance = account?.includeInBalance ?? true;
    var isHidden = account?.isHidden ?? false;
    var isArchived = account?.isArchived ?? false;
    var groupName = account?.groupName;
    final isEditing = account != null;

    if (account != null) {
      nameController.text = account.name;
      if (account.openingBalance != 0) {
        balanceController.text = account.openingBalance.abs().toStringAsFixed(2);
      }
      if (account.billingDay != null) {
        billDayController.text = account.billingDay.toString();
      }
      if (account.repaymentDay != null) {
        repayDayController.text = account.repaymentDay.toString();
      }
      final limit = account.creditLimit;
      if (limit != null && limit != 0) {
        creditLimitController.text = limit.toStringAsFixed(2);
      }
    }

    final result = await showDialog<_AccountDraft>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final subTypes = _subTypesFor(type);
            if (!subTypes.any((item) => item.key == subType)) {
              subType = subTypes.first.key;
            }
            final isCredit = type == AccountService.typeLiability && subType == 'credit';
            return AlertDialog(
              title: Text(isEditing ? "编辑账户" : "新增账户"),
              content: SingleChildScrollView(
                child: Column(
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
                  DropdownButtonFormField<String>(
                    value: groupName ?? AccountService.resolveGroupName(type, subType, groupName),
                    decoration: const InputDecoration(labelText: "账户分组"),
                    items: [
                      for (final item in _groupOptions)
                        DropdownMenuItem(value: item.key, child: Text(item.label)),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        groupName = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "期初余额"),
                  ),
                  if (isCredit) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: creditLimitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "信用额度"),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: billDayController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "账单日"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: repayDayController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "还款日"),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: includeInBalance,
                    title: const Text("计入净资产"),
                    onChanged: (value) => setDialogState(() => includeInBalance = value),
                  ),
                  SwitchListTile(
                    value: isHidden,
                    title: const Text("隐藏账户"),
                    onChanged: (value) => setDialogState(() => isHidden = value),
                  ),
                  SwitchListTile(
                    value: isArchived,
                    title: const Text("归档账户"),
                    onChanged: (value) => setDialogState(() => isArchived = value),
                  ),
                ],
              ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final amount = double.tryParse(balanceController.text.trim()) ?? 0;
                    final billingDay = int.tryParse(billDayController.text.trim());
                    final repaymentDay = int.tryParse(repayDayController.text.trim());
                    final creditLimit = double.tryParse(creditLimitController.text.trim());
                    Navigator.pop(
                      context,
                      _AccountDraft(
                        name: name,
                        type: type,
                        subType: subType,
                        openingBalance: amount,
                        groupName: groupName ?? AccountService.resolveGroupName(type, subType, groupName),
                        billingDay: billingDay,
                        repaymentDay: repaymentDay,
                        creditLimit: creditLimit,
                        includeInBalance: includeInBalance,
                        isHidden: isHidden,
                        isArchived: isArchived,
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

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleAccounts = _showInactive
        ? _accounts
        : _accounts.where((account) => !account.isHidden && !account.isArchived).toList();
    final groupedAccounts = _groupAccounts(visibleAccounts);

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
            const SizedBox(height: 6),
            Row(
              children: [
                Text("显示隐藏/归档", style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Switch(
                  value: _showInactive,
                  onChanged: (value) => setState(() => _showInactive = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            for (final entry in groupedAccounts.entries) ...[
              _buildSection(entry.key, entry.value),
              const SizedBox(height: 16),
            ],
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
    final status = [
      if (account.isHidden) "已隐藏",
      if (account.isArchived) "已归档",
    ];
    final groupLabel = AccountService.displayGroupName(account);
    final creditMeta = AccountService.isCreditAccount(account)
        ? _creditMeta(account, balance)
        : null;
    final detailParts = <String>[
      groupLabel,
      if (creditMeta != null && creditMeta.isNotEmpty) creditMeta,
      if (status.isNotEmpty) status.join(" · "),
    ];
    final detailText = detailParts.where((value) => value.isNotEmpty).join(" · ");
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditAccountDialog(account),
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
                  detailText,
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

  Map<String, List<JiveAccount>> _groupAccounts(List<JiveAccount> accounts) {
    final grouped = <String, List<JiveAccount>>{};
    for (final account in accounts) {
      final group = AccountService.displayGroupName(account);
      grouped.putIfAbsent(group, () => []).add(account);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.order.compareTo(b.order));
    }
    final ordered = <String, List<JiveAccount>>{};
    for (final group in _groupOptions) {
      if (grouped.containsKey(group.key)) {
        ordered[group.key] = grouped[group.key]!;
      }
    }
    final remainingKeys = grouped.keys.where((key) => !ordered.containsKey(key)).toList()..sort();
    for (final key in remainingKeys) {
      ordered[key] = grouped[key]!;
    }
    return ordered;
  }

  String _creditMeta(JiveAccount account, double balance) {
    final parts = <String>[];
    if (account.billingDay != null && account.billingDay! > 0) {
      parts.add("账单日${account.billingDay}");
    }
    if (account.repaymentDay != null && account.repaymentDay! > 0) {
      parts.add("还款日${account.repaymentDay}");
    }
    final creditLimit = account.creditLimit ?? 0;
    if (creditLimit > 0) {
      final used = balance < 0 ? -balance : 0.0;
      final available = (creditLimit - used).clamp(0, double.infinity).toDouble();
      parts.add("额度¥${_formatCompact(creditLimit)}");
      parts.add("已用¥${_formatCompact(used)}");
      parts.add("可用¥${_formatCompact(available)}");
    }
    return parts.join(" ");
  }

  String _formatCompact(double value) {
    return NumberFormat.compactCurrency(symbol: "", decimalDigits: 0).format(value);
  }
}

class _AccountDraft {
  final String name;
  final String type;
  final String subType;
  final double openingBalance;
  final String groupName;
  final int? billingDay;
  final int? repaymentDay;
  final double? creditLimit;
  final bool includeInBalance;
  final bool isHidden;
  final bool isArchived;

  const _AccountDraft({
    required this.name,
    required this.type,
    required this.subType,
    required this.openingBalance,
    required this.groupName,
    this.billingDay,
    this.repaymentDay,
    this.creditLimit,
    required this.includeInBalance,
    required this.isHidden,
    required this.isArchived,
  });
}

class _SubTypeOption {
  final String key;
  final String label;

  const _SubTypeOption(this.key, this.label);
}

class _GroupOption {
  final String key;
  final String label;

  const _GroupOption(this.key, this.label);
}

const List<_GroupOption> _groupOptions = [
  _GroupOption(AccountService.groupAssets, '资金账户'),
  _GroupOption(AccountService.groupCredit, '信用账户'),
  _GroupOption(AccountService.groupDebt, '债务账户'),
  _GroupOption(AccountService.groupReimburse, '报销账户'),
  _GroupOption(AccountService.groupOther, '其他账户'),
];
