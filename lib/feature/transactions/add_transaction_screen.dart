import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/account_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/service/category_service.dart';
import '../../core/service/account_service.dart';
import '../../core/database/category_model.dart';
import '../../core/utils/logger_util.dart';
import '../category/category_create_dialog.dart';
import '../category/category_create_screen.dart';
import '../category/category_edit_dialog.dart';
import '../category/category_manager_screen.dart';
import '../category/category_search_delegate.dart';
import '../stats/stats_screen.dart';
import 'note_field_with_chips.dart';

enum TransactionType { expense, income, transfer }

class AddTransactionScreen extends StatefulWidget {
  final JiveTransaction? editingTransaction;

  const AddTransactionScreen({
    super.key,
    this.editingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const List<String> _accountGroupOrder = [
    ...AccountService.groupOrder,
  ];
  static const List<String> _expenseNoteSuggestions = [
    '早餐',
    '午餐',
    '晚餐',
    '交通',
    '打车',
    '网购',
    '房租',
    '水电',
  ];
  static const List<String> _incomeNoteSuggestions = [
    '工资',
    '报销',
    '奖金',
    '退款',
    '理财',
    '兼职',
  ];
  static const List<String> _transferNoteSuggestions = [
    '还款',
    '储蓄',
    '调拨',
    '借还',
  ];
  static const String _noteTagUsageKeyPrefix = 'note_tag_usage_v1_';

  String _amountStr = "0";
  late Isar _isar;
  bool _isLoading = true;
  bool _hasDataChanges = false;
  bool _isFallbackMode = false;
  bool _isSearchMode = false;
  bool _isEditing = false;
  TransactionType _txType = TransactionType.expense;
  DateTime _selectedTime = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final Map<TransactionType, Map<String, int>> _noteTagUsage = {};
  int? _editingAccountId;
  int? _editingToAccountId;
  String? _editingParentKey;
  String? _editingParentName;
  String? _editingSubKey;
  String? _editingSubName;
  List<JiveCategory> _parentCategories = [];
  List<JiveCategory> _subCategories = [];
  JiveCategory? _selectedParent;
  JiveCategory? _selectedSub;
  List<JiveAccount> _accounts = [];
  Map<int, double> _accountBalances = {};
  JiveAccount? _selectedAccount;
  JiveAccount? _selectedToAccount;
  List<CategorySearchResult> _searchItems = [];
  final Map<String, String> _searchKeyCache = {};
  final TextEditingController _inlineSearchController = TextEditingController();
  final FocusNode _inlineSearchFocus = FocusNode();
  final DateFormat _dateTimeFormat = DateFormat('MM-dd HH:mm');
  String _searchQuery = "";
  final Map<String, List<String>> _searchTokenCache = {};
  final Map<String, List<String>> _systemTokenCache = {};
  bool _searchItemsLoaded = false;

  final List<String> _keys = [
    '7', '8', '9', 'date',
    '4', '5', '6', '+',
    '1', '2', '3', '-',
    '.', '0', 'DEL', 'OK'
  ];

  @override
  void initState() {
    super.initState();
    _initializeEditingState();
    _loadNoteTagUsage();
    _initData();
  }

  @override
  void dispose() {
    _inlineSearchController.dispose();
    _inlineSearchFocus.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeEditingState() {
    final editing = widget.editingTransaction;
    if (editing == null) return;
    _isEditing = true;
    _amountStr = _formatAmountInput(editing.amount);
    _selectedTime = editing.timestamp;
    _txType = _parseTxType(editing.type);
    _editingAccountId = editing.accountId;
    _editingToAccountId = editing.toAccountId;
    _editingParentKey = editing.categoryKey;
    _editingParentName = editing.category;
    _editingSubKey = editing.subCategoryKey;
    _editingSubName = editing.subCategory;
    _noteController.text = editing.note ?? '';
  }

  Future<void> _initData() async {
    try {
      JiveLogger.d(">>> INIT DATA STARTED");
      final dir = await getApplicationDocumentsDirectory();
      
      if (Isar.getInstance() != null) {
        _isar = Isar.getInstance()!;
      } else {
        _isar = await Isar.open(
          [
            JiveTransactionSchema,
            JiveCategorySchema,
            JiveCategoryOverrideSchema,
            JiveAccountSchema,
            JiveAutoDraftSchema,
          ],
          directory: dir.path,
        );
      }
      
      await CategoryService(_isar).initDefaultCategories();
      await AccountService(_isar).initDefaultAccounts();
      await _loadAccounts();
      await _loadParentsForType(
        selectParentKey: _editingParentKey,
        selectParentName: _editingParentName,
        selectSubKey: _editingSubKey,
        selectSubName: _editingSubName,
      );
    } catch (e, s) {
      JiveLogger.e("Error loading categories", e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadParentsForType({
    String? selectParentKey,
    String? selectParentName,
    String? selectSubKey,
    String? selectSubName,
  }) async {
    if (_txType == TransactionType.transfer) {
      _isFallbackMode = false;
      if (mounted) {
        setState(() {
          _parentCategories = [];
          _subCategories = [];
          _selectedParent = null;
          _selectedSub = null;
        });
      }
      return;
    }

    final showIncome = _txType == TransactionType.income;
    var parents = await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(showIncome)
        .isHiddenEqualTo(false)
        .sortByOrder()
        .findAll();

    // FALLBACK (only for expense)
    if (parents.isEmpty && !showIncome) {
      JiveLogger.w("!!! DB EMPTY, USING FALLBACK !!!");
      final service = CategoryService(_isar);
      final lib = service.getSystemLibrary(isIncome: showIncome);
      parents = lib.keys.map((name) => JiveCategory()
        ..key = service.buildSystemParentKey(name, isIncome: showIncome)
        ..name = name
        ..iconName = lib[name]!['icon']
        ..order = 0
      ).toList();
      _isFallbackMode = true;
    } else {
      _isFallbackMode = false;
    }

    if (parents.isNotEmpty) {
      JiveCategory? selected;
      if (selectParentKey != null) {
        for (final parent in parents) {
          if (parent.key == selectParentKey) {
            selected = parent;
            break;
          }
        }
      }
      if (selected == null && selectParentName != null && selectParentName.isNotEmpty) {
        for (final parent in parents) {
          if (parent.name == selectParentName) {
            selected = parent;
            break;
          }
        }
      }
      if (selected == null &&
          _selectedParent != null &&
          parents.any((p) => p.key == _selectedParent!.key)) {
        selected = _selectedParent;
      }
      selected ??= parents.first;

      if (mounted) {
        setState(() {
          _parentCategories = parents;
          _selectedParent = selected;
        });
      }
      await _loadSubCategories(
        selected.key,
        selectKey: selectSubKey,
        selectName: selectSubName,
      );
    } else if (mounted) {
      setState(() {
        _parentCategories = [];
        _subCategories = [];
        _selectedParent = null;
        _selectedSub = null;
      });
    }
  }

  Future<void> _loadAccounts() async {
    final service = AccountService(_isar);
    final accounts = await service.getActiveAccounts();
    final balances = await service.computeBalances(accounts: accounts);
    if (!mounted) return;

    JiveAccount? selectedAccount = _selectedAccount;
    if (accounts.isEmpty) {
      selectedAccount = null;
    } else if (_editingAccountId != null) {
      selectedAccount = accounts.firstWhere(
        (a) => a.id == _editingAccountId,
        orElse: () => accounts.first,
      );
    } else if (selectedAccount == null || !accounts.any((a) => a.id == selectedAccount!.id)) {
      selectedAccount = accounts.first;
    }

    JiveAccount? selectedTo = _selectedToAccount;
    if (_editingToAccountId != null && accounts.isNotEmpty) {
      selectedTo = accounts.firstWhere(
        (a) => a.id == _editingToAccountId,
        orElse: () => selectedTo ?? accounts.first,
      );
    }
    if (selectedTo == null || (selectedAccount != null && selectedTo.id == selectedAccount.id)) {
      selectedTo = selectedAccount == null
          ? null
          : accounts.firstWhere(
              (a) => a.id != selectedAccount!.id,
              orElse: () => selectedAccount!,
            );
    }

    setState(() {
      _accounts = accounts;
      _accountBalances = balances;
      _selectedAccount = selectedAccount;
      _selectedToAccount = selectedTo;
    });
  }

  String _typeValue(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return "income";
      case TransactionType.transfer:
        return "transfer";
      case TransactionType.expense:
      default:
        return "expense";
    }
  }

  bool get _showCategories => _txType != TransactionType.transfer;

  String _currentCategoryLabel() {
    if (_txType == TransactionType.transfer) return "转账";
    final parentName = _selectedParent?.name ?? "";
    final subName = _selectedSub?.name ?? "";
    if (parentName.isEmpty) return "";
    if (subName.isEmpty) return parentName;
    return "$parentName · $subName";
  }

  Future<void> _switchType(TransactionType type) async {
    if (_txType == type) return;
    setState(() {
      _txType = type;
      _selectedParent = null;
      _selectedSub = null;
      _parentCategories = [];
      _subCategories = [];
      _isLoading = true;
      _isSearchMode = false;
      _searchItems = [];
      _searchItemsLoaded = false;
      _searchKeyCache.clear();
      _searchTokenCache.clear();
      _searchQuery = "";
      _inlineSearchController.clear();
    });
    await _loadParentsForType();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSubCategories(
    String parentKey, {
    String? selectKey,
    String? selectName,
  }) async {
    var subs = await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyEqualTo(parentKey)
        .sortByOrder()
        .findAll();
    
    // FALLBACK
    if (_isFallbackMode && subs.isEmpty) {
      final service = CategoryService(_isar);
      final parentName = _parentCategories
              .firstWhere(
                (parent) => parent.key == parentKey,
                orElse: () => JiveCategory()..name = "",
              )
              .name;
      final resolvedName = parentName.isEmpty ? service.resolveSystemParentName(parentKey) : parentName;
      if (resolvedName == null || resolvedName.isEmpty) {
        return;
      }
      final lib = service.getSystemLibrary(isIncome: false);
      if (lib.containsKey(resolvedName)) {
        final children = lib[resolvedName]!['children'] as List;
        subs = children.map<JiveCategory>((c) => JiveCategory()
          ..key = service.buildSystemChildKey(resolvedName, c['name'], isIncome: false)
          ..name = c['name']
          ..iconName = c['icon']
        ).toList();
      }
    }

    final preserveKey = selectKey ?? _selectedSub?.key;

    if (mounted) {
      setState(() {
        _subCategories = subs;
        if (subs.isNotEmpty) {
          if (preserveKey != null) {
            final match = subs.where((item) => item.key == preserveKey);
            _selectedSub = match.isEmpty ? null : match.first;
          } else if (selectName != null && selectName.isNotEmpty) {
            final match = subs.where((item) => item.name == selectName);
            _selectedSub = match.isEmpty ? null : match.first;
          } else {
            _selectedSub = null;
          }
        } else {
          _selectedSub = null;
        }
      });
    }
  }

  Future<void> _refreshCategories() async {
    if (!mounted) return;
    setState(() {
      _selectedParent = null;
      _selectedSub = null;
      _parentCategories = [];
      _subCategories = [];
      _isLoading = true;
      _searchItems = [];
      _searchItemsLoaded = false;
      _searchKeyCache.clear();
      _searchTokenCache.clear();
      _isSearchMode = false;
      _searchQuery = "";
      _inlineSearchController.clear();
    });
    await _loadParentsForType();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openCategoryManager() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryManagerScreen(isar: _isar)),
    );
    if (changed == true) {
      _hasDataChanges = true;
    }
    await _refreshCategories();
  }

  Future<void> _openCategoryStats({
    required JiveCategory parent,
    JiveCategory? sub,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsScreen(
          filterCategoryKey: parent.key,
          filterSubCategoryKey: sub?.key,
        ),
      ),
    );
  }

  Future<List<CategorySearchResult>> _buildSearchItems() async {
    if (_txType == TransactionType.transfer) return [];
    final all = await _isar.collection<JiveCategory>().where().findAll();
    if (all.isEmpty) return [];

    final showIncome = _txType == TransactionType.income;
    final parents = all.where((c) => c.parentKey == null && !c.isHidden && c.isIncome == showIncome).toList();
    parents.sort((a, b) => a.order.compareTo(b.order));
    final parentByKey = {for (final p in parents) p.key: p};
    final items = <CategorySearchResult>[];
    for (final parent in parents) {
      items.add(CategorySearchResult(parent: parent));
    }
    final children = all.where((c) => c.parentKey != null && !c.isHidden && c.isIncome == showIncome).toList();
    for (final child in children) {
      final parent = parentByKey[child.parentKey];
      if (parent == null) continue;
      items.add(CategorySearchResult(parent: parent, sub: child));
    }
    return items;
  }

  Future<void> _toggleInlineSearch() async {
    if (_txType == TransactionType.transfer) return;
    if (_isSearchMode) {
      _exitSearchMode();
      return;
    }
    setState(() => _isSearchMode = true);
    if (_searchItems.isEmpty) {
      final items = await _buildSearchItems();
      if (!mounted) return;
      setState(() {
        _searchItems = items;
        _searchItemsLoaded = true;
        _searchKeyCache.clear();
        _searchTokenCache.clear();
      });
    } else if (!_searchItemsLoaded) {
      setState(() => _searchItemsLoaded = true);
    }
    if (mounted) {
      FocusScope.of(context).requestFocus(_inlineSearchFocus);
    }
  }

  void _exitSearchMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchMode = false;
      _searchQuery = "";
      _inlineSearchController.clear();
    });
  }

  Future<void> _promptAddSubCategory(JiveCategory parent) async {
    final existingNames = (await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyEqualTo(parent.key)
        .findAll())
        .map((child) => child.name)
        .toSet();
    final systemLibrary = CategoryService(_isar).getSystemLibrary(
      isIncome: parent.isIncome,
      includeIncome: true,
    );
    final result = await Navigator.push<CategoryCreateResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryCreateScreen(
          title: "添加子类 · ${parent.name}",
          parentName: parent.name,
          initialIcon: parent.iconName,
          nameLabel: "子类名称",
          allowBatch: true,
          systemLibrary: systemLibrary,
          existingNames: existingNames,
          initialGroupName: parent.name,
          autoBatchAdd: true,
          onBatchAdd: (suggestion, colorHex) async {
            final created = await CategoryService(_isar).createSubCategory(
              parent: parent,
              name: suggestion.name,
              iconName: suggestion.iconName,
              colorHex: colorHex,
              isSystem: true,
            );
            return created != null;
          },
        ),
      ),
    );
    if (result == null) return;
    if (result.hasChanges) {
      _hasDataChanges = true;
      setState(() => _selectedParent = parent);
      await _loadSubCategories(parent.key);
      return;
    }
    if (result.systemSelections.isEmpty && result.names.isEmpty) return;
    final skipped = <String>[];
    JiveCategory? lastCreated;
    if (result.systemSelections.isNotEmpty) {
      for (final item in result.systemSelections) {
        final created = await CategoryService(_isar).createSubCategory(
          parent: parent,
          name: item.name,
          iconName: item.iconName,
          colorHex: result.colorHex,
          isSystem: true,
        );
        if (created == null) {
          skipped.add(item.name);
        } else {
          lastCreated = created;
        }
      }
    } else {
      for (final name in result.names) {
        final iconName = result.autoMatchIcon
            ? CategoryService(_isar).suggestIconName(name, fallback: result.iconName)
            : result.iconName;
        final created = await CategoryService(_isar).createSubCategory(
          parent: parent,
          name: name,
          iconName: iconName,
          colorHex: result.colorHex,
        );
        if (created == null) {
          skipped.add(name);
        } else {
          lastCreated = created;
        }
      }
    }

    if (!mounted) return;
    if (lastCreated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已存在同名子类")),
      );
      return;
    }

    _hasDataChanges = true;
    _searchItems = [];
    _searchItemsLoaded = false;
    _searchKeyCache.clear();
    _searchTokenCache.clear();
    setState(() => _selectedParent = parent);
    await _loadSubCategories(parent.key, selectKey: lastCreated.key);
    if (skipped.isNotEmpty) {
      final preview = skipped.take(3).join("、");
      final suffix = skipped.length > 3 ? "等" : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已忽略重复: $preview$suffix")),
      );
    }
  }

  void _showParentActions(JiveCategory parent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text("管理"),
              onTap: () async {
                Navigator.pop(context);
                await _openCategoryManager();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text("查看统计数据"),
              onTap: () async {
                Navigator.pop(context);
                await _openCategoryStats(parent: parent);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("添加子类"),
              onTap: () async {
                Navigator.pop(context);
                await _promptAddSubCategory(parent);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSubCategoryActions(JiveCategory sub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text("编辑 '${sub.name}'"),
              onTap: () async {
                Navigator.pop(context);
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryEditDialog(category: sub, isar: _isar),
                    fullscreenDialog: true,
                  ),
                );
                if (updated == true) {
                  _hasDataChanges = true;
                  await _refreshCategories();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text("查看统计数据"),
              onTap: () async {
                Navigator.pop(context);
                if (_selectedParent != null) {
                  await _openCategoryStats(parent: _selectedParent!, sub: sub);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("删除分类", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final deleted = await CategoryService(_isar).deleteCategory(sub);
                if (!mounted) return;
                if (!deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("请先处理子类后再删除")),
                  );
                  return;
                }
                _hasDataChanges = true;
                if (_selectedParent != null) {
                  await _loadSubCategories(_selectedParent!.key);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onKeyPress(String key) {
    if (key == 'date') {
      _pickTransactionDate();
      return;
    }
    setState(() {
      if (key == 'DEL') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = "0";
        }
      } else if (key == 'OK') {
        _saveTransaction();
      } else {
        if (_amountStr == "0" && key != '.') {
          _amountStr = key;
        } else if (key == '.' && _amountStr.contains('.')) {
        } else {
          if (_amountStr.length < 10) {
            _amountStr += key;
          }
        }
      }
    });
  }

  Future<void> _pickTransactionDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (time == null) return;
    setState(() {
      _selectedTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountStr);
    if (amount == null || amount <= 0) return;
    if (_txType != TransactionType.transfer && _selectedParent == null) return;
    if (_selectedAccount == null) return;
    if (_txType == TransactionType.transfer && _selectedToAccount == null) return;
    if (_txType == TransactionType.transfer && _selectedToAccount?.id == _selectedAccount?.id) return;

    final typeValue = _typeValue(_txType);
    final parentName = _txType == TransactionType.transfer ? "转账" : _selectedParent!.name;
    final subName = _txType == TransactionType.transfer ? "" : (_selectedSub?.name ?? "");
    final rawText = _txType == TransactionType.transfer
        ? "转账"
        : "${_selectedParent!.name} - ${_selectedSub?.name ?? ''}";

    final tx = widget.editingTransaction ?? JiveTransaction();
    final source = _isEditing ? tx.source : "Manual";
    final note = _noteController.text.trim();
    final existingRawText = tx.rawText;
    final useRawText = _isEditing && source != "Manual" && existingRawText != null;
    tx
      ..amount = amount
      ..source = source ?? "Manual"
      ..type = typeValue
      ..categoryKey = _txType == TransactionType.transfer ? null : _selectedParent!.key
      ..subCategoryKey = _txType == TransactionType.transfer ? null : _selectedSub?.key
      ..category = parentName
      ..subCategory = subName
      ..rawText = useRawText ? existingRawText : rawText
      ..note = note.isEmpty ? null : note
      ..accountId = _selectedAccount?.id
      ..toAccountId = _txType == TransactionType.transfer ? _selectedToAccount?.id : null
      ..timestamp = _selectedTime;

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(tx);
    });

    JiveLogger.i("Manual Transaction Saved: $amount");
    _hasDataChanges = true;

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final amountFontSize = isLandscape ? 48.0 : 72.0;
    final currencyFontSize = isLandscape ? 22.0 : 32.0;
    final labelSpacing = isLandscape ? 4.0 : 12.0;
    final parentTabHeight = isLandscape ? 44.0 : 68.0;
    final subGridAspectRatio = isLandscape ? 1.2 : 0.75;
    final subGridMainAxisSpacing = isLandscape ? 6.0 : 12.0;
    final keyboardAspectRatio = isLandscape ? 3.4 : 1.6;
    final keyboardPadding = EdgeInsets.fromLTRB(20, isLandscape ? 6 : 8, 20, isLandscape ? 6 : 30);
    final keyboardMainAxisSpacing = isLandscape ? 8.0 : 12.0;
    final keyboardCrossAxisSpacing = isLandscape ? 8.0 : 12.0;

    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final hideAmountInSearch = _isSearchMode && isKeyboardVisible;
    final showCustomKeyboard = !_isSearchMode && !isKeyboardVisible;

    final amountHeader = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentCategoryLabel(),
            style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: isLandscape ? 12 : 14),
          ),
          SizedBox(height: isLandscape ? 4 : 8),
          GestureDetector(
            onTap: _pickTransactionDate,
            child: Text(
              _dateTimeFormat.format(_selectedTime),
              style: GoogleFonts.lato(
                color: Colors.grey.shade500,
                fontSize: isLandscape ? 11 : 12,
              ),
            ),
          ),
          SizedBox(height: labelSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "¥",
                style: GoogleFonts.rubik(
                  color: Colors.black87,
                  fontSize: currencyFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _amountStr,
                style: GoogleFonts.rubik(
                  color: JiveTheme.primaryGreen,
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
          if (_accounts.isNotEmpty) ...[
            SizedBox(height: isLandscape ? 6 : 10),
            _buildAccountSelector(isLandscape: isLandscape),
            if (_selectedAccount != null && AccountService.isCreditAccount(_selectedAccount!))
              Padding(
                padding: EdgeInsets.only(top: isLandscape ? 4 : 6),
                child: _buildSelectedCreditSummary(_selectedAccount!, isLandscape: isLandscape),
              ),
          ],
          SizedBox(height: isLandscape ? 6 : 10),
          _buildNoteField(isLandscape: isLandscape),
        ],
      ),
    );

    final amountSection = hideAmountInSearch
        ? const SizedBox.shrink()
        : isLandscape
        ? Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: amountHeader,
          )
        : Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: amountHeader,
            ),
          );

    return WillPopScope(
      onWillPop: () async {
        if (_isSearchMode) {
          _exitSearchMode();
          return false;
        }
        Navigator.pop(context, _hasDataChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context, _hasDataChanges),
          ),
          actions: [
            if (_showCategories)
              IconButton(
                icon: Icon(_isSearchMode ? Icons.close : Icons.search, color: Colors.black87),
                onPressed: _toggleInlineSearch,
              ),
          ],
          centerTitle: true,
          title: _buildTypeSelector(),
        ),
        body: Column(
        children: [
          // 1. 金额显示区 (Flex 1)
          amountSection,

          // 2. 分类与键盘容器 (Flex 2)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  
                  if (_showCategories) ...[
                    if (_isSearchMode) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                        child: _buildInlineSearchField(),
                      ),
                      const Divider(height: 1, color: Colors.black12),
                    ] else ...[
                      // A. 父分类 Tab
                      SizedBox(
                        height: parentTabHeight,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _parentCategories.length,
                          itemBuilder: (context, index) {
                            final cat = _parentCategories[index];
                            final isSelected = cat.key == _selectedParent?.key;
                            final customColor = CategoryService.parseColorHex(cat.colorHex);
                            final activeColor = customColor ?? JiveTheme.primaryGreen;
                            final inactiveColor = JiveTheme.categoryIconInactive;
                            final iconColor = isSelected ? activeColor : inactiveColor;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedParent = cat;
                                  _selectedSub = null;
                                });
                                _loadSubCategories(cat.key);
                              },
                              onLongPress: () => _showParentActions(cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: isSelected
                                    ? BoxDecoration(
                                        border: Border(bottom: BorderSide(color: activeColor, width: 2)),
                                      )
                                    : null,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CategoryService.buildIcon(
                                      cat.iconName,
                                      size: isLandscape ? 16 : 18,
                                      color: iconColor,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: isLandscape ? 11 : 12,
                                        color: iconColor,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black12),
                    ],
                  ],

                  // B. 子分类网格 (Expanded)
                  Expanded(
                    child: _showCategories
                        ? _buildCategoryBody(subGridAspectRatio, subGridMainAxisSpacing)
                        : _buildTransferHint(),
                  ),

                  if (showCustomKeyboard) ...[
                    const Divider(height: 1, color: Colors.black12),

                    // C. 数字键盘
                    Container(
                      padding: keyboardPadding,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: keyboardAspectRatio,
                          crossAxisSpacing: keyboardCrossAxisSpacing,
                          mainAxisSpacing: keyboardMainAxisSpacing,
                        ),
                        itemCount: _keys.length,
                        itemBuilder: (context, index) {
                          return _buildKey(_keys[index]);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypeChip(TransactionType.expense, Icons.arrow_upward, "支出"),
          _buildTypeChip(TransactionType.income, Icons.arrow_downward, "收入"),
          _buildTypeChip(TransactionType.transfer, Icons.swap_horiz, "转账"),
        ],
      ),
    );
  }

  Widget _buildTypeChip(TransactionType type, IconData icon, String label) {
    final isSelected = _txType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _switchType(type),
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
            Icon(icon, size: 14, color: isSelected ? Colors.black87 : Colors.black38),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                color: isSelected ? Colors.black87 : Colors.black45,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector({required bool isLandscape}) {
    final textSize = isLandscape ? 11.0 : 12.0;
    if (_txType == TransactionType.transfer) {
      return Row(
        children: [
          Expanded(
            child: _buildAccountChip(
              label: "从",
              account: _selectedAccount,
              textSize: textSize,
              expand: true,
              onTap: () => _showAccountPicker(pickTo: false),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: _buildAccountChip(
              label: "到",
              account: _selectedToAccount,
              textSize: textSize,
              expand: true,
              onTap: () => _showAccountPicker(pickTo: true),
            ),
          ),
        ],
      );
    }

    return Center(
      child: _buildAccountChip(
        label: "账户",
        account: _selectedAccount,
        textSize: textSize,
        expand: false,
        onTap: () => _showAccountPicker(pickTo: false),
      ),
    );
  }

  Widget _buildAccountChip({
    required String label,
    required JiveAccount? account,
    required double textSize,
    required bool expand,
    required VoidCallback onTap,
  }) {
    final color = AccountService.parseColorHex(account?.colorHex) ?? JiveTheme.primaryGreen;
    final name = account?.name ?? "请选择";
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
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
                    "$label $name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: textSize, color: Colors.black87),
                  ),
                )
              else
                Text(
                  "$label $name",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: textSize, color: Colors.black87),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCreditSummary(JiveAccount account, {required bool isLandscape}) {
    final limit = account.creditLimit ?? 0;
    if (limit <= 0) {
      return const SizedBox.shrink();
    }
    final balance = _accountBalances[account.id] ?? account.openingBalance;
    final used = balance < 0 ? -balance : 0.0;
    final available = (limit - used).clamp(0, double.infinity).toDouble();
    final fontSize = isLandscape ? 10.0 : 11.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isLandscape ? 10 : 12,
      runSpacing: 4,
      children: [
        _buildCreditMetaText("额度", limit, Colors.blueGrey, fontSize),
        _buildCreditMetaText("已用", used, Colors.redAccent, fontSize),
        _buildCreditMetaText("可用", available, JiveTheme.primaryGreen, fontSize),
      ],
    );
  }

  Widget _buildCreditMetaText(String label, double value, Color color, double fontSize) {
    return Text(
      "$label ¥${_formatMoney(value)}",
      style: GoogleFonts.lato(fontSize: fontSize, color: color, fontWeight: FontWeight.w600),
    );
  }

  Future<void> _showAccountPicker({required bool pickTo}) async {
    if (_accounts.isEmpty) return;
    final entries = _buildAccountPickerEntries();
    final selected = await showModalBottomSheet<JiveAccount>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              if (entry.isHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    entry.header ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
              final account = entry.account!;
              final color = AccountService.parseColorHex(account.colorHex) ?? JiveTheme.primaryGreen;
              final currentId = pickTo ? _selectedToAccount?.id : _selectedAccount?.id;
              final isSelected = account.id == currentId;
              final subtitle = _accountSubtitle(account);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: AccountService.buildIcon(account.iconName, size: 18, color: color),
                ),
                title: Text(account.name),
                subtitle: Text(subtitle),
                trailing: isSelected ? Icon(Icons.check, color: color) : null,
                onTap: () => Navigator.pop(context, account),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;
    if (_txType == TransactionType.transfer) {
      final other = pickTo ? _selectedAccount : _selectedToAccount;
      if (other != null && other.id == selected.id) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("转出与转入账户不能相同")),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      if (pickTo) {
        _selectedToAccount = selected;
      } else {
        _selectedAccount = selected;
      }
    });
  }

  List<_AccountPickerEntry> _buildAccountPickerEntries() {
    final grouped = _groupAccounts(_accounts);
    final entries = <_AccountPickerEntry>[];
    for (final entry in grouped.entries) {
      entries.add(_AccountPickerEntry.header(entry.key));
      for (final account in entry.value) {
        entries.add(_AccountPickerEntry.item(account));
      }
    }
    return entries;
  }

  Map<String, List<JiveAccount>> _groupAccounts(List<JiveAccount> accounts) {
    final grouped = <String, List<JiveAccount>>{};
    for (final account in accounts) {
      final group = AccountService.displayGroupName(account);
      grouped.putIfAbsent(group, () => []).add(account);
    }
    for (final group in grouped.values) {
      group.sort((a, b) => a.order.compareTo(b.order));
    }
    final ordered = <String, List<JiveAccount>>{};
    for (final group in _accountGroupOrder) {
      final list = grouped[group];
      if (list != null && list.isNotEmpty) {
        ordered[group] = list;
      }
    }
    final remaining = grouped.keys.where((key) => !ordered.containsKey(key)).toList()..sort();
    for (final key in remaining) {
      ordered[key] = grouped[key] ?? [];
    }
    return ordered;
  }

  String _accountSubtitle(JiveAccount account) {
    final parts = <String>[
      account.type == AccountService.typeLiability ? "负债账户" : "资产账户",
    ];
    if (AccountService.isCreditAccount(account)) {
      final billingDay = account.billingDay;
      final repaymentDay = account.repaymentDay;
      final creditLimit = account.creditLimit;
      if (billingDay != null) {
        parts.add("账单日$billingDay");
      }
      if (repaymentDay != null) {
        parts.add("还款日$repaymentDay");
      }
      if (creditLimit != null && creditLimit > 0) {
        parts.add("额度¥${_formatMoney(creditLimit)}");
      }
    }
    return parts.join(" · ");
  }

  String _formatMoney(double value) {
    final rounded = value.roundToDouble();
    return value == rounded ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  String _formatAmountInput(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceAll(RegExp(r'\.?0+$'), '');
  }

  TransactionType _parseTxType(String? type) {
    switch (type) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  Widget _buildInlineSearchField() {
    return TextField(
      controller: _inlineSearchController,
      focusNode: _inlineSearchFocus,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: "搜索分类",
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _inlineSearchController.clear();
                  setState(() => _searchQuery = "");
                },
              ),
        filled: true,
        isDense: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryBody(double subGridAspectRatio, double subGridMainAxisSpacing) {
    final hasQuery = _isSearchMode && _searchQuery.trim().isNotEmpty;
    if (hasQuery && _searchItemsLoaded && _filterSearchResults(_searchQuery).isEmpty) {
      return _buildSystemSuggestionPanel();
    }
    return _buildSubCategoryGrid(subGridAspectRatio, subGridMainAxisSpacing);
  }

  Widget _buildSubCategoryGrid(double subGridAspectRatio, double subGridMainAxisSpacing) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: subGridAspectRatio,
        mainAxisSpacing: subGridMainAxisSpacing,
        crossAxisSpacing: 8,
      ),
      itemCount: _subCategories.length + 1,
      itemBuilder: (context, index) {
        if (index == _subCategories.length) {
          return GestureDetector(
            onTap: () async {
              final parent = _selectedParent;
              if (parent != null) {
                await _promptAddSubCategory(parent);
              }
            },
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add, color: Colors.grey, size: 20),
                ),
                const SizedBox(height: 3),
                const Text("自定义", style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          );
        }

        final cat = _subCategories[index];
        final isSelected = cat.key == _selectedSub?.key;
        final customColor = CategoryService.parseColorHex(cat.colorHex);
        final activeColor = customColor ?? JiveTheme.primaryGreen;
        final inactiveColor = JiveTheme.categoryIconInactive;
        return GestureDetector(
          onTap: () => setState(() => _selectedSub = cat),
          onLongPress: () => _showSubCategoryActions(cat),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : JiveTheme.categoryIconInactiveBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? activeColor : JiveTheme.categoryIconInactiveBorder,
                  ),
                ),
                child: CategoryService.buildIcon(
                  cat.iconName,
                  size: 18,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.black87 : JiveTheme.categoryLabelInactive,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemSuggestionPanel() {
    final suggestions = _systemSuggestionsForQuery(_searchQuery);
    if (suggestions.isEmpty) {
      return const Center(child: Text("未找到匹配分类"));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: suggestions.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text("系统库建议", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Text("点击添加并选中", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          );
        }
        final suggestion = suggestions[index - 1];
        final title = suggestion.isSub ? suggestion.name : suggestion.parentName;
        final subtitle = suggestion.isSub ? suggestion.parentName : "一级分类";
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: CategoryService.buildIcon(
              suggestion.iconName,
              size: 18,
              color: JiveTheme.categoryIconInactive,
            ),
          ),
          title: Text(title, style: TextStyle(color: Colors.grey.shade700)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: JiveTheme.categoryLabelInactive)),
          trailing: const Icon(Icons.add, color: Colors.grey),
          onTap: () => _applySystemSuggestion(suggestion),
        );
      },
    );
  }

  List<_SystemSuggestion> _systemSuggestionsForQuery(String query) {
    final normalized = _normalizeSearch(query);
    if (normalized.isEmpty) return const [];
    final isIncome = _txType == TransactionType.income;
    final lib = CategoryService(_isar).getSystemLibrary(isIncome: isIncome);
    final existingParents = <String>{};
    final existingChildren = <String>{};
    for (final item in _searchItems) {
      existingParents.add(item.parent.name);
      final sub = item.sub;
      if (sub == null) continue;
      existingChildren.add("${item.parent.name}::${sub.name}");
    }

    final suggestions = <_SystemSuggestion>[];
    for (final entry in lib.entries) {
      final parentName = entry.key;
      final parentIcon = (entry.value['icon'] as String?)?.trim().isNotEmpty == true
          ? entry.value['icon'] as String
          : "category";
      if (!existingParents.contains(parentName) &&
          _matchesSystemTokens(_tokensForSystem(parentName, "p::$parentName"), normalized)) {
        suggestions.add(_SystemSuggestion.parent(parentName, parentIcon));
      }
      final children = entry.value['children'] as List<dynamic>? ?? const [];
      for (final child in children) {
        final childName = child['name'] as String? ?? "";
        if (childName.trim().isEmpty) continue;
        final childIcon = (child['icon'] as String?)?.trim().isNotEmpty == true
            ? child['icon'] as String
            : "category";
        final key = "$parentName::$childName";
        if (existingChildren.contains(key)) continue;
        final tokens = <String>[
          ..._tokensForSystem(childName, "c::$key"),
          ..._tokensForSystem(parentName, "cp::$parentName"),
        ];
        if (_matchesSystemTokens(tokens, normalized)) {
          suggestions.add(_SystemSuggestion.child(parentName, childName, childIcon, parentIcon));
        }
      }
    }
    return suggestions;
  }

  bool _matchesSystemTokens(List<String> tokens, String query) {
    for (final token in tokens) {
      if (token.contains(query)) return true;
    }
    return false;
  }

  Future<void> _applySystemSuggestion(_SystemSuggestion suggestion) async {
    final service = CategoryService(_isar);
    final isIncome = _txType == TransactionType.income;
    JiveCategory? parent = await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(isIncome)
        .nameEqualTo(suggestion.parentName)
        .findFirst();

    parent ??= await service.createParentCategory(
      name: suggestion.parentName,
      iconName: suggestion.parentIconName,
      isIncome: isIncome,
      isSystem: true,
    );

    if (parent == null) {
      return;
    }

    JiveCategory? sub;
    if (suggestion.isSub) {
      sub = await service.createSubCategory(
        parent: parent,
        name: suggestion.name,
        iconName: suggestion.iconName,
        isSystem: true,
      );
      sub ??= await _isar.collection<JiveCategory>()
          .filter()
          .parentKeyEqualTo(parent.key)
          .nameEqualTo(suggestion.name)
          .findFirst();
    }

    await _reloadParentsAndSelect(parentKey: parent.key, subKey: sub?.key);
    _hasDataChanges = true;
    _searchItems = [];
    _searchItemsLoaded = false;
    _searchKeyCache.clear();
    _searchTokenCache.clear();
    if (mounted) {
      _exitSearchMode();
    }
  }

  Future<void> _reloadParentsAndSelect({required String parentKey, String? subKey}) async {
    final showIncome = _txType == TransactionType.income;
    var parents = await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(showIncome)
        .isHiddenEqualTo(false)
        .sortByOrder()
        .findAll();

    if (parents.isEmpty && !showIncome) {
      final service = CategoryService(_isar);
      final lib = service.getSystemLibrary(isIncome: showIncome);
      parents = lib.keys.map((name) => JiveCategory()
        ..key = service.buildSystemParentKey(name, isIncome: showIncome)
        ..name = name
        ..iconName = lib[name]!['icon']
        ..order = 0
      ).toList();
      _isFallbackMode = true;
    } else {
      _isFallbackMode = false;
    }

    JiveCategory? selected;
    if (parents.isNotEmpty) {
      selected = parents.firstWhere(
        (item) => item.key == parentKey,
        orElse: () => parents.first,
      );
    }

    if (!mounted) return;
    setState(() {
      _parentCategories = parents;
      _selectedParent = selected;
    });
    if (_selectedParent != null) {
      await _loadSubCategories(_selectedParent!.key, selectKey: subKey);
    } else {
      setState(() {
        _subCategories = [];
        _selectedSub = null;
      });
    }
  }

  List<CategorySearchResult> _filterSearchResults([String? query]) {
    final q = _normalizeSearch(query ?? _searchQuery);
    if (q.isEmpty) return _searchItems;
    return _searchItems.where((item) {
      if (_matches(item.parent, q)) return true;
      final sub = item.sub;
      return sub != null && _matches(sub, q);
    }).toList();
  }

  String _normalizeSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  }

  bool _matches(JiveCategory category, String query) {
    final key = _searchKeyCache[category.key] ??= _buildSearchKey(category);
    return key.contains(query);
  }

  String _buildSearchKey(JiveCategory category) {
    final name = _normalizeSearch(category.name);
    final icon = _normalizeSearch(category.iconName);
    final pinyin = _normalizeSearch(PinyinHelper.getPinyinE(category.name));
    final short = _normalizeSearch(PinyinHelper.getShortPinyin(category.name));
    return "$name $icon $pinyin $short";
  }

  List<String> _tokensForCategory(JiveCategory category) {
    return _searchTokenCache[category.key] ??= _buildTokensForName(category.name);
  }

  List<String> _tokensForSystem(String name, String key) {
    return _systemTokenCache[key] ??= _buildTokensForName(name);
  }

  List<String> _buildTokensForName(String name) {
    final normalized = _normalizeSearch(name);
    final pinyin = _normalizeSearch(PinyinHelper.getPinyinE(name));
    final short = _normalizeSearch(PinyinHelper.getShortPinyin(name));
    return [normalized, pinyin, short]..removeWhere((token) => token.isEmpty);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (_searchQuery.trim().isEmpty) return;
    _applySearchSelection(_searchQuery);
  }

  Future<void> _applySearchSelection(String query) async {
    if (_searchItems.isEmpty) return;
    final results = _filterSearchResults(query);
    if (results.isEmpty) return;
    final normalized = _normalizeSearch(query);
    final exactMatches = results.where((item) => _isExactMatch(item, normalized)).toList();
    if (exactMatches.isNotEmpty) {
      await _selectSearchResult(exactMatches.first);
      return;
    }
    final prefixMatches = results.where((item) => _isPrefixMatch(item, normalized)).toList();
    if (prefixMatches.length == 1) {
      await _selectSearchResult(prefixMatches.first);
    }
  }

  Future<void> _selectSearchResult(CategorySearchResult result) async {
    final parent = result.parent;
    final subKey = result.sub?.key;
    setState(() {
      _selectedParent = parent;
      _selectedSub = result.sub;
    });
    await _loadSubCategories(parent.key, selectKey: subKey);
  }

  bool _isExactMatch(CategorySearchResult item, String query) {
    final tokens = _tokensForCategory(item.sub ?? item.parent);
    return tokens.contains(query);
  }

  bool _isPrefixMatch(CategorySearchResult item, String query) {
    final tokens = _tokensForCategory(item.sub ?? item.parent);
    for (final token in tokens) {
      if (token.startsWith(query)) return true;
    }
    return false;
  }

  Future<void> _loadNoteTagUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <TransactionType, Map<String, int>>{};
    for (final type in TransactionType.values) {
      final raw = prefs.getString('$_noteTagUsageKeyPrefix${type.name}');
      if (raw == null) continue;
      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        continue;
      }
      if (decoded is! Map) continue;
      final map = <String, int>{};
      decoded.forEach((key, value) {
        if (key is String && value is num) {
          map[key] = value.toInt();
        }
      });
      if (map.isNotEmpty) {
        loaded[type] = map;
      }
    }
    if (!mounted) return;
    setState(() {
      _noteTagUsage
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<void> _persistNoteTagUsage(TransactionType type) async {
    final prefs = await SharedPreferences.getInstance();
    final usage = _noteTagUsage[type];
    final key = '$_noteTagUsageKeyPrefix${type.name}';
    if (usage == null || usage.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(usage));
  }

  void _trackNoteTagUsage(TransactionType type, String tag) {
    final usage = _noteTagUsage.putIfAbsent(type, () => {});
    usage[tag] = (usage[tag] ?? 0) + 1;
    _persistNoteTagUsage(type);
    if (mounted) {
      setState(() {});
    }
  }

  List<String> _noteSuggestionsForType(TransactionType type) {
    final base = switch (type) {
      TransactionType.income => _incomeNoteSuggestions,
      TransactionType.transfer => _transferNoteSuggestions,
      _ => _expenseNoteSuggestions,
    };
    final usage = _noteTagUsage[type];
    if (usage == null || usage.isEmpty) return base;
    final order = <String, int>{
      for (var i = 0; i < base.length; i++) base[i]: i,
    };
    final sorted = [...base];
    sorted.sort((a, b) {
      final countA = usage[a] ?? 0;
      final countB = usage[b] ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA);
      }
      return (order[a] ?? 0).compareTo(order[b] ?? 0);
    });
    return sorted;
  }

  Widget _buildNoteField({required bool isLandscape}) {
    final currentType = _txType;
    return NoteFieldWithChips(
      controller: _noteController,
      isLandscape: isLandscape,
      suggestions: _noteSuggestionsForType(currentType),
      onTagSelected: (tag) => _trackNoteTagUsage(currentType, tag),
    );
  }


  Widget _buildTransferHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 28, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text("转账无需分类", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    bool isOk = key == 'OK';
    bool isDel = key == 'DEL';
    
    if (isOk) {
      return InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            color: JiveTheme.primaryGreen,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: JiveTheme.primaryGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: const Center(child: Icon(Icons.check, color: Colors.white, size: 28)),
        ),
      );
    }

    return InkWell(
      onTap: () => _onKeyPress(key),
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: isDel 
            ? const Icon(Icons.backspace_rounded, size: 22, color: Colors.black54)
            : ['+', '-', 'date'].contains(key)
                ? _buildOpIcon(key)
                : Text(key, style: GoogleFonts.rubik(fontSize: 26, color: Colors.black87, fontWeight: FontWeight.w400)),
      ),
    );
  }

  Widget _buildOpIcon(String key) {
    if (key == 'date') return const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.black45);
    return Text(key, style: const TextStyle(fontSize: 24, color: Colors.black45));
  }
}

class _AccountPickerEntry {
  final String? header;
  final JiveAccount? account;

  const _AccountPickerEntry.header(this.header) : account = null;
  const _AccountPickerEntry.item(this.account) : header = null;

  bool get isHeader => header != null;
}

class _SystemSuggestion {
  final String parentName;
  final String name;
  final String parentIconName;
  final String iconName;
  final bool isSub;

  const _SystemSuggestion._({
    required this.parentName,
    required this.name,
    required this.parentIconName,
    required this.iconName,
    required this.isSub,
  });

  factory _SystemSuggestion.parent(String name, String iconName) {
    return _SystemSuggestion._(
      parentName: name,
      name: name,
      parentIconName: iconName,
      iconName: iconName,
      isSub: false,
    );
  }

  factory _SystemSuggestion.child(String parentName, String name, String iconName, String parentIconName) {
    return _SystemSuggestion._(
      parentName: parentName,
      name: name,
      parentIconName: parentIconName,
      iconName: iconName,
      isSub: true,
    );
  }
}
