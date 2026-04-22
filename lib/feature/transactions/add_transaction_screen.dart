import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/account_model.dart';
import '../../core/database/book_model.dart';
import '../../core/database/budget_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/project_model.dart';
import '../../core/service/book_service.dart';
import '../../core/service/project_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/account_service.dart';
import '../../core/service/budget_pref_service.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/repository/transaction_repository.dart';
import '../../core/repository/isar_transaction_repository.dart';
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
import '../../core/widgets/currency_picker.dart';
import '../accounts/accounts_screen.dart';
import '../stats/stats_screen.dart';
import '../tag/tag_icon_catalog.dart';
import '../tag/tag_picker_sheet.dart';
import 'transaction_amount_expression.dart';
import 'widgets/account_selector_section.dart';
import 'widgets/compact_amount_bar.dart';
import 'widgets/quick_field_pills_bar.dart';
import 'widgets/transaction_datetime_sheet.dart';
import 'widgets/transaction_split_sheet.dart';
import 'widgets/transaction_calculator_key.dart';
import 'widgets/transaction_field_chips.dart';
import 'widgets/transaction_misc_widgets.dart';
import 'widgets/transaction_panels.dart';
import 'widgets/transaction_type_selector.dart';

enum TransactionType { expense, income, transfer }

typedef AddTransactionSaver = Future<void> Function(JiveTransaction tx);
typedef AddTransactionSmartTagResolver =
    Future<List<String>> Function(JiveTransaction tx);

class AddTransactionScreenKeys {
  static const amountFormula = ValueKey('add-transaction-amount-formula');
  static const amountResult = ValueKey('add-transaction-amount-result');
  static const noteCollapsed = ValueKey('add-transaction-note-collapsed');
  static const noteTextField = ValueKey('add-transaction-note-text-field');
  static const saveButton = ValueKey('add-transaction-save-button');

  static ValueKey<String> amountKey(String key) =>
      ValueKey('add-transaction-amount-key-$key');

  static ValueKey<String> parentCategory(String key) =>
      ValueKey('add-transaction-parent-category-$key');

  static ValueKey<String> subCategory(String key) =>
      ValueKey('add-transaction-sub-category-$key');
}

class AddTransactionScreen extends StatefulWidget {
  final JiveTransaction? editingTransaction;
  final JiveTransaction? prefillTransaction;
  final TransactionType? initialType;
  final bool startWithSpeech;
  final String? initialSpeechText;
  final int? bookId;
  @visibleForTesting
  final Isar? isar;
  @visibleForTesting
  final bool bootstrapDefaults;
  @visibleForTesting
  final List<JiveCategory>? initialParentCategories;
  @visibleForTesting
  final List<JiveCategory>? initialSubCategories;
  @visibleForTesting
  final List<JiveAccount>? initialAccounts;
  @visibleForTesting
  final Map<int, double>? initialAccountBalances;
  @visibleForTesting
  final List<JiveTag>? initialTags;
  @visibleForTesting
  final List<JiveProject>? initialProjects;
  @visibleForTesting
  final AddTransactionSaver? transactionSaver;
  @visibleForTesting
  final AddTransactionSmartTagResolver? smartTagResolver;

  const AddTransactionScreen({
    super.key,
    this.editingTransaction,
    this.prefillTransaction,
    this.initialType,
    this.startWithSpeech = false,
    this.initialSpeechText,
    this.bookId,
    this.isar,
    this.bootstrapDefaults = true,
    this.initialParentCategories,
    this.initialSubCategories,
    this.initialAccounts,
    this.initialAccountBalances,
    this.initialTags,
    this.initialProjects,
    this.transactionSaver,
    this.smartTagResolver,
  }) : assert(
         (initialParentCategories == null &&
                 initialSubCategories == null &&
                 initialAccounts == null &&
                 initialAccountBalances == null &&
                 initialTags == null &&
                 initialProjects == null) ||
             isar != null,
         'Initial transaction entry data requires an injected Isar.',
       );

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const String _noteTagUsageKeyPrefix = 'note_tag_usage_v1_';
  static const int _kMaxAmountExpressionLength = 28;

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

  bool _continuousMode = false;
  bool _plusShowsMultiply = false; // false=+, true=×
  bool _minusShowsDivide = false; // false=-, true=÷
  String _amountStr = "0";
  String _toAmountStr = ""; // 跨币种转账的转入金额
  double? _crossCurrencyRate; // 跨币种转账时使用的汇率
  String? _crossCurrencyRateSource; // 汇率来源
  bool _isEditingToAmount = false; // 是否正在编辑转入金额
  late Isar _isar;
  late TransactionRepository _transactionRepo;
  final TextEditingController _toAmountController = TextEditingController();
  bool _isLoading = true;
  bool _hasDataChanges = false;
  bool _isFallbackMode = false;
  bool _isSearchMode = false;
  bool _isEditing = false;
  bool _excludeFromBudget = false; // 不计入预算（仅对支出有效）
  bool _excludeFromTotals = false; // 不计入收支（账单标记）

  // 优惠与手续费（单账户模式）——组合模式下各 split 自带字段
  double? _discountAmount;
  double? _feeAmount;

  // 组合模式（multi-account split）
  List<TxSplitEntry> _splits = [];
  String? _editingSplitGroupKey; // 编辑既有组合交易时的 groupKey

  bool get _isSplitMode => _splits.length > 1;

  // 附件图片路径（存 JiveTransaction.attachmentPaths）
  List<String> _attachmentPaths = [];
  final ImagePicker _imagePicker = ImagePicker();
  TransactionType _txType = TransactionType.expense;
  DateTime _selectedTime = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  bool _isNoteExpanded = false;
  final Map<TransactionType, Map<String, int>> _noteTagUsage = {};
  StreamSubscription<void>? _categoryWatcher;
  bool _isRefreshingCategories = false;
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
  List<JiveBook> _books = [];
  JiveBook? _currentBook;
  List<CategorySearchResult> _searchItems = [];
  final Map<String, String> _searchKeyCache = {};
  final TextEditingController _inlineSearchController = TextEditingController();
  final FocusNode _inlineSearchFocus = FocusNode();
  String _searchQuery = "";
  final Map<String, List<String>> _searchTokenCache = {};
  final Map<String, List<String>> _systemTokenCache = {};
  bool _searchItemsLoaded = false;
  CurrencyService? _currencyService;
  String _baseCurrency = 'CNY';

  // Account usage frequency tracking (T4)
  Map<int, int> _accountUsageCount = {};
  String? _reimbursementStatus; // T5: null or 'pending'

  final List<String> _keys = [
    '7',
    '8',
    '9',
    'AGAIN',
    '4',
    '5',
    '6',
    '+', // 点击切换为 ×
    '1',
    '2',
    '3',
    '-', // 点击切换为 ÷
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
    } else if (widget.initialSpeechText != null &&
        widget.initialSpeechText!.trim().isNotEmpty) {
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
    _categoryWatcher?.cancel();
    _inlineSearchController.dispose();
    _inlineSearchFocus.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
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
      _excludeFromTotals = editing.excludeFromTotals;
      _discountAmount = editing.discountAmount;
      _feeAmount = editing.feeAmount;
      _editingSplitGroupKey = editing.splitGroupKey;
      _reimbursementStatus = editing.reimbursementStatus;
      _attachmentPaths = List<String>.from(editing.attachmentPaths);
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
      _excludeFromTotals = prefill.excludeFromTotals;
      _discountAmount = prefill.discountAmount;
      _feeAmount = prefill.feeAmount;
      _attachmentPaths = List<String>.from(prefill.attachmentPaths);
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
      _isar = widget.isar ?? await DatabaseService.getInstance();
      _transactionRepo = IsarTransactionRepository(_isar);

      _currencyService = CurrencyService(_isar);
      if (_hasInitialEntryData) {
        _applyInitialEntryData();
        return;
      }
      _baseCurrency = await _currencyService!.getBaseCurrency();
      if (widget.bootstrapDefaults) {
        await CategoryService(_isar).initDefaultCategories();
        await AccountService(_isar).initDefaultAccounts();
        await TagService(_isar).initDefaultGroups();
      }
      await _loadAccounts();
      await _loadAccountUsage();
      await _loadTags();
      await _loadProjects();
      await _loadBooks();
      await _loadParentsForType(
        selectParentKey: _editingParentKey,
        selectParentName: _editingParentName,
        selectSubKey: _editingSubKey,
        selectSubName: _editingSubName,
      );
      await _loadSplitSiblings();
      _startCategoryWatcher();
    } catch (e, s) {
      JiveLogger.e("Error loading categories", e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasInitialEntryData =>
      widget.initialParentCategories != null ||
      widget.initialSubCategories != null ||
      widget.initialAccounts != null ||
      widget.initialAccountBalances != null ||
      widget.initialTags != null ||
      widget.initialProjects != null;

  void _applyInitialEntryData() {
    final parents = widget.initialParentCategories ?? const <JiveCategory>[];
    final subs = widget.initialSubCategories ?? const <JiveCategory>[];
    final accounts = widget.initialAccounts ?? const <JiveAccount>[];
    final tags = widget.initialTags ?? const <JiveTag>[];
    final projects = widget.initialProjects ?? const <JiveProject>[];
    if (!mounted) return;
    setState(() {
      _parentCategories = parents;
      _selectedParent = parents.isEmpty ? null : parents.first;
      _subCategories = subs;
      _selectedSub = null;
      _accounts = accounts;
      _accountBalances =
          widget.initialAccountBalances ??
          {for (final account in accounts) account.id: account.openingBalance};
      _selectedAccount = accounts.isEmpty ? null : accounts.first;
      _selectedToAccount = accounts.length > 1 ? accounts[1] : null;
      _tags = tags;
      _projects = projects;
      _baseCurrency = accounts.isEmpty ? 'CNY' : accounts.first.currency;
      _isFallbackMode = false;
      _isLoading = false;
    });
  }

  void _startCategoryWatcher() {
    _categoryWatcher ??= _isar
        .collection<JiveCategory>()
        .watchLazy(fireImmediately: false)
        .listen((_) => _refreshCategories());
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

    parents.sort(_compareCategoryForDisplay);

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

  Future<void> _loadAccountUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('account_usage_count_v1');
    if (json != null) {
      final decoded = Map<String, dynamic>.from(
        const JsonCodec().decode(json) as Map,
      );
      _accountUsageCount = decoded.map(
        (k, v) => MapEntry(int.parse(k), v as int),
      );
    }
  }

  Future<void> _incrementAccountUsage(int accountId) async {
    _accountUsageCount[accountId] = (_accountUsageCount[accountId] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    final encoded = _accountUsageCount.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(
      'account_usage_count_v1',
      const JsonCodec().encode(encoded),
    );
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

  Future<void> _loadSplitSiblings() async {
    if (_editingSplitGroupKey == null) return;
    final rows = await _transactionRepo.getBySplitGroupKey(
      _editingSplitGroupKey!,
    );
    if (rows.length <= 1 || !mounted) return;
    final accountById = {for (final a in _accounts) a.id: a};
    final splits = <TxSplitEntry>[];
    for (final row in rows) {
      final account = row.accountId != null ? accountById[row.accountId] : null;
      if (account == null) continue;
      splits.add(
        TxSplitEntry(
          account: account,
          amount: row.amount,
          discount: row.discountAmount,
          fee: row.feeAmount,
        ),
      );
    }
    if (splits.length <= 1) return;
    setState(() {
      _splits = splits;
      _amountStr = _formatAmountInput(
        splits.fold<double>(0, (sum, s) => sum + s.netAmount),
      );
    });
  }

  Future<void> _loadBooks() async {
    final service = BookService(_isar);
    await service.initDefaultBook();
    final books = await service.getActiveBooks();
    final defaultBook = await service.getDefaultBook();
    if (!mounted) return;
    setState(() {
      _books = books;
      // If caller passed a specific bookId, honor it; otherwise fall back
      // to the user's default book.
      if (widget.bookId != null) {
        _currentBook = books.firstWhere(
          (b) => b.id == widget.bookId,
          orElse: () =>
              defaultBook ?? (books.isNotEmpty ? books.first : _fallbackBook()),
        );
      } else {
        _currentBook = defaultBook ?? (books.isNotEmpty ? books.first : null);
      }
    });
  }

  JiveBook _fallbackBook() {
    return JiveBook()
      ..key = BookService.defaultBookKey
      ..name = '默认账本'
      ..iconName = 'book'
      ..currency = 'CNY'
      ..isDefault = true;
  }

  Future<void> _showBookPicker() async {
    if (_books.isEmpty) return;
    final picked = await showModalBottomSheet<JiveBook>(
      context: context,
      backgroundColor: JiveTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '选择账本',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: JiveTheme.secondaryTextColor(ctx),
                ),
              ),
            ),
            ..._books.map((book) {
              final isSelected = book.id == _currentBook?.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: JiveTheme.primaryGreen.withValues(
                    alpha: 0.15,
                  ),
                  child: Icon(
                    Icons.book_outlined,
                    size: 20,
                    color: JiveTheme.primaryGreen,
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(book.name, overflow: TextOverflow.ellipsis),
                    ),
                    if (book.isShared) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '共享',
                          style: TextStyle(
                            fontSize: 10,
                            color: JiveTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: book.isDefault ? const Text('默认') : null,
                trailing: isSelected
                    ? Icon(Icons.check, color: JiveTheme.primaryGreen)
                    : null,
                onTap: () => Navigator.pop(ctx, book),
              );
            }),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _currentBook = picked);
    }
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

  int _compareCategoryForDisplay(JiveCategory a, JiveCategory b) {
    final sourceCompare = (a.isSystem ? 1 : 0).compareTo(b.isSystem ? 1 : 0);
    if (sourceCompare != 0) return sourceCompare;
    final orderCompare = a.order.compareTo(b.order);
    if (orderCompare != 0) return orderCompare;
    return a.name.compareTo(b.name);
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
        .isHiddenEqualTo(false)
        .sortByOrder()
        .findAll();

    subs.sort(_compareCategoryForDisplay);

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
    if (!mounted || _isRefreshingCategories) return;
    _isRefreshingCategories = true;
    final parentKey = _selectedParent?.key;
    final parentName = _selectedParent?.name;
    final subKey = _selectedSub?.key;
    final subName = _selectedSub?.name;
    try {
      setState(() {
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
      await _loadParentsForType(
        selectParentKey: parentKey,
        selectParentName: parentName,
        selectSubKey: subKey,
        selectSubName: subName,
      );
    } finally {
      _isRefreshingCategories = false;
      if (mounted) setState(() => _isLoading = false);
    }
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
    var parents = all
        .where(
          (c) => c.parentKey == null && !c.isHidden && c.isIncome == showIncome,
        )
        .toList();
    parents.sort(_compareCategoryForDisplay);
    final parentByKey = {for (final p in parents) p.key: p};
    final items = <CategorySearchResult>[];
    for (final parent in parents) {
      items.add(CategorySearchResult(parent: parent));
    }
    var children = all
        .where(
          (c) => c.parentKey != null && !c.isHidden && c.isIncome == showIncome,
        )
        .toList();
    // 过滤掉不属于已选父分类的子分类
    children =
        children.where((c) => parentByKey.containsKey(c.parentKey)).toList()
          ..sort(_compareCategoryForDisplay);
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
    if (key == 'AGAIN') {
      setState(() => _continuousMode = !_continuousMode);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_continuousMode ? '连续记账：开' : '连续记账：关'),
            duration: const Duration(seconds: 1),
          ),
        );
      return;
    }
    if (key == 'OK') {
      if (_hasExpression(_amountStr)) {
        final preview = _expressionPreview();
        if (preview == null || preview <= 0) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('算式无效，请调整后再保存'),
                duration: Duration(seconds: 1),
              ),
            );
          return;
        }
        setState(() {
          _amountStr = _formatAmountInput(preview);
          if (!_isEditingToAmount && _crossCurrencyRate != null) {
            _calculateToAmount();
          }
        });
      }
      unawaited(_saveTransaction());
      return;
    }
    setState(() {
      if (key == 'DEL') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = "0";
        }
      } else if (key == '+' || key == '-') {
        // 运算符键：根据切换状态决定实际插入的运算符
        final actualOp = key == '+'
            ? (_plusShowsMultiply ? '×' : '+')
            : (_minusShowsDivide ? '÷' : '-');
        if (_amountStr == "0" || _amountStr.isEmpty) return;
        final lastChar = _amountStr[_amountStr.length - 1];
        if ('+-×÷.'.contains(lastChar)) return;
        if (_amountStr.length < _kMaxAmountExpressionLength) {
          _amountStr += actualOp;
        }
      } else {
        if (_amountStr == "0" && key != '.') {
          _amountStr = key;
        } else if (key == '.') {
          // 只在当前数字段没有小数点时允许
          final lastSegment = _amountStr.split(RegExp('[+\\-×÷]')).last;
          if (!lastSegment.contains('.') &&
              _amountStr.length < _kMaxAmountExpressionLength) {
            _amountStr += key;
          }
        } else {
          if (_amountStr.length < _kMaxAmountExpressionLength) {
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

  void _toggleOperatorKey(String keyValue) {
    HapticFeedback.selectionClick();
    setState(() {
      if (keyValue == '+') {
        _plusShowsMultiply = !_plusShowsMultiply;
        final replacement = _plusShowsMultiply ? '×' : '+';
        if (_amountStr.endsWith('+') || _amountStr.endsWith('×')) {
          _amountStr =
              '${_amountStr.substring(0, _amountStr.length - 1)}$replacement';
        }
      } else if (keyValue == '-') {
        _minusShowsDivide = !_minusShowsDivide;
        final replacement = _minusShowsDivide ? '÷' : '-';
        if (_amountStr.endsWith('-') || _amountStr.endsWith('÷')) {
          _amountStr =
              '${_amountStr.substring(0, _amountStr.length - 1)}$replacement';
        }
      }

      if (!_isEditingToAmount && _crossCurrencyRate != null) {
        _calculateToAmount();
      }
    });
  }

  void _toggleNoteExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _isNoteExpanded = !_isNoteExpanded);
  }

  /// 是否包含运算表达式
  bool _hasExpression(String s) => TransactionAmountExpression.hasExpression(s);

  /// 获取表达式的预览结果（供显示用）
  double? _expressionPreview() =>
      TransactionAmountExpression.preview(_amountStr);

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
      ..excludeFromTotals = _excludeFromTotals
      ..discountAmount = _discountAmount
      ..feeAmount = _feeAmount
      ..attachmentPaths = List<String>.from(_attachmentPaths)
      ..smartTagKeys = List<String>.from(tx.smartTagKeys)
      ..reimbursementStatus = _reimbursementStatus
      ..timestamp = _selectedTime
      ..bookId = _currentBook?.id ?? widget.bookId ?? tx.bookId;

    if (!_isEditing) {
      final matched =
          await (widget.smartTagResolver ??
              TagRuleService(_isar).resolveMatchingTags)(tx);
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
    final transactionSaver = widget.transactionSaver;
    if (transactionSaver != null) {
      await transactionSaver(tx);
    } else {
      if (_isSplitMode) {
        // 组合模式：tx 变成模板，从 _splits 里实际生成 N 行。
        final groupKey =
            _editingSplitGroupKey ??
            'split_${DateTime.now().millisecondsSinceEpoch}_${tx.syncKey}';
        // 如果是编辑既有 split group，先删除整组
        if (_editingSplitGroupKey != null) {
          final old = await _transactionRepo.getBySplitGroupKey(
            _editingSplitGroupKey!,
          );
          if (old.isNotEmpty) {
            await _transactionRepo.deleteAll(old.map((r) => r.id).toList());
          }
        }
        final rows = <JiveTransaction>[];
        for (final split in _splits) {
          final row = JiveTransaction()
            ..amount = split.amount
            ..source = tx.source
            ..type = tx.type
            ..categoryKey = tx.categoryKey
            ..subCategoryKey = tx.subCategoryKey
            ..category = tx.category
            ..subCategory = tx.subCategory
            ..rawText = tx.rawText
            ..note = tx.note
            ..accountId = split.account.id
            ..projectId = tx.projectId
            ..tagKeys = List<String>.from(tx.tagKeys)
            ..smartTagKeys = List<String>.from(tx.smartTagKeys)
            ..excludeFromBudget = tx.excludeFromBudget
            ..excludeFromTotals = tx.excludeFromTotals
            ..discountAmount = split.discount
            ..feeAmount = split.fee
            ..timestamp = tx.timestamp
            ..bookId = tx.bookId
            ..splitGroupKey = groupKey;
          TransactionService.touchSyncMetadata(row);
          rows.add(row);
        }
        await _transactionRepo.insertAll(rows);
      } else {
        if (_isEditing) {
          await _transactionRepo.update(tx);
        } else {
          await _transactionRepo.insert(tx);
        }
      }
      if (tx.tagKeys.isNotEmpty) {
        await TagService(_isar).markTagsUsed(tx.tagKeys, tx.timestamp);
      }

      // Track account usage frequency
      if (_selectedAccount != null) {
        await _incrementAccountUsage(_selectedAccount!.id);
      }

      // 商户记忆自动学习
      await MerchantMemoryService(_isar).learnFromTransaction(tx);
    }

    JiveLogger.i("Manual Transaction Saved: $amount");
    _hasDataChanges = true;

    if (mounted) {
      HapticFeedback.mediumImpact();
      DataReloadBus.notify();
      if (_continuousMode) {
        final keepAccount = _selectedAccount;
        final keepDate = _selectedTime;
        setState(() {
          _amountStr = "0";
          _plusShowsMultiply = false;
          _minusShowsDivide = false;
          _noteController.clear();
          _isNoteExpanded = false;
          _selectedSub = null;
          _selectedTagKeys.clear();
          _selectedProjectId = null;
          _selectedAccount = keepAccount;
          _selectedTime = keepDate;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存，继续记账'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
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
                    ...shown.map((impact) => BudgetImpactRow(impact: impact)),
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

    final selectedTagsList = _tags
        .where((t) => _selectedTagKeys.contains(t.key))
        .toList();
    final selectedProjectObj = _selectedProjectId != null
        ? _projects.where((p) => p.id == _selectedProjectId).firstOrNull
        : null;
    final isCreditAccount =
        _selectedAccount != null &&
        AccountService.isCreditAccount(_selectedAccount!);
    final isCrossCurrency =
        _txType == TransactionType.transfer &&
        _selectedAccount != null &&
        _selectedToAccount != null &&
        _selectedAccount!.currency != _selectedToAccount!.currency;

    return PopScope(
      canPop: !_isSearchMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchMode) {
          _exitSearchMode();
          return;
        }
      },
      child: Scaffold(
        backgroundColor: JiveTheme.surfaceColor(context),
        appBar: AppBar(
          backgroundColor: JiveTheme.surfaceColor(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: JiveTheme.textColor(context)),
            onPressed: () => Navigator.pop(context, _hasDataChanges),
          ),
          actions: [
            if (_showCategories)
              IconButton(
                icon: Icon(
                  _isSearchMode ? Icons.close : Icons.search,
                  color: JiveTheme.textColor(context),
                ),
                onPressed: _toggleInlineSearch,
              ),
          ],
          centerTitle: true,
          title: TransactionTypeSelector(
            currentType: _txType,
            onChanged: _switchType,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // 1. 分类区（占大部分空间）
                Expanded(
                  child: Container(
                    color: JiveTheme.cardColor(context),
                    child: Column(
                      children: [
                        if (_showCategories && _isSearchMode) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: InlineCategorySearchField(
                              controller: _inlineSearchController,
                              focusNode: _inlineSearchFocus,
                              currentQuery: _searchQuery,
                              onChanged: _onSearchChanged,
                              onClear: () {
                                _inlineSearchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: JiveTheme.dividerColor(context),
                          ),
                        ] else if (_showCategories) ...[
                          // 父分类 Tab
                          SizedBox(
                            height: parentTabHeight,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: _parentCategories.length,
                              itemBuilder: (context, index) {
                                final cat = _parentCategories[index];
                                final isSelected =
                                    cat.key == _selectedParent?.key;
                                final customColor =
                                    CategoryService.parseColorHex(cat.colorHex);
                                final activeColor =
                                    customColor ?? JiveTheme.primaryGreen;
                                final inactiveColor =
                                    JiveTheme.secondaryTextColor(context);
                                final iconColor = isSelected
                                    ? activeColor
                                    : inactiveColor;
                                return GestureDetector(
                                  key: AddTransactionScreenKeys.parentCategory(
                                    cat.key,
                                  ),
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
                          Divider(
                            height: 1,
                            color: JiveTheme.dividerColor(context),
                          ),
                        ],
                        // 子分类网格
                        Expanded(
                          child: _showCategories
                              ? _buildCategoryBody(
                                  subGridAspectRatio,
                                  subGridMainAxisSpacing,
                                )
                              : const TransferModeHint(),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. 跨币种汇率卡 (转账模式且币种不同时)
                if (isCrossCurrency)
                  Container(
                    color: JiveTheme.cardColor(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: AccountSelectorSection(
                      txType: _txType,
                      selectedAccount: _selectedAccount,
                      selectedToAccount: _selectedToAccount,
                      isLandscape: true, // compact rendering
                      toAmountController: _toAmountController,
                      crossCurrencyRate: _crossCurrencyRate,
                      crossCurrencyRateSource: _crossCurrencyRateSource,
                      onPickAccount: (pickTo) =>
                          _showAccountPicker(pickTo: pickTo),
                      onToAmountChanged: (value) {
                        setState(() {
                          _toAmountStr = value;
                          _isEditingToAmount = true;
                        });
                      },
                      onRecalculateRate: () {
                        setState(() {
                          _isEditingToAmount = false;
                          _calculateToAmount();
                        });
                      },
                    ),
                  ),

                // 3. 信用卡额度信息（如果选了信用卡）
                if (isCreditAccount)
                  Container(
                    color: JiveTheme.cardColor(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: CreditAccountSummary(
                      account: _selectedAccount!,
                      balance:
                          _accountBalances[_selectedAccount!.id] ??
                          _selectedAccount!.openingBalance,
                      isLandscape: true,
                    ),
                  ),

                // 4. 商户建议横幅
                MerchantSuggestionBanner(
                  suggestion: _merchantSuggestion,
                  parentCategories: _parentCategories,
                  onApply: _applyMerchantSuggestion,
                  onDismiss: () => setState(() => _merchantSuggestion = null),
                ),

                // 5. 快捷字段药丸栏
                QuickFieldPillsBar(
                  selectedAccount: _selectedAccount,
                  selectedTags: selectedTagsList,
                  selectedProject: selectedProjectObj,
                  excludeFromBudget: _excludeFromBudget,
                  excludeFromTotals: _excludeFromTotals,
                  isExpense: _txType == TransactionType.expense,
                  isTransfer: _txType == TransactionType.transfer,
                  discountAmount: _discountAmount,
                  feeAmount: _feeAmount,
                  isSplitMode: _isSplitMode,
                  splitCount: _splits.length,
                  onTapAccount: () => _showAccountPicker(pickTo: false),
                  onTapTags: _showTagPicker,
                  onTapProject: _showProjectPicker,
                  onTapBillFlag: _showBillFlagDialog,
                  onTapDiscount: () => _showAdjustmentDialog(isFee: false),
                  onTapFee: () => _showAdjustmentDialog(isFee: true),
                  onTapSplit: _openSplitSheet,
                  onTapPhoto: _showPhotoPicker,
                  photoCount: _attachmentPaths.length,
                  onToggleExcludeBudget: (v) =>
                      setState(() => _excludeFromBudget = v),
                  bookName: _currentBook != null
                      ? (_currentBook!.isDefault && _currentBook!.name == '默认账本'
                            ? '账本'
                            : _currentBook!.name)
                      : null,
                  bookEmoji: _currentBook?.iconName == 'book' ? '📖' : null,
                  onTapBook: _currentBook != null ? _showBookPicker : null,
                  reimbursementStatus: _reimbursementStatus,
                  onTapReimbursement: _toggleReimbursementFlag,
                ),

                // 6. 紧凑金额条
                if (!hideAmountInSearch)
                  CompactAmountBar(
                    amountStr: _amountStr,
                    formulaKey: AddTransactionScreenKeys.amountFormula,
                    resultKey: AddTransactionScreenKeys.amountResult,
                    noteTextFieldKey: AddTransactionScreenKeys.noteTextField,
                    noteToggleKey: AddTransactionScreenKeys.noteCollapsed,
                    currency: _selectedAccount?.currency ?? _baseCurrency,
                    txType: _txType,
                    selectedTime: _selectedTime,
                    noteController: _noteController,
                    noteFocusNode: _noteFocusNode,
                    isNoteExpanded: _isNoteExpanded,
                    onToggleNoteExpanded: _toggleNoteExpanded,
                    onTapTime: _showTimePicker,
                    onTapCurrency: _showCurrencyPicker,
                    expressionResult: _expressionPreview(),
                    accountName: _selectedAccount?.name,
                    onTapAccount: () => _showAccountPicker(pickTo: false),
                  ),

                // 7. 数字键盘
                if (showCustomKeyboard)
                  Container(
                    color: JiveTheme.cardColor(context),
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
                        final keyValue = _keys[index];
                        return TransactionCalculatorKey(
                          key: keyValue == 'OK'
                              ? AddTransactionScreenKeys.saveButton
                              : AddTransactionScreenKeys.amountKey(keyValue),
                          keyValue: keyValue,
                          txType: _txType,
                          onKeyPress: _onKeyPress,
                          speechActive: _speechHoldActive || _speechHoldPending,
                          onOkLongPressStart: _startSpeechHold,
                          onOkLongPressEnd: _stopSpeechHold,
                          onOkLongPressCancel: _cancelSpeechHold,
                          plusLabel: _plusShowsMultiply ? '×' : '+',
                          minusLabel: _minusShowsDivide ? '÷' : '-',
                          onOperatorToggle: () => _toggleOperatorKey(keyValue),
                        );
                      },
                    ),
                  ),
              ],
            ),
            // Voice listening overlay
            if (_speechHoldActive)
              const Positioned(
                left: 20,
                right: 20,
                top: 12,
                child: VoiceListeningOverlay(),
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
      final suggestion = await MerchantMemoryService(
        _isar,
      ).getSuggestion(text.trim());
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

  // ══════════════════════════════════════════════════
  // ── Voice Recognition Methods ──
  // ══════════════════════════════════════════════════

  void _showHoldToTalkHint() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("按住麦克风说话，松开结束")));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("语音记账已关闭")));
      return;
    }
    final quota = await VoiceQuotaStore.load();
    final preferOnline = settings.onlineEnhance && !quota.isOnlineExceeded;
    if (settings.onlineEnhance && quota.isOnlineExceeded && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("今日线上语音配额已用完，已切换为本地识别")));
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
      finalResult = await speechService.stopListening().timeout(
        const Duration(seconds: 8),
      );
    } on TimeoutException {
      await speechService.cancel();
      finalResult = const SpeechRecognitionResult(errorCode: 'TIMEOUT');
    } catch (_) {
      finalResult = const SpeechRecognitionResult(errorCode: 'UNKNOWN');
    }

    await _handleSpeechResult(
      finalResult,
      usedFallback: usedFallback,
      engine: engine,
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("已取消语音识别")));
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

    if (!mounted) return;
    if (errorCode != null && recognized == null) {
      final message = _speechErrorMessage(errorCode);
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } else if (recognized == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("未识别到语音，可手动输入")));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("线上语音配额即将用完，建议使用本地识别")));
    } else if (quota.warningLevel == VoiceQuotaWarningLevel.exceeded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("今日线上语音配额已用完，已建议改用本地识别")));
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
          if (!dialogContext.mounted) return;
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
            TextButton(onPressed: () => closeDialog(), child: const Text("取消")),
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
              if (!context.mounted) return;
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                    SpeechPreviewRow(label: "金额", value: amountLabel),
                    SpeechPreviewRow(label: "类型", value: typeLabel),
                    if (preview?.type == 'transfer')
                      SpeechPreviewRow(
                        label: "账户",
                        value: "$accountLabel → $toAccountLabel",
                      )
                    else
                      SpeechPreviewRow(label: "账户", value: accountLabel),
                    SpeechPreviewRow(label: "时间", value: timeLabel),
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
        if (_selectedAccount != null &&
            _selectedToAccount?.id == _selectedAccount?.id) {
          _selectedToAccount = _speechPickAlternateAccount(_selectedAccount);
        }
      }
    });
  }

  Future<void> _speechApplyCategorySuggestion(SpeechIntent intent) async {
    if (_txType == TransactionType.transfer) return;
    final text = intent.cleanedText ?? intent.rawText;
    final match = (await AutoRuleEngine.instance()).match(
      text: text,
      source: 'Voice',
    );
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
        final normalizedAlias = alias.toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '',
        );
        if (normalizedAlias.isEmpty) continue;
        if (normalizedHint.contains(normalizedAlias) ||
            normalizedAlias.contains(normalizedHint)) {
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _showPhotoPicker() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JiveTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachmentPaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_attachmentPaths.length, (i) {
                    final path = _attachmentPaths[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx, 'remove:$i');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action.startsWith('remove:')) {
      final i = int.tryParse(action.substring(7));
      if (i != null && i >= 0 && i < _attachmentPaths.length) {
        setState(() => _attachmentPaths.removeAt(i));
      }
      return;
    }
    XFile? file;
    try {
      if (action == 'camera') {
        file = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
      } else if (action == 'gallery') {
        file = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
      }
    } catch (e) {
      JiveLogger.e('photo picker failed', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法获取图片')));
      }
      return;
    }
    if (file != null && mounted) {
      setState(() => _attachmentPaths.add(file!.path));
    }
  }

  Future<void> _openSplitSheet() async {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加账户')));
      return;
    }
    // Seed splits from current single-account state if empty.
    final seed = _splits.isNotEmpty
        ? _splits
        : (_selectedAccount != null && (double.tryParse(_amountStr) ?? 0) > 0
              ? [
                  TxSplitEntry(
                    account: _selectedAccount!,
                    amount: double.tryParse(_amountStr) ?? 0,
                    discount: _discountAmount,
                    fee: _feeAmount,
                  ),
                ]
              : <TxSplitEntry>[]);
    final result = await showTransactionSplitSheet(
      context,
      accounts: _accounts,
      initial: seed,
    );
    if (result == null || !mounted) return;
    setState(() {
      _splits = result;
      if (_splits.length == 1) {
        // Collapsing back to single mode — write split's values into the
        // screen-level state so the single-account save path picks them up.
        final only = _splits.first;
        _selectedAccount = only.account;
        _amountStr = _formatAmountInput(only.amount);
        _discountAmount = only.discount;
        _feeAmount = only.fee;
      } else if (_splits.length > 1) {
        // Multi-split: clear single-account discount/fee because each split
        // tracks its own. The displayed amount becomes the net total.
        _discountAmount = null;
        _feeAmount = null;
        _amountStr = _formatAmountInput(
          _splits.fold<double>(0, (sum, s) => sum + s.netAmount),
        );
      }
    });
  }

  Future<void> _showAdjustmentDialog({required bool isFee}) async {
    final title = isFee ? '手续费' : '优惠';
    final current = isFee ? _feeAmount : _discountAmount;
    final controller = TextEditingController(
      text: current != null && current > 0
          ? current.toStringAsFixed(current % 1 == 0 ? 0 : 2)
          : '',
    );
    final result = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JiveTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: JiveTheme.textColor(ctx),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isFee ? '银行/平台收取的额外费用，会叠加到实际支出。' : '店铺优惠/券金额，会从账单总额里扣减。',
              style: TextStyle(
                fontSize: 12,
                color: JiveTheme.secondaryTextColor(ctx),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: isFee ? '+ ' : '- ',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                final parsed = double.tryParse(v) ?? 0;
                Navigator.pop(ctx, parsed);
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 0.0),
                  child: const Text('清除'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(controller.text) ?? 0;
                    Navigator.pop(ctx, parsed);
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (isFee) {
        _feeAmount = result > 0 ? result : null;
      } else {
        _discountAmount = result > 0 ? result : null;
      }
    });
  }

  void _toggleReimbursementFlag() {
    setState(() {
      _reimbursementStatus = _reimbursementStatus == null ? 'pending' : null;
    });
  }

  Future<void> _showBillFlagDialog() async {
    bool notTotals = _excludeFromTotals;
    bool notBudget = _excludeFromBudget;
    final isTransfer = _txType == TransactionType.transfer;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('账单标记'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '可对账单进行标记，不计入收支、不计入预算。',
                  style: TextStyle(
                    fontSize: 12,
                    color: JiveTheme.secondaryTextColor(ctx),
                  ),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                title: const Text('不计入收支'),
                value: notTotals,
                onChanged: (v) => setDialogState(() => notTotals = v ?? false),
              ),
              // 转账交易本身不计入预算，所以隐藏这一行（对齐 钱迹）
              if (!isTransfer)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: const Text('不计入预算'),
                  value: notBudget,
                  onChanged: (v) =>
                      setDialogState(() => notBudget = v ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() {
        _excludeFromTotals = notTotals;
        _excludeFromBudget = isTransfer ? false : notBudget;
      });
    }
  }

  Future<void> _showTimePicker() async {
    final picked = await showTransactionDateTimeSheet(
      context,
      initial: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
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

  Future<void> _showCurrencyPicker() async {
    final currentCurrency = _selectedAccount?.currency ?? _baseCurrency;
    final selected = await CurrencyPicker.showPicker(
      context,
      selectedCode: currentCurrency,
      showCrypto: false,
      title: '选择货币',
    );
    if (selected == null || selected == currentCurrency || !mounted) return;

    // 查找该币种的账户
    final matchingAccounts = _accounts
        .where((a) => a.currency == selected)
        .toList();
    if (matchingAccounts.isNotEmpty) {
      setState(() {
        _selectedAccount = matchingAccounts.first;
      });
      if (_txType == TransactionType.transfer) {
        await _loadCrossCurrencyRate();
      }
    } else {
      if (!mounted) return;
      // Show exchange rate info for foreign currency
      final baseCurrency = _baseCurrency;
      double? rate;
      if (_currencyService != null) {
        final rateRecord = await _currencyService!.getRateRecord(
          baseCurrency,
          selected,
        );
        rate = rateRecord?.rate;
      }
      if (!mounted) return;
      final rateInfo = rate != null
          ? '\n当前汇率: 1 $baseCurrency ≈ ${rate.toStringAsFixed(4)} $selected'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('暂无 $selected 币种的账户，请先在账户管理中添加$rateInfo'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showAccountPicker({required bool pickTo}) async {
    if (_accounts.isEmpty) return;
    // Flat list sorted by usage frequency
    final sortedAccounts = List<JiveAccount>.from(_accounts)
      ..sort((a, b) {
        final countA = _accountUsageCount[a.id] ?? 0;
        final countB = _accountUsageCount[b.id] ?? 0;
        if (countA != countB) return countB.compareTo(countA);
        return a.order.compareTo(b.order);
      });
    final selected = await showModalBottomSheet<JiveAccount>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JiveTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AccountPickerSheet(
          accounts: sortedAccounts,
          currentId: pickTo ? _selectedToAccount?.id : _selectedAccount?.id,
          accountUsageCount: _accountUsageCount,
          onAddAccount: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('账户管理')),
                  body: const AccountsScreen(),
                ),
              ),
            ).then((_) => _loadAccounts());
          },
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

  Widget _buildCategoryBody(
    double subGridAspectRatio,
    double subGridMainAxisSpacing,
  ) {
    final hasQuery = _isSearchMode && _searchQuery.trim().isNotEmpty;
    if (hasQuery &&
        _searchItemsLoaded &&
        _filterSearchResults(_searchQuery).isEmpty) {
      return SystemSuggestionPanel(
        suggestions: _systemSuggestionsForQuery(_searchQuery),
        onApply: _applySystemSuggestion,
      );
    }
    return SubCategoryGrid(
      subCategories: _subCategories,
      selectedSub: _selectedSub,
      categoryKeyBuilder: (cat) =>
          AddTransactionScreenKeys.subCategory(cat.key),
      aspectRatio: subGridAspectRatio,
      mainAxisSpacing: subGridMainAxisSpacing,
      onSelect: (cat) => setState(() => _selectedSub = cat),
      onLongPress: _showSubCategoryActions,
      onAddCustom: () async {
        final parent = _selectedParent;
        if (parent != null) {
          await _promptAddSubCategory(parent);
        }
      },
    );
  }

  List<SystemSuggestion> _systemSuggestionsForQuery(String query) {
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

    final suggestions = <SystemSuggestion>[];
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
        suggestions.add(SystemSuggestion.parent(parentName, parentIcon));
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
            SystemSuggestion.child(
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

  Future<void> _applySystemSuggestion(SystemSuggestion suggestion) async {
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

    parents.sort(_compareCategoryForDisplay);

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
}

/// Redesigned account picker sheet: flat list, search, 2-column grid, + icon at top-right
class _AccountPickerSheet extends StatefulWidget {
  final List<JiveAccount> accounts;
  final int? currentId;
  final Map<int, int> accountUsageCount;
  final VoidCallback onAddAccount;

  const _AccountPickerSheet({
    required this.accounts,
    required this.currentId,
    required this.accountUsageCount,
    required this.onAddAccount,
  });

  @override
  State<_AccountPickerSheet> createState() => _AccountPickerSheetState();
}

class _AccountPickerSheetState extends State<_AccountPickerSheet> {
  String _query = '';
  final _searchController = TextEditingController();

  List<JiveAccount> get _filtered {
    if (_query.isEmpty) return widget.accounts;
    final lower = _query.toLowerCase();
    return widget.accounts
        .where((a) => a.name.toLowerCase().contains(lower))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _filtered;
    final isDark = JiveTheme.isDark(context);
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header: title + add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    '选择账户',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: JiveTheme.textColor(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.add, color: JiveTheme.primaryGreen),
                    onPressed: widget.onAddAccount,
                    tooltip: '添加账户',
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索账户',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            // 2-column grid
            Expanded(
              child: accounts.isEmpty
                  ? Center(
                      child: Text(
                        '未找到匹配的账户',
                        style: TextStyle(
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                    )
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final color =
                            AccountService.parseColorHex(account.colorHex) ??
                            JiveTheme.primaryGreen;
                        final isSelected = account.id == widget.currentId;
                        return InkWell(
                          onTap: () => Navigator.pop(context, account),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: isDark ? 0.25 : 0.1)
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.5)
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.grey.shade200),
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: color.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: AccountService.buildIcon(
                                    account.iconName,
                                    size: 14,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    account.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: JiveTheme.textColor(context),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check, size: 16, color: color),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
