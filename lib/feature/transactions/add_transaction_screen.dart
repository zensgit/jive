import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/account_model.dart';
import '../../core/database/budget_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/project_model.dart';
import '../../core/service/project_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/category_icon_style.dart';
import '../../core/service/account_service.dart';
import '../../core/service/budget_pref_service.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/tag_service.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/tag_rule_service.dart';
import '../../core/service/transaction_service.dart';
import '../../core/widgets/jive_calendar/jive_calendar.dart';
import '../../core/database/category_model.dart';
import '../../core/service/auto_rule_engine.dart';
import '../../core/service/merchant_memory_service.dart';
import '../../core/service/speech_intent_parser.dart';
import '../../core/service/speech_settings.dart';
import '../../core/service/speech_service.dart';
import '../../core/service/voice_quota_service.dart';
import '../../core/utils/logger_util.dart';
import '../category/category_create_dialog.dart';
import '../category/category_create_screen.dart';
import '../category/category_edit_dialog.dart';
import '../category/category_manager_screen.dart';
import '../category/category_search_delegate.dart';
import '../stats/stats_screen.dart';
import '../tag/tag_icon_catalog.dart';
import '../tag/tag_picker_sheet.dart';
import 'note_field_with_chips.dart';

enum TransactionType { expense, income, transfer }

class AddTransactionScreen extends StatefulWidget {
  final JiveTransaction? editingTransaction;
  final JiveTransaction? prefillTransaction;
  final TransactionType? initialType;
  final bool startWithSpeech;
  final String? initialSpeechText;
  final int? bookId;

  const AddTransactionScreen({
    super.key,
    this.editingTransaction,
    this.prefillTransaction,
    this.initialType,
    this.startWithSpeech = false,
    this.initialSpeechText,
    this.bookId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const List<String> _accountGroupOrder = [...AccountService.groupOrder];
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
  static const List<String> _transferNoteSuggestions = ['还款', '储蓄', '调拨', '借还'];
  static const String _noteTagUsageKeyPrefix = 'note_tag_usage_v1_';

  // ── Voice recognition state ──
  final SpeechIntentParser _speechParser = SpeechIntentParser();
  bool _speechHoldActive = false;
  bool _speechHoldPending = false;
  bool _speechHoldStopQueued = false;
  bool _speechHoldCancelQueued = false;
  bool _speechHoldUsedFallback = false;
  bool _speechUiActive = false;
  SpeechEngine? _speechHoldEngine;
  SpeechService? _speechHoldService;

  String _amountStr = "0";
  String _toAmountStr = ""; // 跨币种转账的转入金额
  double? _crossCurrencyRate; // 跨币种转账时使用的汇率
  String? _crossCurrencyRateSource; // 汇率来源
  bool _isEditingToAmount = false; // 是否正在编辑转入金额
  late Isar _isar;
  final TextEditingController _toAmountController = TextEditingController();
  bool _isLoading = true;
  bool _hasDataChanges = false;
  bool _isFallbackMode = false;
  bool _isSearchMode = false;
  bool _isEditing = false;
  bool _excludeFromBudget = false; // 不计入预算（仅对支出有效）
  TransactionType _txType = TransactionType.expense;
  DateTime _selectedTime = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final Map<TransactionType, Map<String, int>> _noteTagUsage = {};
  // ── Merchant memory ──
  MerchantSuggestion? _merchantSuggestion;
  Timer? _merchantDebounce;
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
  List<JiveTag> _tags = [];
  List<String> _selectedTagKeys = [];
  List<JiveProject> _projects = [];
  int? _selectedProjectId;
  List<CategorySearchResult> _searchItems = [];
  final Map<String, String> _searchKeyCache = {};
  final TextEditingController _inlineSearchController = TextEditingController();
  final FocusNode _inlineSearchFocus = FocusNode();
  final DateFormat _dateTimeFormat = DateFormat('MM-dd HH:mm');
  String _searchQuery = "";
  final Map<String, List<String>> _searchTokenCache = {};
  final Map<String, List<String>> _systemTokenCache = {};
  bool _searchItemsLoaded = false;
  CurrencyService? _currencyService;

  final List<String> _keys = [
    '7',
    '8',
    '9',
    'date',
    '4',
    '5',
    '6',
    '+',
    '1',
    '2',
    '3',
    '-',
    '.',
    '0',
    'DEL',
    'OK',
  ];

  @override
  void initState() {
    super.initState();
    _initializeEditingState();
    _loadNoteTagUsage();
    _initData();
    _noteController.addListener(() => _onNoteChanged(_noteController.text));
    // Speech initialization
    if (widget.startWithSpeech) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final initialText = widget.initialSpeechText;
          if (initialText != null && initialText.trim().isNotEmpty) {
            _handleInitialSpeechText(initialText);
          } else {
            _showHoldToTalkHint();
          }
        }
      });
    } else if (widget.initialSpeechText != null && widget.initialSpeechText!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleInitialSpeechText(widget.initialSpeechText!);
        }
      });
    }
  }

  @override
  void dispose() {
    _merchantDebounce?.cancel();
    _inlineSearchController.dispose();
    _inlineSearchFocus.dispose();
    _noteController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }

  void _initializeEditingState() {
    final editing = widget.editingTransaction;
    if (editing != null) {
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
      _selectedTagKeys = List<String>.from(editing.tagKeys);
      _selectedProjectId = editing.projectId;
      _excludeFromBudget =
          _txType == TransactionType.expense && editing.excludeFromBudget;
      // 跨币种转账数据
      if (editing.toAmount != null) {
        _toAmountStr = _formatAmountInput(editing.toAmount!);
        _toAmountController.text = _toAmountStr;
        _isEditingToAmount = true; // 已有数据，不自动覆盖
      }
      _crossCurrencyRate = editing.exchangeRate;
      return;
    }

    final prefill = widget.prefillTransaction;
    if (prefill != null) {
      _amountStr = _formatAmountInput(prefill.amount);
      _selectedTime = prefill.timestamp;
      _txType = _parseTxType(prefill.type);
      _editingAccountId = prefill.accountId;
      _editingToAccountId = prefill.toAccountId;
      _editingParentKey = prefill.categoryKey;
      _editingParentName = prefill.category;
      _editingSubKey = prefill.subCategoryKey;
      _editingSubName = prefill.subCategory;
      _noteController.text = prefill.note ?? '';
      _selectedTagKeys = List<String>.from(prefill.tagKeys);
      _selectedProjectId = prefill.projectId;
      _excludeFromBudget =
          _txType == TransactionType.expense && prefill.excludeFromBudget;
      // 跨币种转账数据
      if (prefill.toAmount != null) {
        _toAmountStr = _formatAmountInput(prefill.toAmount!);
        _toAmountController.text = _toAmountStr;
        _isEditingToAmount = true;
      }
      _crossCurrencyRate = prefill.exchangeRate;
      return;
    }

    // 使用初始类型（如果提供）
    if (widget.initialType != null) {
      _txType = widget.initialType!;
    }
  }

  Future<void> _initData() async {
    try {
      JiveLogger.d(">>> INIT DATA STARTED");
      _isar = await DatabaseService.getInstance();

      _currencyService = CurrencyService(_isar);
      await CategoryService(_isar).initDefaultCategories();
      await AccountService(_isar).initDefaultAccounts();
      await TagService(_isar).initDefaultGroups();
      await _loadAccounts();
      await _loadTags();
      await _loadProjects();
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
    var parents = await _isar
        .collection<JiveCategory>()
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
      parents = lib.keys
          .map(
            (name) => JiveCategory()
              ..key = service.buildSystemParentKey(name, isIncome: showIncome)
              ..name = name
              ..iconName = lib[name]!['icon']
              ..order = 0,
          )
          .toList();
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
      if (selected == null &&
          selectParentName != null &&
          selectParentName.isNotEmpty) {
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
    } else if (selectedAccount == null ||
        !accounts.any((a) => a.id == selectedAccount!.id)) {
      selectedAccount = accounts.first;
    }

    JiveAccount? selectedTo = _selectedToAccount;
    if (_editingToAccountId != null && accounts.isNotEmpty) {
      selectedTo = accounts.firstWhere(
        (a) => a.id == _editingToAccountId,
        orElse: () => selectedTo ?? accounts.first,
      );
    }
    if (selectedTo == null ||
        (selectedAccount != null && selectedTo.id == selectedAccount.id)) {
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

  Future<void> _loadTags() async {
    final tags = await TagService(_isar).getTags(includeArchived: false);
    if (!mounted) return;
    setState(() {
      _tags = tags;
      _selectedTagKeys = _selectedTagKeys
          .where((key) => tags.any((t) => t.key == key))
          .toList();
    });
  }

  Future<void> _loadProjects() async {
    final projects = await ProjectService(_isar).getActiveProjects();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      // 验证选中的项目是否仍然存在
      if (_selectedProjectId != null &&
          !projects.any((p) => p.id == _selectedProjectId)) {
        _selectedProjectId = null;
      }
    });
  }

  /// 加载跨币种转账的汇率
  Future<void> _loadCrossCurrencyRate() async {
    if (_currencyService == null) return;
    if (_selectedAccount == null || _selectedToAccount == null) {
      setState(() {
        _crossCurrencyRate = null;
        _crossCurrencyRateSource = null;
        _toAmountStr = "";
        _toAmountController.text = "";
      });
      return;
    }

    final fromCurrency = _selectedAccount!.currency;
    final toCurrency = _selectedToAccount!.currency;

    if (fromCurrency == toCurrency) {
      setState(() {
        _crossCurrencyRate = null;
        _crossCurrencyRateSource = null;
        _toAmountStr = "";
        _toAmountController.text = "";
      });
      return;
    }

    // 获取汇率记录
    final rateRecord = await _currencyService!.getRateRecord(
      fromCurrency,
      toCurrency,
    );
    double? rate;
    String? source;

    if (rateRecord != null) {
      rate = rateRecord.rate;
      source = rateRecord.source;
    } else {
      // 使用默认汇率
      rate = CurrencyDefaults.getRate(fromCurrency, toCurrency);
      source = 'default';
    }

    if (!mounted) return;

    setState(() {
      _crossCurrencyRate = rate;
      _crossCurrencyRateSource = source;
      // 如果有输入金额且未手动编辑转入金额，自动计算
      if (!_isEditingToAmount && _toAmountStr.isEmpty) {
        _calculateToAmount();
      }
    });
  }

  /// 根据汇率计算转入金额
  void _calculateToAmount() {
    if (_crossCurrencyRate == null) return;
    final amount = double.tryParse(_amountStr);
    if (amount == null || amount <= 0) {
      _toAmountStr = "";
      _toAmountController.text = "";
      return;
    }
    final toAmount = amount * _crossCurrencyRate!;
    final toDecimals = CurrencyDefaults.getDecimalPlaces(
      _selectedToAccount?.currency ?? 'CNY',
    );
    _toAmountStr = toAmount.toStringAsFixed(toDecimals);
    _toAmountController.text = _toAmountStr;
  }

  String _typeValue(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return "income";
      case TransactionType.transfer:
        return "transfer";
      case TransactionType.expense:
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
      if (type != TransactionType.expense) {
        _excludeFromBudget = false;
      }
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
    var subs = await _isar
        .collection<JiveCategory>()
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
      final resolvedName = parentName.isEmpty
          ? service.resolveSystemParentName(parentKey)
          : parentName;
      if (resolvedName == null || resolvedName.isEmpty) {
        return;
      }
      final lib = service.getSystemLibrary(isIncome: false);
      if (lib.containsKey(resolvedName)) {
        final children = lib[resolvedName]!['children'] as List;
        subs = children
            .map<JiveCategory>(
              (c) => JiveCategory()
                ..key = service.buildSystemChildKey(
                  resolvedName,
                  c['name'],
                  isIncome: false,
                )
                ..name = c['name']
                ..iconName = c['icon'],
            )
            .toList();
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
      MaterialPageRoute(
        builder: (context) => CategoryManagerScreen(isar: _isar),
      ),
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
    final parents = all
        .where(
          (c) => c.parentKey == null && !c.isHidden && c.isIncome == showIncome,
        )
        .toList();
    parents.sort((a, b) => a.order.compareTo(b.order));
    final parentByKey = {for (final p in parents) p.key: p};
    final items = <CategorySearchResult>[];
    for (final parent in parents) {
      items.add(CategorySearchResult(parent: parent));
    }
    final children = all
        .where(
          (c) => c.parentKey != null && !c.isHidden && c.isIncome == showIncome,
        )
        .toList();
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
    final existingNames =
        (await _isar
                .collection<JiveCategory>()
                .filter()
                .parentKeyEqualTo(parent.key)
                .findAll())
            .map((child) => child.name)
            .toSet();
    final systemLibrary = CategoryService(
      _isar,
    ).getSystemLibrary(isIncome: parent.isIncome, includeIncome: true);
    if (!mounted) return;
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
          onBatchAdd: (suggestion, colorHex, iconForceTinted) async {
            final created = await CategoryService(_isar).createSubCategory(
              parent: parent,
              name: suggestion.name,
              iconName: suggestion.iconName,
              colorHex: colorHex,
              isSystem: true,
              iconForceTinted: iconForceTinted,
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
          iconForceTinted: result.iconForceTinted,
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
            ? CategoryService(
                _isar,
              ).suggestIconName(name, fallback: result.iconName)
            : result.iconName;
        final created = await CategoryService(_isar).createSubCategory(
          parent: parent,
          name: name,
          iconName: iconName,
          colorHex: result.colorHex,
          iconForceTinted: result.iconForceTinted,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("已存在同名子类")));
      return;
    }

    _hasDataChanges = true;
    _searchItems = [];
    _searchItemsLoaded = false;
    _searchKeyCache.clear();
    _searchTokenCache.clear();
    setState(() => _selectedParent = parent);
    await _loadSubCategories(parent.key, selectKey: lastCreated.key);
    if (!mounted) return;
    if (skipped.isNotEmpty) {
      final preview = skipped.take(3).join("、");
      final suffix = skipped.length > 3 ? "等" : "";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("已忽略重复: $preview$suffix")));
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
                    builder: (context) =>
                        CategoryEditDialog(category: sub, isar: _isar),
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
                final deleted = await CategoryService(
                  _isar,
                ).deleteCategory(sub);
                if (!mounted) return;
                if (!deleted) {
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(const SnackBar(content: Text("请先处理子类后再删除")));
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
      // 如果是跨币种转账且未手动编辑转入金额，自动计算
      if (!_isEditingToAmount && _crossCurrencyRate != null) {
        _calculateToAmount();
      }
    });
  }

  Future<void> _pickTransactionDate() async {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month, now.day);
    final result = await JiveDatePicker.pickDateResult(
      context,
      initialDay: _selectedTime,
      firstDay: DateTime(2010),
      lastDay: lastDay,
      bottomLabel: '选择日期',
    );
    if (!mounted) return;
    final pickedDay = result.value;
    if (!result.didChange || pickedDay == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (time == null) return;
    setState(() {
      _selectedTime = DateTime(
        pickedDay.year,
        pickedDay.month,
        pickedDay.day,
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
    if (_txType == TransactionType.transfer && _selectedToAccount == null) {
      return;
    }
    if (_txType == TransactionType.transfer &&
        _selectedToAccount?.id == _selectedAccount?.id) {
      return;
    }

    final typeValue = _typeValue(_txType);
    final parentName = _txType == TransactionType.transfer
        ? "转账"
        : _selectedParent!.name;
    final subName = _txType == TransactionType.transfer
        ? ""
        : (_selectedSub?.name ?? "");
    final rawText = _txType == TransactionType.transfer
        ? "转账"
        : "${_selectedParent!.name} - ${_selectedSub?.name ?? ''}";

    if (_selectedProjectId != null) {
      final project = _projects
          .where((p) => p.id == _selectedProjectId)
          .firstOrNull;
      if (project != null && project.budget > 0) {
        final service = ProjectService(_isar);
        final currentSpent = await service.calculateProjectSpending(project.id);
        final editingAmount =
            _isEditing && widget.editingTransaction?.projectId == project.id
            ? widget.editingTransaction?.amount ?? 0
            : 0;
        final projected = currentSpent - editingAmount + amount;
        if (projected > project.budget) {
          final over = projected - project.budget;
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('预算将超支'),
              content: Text('关联该交易后将超支 ¥${over.toStringAsFixed(0)}，是否继续？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('继续'),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      }
    }

    final budgetSaveAlertEnabled =
        await BudgetPrefService.getBudgetSaveAlertEnabled();
    if (budgetSaveAlertEnabled &&
        _txType == TransactionType.expense &&
        !_excludeFromBudget) {
      final service = BudgetService(_isar, CurrencyService(_isar));

      final newTx = JiveTransaction()
        ..amount = amount
        ..source = 'Manual'
        ..timestamp = _selectedTime
        ..type = 'expense'
        ..categoryKey = _selectedParent!.key
        ..subCategoryKey = _selectedSub?.key
        ..excludeFromBudget = false;

      JiveTransaction? oldTx;
      if (_isEditing && widget.editingTransaction != null) {
        final editing = widget.editingTransaction!;
        oldTx = JiveTransaction()
          ..amount = editing.amount
          ..source = editing.source
          ..timestamp = editing.timestamp
          ..type = editing.type
          ..categoryKey = editing.categoryKey
          ..subCategoryKey = editing.subCategoryKey
          ..excludeFromBudget = editing.excludeFromBudget;
      }

      final impacts = await service.evaluateBudgetImpactsForTransaction(
        newTransaction: newTx,
        oldTransaction: oldTx,
      );
      if (impacts.isNotEmpty) {
        final proceed = await _confirmBudgetImpact(impacts);
        if (proceed != true) return;
      }
    }

    final tx = widget.editingTransaction ?? JiveTransaction();
    final source = _isEditing ? tx.source : "Manual";
    final note = _noteController.text.trim();
    final existingRawText = tx.rawText;
    final useRawText =
        _isEditing && source != "Manual" && existingRawText != null;
    tx
      ..amount = amount
      ..source = source
      ..type = typeValue
      ..categoryKey = _txType == TransactionType.transfer
          ? null
          : _selectedParent!.key
      ..subCategoryKey = _txType == TransactionType.transfer
          ? null
          : _selectedSub?.key
      ..category = parentName
      ..subCategory = subName
      ..rawText = useRawText ? existingRawText : rawText
      ..note = note.isEmpty ? null : note
      ..accountId = _selectedAccount?.id
      ..toAccountId = _txType == TransactionType.transfer
          ? _selectedToAccount?.id
          : null
      ..toAmount =
          _txType == TransactionType.transfer && _crossCurrencyRate != null
          ? double.tryParse(_toAmountStr)
          : null
      ..exchangeRate = _txType == TransactionType.transfer
          ? _crossCurrencyRate
          : null
      ..projectId = _selectedProjectId
      ..tagKeys = List<String>.from(_selectedTagKeys)
      ..excludeFromBudget =
          _txType == TransactionType.expense && _excludeFromBudget
      ..smartTagKeys = List<String>.from(tx.smartTagKeys)
      ..timestamp = _selectedTime
      ..bookId = widget.bookId ?? tx.bookId;

    if (!_isEditing) {
      final matched = await TagRuleService(_isar).resolveMatchingTags(tx);
      if (matched.isNotEmpty) {
        final merged = <String>{...tx.tagKeys, ...matched}.toList();
        tx.tagKeys = merged;
        tx.smartTagKeys = matched;
      } else {
        tx.smartTagKeys = [];
      }
    } else {
      // Keep smart tags only if the tag still exists on the transaction.
      tx.smartTagKeys = tx.smartTagKeys.where(tx.tagKeys.contains).toList();
    }

    TransactionService.touchSyncMetadata(tx);
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(tx);
    });
    if (tx.tagKeys.isNotEmpty) {
      await TagService(_isar).markTagsUsed(tx.tagKeys, tx.timestamp);
    }

    // 商户记忆自动学习
    await MerchantMemoryService(_isar).learnFromTransaction(tx);

    JiveLogger.i("Manual Transaction Saved: $amount");
    _hasDataChanges = true;

    if (mounted) {
      DataReloadBus.notify();
      Navigator.pop(context, true);
    }
  }

  Future<bool?> _confirmBudgetImpact(
    List<BudgetTransactionImpact> impacts,
  ) async {
    if (impacts.isEmpty) return true;
    final hasExceeded = impacts.any(
      (i) => i.projectedStatus == BudgetStatus.exceeded,
    );

    var dontShowAgain = false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final maxItems = 4;
        final shown = impacts.take(maxItems).toList();
        final more = impacts.length - shown.length;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(hasExceeded ? '预算将超支' : '预算预警'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本次保存将触发以下预算提醒：'),
                    const SizedBox(height: 12),
                    ...shown.map((impact) => _buildBudgetImpactRow(impact)),
                    if (more > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '另有 $more 个预算…',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () =>
                          setState(() => dontShowAgain = !dontShowAgain),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Checkbox(
                              value: dontShowAgain,
                              onChanged: (value) => setState(
                                () => dontShowAgain = value ?? false,
                              ),
                            ),
                            const Expanded(child: Text('不再提示预算提醒')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '你也可以在「设置 → 预算设置」中调整该偏好。',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('继续保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (proceed == true && dontShowAgain) {
      await BudgetPrefService.setBudgetSaveAlertEnabled(false);
    }
    return proceed;
  }

  Widget _buildBudgetImpactRow(BudgetTransactionImpact impact) {
    final budget = impact.budget;
    final symbol = CurrencyDefaults.getSymbol(budget.currency);
    final isExceeded = impact.projectedStatus == BudgetStatus.exceeded;
    final color = isExceeded ? Colors.red.shade700 : Colors.orange.shade700;
    final icon = isExceeded ? Icons.warning_amber_rounded : Icons.info_outline;
    final message = isExceeded
        ? '将超支 $symbol ${(impact.projectedUsedAmount - impact.effectiveAmount).abs().toStringAsFixed(0)}'
        : '将达到预警 ${budget.alertThreshold?.toStringAsFixed(0) ?? '--'}%（${impact.projectedUsedPercent.toStringAsFixed(1)}%）';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(color: color.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final amountFontSize = isLandscape ? 48.0 : 72.0;
    final currencyFontSize = isLandscape ? 22.0 : 32.0;
    final labelSpacing = isLandscape ? 4.0 : 12.0;
    final parentTabHeight = isLandscape ? 44.0 : 68.0;
    final subGridAspectRatio = isLandscape ? 1.2 : 0.75;
    final subGridMainAxisSpacing = isLandscape ? 6.0 : 12.0;
    final keyboardAspectRatio = isLandscape ? 3.4 : 1.6;
    final keyboardPadding = EdgeInsets.fromLTRB(
      20,
      isLandscape ? 6 : 8,
      20,
      isLandscape ? 6 : 30,
    );
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
            style: GoogleFonts.lato(
              color: Colors.grey.shade500,
              fontSize: isLandscape ? 12 : 14,
            ),
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
                CurrencyDefaults.getSymbol(_selectedAccount?.currency ?? 'CNY'),
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
            if (_selectedAccount != null &&
                AccountService.isCreditAccount(_selectedAccount!))
              Padding(
                padding: EdgeInsets.only(top: isLandscape ? 4 : 6),
                child: _buildSelectedCreditSummary(
                  _selectedAccount!,
                  isLandscape: isLandscape,
                ),
              ),
          ],
          SizedBox(height: isLandscape ? 6 : 10),
          _buildNoteField(isLandscape: isLandscape),
          SizedBox(height: isLandscape ? 6 : 8),
          _buildTagSelector(isLandscape: isLandscape),
          if (_txType == TransactionType.expense) ...[
            SizedBox(height: isLandscape ? 6 : 8),
            _buildBudgetFlags(isLandscape: isLandscape),
          ],
          SizedBox(height: isLandscape ? 6 : 8),
          _buildProjectSelector(isLandscape: isLandscape),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchMode) {
          _exitSearchMode();
          return;
        }
        Navigator.pop(context, _hasDataChanges);
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showHoldToTalkHint,
              onLongPressStart: (_) => _startSpeechHold(),
              onLongPressEnd: (_) => _stopSpeechHold(),
              onLongPressCancel: _cancelSpeechHold,
              child: const SizedBox(
                width: kMinInteractiveDimension,
                height: kMinInteractiveDimension,
                child: Center(
                  child: Icon(Icons.mic, color: Colors.black87),
                ),
              ),
            ),
            if (_showCategories)
              IconButton(
                icon: Icon(
                  _isSearchMode ? Icons.close : Icons.search,
                  color: Colors.black87,
                ),
                onPressed: _toggleInlineSearch,
              ),
          ],
          centerTitle: true,
          title: _buildTypeSelector(),
        ),
        body: Stack(
          children: [
            Column(
          children: [
            // 1. 金额显示区 (Flex 1)
            amountSection,

            // 2. 分类与键盘容器 (Flex 2)
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
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
                              final isSelected =
                                  cat.key == _selectedParent?.key;
                              final customColor = CategoryService.parseColorHex(
                                cat.colorHex,
                              );
                              final activeColor =
                                  customColor ?? JiveTheme.primaryGreen;
                              final inactiveColor =
                                  JiveTheme.categoryIconInactive;
                              final iconColor = isSelected
                                  ? activeColor
                                  : inactiveColor;
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: isSelected
                                      ? BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: activeColor,
                                              width: 2,
                                            ),
                                          ),
                                        )
                                      : null,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CategoryService.buildIcon(
                                        cat.iconName,
                                        size: isLandscape ? 16 : 18,
                                        color: iconColor,
                                        isSystemCategory: cat.isSystem,
                                        forceTinted: cat.iconForceTinted,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: isLandscape ? 11 : 12,
                                          color: iconColor,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
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
                          ? _buildCategoryBody(
                              subGridAspectRatio,
                              subGridMainAxisSpacing,
                            )
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
            // Voice listening overlay
            if (_speechHoldActive)
              Positioned(
                left: 20,
                right: 20,
                top: 12,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text("正在聆听，松开结束", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // ── Merchant Memory Methods ──
  // ══════════════════════════════════════════════════

  void _onNoteChanged(String text) {
    _merchantDebounce?.cancel();
    if (text.trim().length < 2) {
      if (_merchantSuggestion != null) {
        setState(() => _merchantSuggestion = null);
      }
      return;
    }
    _merchantDebounce = Timer(const Duration(milliseconds: 300), () async {
      final suggestion = await MerchantMemoryService(_isar).getSuggestion(text.trim());
      if (!mounted) return;
      setState(() => _merchantSuggestion = suggestion);
    });
  }

  void _applyMerchantSuggestion() {
    final suggestion = _merchantSuggestion;
    if (suggestion == null) return;
    if (suggestion.categoryKey != null) {
      final parent = _parentCategories.firstWhere(
        (cat) => cat.key == suggestion.categoryKey,
        orElse: () => _parentCategories.first,
      );
      if (parent.key == suggestion.categoryKey) {
        setState(() => _selectedParent = parent);
        _loadSubCategories(parent.key);
      }
    }
    setState(() => _merchantSuggestion = null);
  }

  Widget _buildMerchantSuggestionBanner() {
    final suggestion = _merchantSuggestion;
    if (suggestion == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.store, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "建议分类: ${_parentCategories.where((c) => c.key == suggestion.categoryKey).map((c) => c.name).firstOrNull ?? '未知'}",
              style: TextStyle(fontSize: 12, color: Colors.green.shade800),
            ),
          ),
          GestureDetector(
            onTap: _applyMerchantSuggestion,
            child: Text("应用", style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _merchantSuggestion = null),
            child: Icon(Icons.close, size: 14, color: Colors.green.shade400),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // ── Voice Recognition Methods ──
  // ══════════════════════════════════════════════════

  void _showHoldToTalkHint() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("按住麦克风说话，松开结束")),
    );
  }

  Future<void> _handleInitialSpeechText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !mounted) return;
    final intent = await _showSpeechPreview(trimmed);
    if (!mounted || intent == null) return;
    await _applySpeechIntent(intent);
  }

  Future<void> _startSpeechHold() async {
    if (_speechHoldActive || _speechHoldPending) return;
    _speechHoldPending = true;
    _speechHoldStopQueued = false;
    _speechHoldCancelQueued = false;
    final settings = await SpeechSettingsStore.load();
    if (!settings.enabled) {
      JiveLogger.i("Speech hold skipped: disabled");
      _speechHoldPending = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("语音记账已关闭")),
      );
      return;
    }
    final quota = await VoiceQuotaStore.load();
    final preferOnline = settings.onlineEnhance && !quota.isOnlineExceeded;
    if (settings.onlineEnhance && quota.isOnlineExceeded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("今日线上语音配额已用完，已切换为本地识别")),
      );
    }

    final speechService = SpeechServiceFactory.create();
    final engineCandidates = preferOnline
        ? <SpeechEngine>[SpeechEngine.system, SpeechEngine.iflytek]
        : <SpeechEngine>[SpeechEngine.system];

    SpeechEngine? selectedEngine;
    SpeechRecognitionResult? startResult;
    for (var i = 0; i < engineCandidates.length; i++) {
      final engine = engineCandidates[i];
      final preferOffline = engine == SpeechEngine.system;
      JiveLogger.i(
        "Speech hold start (engine=${engine.value}, locale=${settings.locale}, onlineEnhance=${settings.onlineEnhance})",
      );
      startResult = await speechService.startListening(
        locale: settings.locale,
        preferOffline: preferOffline,
        engine: engine,
      );
      if (startResult.errorCode == null) {
        selectedEngine = engine;
        break;
      }
      JiveLogger.w(
        "Speech hold start failed (engine=${engine.value}, error=${startResult.errorCode})",
      );
      if (!_shouldFallbackFromSpeechError(startResult.errorCode)) {
        break;
      }
    }

    if (selectedEngine == null) {
      _speechHoldPending = false;
      _showSpeechError(startResult?.errorCode);
      return;
    }

    final usedFallback = selectedEngine != engineCandidates.first;

    if (!mounted) return;
    _speechHoldPending = false;
    setState(() {
      _speechHoldActive = true;
      _speechHoldUsedFallback = usedFallback;
      _speechHoldService = speechService;
      _speechHoldEngine = selectedEngine;
    });

    if (_speechHoldCancelQueued) {
      _speechHoldCancelQueued = false;
      await _cancelSpeechHold();
      return;
    }
    if (_speechHoldStopQueued) {
      _speechHoldStopQueued = false;
      await _stopSpeechHold();
    }
  }

  Future<void> _stopSpeechHold() async {
    if (_speechHoldPending && !_speechHoldActive) {
      _speechHoldStopQueued = true;
      return;
    }
    if (!_speechHoldActive) return;
    final speechService = _speechHoldService;
    final usedFallback = _speechHoldUsedFallback;
    final engine = _speechHoldEngine;
    setState(() {
      _speechHoldActive = false;
      _speechHoldUsedFallback = false;
      _speechHoldService = null;
      _speechHoldEngine = null;
    });

    if (speechService == null) return;

    SpeechRecognitionResult finalResult;
    try {
      finalResult = await speechService.stopListening().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      await speechService.cancel();
      finalResult = const SpeechRecognitionResult(errorCode: 'TIMEOUT');
    } catch (_) {
      finalResult = const SpeechRecognitionResult(errorCode: 'UNKNOWN');
    }

    await _handleSpeechResult(finalResult, usedFallback: usedFallback, engine: engine);
  }

  Future<void> _cancelSpeechHold() async {
    if (_speechHoldPending && !_speechHoldActive) {
      _speechHoldCancelQueued = true;
      return;
    }
    if (!_speechHoldActive) return;
    final speechService = _speechHoldService;
    setState(() {
      _speechHoldActive = false;
      _speechHoldUsedFallback = false;
      _speechHoldService = null;
      _speechHoldEngine = null;
    });
    if (speechService != null) {
      await speechService.cancel();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已取消语音识别")),
      );
    }
  }

  Future<void> _handleSpeechResult(
    SpeechRecognitionResult finalResult, {
    bool usedFallback = false,
    SpeechEngine? engine,
  }) async {
    if (!mounted) return;
    final recognized = finalResult.text;
    final errorCode = finalResult.errorCode;

    if (recognized != null) {
      JiveLogger.i(
        "Speech hold result success (length=${recognized.length}, fallback=$usedFallback)",
      );
      final onlineUsed = engine != null && engine != SpeechEngine.system;
      final quota = await VoiceQuotaStore.increment(online: onlineUsed);
      if (onlineUsed) {
        _showQuotaWarning(quota);
      }
    } else {
      JiveLogger.w(
        "Speech hold result failure (error=${errorCode ?? 'NONE'}, fallback=$usedFallback)",
      );
    }

    if (errorCode == 'CANCELLED') return;

    if (errorCode != null && recognized == null) {
      final message = _speechErrorMessage(errorCode);
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } else if (recognized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("未识别到语音，可手动输入")),
      );
    }

    if (_speechUiActive) {
      JiveLogger.w("Speech UI busy, skipping result");
      return;
    }
    _speechUiActive = true;
    try {
      final text = recognized ?? await _promptSpeechText();
      if (!mounted) return;
      final trimmed = text?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      final intent = await _showSpeechPreview(trimmed);
      if (intent == null) return;
      await _applySpeechIntent(intent);
    } finally {
      _speechUiActive = false;
    }
  }

  void _showQuotaWarning(VoiceQuota quota) {
    if (!mounted) return;
    if (quota.warningLevel == VoiceQuotaWarningLevel.high) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("线上语音配额即将用完，建议使用本地识别")),
      );
    } else if (quota.warningLevel == VoiceQuotaWarningLevel.exceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("今日线上语音配额已用完，已建议改用本地识别")),
      );
    }
  }

  Future<String?> _promptSpeechText({String? initialText}) async {
    if (!mounted) return null;
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return null;
    var currentText = initialText ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var closing = false;
        Future<void> closeDialog([String? value]) async {
          if (closing) return;
          closing = true;
          FocusScope.of(dialogContext).unfocus();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (!Navigator.of(dialogContext).canPop()) return;
          Navigator.pop(dialogContext, value);
        }

        return AlertDialog(
          scrollable: true,
          title: const Text("语音输入"),
          content: TextFormField(
            initialValue: currentText,
            autofocus: true,
            onChanged: (value) => currentText = value,
            decoration: const InputDecoration(hintText: "例如：今天午餐花了 23 元 微信"),
          ),
          actions: [
            TextButton(
              onPressed: () => closeDialog(),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () => closeDialog(currentText),
              child: const Text("继续"),
            ),
          ],
        );
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return result;
  }

  Future<SpeechIntent?> _showSpeechPreview(String text) async {
    if (!mounted) return null;
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return null;
    var currentText = text;
    final accountNames = _accounts.map((account) => account.name).toList();
    SpeechIntent? intent = _speechParser.parse(
      currentText,
      now: DateTime.now(),
      accountNames: accountNames,
    );
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final result = await showModalBottomSheet<SpeechIntent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            var closing = false;
            Future<void> closeSheet([SpeechIntent? value]) async {
              if (closing) return;
              closing = true;
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 50));
              Navigator.pop(context, value);
            }

            void updateIntent(String value) {
              if (closing) return;
              currentText = value;
              setSheetState(() {
                intent = _speechParser.parse(
                  value,
                  now: DateTime.now(),
                  accountNames: accountNames,
                );
              });
            }

            final preview = intent;
            final isValid = preview?.isValid ?? false;
            final typeLabel = _speechTypeLabel(preview?.type);
            final amountLabel = preview?.amount == null
                ? "未识别"
                : _speechFormatAmount(preview!.amount!);
            final timeLabel = preview == null
                ? formatter.format(DateTime.now())
                : formatter.format(preview.timestamp);
            final accountLabel = preview?.accountHint ?? "默认账户";
            final toAccountLabel = preview?.toAccountHint ?? "自动选择";
            return AnimatedPadding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "语音预览",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: currentText,
                      minLines: 1,
                      maxLines: 3,
                      onChanged: updateIntent,
                      decoration: const InputDecoration(
                        labelText: "识别文本",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (!isValid) ...[
                      const SizedBox(height: 8),
                      Text(
                        "未识别到金额，请修改文本",
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildSpeechPreviewRow("金额", amountLabel),
                    _buildSpeechPreviewRow("类型", typeLabel),
                    if (preview?.type == 'transfer')
                      _buildSpeechPreviewRow("账户", "$accountLabel → $toAccountLabel")
                    else
                      _buildSpeechPreviewRow("账户", accountLabel),
                    _buildSpeechPreviewRow("时间", timeLabel),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => closeSheet(),
                          child: const Text("取消"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isValid ? () => closeSheet(preview) : null,
                          child: const Text("填充表单"),
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
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return result;
  }

  Widget _buildSpeechPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applySpeechIntent(SpeechIntent intent) async {
    final nextType = _speechTypeFromIntent(intent.type);
    if (nextType != null && nextType != _txType) {
      await _switchType(nextType);
    }

    if (_isSearchMode) {
      _exitSearchMode();
    }

    if (!mounted) return;
    setState(() {
      if (intent.amount != null) {
        _amountStr = _speechFormatAmount(intent.amount!);
      }
    });

    _speechApplyAccountHints(intent);
    await _speechApplyCategorySuggestion(intent);
  }

  void _speechApplyAccountHints(SpeechIntent intent) {
    if (_accounts.isEmpty) return;
    final from = _speechResolveAccountByHint(intent.accountHint);
    final to = _txType == TransactionType.transfer
        ? _speechResolveAccountByHint(intent.toAccountHint, excludeId: from?.id)
        : null;

    setState(() {
      if (from != null) {
        _selectedAccount = from;
      }
      if (_txType == TransactionType.transfer) {
        if (to != null && to.id != _selectedAccount?.id) {
          _selectedToAccount = to;
        }
        if (_selectedAccount != null && _selectedToAccount?.id == _selectedAccount?.id) {
          _selectedToAccount = _speechPickAlternateAccount(_selectedAccount);
        }
      }
    });
  }

  Future<void> _speechApplyCategorySuggestion(SpeechIntent intent) async {
    if (_txType == TransactionType.transfer) return;
    final text = intent.cleanedText ?? intent.rawText;
    final match = (await AutoRuleEngine.instance()).match(text: text, source: 'Voice');
    if (match.parent == null) return;
    final parent = _parentCategories.firstWhere(
      (cat) => cat.name == match.parent,
      orElse: () => _parentCategories.first,
    );
    if (parent.name != match.parent) return;
    if (!mounted) return;
    setState(() {
      _selectedParent = parent;
    });
    await _loadSubCategories(parent.key);
    if (match.sub == null || !mounted) return;
    final sub = _subCategories.firstWhere(
      (cat) => cat.name == match.sub,
      orElse: () => _subCategories.first,
    );
    if (sub.name != match.sub) return;
    setState(() {
      _selectedSub = sub;
    });
  }

  TransactionType? _speechTypeFromIntent(String? type) {
    switch (type) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
        return TransactionType.expense;
    }
    return null;
  }

  String _speechTypeLabel(String? type) {
    switch (type) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      case 'expense':
        return '支出';
      default:
        return '自动识别';
    }
  }

  String _speechFormatAmount(double amount) {
    final fixed = amount.toStringAsFixed(2);
    return fixed.replaceAll(RegExp(r'\.?0+$'), '');
  }

  JiveAccount? _speechResolveAccountByHint(String? hint, {int? excludeId}) {
    if (hint == null || hint.trim().isEmpty) return null;
    final normalizedHint = hint.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    JiveAccount? best;
    var bestLen = 0;
    for (final account in _accounts) {
      if (excludeId != null && account.id == excludeId) continue;
      for (final alias in _speechAccountAliases(account)) {
        final normalizedAlias = alias.toLowerCase().replaceAll(RegExp(r'\s+'), '');
        if (normalizedAlias.isEmpty) continue;
        if (normalizedHint.contains(normalizedAlias) || normalizedAlias.contains(normalizedHint)) {
          if (normalizedAlias.length > bestLen) {
            best = account;
            bestLen = normalizedAlias.length;
          }
        }
      }
    }
    return best;
  }

  List<String> _speechAccountAliases(JiveAccount account) {
    final aliases = <String>{account.name};
    final trimmed = account.name.replaceAll(RegExp(r'(钱包|账户|帐户)$'), '');
    if (trimmed.length >= 2 && trimmed != account.name) {
      aliases.add(trimmed);
    }
    if (account.name.contains('微信')) aliases.add('微信');
    if (account.name.contains('支付宝')) aliases.add('支付宝');
    if (account.name.contains('现金')) aliases.add('现金');
    if (account.name.contains('银行卡') || account.name.contains('银行')) {
      aliases.add('银行卡');
    }
    if (account.name.contains('信用卡')) aliases.add('信用卡');
    return aliases.toList();
  }

  JiveAccount? _speechPickAlternateAccount(JiveAccount? selected) {
    if (selected == null) return null;
    return _accounts.firstWhere(
      (account) => account.id != selected.id,
      orElse: () => selected,
    );
  }

  bool _shouldFallbackFromSpeechError(String? code) {
    switch (code) {
      case 'NO_PERMISSION':
      case 'BUSY':
      case 'CANCELLED':
      case 'NO_SESSION':
        return false;
    }
    return true;
  }

  void _showSpeechError(String? code) {
    if (!mounted) return;
    final message = _speechErrorMessage(code);
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _speechErrorMessage(String? code) {
    if (code != null && code.startsWith('IFLYTEK_ERROR')) {
      return "讯飞识别失败，可手动输入";
    }
    if (code != null && code.startsWith('BAIDU_ERROR')) {
      return "百度语音识别失败，可手动输入";
    }
    switch (code) {
      case 'BUSY':
        return "语音识别正忙，请稍后重试";
      case 'NO_PERMISSION':
        return "未获得麦克风或语音识别权限";
      case 'NO_NETWORK':
        return "网络不可用，已切换为手动输入";
      case 'NO_ENGINE':
        return "设备不支持语音识别";
      case 'NO_CREDENTIALS':
        return "未配置语音识别密钥";
      case 'NO_BAIDU_SDK':
        return "百度语音 SDK 未配置";
      case 'NO_SESSION':
        return "语音识别未开始";
      case 'CANCELLED':
        return "语音识别已取消";
      case 'TIMEOUT':
        return "语音识别超时，已切换为手动输入";
      case 'NO_MATCH':
        return "未识别到语音，可手动输入";
      case 'AUDIO':
        return "麦克风异常，可手动输入";
      case 'CLIENT':
        return "语音识别失败，可手动输入";
      case 'SERVER':
        return "语音识别服务异常，可手动输入";
      case 'UNAVAILABLE':
        return "语音识别不可用";
      case 'UNKNOWN':
        return "语音识别失败，可手动输入";
    }
    return null;
  }

  // ══════════════════════════════════════════════════
  // ── End Voice Recognition Methods ──
  // ══════════════════════════════════════════════════

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
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
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black87 : Colors.black38,
            ),
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
      // 检测是否为跨币种转账
      final fromCurrency = _selectedAccount?.currency ?? 'CNY';
      final toCurrency = _selectedToAccount?.currency ?? 'CNY';
      final isCrossCurrency =
          _selectedAccount != null &&
          _selectedToAccount != null &&
          fromCurrency != toCurrency;

      return Column(
        children: [
          Row(
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
          ),
          if (isCrossCurrency) ...[
            const SizedBox(height: 8),
            // 跨币种转账信息卡片
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
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
                      if (_crossCurrencyRate != null) ...[
                        _buildRateSourceBadge(
                          _crossCurrencyRateSource ?? 'default',
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '1 $fromCurrency = ${_crossCurrencyRate!.toStringAsFixed(4)} $toCurrency',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 转入金额输入
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
                                  controller: _toAmountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
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
                                  onChanged: (value) {
                                    setState(() {
                                      _toAmountStr = value;
                                      _isEditingToAmount = true;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 重新计算按钮
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isEditingToAmount = false;
                            _calculateToAmount();
                          });
                        },
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
            ),
          ],
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

  Widget _buildTagSelector({required bool isLandscape}) {
    final textSize = isLandscape ? 10.0 : 12.0;
    final selectedTags = _tags
        .where((tag) => _selectedTagKeys.contains(tag.key))
        .toList();
    return Align(
      alignment: Alignment.center,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          for (final tag in selectedTags) _buildSelectedTagChip(tag, textSize),
          ActionChip(
            label: Text(
              selectedTags.isEmpty ? '添加标签' : '编辑标签',
              style: TextStyle(fontSize: textSize),
            ),
            avatar: const Icon(
              Icons.label_outline,
              size: 14,
              color: Colors.black54,
            ),
            onPressed: _showTagPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTagChip(JiveTag tag, double textSize) {
    final color = AccountService.parseColorHex(tag.colorHex) ?? Colors.blueGrey;
    return InputChip(
      label: Text(
        tagDisplayName(tag),
        style: TextStyle(
          fontSize: textSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      onDeleted: () => setState(() => _selectedTagKeys.remove(tag.key)),
    );
  }

  Widget _buildBudgetFlags({required bool isLandscape}) {
    if (_txType != TransactionType.expense) return const SizedBox.shrink();
    final textSize = isLandscape ? 10.0 : 12.0;
    final color = _excludeFromBudget
        ? Colors.orange.shade700
        : Colors.grey.shade700;
    return Align(
      alignment: Alignment.center,
      child: FilterChip(
        label: Text(
          '不计入预算',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        avatar: Icon(Icons.pie_chart_outline, size: 14, color: color),
        selected: _excludeFromBudget,
        onSelected: (value) => setState(() => _excludeFromBudget = value),
        showCheckmark: true,
        selectedColor: Colors.orange.withValues(alpha: 0.12),
        checkmarkColor: Colors.orange.shade700,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  Future<void> _showTagPicker() async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return TagPickerSheet(
          tags: _tags,
          selectedKeys: _selectedTagKeys,
          onCreateTag: (name) async {
            final created = await TagService(_isar).createTag(name: name);
            await _loadTags();
            return created;
          },
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _selectedTagKeys = picked;
    });
  }

  Widget _buildProjectSelector({required bool isLandscape}) {
    final textSize = isLandscape ? 10.0 : 12.0;
    final selectedProject = _selectedProjectId != null
        ? _projects.where((p) => p.id == _selectedProjectId).firstOrNull
        : null;

    if (selectedProject != null) {
      final color = selectedProject.colorHex != null
          ? Color(
              int.parse(selectedProject.colorHex!.replaceFirst('#', '0xFF')),
            )
          : JiveTheme.primaryGreen;
      return Align(
        alignment: Alignment.center,
        child: InputChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidgetForName(
                selectedProject.iconName,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                selectedProject.name,
                style: TextStyle(
                  fontSize: textSize,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: color.withValues(alpha: 0.12),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          onDeleted: () => setState(() => _selectedProjectId = null),
          onPressed: _showProjectPicker,
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: ActionChip(
        label: Text('关联项目', style: TextStyle(fontSize: textSize)),
        avatar: const Icon(
          Icons.folder_outlined,
          size: 14,
          color: Colors.black54,
        ),
        onPressed: _showProjectPicker,
      ),
    );
  }

  Future<void> _showProjectPicker() async {
    if (_projects.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无可用项目，请先创建项目')));
      return;
    }

    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '选择项目',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedProjectId != null)
                      TextButton(
                        onPressed: () => Navigator.pop(context, -1),
                        child: const Text('取消关联'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    final color = project.colorHex != null
                        ? Color(
                            int.parse(
                              project.colorHex!.replaceFirst('#', '0xFF'),
                            ),
                          )
                        : JiveTheme.primaryGreen;
                    final isSelected = project.id == _selectedProjectId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: iconWidgetForName(
                          project.iconName,
                          size: 18,
                          color: color,
                        ),
                      ),
                      title: Text(project.name),
                      subtitle: project.budget > 0
                          ? Text('预算 ¥${project.budget.toStringAsFixed(0)}')
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check, color: color)
                          : null,
                      onTap: () => Navigator.pop(context, project.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _selectedProjectId = selected == -1 ? null : selected;
    });
  }

  Widget _buildRateSourceBadge(String source) {
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
        color = Colors.grey;
        label = '默认';
        break;
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

  Widget _buildAccountChip({
    required String label,
    required JiveAccount? account,
    required double textSize,
    required bool expand,
    required VoidCallback onTap,
  }) {
    final color =
        AccountService.parseColorHex(account?.colorHex) ??
        JiveTheme.primaryGreen;
    final name = account?.name ?? "请选择";
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

  Widget _buildSelectedCreditSummary(
    JiveAccount account, {
    required bool isLandscape,
  }) {
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

  Widget _buildCreditMetaText(
    String label,
    double value,
    Color color,
    double fontSize,
  ) {
    return Text(
      "$label ¥${_formatMoney(value)}",
      style: GoogleFonts.lato(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
      ),
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
              final color =
                  AccountService.parseColorHex(account.colorHex) ??
                  JiveTheme.primaryGreen;
              final currentId = pickTo
                  ? _selectedToAccount?.id
                  : _selectedAccount?.id;
              final isSelected = account.id == currentId;
              final subtitle = _accountSubtitle(account);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: AccountService.buildIcon(
                    account.iconName,
                    size: 18,
                    color: color,
                  ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("转出与转入账户不能相同")));
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

    // 跨币种转账时加载汇率
    if (_txType == TransactionType.transfer) {
      await _loadCrossCurrencyRate();
    }
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
    final remaining =
        grouped.keys.where((key) => !ordered.containsKey(key)).toList()..sort();
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
    return value == rounded
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryBody(
    double subGridAspectRatio,
    double subGridMainAxisSpacing,
  ) {
    final hasQuery = _isSearchMode && _searchQuery.trim().isNotEmpty;
    if (hasQuery &&
        _searchItemsLoaded &&
        _filterSearchResults(_searchQuery).isEmpty) {
      return _buildSystemSuggestionPanel();
    }
    return _buildSubCategoryGrid(subGridAspectRatio, subGridMainAxisSpacing);
  }

  Widget _buildSubCategoryGrid(
    double subGridAspectRatio,
    double subGridMainAxisSpacing,
  ) {
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
                const Text(
                  "自定义",
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final cat = _subCategories[index];
        final isSelected = cat.key == _selectedSub?.key;
        final customColor = CategoryService.parseColorHex(cat.colorHex);
        final activeColor = customColor ?? JiveTheme.primaryGreen;
        final inactiveColor = JiveTheme.categoryIconInactive;
        final isCategoryAssetIcon =
            (cat.iconName.endsWith(".png") || cat.iconName.endsWith(".svg")) &&
            (!cat.iconName.startsWith("assets/") ||
                cat.iconName.startsWith("assets/category_icons/"));
        final shouldTintIcon = isCategoryAssetIcon
            ? (cat.iconForceTinted ||
                  CategoryIconStyleConfig.current.shouldTintForCategory(
                    isSystemCategory: cat.isSystem,
                  ))
            : true;
        final coloredIcons = !shouldTintIcon;
        return GestureDetector(
          onTap: () => setState(() => _selectedSub = cat),
          onLongPress: () => _showSubCategoryActions(cat),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (coloredIcons
                            ? activeColor.withValues(alpha: 0.14)
                            : activeColor)
                      : (coloredIcons
                            ? Colors.white
                            : JiveTheme.categoryIconInactiveBackground),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : JiveTheme.categoryIconInactiveBorder,
                  ),
                ),
                child: CategoryService.buildIcon(
                  cat.iconName,
                  size: 18,
                  color: coloredIcons
                      ? (isSelected ? null : inactiveColor)
                      : (isSelected ? Colors.white : inactiveColor),
                  isSystemCategory: cat.isSystem,
                  forceTinted: cat.iconForceTinted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? Colors.black87
                      : JiveTheme.categoryLabelInactive,
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
                Text(
                  "系统库建议",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  "点击添加并选中",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }
        final suggestion = suggestions[index - 1];
        final title = suggestion.isSub
            ? suggestion.name
            : suggestion.parentName;
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
              isSystemCategory: true,
            ),
          ),
          title: Text(title, style: TextStyle(color: Colors.grey.shade700)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: JiveTheme.categoryLabelInactive,
            ),
          ),
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
      final parentIcon =
          (entry.value['icon'] as String?)?.trim().isNotEmpty == true
          ? entry.value['icon'] as String
          : "category";
      if (!existingParents.contains(parentName) &&
          _matchesSystemTokens(
            _tokensForSystem(parentName, "p::$parentName"),
            normalized,
          )) {
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
          suggestions.add(
            _SystemSuggestion.child(
              parentName,
              childName,
              childIcon,
              parentIcon,
            ),
          );
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
    JiveCategory? parent = await _isar
        .collection<JiveCategory>()
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
      sub ??= await _isar
          .collection<JiveCategory>()
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

  Future<void> _reloadParentsAndSelect({
    required String parentKey,
    String? subKey,
  }) async {
    final showIncome = _txType == TransactionType.income;
    var parents = await _isar
        .collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(showIncome)
        .isHiddenEqualTo(false)
        .sortByOrder()
        .findAll();

    if (parents.isEmpty && !showIncome) {
      final service = CategoryService(_isar);
      final lib = service.getSystemLibrary(isIncome: showIncome);
      parents = lib.keys
          .map(
            (name) => JiveCategory()
              ..key = service.buildSystemParentKey(name, isIncome: showIncome)
              ..name = name
              ..iconName = lib[name]!['icon']
              ..order = 0,
          )
          .toList();
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
    return _searchTokenCache[category.key] ??= _buildTokensForName(
      category.name,
    );
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
    final exactMatches = results
        .where((item) => _isExactMatch(item, normalized))
        .toList();
    if (exactMatches.isNotEmpty) {
      await _selectSearchResult(exactMatches.first);
      return;
    }
    final prefixMatches = results
        .where((item) => _isPrefixMatch(item, normalized))
        .toList();
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
      setState(() {
        // trigger rebuild after note tag usage updated
      });
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMerchantSuggestionBanner(),
        NoteFieldWithChips(
          controller: _noteController,
          isLandscape: isLandscape,
          suggestions: _noteSuggestionsForType(currentType),
          onTagSelected: (tag) => _trackNoteTagUsage(currentType, tag),
        ),
      ],
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
            boxShadow: [
              BoxShadow(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.check, color: Colors.white, size: 28),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _onKeyPress(key),
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: isDel
            ? const Icon(
                Icons.backspace_rounded,
                size: 22,
                color: Colors.black54,
              )
            : ['+', '-', 'date'].contains(key)
            ? _buildOpIcon(key)
            : Text(
                key,
                style: GoogleFonts.rubik(
                  fontSize: 26,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }

  Widget _buildOpIcon(String key) {
    if (key == 'date') {
      return const Icon(
        Icons.calendar_today_rounded,
        size: 20,
        color: Colors.black45,
      );
    }
    return Text(
      key,
      style: const TextStyle(fontSize: 24, color: Colors.black45),
    );
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

  factory _SystemSuggestion.child(
    String parentName,
    String name,
    String iconName,
    String parentIconName,
  ) {
    return _SystemSuggestion._(
      parentName: parentName,
      name: name,
      parentIconName: parentIconName,
      iconName: iconName,
      isSub: true,
    );
  }
}
