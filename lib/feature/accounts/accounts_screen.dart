import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/data/account_type_catalog.dart';
import '../../core/data/bank_catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/service/account_service.dart';
import 'account_reconcile_screen.dart';

class AccountsScreen extends StatefulWidget {
  final ValueListenable<int>? reloadSignal;
  final VoidCallback? onDataChanged;

  const AccountsScreen({
    super.key,
    this.reloadSignal,
    this.onDataChanged,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  List<JiveAccount> _accounts = [];
  Map<int, double> _balances = {};
  AccountTotals _totals = const AccountTotals(assets: 0, liabilities: 0);
  double _creditLimit = 0;
  double _creditUsed = 0;
  double _creditAvailable = 0;
  final ImagePicker _imagePicker = ImagePicker();

  static const List<String> _accountColorPalette = [
    '#43A047',
    '#1E88E5',
    '#2E7D32',
    '#0277BD',
    '#26A69A',
    '#7CB342',
    '#5E35B1',
    '#8E24AA',
    '#D32F2F',
    '#EF5350',
    '#FF7043',
    '#FFB300',
    '#FBC02D',
    '#5C6BC0',
    '#607D8B',
    '#546E7A',
    '#795548',
    '#424242',
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    widget.reloadSignal?.addListener(_handleReload);
  }

  @override
  void didUpdateWidget(covariant AccountsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal != widget.reloadSignal) {
      oldWidget.reloadSignal?.removeListener(_handleReload);
      widget.reloadSignal?.addListener(_handleReload);
    }
  }

  @override
  void dispose() {
    widget.reloadSignal?.removeListener(_handleReload);
    super.dispose();
  }

  void _handleReload() {
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
    } else {
      _isar = await Isar.open([
        JiveTransactionSchema,
        JiveCategorySchema,
        JiveCategoryOverrideSchema,
        JiveAccountSchema,
        JiveAutoDraftSchema,
      ], directory: dir.path);
    }

    final service = AccountService(_isar);
    await service.initDefaultAccounts();
    final accounts = await service.getActiveAccounts();
    final balances = await service.computeBalances(accounts: accounts);
    final totals = service.calculateTotals(accounts, balances);
    final creditSummary = _computeCreditSummary(accounts, balances);

    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _balances = balances;
      _totals = totals;
      _creditLimit = creditSummary.limit;
      _creditUsed = creditSummary.used;
      _creditAvailable = creditSummary.available;
      _isLoading = false;
    });
  }

  Future<void> _showCreateAccountDialog() async {
    final draft = await _showAccountFormSheet();
    if (draft == null) return;
    await _applyAccountDraft(draft);
  }

  Future<void> _openReconcile(JiveAccount account) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountReconcileScreen(
          accountId: account.id,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );
  }

  Future<void> _applyAccountDraft(_AccountDraft draft) async {
    final openingBalance = draft.type == AccountService.typeLiability
        ? -draft.openingBalance.abs()
        : draft.openingBalance;
    final service = AccountService(_isar);
    if (draft.editingAccount == null) {
      await service.createAccount(
        name: draft.name,
        type: draft.type,
        subType: draft.subType,
        openingBalance: openingBalance,
        iconName: draft.iconName,
        colorHex: draft.colorHex,
        groupName: draft.groupName,
        billingDay: draft.billingDay,
        repaymentDay: draft.repaymentDay,
        creditLimit: draft.creditLimit,
        includeInBalance: draft.includeInBalance,
      );
    } else {
      await service.updateAccount(
        draft.editingAccount!,
        name: draft.name,
        type: draft.type,
        subType: draft.subType,
        openingBalance: openingBalance,
        iconName: draft.iconName,
        colorHex: draft.colorHex,
        groupName: draft.groupName,
        billingDay: draft.billingDay,
        repaymentDay: draft.repaymentDay,
        creditLimit: draft.creditLimit,
        includeInBalance: draft.includeInBalance,
      );
    }
    if (!mounted) return;
    _loadAccounts();
  }

  Future<_AccountDraft?> _showAccountFormSheet({JiveAccount? editing}) async {
    final banks = await BankCatalog.load();
    AccountTypeOption? selectedType = editing != null
        ? AccountTypeCatalog.optionFor(editing.subType) ??
              AccountTypeOption(
                id: editing.subType ?? 'custom',
                label: editing.subType ?? '账户',
                type: editing.type,
                group: AccountService.displayGroupName(editing),
                icon: editing.iconName,
                colorHex: editing.colorHex,
              )
        : null;
    if (selectedType == null) {
      selectedType = await _showAccountTypePicker();
      if (selectedType == null) return null;
    }
    BankEntry? selectedBank = selectedType.requiresBank
        ? BankCatalog.findByIcon(banks, editing?.iconName)
        : null;
    if (editing == null && selectedType.requiresBank && selectedBank == null) {
      selectedBank = await _showBankPicker(
        selectedBank,
        title: selectedType.id == 'credit' ? '选择信用卡银行' : '选择银行',
        hintText: '搜索银行',
      );
    }
    var iconName =
        editing?.iconName ??
        ((selectedBank?.icon.isNotEmpty ?? false)
            ? selectedBank!.icon
            : selectedType.icon);
    final defaultColor = _resolveDefaultColor(selectedType, selectedBank);

    final nameController = TextEditingController(
      text: editing?.name ?? _defaultAccountName(selectedType, selectedBank),
    );
    final balanceController = TextEditingController(
      text: editing != null ? editing.openingBalance.abs().toString() : '',
    );
    final billDayController = TextEditingController(
      text: editing?.billingDay?.toString() ?? '',
    );
    final repayDayController = TextEditingController(
      text: editing?.repaymentDay?.toString() ?? '',
    );
    final creditLimitController = TextEditingController(
      text: editing?.creditLimit?.toString() ?? '',
    );
    var includeInBalance = editing?.includeInBalance ?? true;
    var colorHex = editing?.colorHex ?? defaultColor;
    var nameCustomized = editing != null;
    var iconCustomized = false;
    var colorCustomized = false;
    if (editing != null) {
      if (selectedType.requiresBank) {
        iconCustomized =
            selectedBank == null || editing.iconName != selectedBank!.icon;
      } else {
        iconCustomized = editing.iconName != selectedType.icon;
      }
      colorCustomized =
          (editing.colorHex ?? '').trim().isNotEmpty &&
          editing.colorHex != defaultColor;
    }

    Future<void> ensureBankSelected(StateSetter setSheetState) async {
      if (!selectedType!.requiresBank) return;
      final bank = await _showBankPicker(selectedBank);
      if (bank == null) return;
      setSheetState(() {
        selectedBank = bank;
        iconName = bank.icon.isEmpty ? iconName : bank.icon;
        if (!colorCustomized) {
          colorHex = _resolveDefaultColor(selectedType!, bank);
        }
        iconCustomized = false;
        if (!nameCustomized) {
          nameController.text = _defaultAccountName(
            selectedType!,
            selectedBank,
          );
        }
      });
    }

    return showModalBottomSheet<_AccountDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final labelStyle = GoogleFonts.lato(
              fontSize: 13,
              color: Colors.grey.shade600,
            );
            final valueStyle = GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            );
            final defaultColor = _resolveDefaultColor(
              selectedType!,
              selectedBank,
            );
            final resolvedColor = colorCustomized ? colorHex : defaultColor;
            final iconColor =
                AccountService.parseColorHex(resolvedColor) ??
                JiveTheme.primaryGreen;
            final iconBank = BankCatalog.findByIcon(banks, iconName);
            final isFileIcon = AccountService.isFileIcon(iconName);
            final iconLabel = isFileIcon
                ? '自定义图片'
                : (iconBank?.name ??
                      (iconCustomized ? '自定义图标' : '默认图标'));
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomInset),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          editing == null ? '新增账户' : '编辑账户',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: AccountService.buildIcon(
                              iconName,
                              size: 22,
                              color: iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedType!.group, style: labelStyle),
                              Text(selectedType!.label, style: valueStyle),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await _showAccountTypePicker(
                              current: selectedType,
                            );
                            if (picked == null) return;
                            setSheetState(() {
                              selectedType = picked;
                              selectedBank = null;
                              iconName = picked.icon;
                              colorHex = _resolveDefaultColor(picked, null);
                              iconCustomized = false;
                              colorCustomized = false;
                              if (!nameCustomized) {
                                nameController.text = _defaultAccountName(
                                  picked,
                                  selectedBank,
                                );
                              }
                            });
                            if (selectedType!.requiresBank &&
                                selectedBank == null) {
                              await ensureBankSelected(setSheetState);
                            }
                          },
                          child: const Text('更换'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (selectedType!.requiresBank) ...[
                      InkWell(
                        onTap: () => ensureBankSelected(setSheetState),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '选择银行',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.chevron_right),
                          ),
                          child: Row(
                            children: [
                              if (selectedBank != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AccountService.buildIcon(
                                    selectedBank!.icon,
                                    size: 18,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  selectedBank?.name ?? '请选择',
                                  style: valueStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    InkWell(
                      onTap: () async {
                        final action = await _showIconSourceSheet();
                        if (action == null) return;
                        _IconSelection? selection;
                        if (action == _IconSourceAction.bank) {
                          final bank = await _showBankPicker(
                            BankCatalog.findByIcon(banks, iconName),
                            title: '选择银行图标',
                            hintText: '搜索图标',
                          );
                          if (bank != null) {
                            selection = _IconSelection(
                              iconName: bank.icon,
                              colorHex: bank.color,
                              label: bank.name,
                            );
                          }
                        } else if (action == _IconSourceAction.gallery) {
                          selection = await _pickCustomIcon(
                            ImageSource.gallery,
                          );
                        } else if (action == _IconSourceAction.camera) {
                          selection = await _pickCustomIcon(ImageSource.camera);
                        }
                        if (selection == null) return;
                        setSheetState(() {
                          iconName = selection!.iconName;
                          iconCustomized = true;
                          if (!colorCustomized &&
                              selection!.colorHex != null &&
                              selection!.colorHex!.trim().isNotEmpty) {
                            colorHex = selection!.colorHex!;
                          }
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '账户图标',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.chevron_right),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: AccountService.buildIcon(
                                  iconName,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(iconLabel, style: valueStyle)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('图标颜色', style: labelStyle),
                        const Spacer(),
                        if (iconCustomized || colorCustomized)
                          TextButton(
                            onPressed: () {
                              final resetIcon =
                                  selectedBank?.icon.isNotEmpty == true
                                  ? selectedBank!.icon
                                  : selectedType!.icon;
                              final resetColor = _resolveDefaultColor(
                                selectedType!,
                                selectedBank,
                              );
                              setSheetState(() {
                                iconName = resetIcon;
                                colorHex = resetColor;
                                iconCustomized = false;
                                colorCustomized = false;
                              });
                            },
                            child: const Text('恢复默认'),
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildColorOption(
                          label: '默认',
                          colorHex: defaultColor,
                          selected: !colorCustomized,
                          onTap: () {
                            setSheetState(() {
                              colorHex = defaultColor;
                              colorCustomized = false;
                            });
                          },
                        ),
                        for (final color in _accountColorPalette)
                          _buildColorOption(
                            colorHex: color,
                            selected: colorCustomized && colorHex == color,
                            onTap: () {
                              setSheetState(() {
                                colorHex = color;
                                colorCustomized = color != defaultColor;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '账户名称',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => nameCustomized = true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '期初余额',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (selectedType!.requiresCreditMeta) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: creditLimitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '信用额度',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: billDayController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '账单日',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: repayDayController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '还款日',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    SwitchListTile(
                      value: includeInBalance,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: const Text('计入净资产'),
                      onChanged: (value) =>
                          setSheetState(() => includeInBalance = value),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;
                              if (editing == null &&
                                  selectedType!.requiresBank &&
                                  selectedBank == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请选择银行')),
                                );
                                return;
                              }
                              final amount =
                                  double.tryParse(
                                    balanceController.text.trim(),
                                  ) ??
                                  0;
                              final creditLimit = double.tryParse(
                                creditLimitController.text.trim(),
                              );
                              final billingDay = int.tryParse(
                                billDayController.text.trim(),
                              );
                              final repaymentDay = int.tryParse(
                                repayDayController.text.trim(),
                              );
                              final resolvedIcon =
                                  (!iconCustomized &&
                                      selectedBank?.icon.isNotEmpty == true)
                                  ? selectedBank!.icon
                                  : iconName;
                              final resolvedColor =
                                  (!iconCustomized &&
                                      selectedBank?.color.isNotEmpty == true)
                                  ? selectedBank!.color
                                  : colorHex;
                              Navigator.pop(
                                sheetContext,
                                _AccountDraft(
                                  editingAccount: editing,
                                  name: name,
                                  type: selectedType!.type,
                                  subType: selectedType!.id,
                                  iconName: resolvedIcon,
                                  colorHex: resolvedColor,
                                  groupName: selectedType!.group,
                                  openingBalance: amount,
                                  billingDay: billingDay,
                                  repaymentDay: repaymentDay,
                                  creditLimit: creditLimit,
                                  includeInBalance: includeInBalance,
                                ),
                              );
                            },
                            child: const Text('保存'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<AccountTypeOption?> _showAccountTypePicker({
    AccountTypeOption? current,
  }) async {
    return showModalBottomSheet<AccountTypeOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JiveTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final width = MediaQuery.of(sheetContext).size.width;
        final columns = width >= 460
            ? 6
            : width >= 380
                ? 5
                : 4;
        final tileHeight = _accountTypeTileHeight(sheetContext, columns);
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                '选择账户类型',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              for (final section in AccountTypeCatalog.sections) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.title,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: JiveTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: section.options.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: tileHeight,
                    ),
                    itemBuilder: (context, index) {
                      final option = section.options[index];
                      final isSelected = current?.id == option.id;
                      final color =
                          AccountService.parseColorHex(option.colorHex) ??
                          JiveTheme.primaryGreen;
                      return InkWell(
                        onTap: () => Navigator.pop(sheetContext, option),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: Center(
                                  child: AccountService.buildIcon(
                                    option.icon,
                                    size: 22,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  color: isSelected ? color : null,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 2,
                                width: isSelected ? 16 : 0,
                                decoration: BoxDecoration(
                                  color: isSelected ? color : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }

  double _accountTypeTileHeight(BuildContext context, int columns) {
    final scale = MediaQuery.textScaleFactorOf(context);
    final base = columns >= 6
        ? 64.0
        : columns >= 5
            ? 68.0
            : 74.0;
    if (scale >= 1.2) return base + 6;
    if (scale >= 1.1) return base + 4;
    return base;
  }

  Future<BankEntry?> _showBankPicker(
    BankEntry? current, {
    String title = '选择银行',
    String hintText = '搜索银行',
  }) async {
    final banks = await BankCatalog.load();
    final controller = TextEditingController();
    var filtered = banks;

    return showModalBottomSheet<BankEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JiveTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: hintText,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: JiveTheme.cardWhite,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          filtered = BankCatalog.filter(banks, value);
                        });
                      },
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: JiveTheme.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final bank = filtered[index];
                            final isSelected = current?.name == bank.name;
                            return InkWell(
                              onTap: () => Navigator.pop(sheetContext, bank),
                              child: Container(
                                color: isSelected
                                    ? JiveTheme.primaryGreen.withOpacity(0.06)
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Center(
                                        child: AccountService.buildIcon(
                                          bank.icon,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bank.name,
                                            style: GoogleFonts.lato(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (bank.name2.isNotEmpty)
                                            Text(
                                              bank.name2,
                                              style: GoogleFonts.lato(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: JiveTheme.primaryGreen,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemCount: filtered.length,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<_IconSourceAction?> _showIconSourceSheet() async {
    return showModalBottomSheet<_IconSourceAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('银行图标'),
                onTap: () =>
                    Navigator.pop(sheetContext, _IconSourceAction.bank),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () =>
                    Navigator.pop(sheetContext, _IconSourceAction.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('拍照'),
                onTap: () =>
                    Navigator.pop(sheetContext, _IconSourceAction.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<_IconSelection?> _pickCustomIcon(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 92,
      );
      if (picked == null) return null;
      final savedPath = await _persistCustomIcon(picked);
      if (savedPath == null) return null;
      return _IconSelection(iconName: 'file:$savedPath', label: '自定义图片');
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法读取图片，请稍后再试')));
      return null;
    }
  }

  Future<String?> _persistCustomIcon(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/account_icons');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final sourcePath = file.path;
    final dotIndex = sourcePath.lastIndexOf('.');
    final ext = dotIndex == -1 ? '.png' : sourcePath.substring(dotIndex);
    final filename =
        'account_icon_${DateTime.now().microsecondsSinceEpoch}$ext';
    final targetPath = '${folder.path}/$filename';
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  String _resolveDefaultColor(AccountTypeOption option, BankEntry? bank) {
    if (bank != null && bank.color.trim().isNotEmpty) return bank.color;
    return option.colorHex ?? '#66BB6A';
  }

  Widget _buildColorOption({
    required bool selected,
    required VoidCallback onTap,
    String? colorHex,
    String? label,
  }) {
    final color = colorHex != null
        ? AccountService.parseColorHex(colorHex)
        : null;
    if (label != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? JiveTheme.primaryGreen.withOpacity(0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? JiveTheme.primaryGreen : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: selected ? JiveTheme.primaryGreen : Colors.grey.shade600,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.transparent,
          border: Border.all(
            color: selected ? JiveTheme.primaryGreen : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  String _defaultAccountName(AccountTypeOption option, BankEntry? bank) {
    if (bank == null) return option.label;
    final suffix = option.nameSuffix ?? '';
    if (suffix.isEmpty) return bank.name;
    return '${bank.name}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedAccounts = <String, List<JiveAccount>>{};
    for (final account in _accounts) {
      final group = AccountService.displayGroupName(account);
      groupedAccounts.putIfAbsent(group, () => []).add(account);
    }
    final orderedGroups = <String>[...AccountService.groupOrder];
    final extras =
        groupedAccounts.keys
            .where((group) => !orderedGroups.contains(group))
            .toList()
          ..sort();
    orderedGroups.addAll(extras);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAccounts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "资产",
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _showCreateAccountDialog,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            for (final group in orderedGroups)
              if ((groupedAccounts[group] ?? []).isNotEmpty) ...[
                _buildSection(group, groupedAccounts[group]!),
                const SizedBox(height: 16),
              ],
            const SizedBox(height: 24),
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
          Text(
            "净资产",
            style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 13),
          ),
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
          if (_creditLimit > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildMetaStat("信用额度", _creditLimit, Colors.blueGrey),
                _buildMetaStat("已用", _creditUsed, Colors.redAccent),
                _buildMetaStat("可用", _creditAvailable, JiveTheme.primaryGreen),
              ],
            ),
          ],
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
        style: GoogleFonts.lato(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<JiveAccount> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
    final displayBalance = account.type == AccountService.typeLiability
        ? balance.abs()
        : balance;
    final amountColor = account.type == AccountService.typeLiability
        ? Colors.redAccent
        : JiveTheme.primaryGreen;
    final color =
        AccountService.parseColorHex(account.colorHex) ??
        JiveTheme.primaryGreen;
    final option = AccountTypeCatalog.optionFor(account.subType);
    final detailText = AccountService.isCreditAccount(account)
        ? _creditMeta(account, balance)
        : (option?.label ?? AccountService.displayGroupName(account));
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final draft = await _showAccountFormSheet(editing: account);
        if (draft == null) return;
        await _applyAccountDraft(draft);
      },
      child: Container(
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
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: AccountService.buildIcon(
                  account.iconName,
                  size: 22,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detailText,
                    style: GoogleFonts.lato(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: "¥").format(displayBalance),
                  style: GoogleFonts.rubik(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _openReconcile(account),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.grey.shade600,
                    textStyle: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.receipt_long, size: 14),
                      SizedBox(width: 4),
                      Text('对账'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      final available = (creditLimit - used)
          .clamp(0, double.infinity)
          .toDouble();
      parts.add("额度¥${_formatCompact(creditLimit)}");
      parts.add("已用¥${_formatCompact(used)}");
      parts.add("可用¥${_formatCompact(available)}");
    }
    return parts.join(" ");
  }

  String _formatCompact(double value) {
    return NumberFormat.compactCurrency(
      symbol: "",
      decimalDigits: 0,
    ).format(value);
  }

  _CreditSummary _computeCreditSummary(
    List<JiveAccount> accounts,
    Map<int, double> balances,
  ) {
    double limit = 0;
    double used = 0;
    double available = 0;

    for (final account in accounts) {
      if (!AccountService.isCreditAccount(account)) continue;
      final accountLimit = account.creditLimit;
      if (accountLimit == null || accountLimit <= 0) continue;
      final balance = balances[account.id] ?? account.openingBalance;
      final usedForAccount = balance < 0 ? -balance : 0.0;
      limit += accountLimit;
      used += usedForAccount;
      final availableForAccount = accountLimit - usedForAccount;
      if (availableForAccount > 0) {
        available += availableForAccount;
      }
    }

    return _CreditSummary(limit: limit, used: used, available: available);
  }

}

class _AccountDraft {
  final JiveAccount? editingAccount;
  final String name;
  final String type;
  final String subType;
  final String iconName;
  final String? colorHex;
  final String? groupName;
  final double openingBalance;
  final int? billingDay;
  final int? repaymentDay;
  final double? creditLimit;
  final bool includeInBalance;

  const _AccountDraft({
    this.editingAccount,
    required this.name,
    required this.type,
    required this.subType,
    required this.iconName,
    this.colorHex,
    this.groupName,
    required this.openingBalance,
    this.billingDay,
    this.repaymentDay,
    this.creditLimit,
    required this.includeInBalance,
  });
}

class _CreditSummary {
  final double limit;
  final double used;
  final double available;

  const _CreditSummary({
    required this.limit,
    required this.used,
    required this.available,
  });
}

enum _IconSourceAction { bank, gallery, camera }

class _IconSelection {
  final String iconName;
  final String? colorHex;
  final String? label;

  const _IconSelection({required this.iconName, this.colorHex, this.label});
}
