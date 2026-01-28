import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/database/tag_rule_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/widgets/transaction_filter_sheet.dart';
import '../../core/service/category_service.dart';
import '../../core/service/ui_pref_service.dart';
import '../transactions/transaction_detail_screen.dart';

class CategoryTransactionsScreen extends StatefulWidget {
  final String title;
  final String? filterCategoryKey;
  final String? filterSubCategoryKey;
  final bool includeSubCategories;

  const CategoryTransactionsScreen({
    super.key,
    required this.title,
    this.filterCategoryKey,
    this.filterSubCategoryKey,
    this.includeSubCategories = true,
  });

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends State<CategoryTransactionsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  String? _error;
  List<JiveTransaction> _transactions = [];
  Map<String, JiveCategory> _categoryByKey = {};
  final DateFormat _dateFormat = DateFormat('MM-dd HH:mm');
  final NumberFormat _currency = NumberFormat.currency(symbol: '¥');
  Map<int, JiveAccount> _accountById = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  String? _searchCategoryKey;
  int? _searchAccountId;
  String? _searchTag;
  DateTimeRange? _searchDateRange;
  DateTime? _minTransactionDate;
  DateTime? _maxTransactionDate;
  Set<int> _transactionYears = {};
  Map<String, JiveTag> _tagByKey = {};
  _TransactionSortField _sortField = _TransactionSortField.date;
  _TransactionSortDirection _sortDirection = _TransactionSortDirection.desc;
  bool _groupByDate = false;
  bool _showDateHeadersWhenNotDate = false;
  bool _showSmartTagBadge = true;
  late bool _includeSubCategories;

  static const double _floatingBarHeight = 60;

  @override
  void initState() {
    super.initState();
    final hasCategoryFilter =
        (widget.filterCategoryKey?.trim().isNotEmpty ?? false) ||
        (widget.filterSubCategoryKey?.trim().isNotEmpty ?? false);
    _groupByDate = !hasCategoryFilter;
    _includeSubCategories = widget.includeSubCategories;
    _loadGroupingPreference();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final existing = Isar.getInstance();
      if (existing != null) {
        _isar = existing;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _isar = await Isar.open([
          JiveTransactionSchema,
          JiveCategorySchema,
          JiveCategoryOverrideSchema,
          JiveAccountSchema,
          JiveAutoDraftSchema,
          JiveTagSchema,
          JiveTagGroupSchema,
          JiveTagRuleSchema,
          JiveTagConversionLogSchema,
        ], directory: dir.path);
      }

      final showBadge = await UiPrefService.getShowSmartTagBadge();
      final categories = await _isar
          .collection<JiveCategory>()
          .where()
          .findAll();
      final categoryMap = {for (final c in categories) c.key: c};
      final accounts = await _isar.collection<JiveAccount>().where().findAll();
      final accountMap = {for (final a in accounts) a.id: a};
      final tags = await _isar.collection<JiveTag>().where().findAll();
      final tagMap = {for (final t in tags) t.key: t};

      if (mounted) {
        setState(() {
          _categoryByKey = categoryMap;
          _accountById = accountMap;
          _tagByKey = tagMap;
          _showSmartTagBadge = showBadge;
        });
      }

      await _reloadTransactions(showLoading: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    final visible = _applySearch(_transactions);
    final items = _buildListItems(visible);
    final bottomInset = _floatingBarHeight + 32;
    return Stack(
      children: [
        if (_transactions.isEmpty)
          ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
            children: [
              if (_canToggleSubCategories) _buildSubCategoryToggle(),
              const SizedBox(height: 120),
              Center(
                child: Text(
                  '暂无账单',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          )
        else if (visible.isEmpty)
          ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
            children: [
              if (_canToggleSubCategories) _buildSubCategoryToggle(),
              const SizedBox(height: 120),
              Center(
                child: Text(
                  '没有符合条件的账单',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          )
        else
          ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: items.length + (_canToggleSubCategories ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (_canToggleSubCategories && index == 0) {
                return _buildSubCategoryToggle();
              }
              final item = items[_canToggleSubCategories ? index - 1 : index];
              if (item is _TransactionDayHeader) {
                return _buildDayHeader(item);
              }
              final entryItem = item as _TransactionEntryItem;
              return _buildTransactionTile(entryItem.transaction);
            },
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _buildFloatingToolsBar(),
        ),
      ],
    );
  }

  bool get _canToggleSubCategories {
    final hasCategory = widget.filterCategoryKey?.trim().isNotEmpty ?? false;
    final hasSub = widget.filterSubCategoryKey?.trim().isNotEmpty ?? false;
    return hasCategory && !hasSub;
  }

  Widget _buildSubCategoryToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '包含二级分类账单',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
          Switch.adaptive(
            value: _includeSubCategories,
            onChanged: (value) {
              setState(() => _includeSubCategories = value);
              _reloadTransactions(showLoading: true);
            },
            activeColor: Colors.green.shade600,
          ),
        ],
      ),
    );
  }

  Future<void> _reloadTransactions({required bool showLoading}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    final String? subKey =
        (widget.filterSubCategoryKey != null &&
            widget.filterSubCategoryKey!.isNotEmpty)
        ? widget.filterSubCategoryKey
        : null;
    final String? categoryKey =
        (widget.filterCategoryKey != null &&
            widget.filterCategoryKey!.isNotEmpty)
        ? widget.filterCategoryKey
        : null;

    late final List<JiveTransaction> txs;
    if (subKey != null) {
      txs = await _isar.jiveTransactions
          .filter()
          .subCategoryKeyEqualTo(subKey)
          .sortByTimestampDesc()
          .findAll();
    } else if (categoryKey != null) {
      final filter = _isar.jiveTransactions.filter().categoryKeyEqualTo(
        categoryKey,
      );
      if (_canToggleSubCategories && !_includeSubCategories) {
        txs = await filter
            .group(
              (q) => q.subCategoryKeyIsNull().or().subCategoryKeyEqualTo(''),
            )
            .sortByTimestampDesc()
            .findAll();
      } else {
        txs = await filter.sortByTimestampDesc().findAll();
      }
    } else {
      txs = await _isar.jiveTransactions
          .where()
          .sortByTimestampDesc()
          .findAll();
    }

    DateTime? minDate;
    DateTime? maxDate;
    final years = <int>{};
    for (final tx in txs) {
      final timestamp = tx.timestamp;
      years.add(timestamp.year);
      minDate = minDate == null || timestamp.isBefore(minDate)
          ? timestamp
          : minDate;
      maxDate = maxDate == null || timestamp.isAfter(maxDate)
          ? timestamp
          : maxDate;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (maxDate == null || today.isAfter(maxDate)) {
      maxDate = today;
    }
    if (minDate != null) {
      minDate = DateTime(minDate.year, minDate.month, minDate.day);
    }
    if (maxDate != null) {
      maxDate = DateTime(maxDate.year, maxDate.month, maxDate.day);
    }

    if (mounted) {
      setState(() {
        _transactions = txs;
        _minTransactionDate = minDate;
        _maxTransactionDate = maxDate;
        _transactionYears = years;
        _isLoading = false;
      });
    }
  }

  Widget _buildFloatingToolsBar() {
    final hasSearch = _hasSearchFilters();
    final hasFilters =
        _searchCategoryKey != null ||
        _searchAccountId != null ||
        (_searchTag?.isNotEmpty ?? false) ||
        _searchDateRange != null;
    return Material(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: SizedBox(
        height: _floatingBarHeight,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '查找账单',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    filled: true,
                    isDense: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 32,
                      minWidth: 0,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _openSearchSheet,
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.tune,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                              if (hasFilters)
                                Positioned(
                                  right: -1,
                                  top: -1,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        if (hasSearch)
                          IconButton(
                            onPressed: _clearSearch,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                onPressed: _openSortSheet,
                tooltip: _sortSummary(),
                icon: Icon(Icons.sort, size: 20, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateHeaders() {
    if (!_groupByDate) return false;
    if (_sortField == _TransactionSortField.date) return true;
    return _showDateHeadersWhenNotDate;
  }

  Future<void> _loadGroupingPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_groupingPreferenceKey());
    if (stored == null || !mounted) return;
    setState(() => _groupByDate = stored);
  }

  Future<void> _saveGroupingPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_groupingPreferenceKey(), value);
  }

  String _groupingPreferenceKey() {
    final categoryKey = widget.filterCategoryKey?.trim();
    final subKey = widget.filterSubCategoryKey?.trim();
    if ((categoryKey?.isNotEmpty ?? false) || (subKey?.isNotEmpty ?? false)) {
      return 'transactions_grouping_v1_category_${categoryKey ?? 'all'}_${subKey ?? 'all'}';
    }
    return 'transactions_grouping_v1_all';
  }

  List<_TransactionListItem> _buildListItems(List<JiveTransaction> entries) {
    if (!_shouldShowDateHeaders()) {
      final sorted = _sortTransactions(entries);
      return sorted.map(_TransactionEntryItem.new).toList();
    }
    final grouped = <DateTime, List<JiveTransaction>>{};
    for (final tx in entries) {
      final day = DateTime(
        tx.timestamp.year,
        tx.timestamp.month,
        tx.timestamp.day,
      );
      grouped.putIfAbsent(day, () => []).add(tx);
    }
    final days = grouped.keys.toList()
      ..sort((a, b) {
        if (_sortField == _TransactionSortField.date) {
          final compare = a.compareTo(b);
          return _sortDirection == _TransactionSortDirection.desc
              ? -compare
              : compare;
        }
        return b.compareTo(a);
      });
    final items = <_TransactionListItem>[];
    for (final day in days) {
      final dayEntries = grouped[day] ?? const [];
      final sortedEntries = _sortTransactions(dayEntries);
      var income = 0.0;
      var expense = 0.0;
      for (final tx in dayEntries) {
        final type = tx.type ?? 'expense';
        if (type == 'income') {
          income += tx.amount.abs();
        } else if (type == 'expense') {
          expense += tx.amount.abs();
        }
      }
      items.add(
        _TransactionDayHeader(
          date: day,
          income: income,
          expense: expense,
          count: dayEntries.length,
        ),
      );
      items.addAll(sortedEntries.map(_TransactionEntryItem.new));
    }
    return items;
  }

  Widget _buildDayHeader(_TransactionDayHeader header) {
    final dateLabel = DateFormat('MM.dd').format(header.date);
    final weekdayLabel = _weekdayLabel(header.date);
    final countLabel = '${header.count}笔';
    final incomeLabel = _currency.format(header.income);
    final expenseLabel = _currency.format(header.expense);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$dateLabel $weekdayLabel · $countLabel',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '收 $incomeLabel',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                ),
                TextSpan(
                  text: ' / ',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                TextSpan(
                  text: '支 $expenseLabel',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return '周一';
      case DateTime.tuesday:
        return '周二';
      case DateTime.wednesday:
        return '周三';
      case DateTime.thursday:
        return '周四';
      case DateTime.friday:
        return '周五';
      case DateTime.saturday:
        return '周六';
      case DateTime.sunday:
        return '周日';
    }
    return '';
  }

  Future<void> _openSearchSheet() async {
    FocusScope.of(context).unfocus();
    final categories =
        _categoryByKey.values.where((category) => !category.isHidden).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final accounts = _accountById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final enabledYears = _transactionYears.isNotEmpty
            ? _transactionYears
            : null;
        return TransactionFilterSheet(
          categories: categories,
          accounts: accounts,
          initialCategoryKey: _searchCategoryKey,
          initialAccountId: _searchAccountId,
          initialTag: _searchTag,
          initialDateRange: _searchDateRange,
          minDate: _minTransactionDate,
          maxDate: _maxTransactionDate,
          enabledYears: enabledYears,
          onChanged: (categoryKey, accountId, tag, dateRange) {
            _updateSearchFilters(
              categoryKey: categoryKey,
              accountId: accountId,
              tag: tag,
              dateRange: dateRange,
            );
          },
          onClear: _clearSearchFilters,
        );
      },
    );
  }

  Future<void> _openSortSheet() async {
    FocusScope.of(context).unfocus();
    var field = _sortField;
    var direction = _sortDirection;
    var groupByDate = _groupByDate;
    var showDateHeadersWhenNotDate = _showDateHeadersWhenNotDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '排列方式',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '模式',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('账单模式'),
                          selected: groupByDate,
                          selectedColor: Colors.green.shade600.withOpacity(
                            0.18,
                          ),
                          onSelected: (_) =>
                              setModalState(() => groupByDate = true),
                        ),
                        ChoiceChip(
                          label: const Text('列表模式'),
                          selected: !groupByDate,
                          selectedColor: Colors.green.shade600.withOpacity(
                            0.18,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              groupByDate = false;
                              showDateHeadersWhenNotDate = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _TransactionSortField.values.map((value) {
                        final label = _sortFieldLabel(value);
                        return ChoiceChip(
                          label: Text(label),
                          selected: field == value,
                          selectedColor: Colors.green.shade600.withOpacity(
                            0.18,
                          ),
                          onSelected: (_) => setModalState(() => field = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '顺序',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _TransactionSortDirection.values.map((value) {
                        final label = _sortDirectionLabel(value, field);
                        return ChoiceChip(
                          label: Text(label),
                          selected: direction == value,
                          selectedColor: Colors.green.shade600.withOpacity(
                            0.18,
                          ),
                          onSelected: (_) =>
                              setModalState(() => direction = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    if (groupByDate && field != _TransactionSortField.date)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('非日期排序显示日期头'),
                        value: showDateHeadersWhenNotDate,
                        onChanged: (value) => setModalState(
                          () => showDateHeadersWhenNotDate = value,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sortField = field;
                            _sortDirection = direction;
                            _groupByDate = groupByDate;
                            _showDateHeadersWhenNotDate =
                                showDateHeadersWhenNotDate;
                          });
                          _saveGroupingPreference(groupByDate);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('应用'),
                      ),
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

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _updateSearchFilters({
    String? categoryKey,
    int? accountId,
    String? tag,
    DateTimeRange? dateRange,
  }) {
    final normalizedTag = tag?.trim();
    setState(() {
      _searchCategoryKey = categoryKey;
      _searchAccountId = accountId;
      _searchTag = (normalizedTag == null || normalizedTag.isEmpty)
          ? null
          : normalizedTag;
      _searchDateRange = dateRange;
    });
  }

  void _clearSearchFilters() {
    setState(() {
      _searchCategoryKey = null;
      _searchAccountId = null;
      _searchTag = null;
      _searchDateRange = null;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchCategoryKey = null;
      _searchAccountId = null;
      _searchTag = null;
      _searchDateRange = null;
    });
    _searchController.clear();
    _searchFocus.unfocus();
  }

  bool _hasSearchFilters() {
    return _searchQuery.trim().isNotEmpty ||
        _searchCategoryKey != null ||
        _searchAccountId != null ||
        (_searchTag?.isNotEmpty ?? false) ||
        _searchDateRange != null;
  }

  List<JiveTransaction> _applySearch(List<JiveTransaction> entries) {
    final query = _searchQuery.trim().toLowerCase();
    final tagQuery = _searchTag?.trim();
    final amountQuery = double.tryParse(query);

    return entries.where((tx) {
      if (_searchCategoryKey != null) {
        final key = _searchCategoryKey;
        final categoryName = _categoryByKey[key!]?.name;
        final matchesKey = tx.categoryKey == key || tx.subCategoryKey == key;
        final matchesName =
            categoryName != null &&
            (tx.category == categoryName || tx.subCategory == categoryName);
        if (!matchesKey && !matchesName) return false;
      }

      if (_searchAccountId != null) {
        final id = _searchAccountId;
        if (tx.accountId != id && tx.toAccountId != id) {
          return false;
        }
      }

      if (tagQuery != null && tagQuery.isNotEmpty) {
        if (!_noteHasTag(tx.note, tagQuery)) {
          return false;
        }
      }

      if (_searchDateRange != null) {
        if (!_withinDateRange(tx.timestamp, _searchDateRange!)) {
          return false;
        }
      }

      if (query.isEmpty) return true;

      final searchText = _entrySearchText(tx);
      if (searchText.contains(query)) return true;

      if (amountQuery != null) {
        final amountText = tx.amount.toStringAsFixed(2);
        if (amountText.contains(query)) return true;
      }

      return false;
    }).toList();
  }

  List<JiveTransaction> _sortTransactions(List<JiveTransaction> entries) {
    final sorted = List<JiveTransaction>.from(entries);
    sorted.sort((a, b) {
      int compare;
      switch (_sortField) {
        case _TransactionSortField.amount:
          compare = a.amount.compareTo(b.amount);
          break;
        case _TransactionSortField.category:
          compare = _categorySortLabel(a).compareTo(_categorySortLabel(b));
          break;
        case _TransactionSortField.account:
          compare = _accountSortLabel(a).compareTo(_accountSortLabel(b));
          break;
        case _TransactionSortField.tag:
          compare = _tagSortLabel(a).compareTo(_tagSortLabel(b));
          break;
        case _TransactionSortField.date:
          compare = a.timestamp.compareTo(b.timestamp);
          break;
      }
      if (compare == 0) {
        compare = a.timestamp.compareTo(b.timestamp);
      }
      return _sortDirection == _TransactionSortDirection.desc
          ? -compare
          : compare;
    });
    return sorted;
  }

  String _sortFieldLabel(_TransactionSortField field) {
    switch (field) {
      case _TransactionSortField.amount:
        return '金额';
      case _TransactionSortField.category:
        return '分类';
      case _TransactionSortField.account:
        return '账户';
      case _TransactionSortField.tag:
        return '标签';
      case _TransactionSortField.date:
        return '日期';
    }
  }

  String _sortDirectionLabel(
    _TransactionSortDirection direction,
    _TransactionSortField field,
  ) {
    if (field == _TransactionSortField.date) {
      return direction == _TransactionSortDirection.desc ? '新→旧' : '旧→新';
    }
    if (field == _TransactionSortField.amount) {
      return direction == _TransactionSortDirection.desc ? '大→小' : '小→大';
    }
    return direction == _TransactionSortDirection.desc ? 'Z→A' : 'A→Z';
  }

  String _sortSummary() {
    return '${_sortFieldLabel(_sortField)} ${_sortDirectionLabel(_sortDirection, _sortField)}';
  }

  String _entrySearchText(JiveTransaction tx) {
    final category = _displayCategoryName(tx.categoryKey, tx.category);
    final subCategory = _displayCategoryName(tx.subCategoryKey, tx.subCategory);
    final account = _resolveAccountName(tx.accountId);
    final counter = _resolveAccountName(tx.toAccountId);
    final note = tx.note ?? '';
    final rawText = tx.rawText ?? '';
    final source = tx.source;
    final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.timestamp);
    return [
      category,
      subCategory,
      account,
      counter,
      note,
      rawText,
      source,
      date,
    ].join(' ').toLowerCase();
  }

  bool _noteHasTag(String? note, String tag) {
    final raw = note?.trim() ?? '';
    if (raw.isEmpty) return false;
    final pattern = RegExp('(^|\\s)${RegExp.escape(tag)}(?=\\s|\$)');
    return pattern.hasMatch(raw);
  }

  List<String> _extractNoteTags(String? note) {
    final raw = note?.trim() ?? '';
    if (raw.isEmpty) return const [];
    return raw.split(RegExp(r'\\s+')).where((item) => item.isNotEmpty).toList();
  }

  bool _withinDateRange(DateTime timestamp, DateTimeRange range) {
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    return !timestamp.isBefore(start) && !timestamp.isAfter(end);
  }

  String _categorySortLabel(JiveTransaction tx) {
    if ((tx.subCategory ?? '').isNotEmpty) {
      return _displayCategoryName(
        tx.subCategoryKey,
        tx.subCategory,
      ).toLowerCase();
    }
    return _displayCategoryName(tx.categoryKey, tx.category).toLowerCase();
  }

  String _accountSortLabel(JiveTransaction tx) {
    final from = _resolveAccountName(tx.accountId);
    if (from.isNotEmpty) return from.toLowerCase();
    return _resolveAccountName(tx.toAccountId).toLowerCase();
  }

  String _tagSortLabel(JiveTransaction tx) {
    if (tx.tagKeys.isNotEmpty) {
      final tags = tx.tagKeys
          .map((key) => _tagByKey[key]?.name ?? '')
          .where((name) => name.trim().isNotEmpty)
          .toList();
      if (tags.isNotEmpty) {
        tags.sort();
        return tags.first.toLowerCase();
      }
    }
    final noteTags = _extractNoteTags(tx.note);
    if (noteTags.isEmpty) return '';
    return noteTags.first.toLowerCase();
  }

  String _resolveAccountName(int? accountId) {
    if (accountId == null) return '';
    return _accountById[accountId]?.name ?? '';
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '未分类';
  }

  Widget _buildTransactionTile(JiveTransaction tx) {
    final isIncome = (tx.type ?? 'expense') == 'income';
    final amountColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;
    final amountPrefix = isIncome ? '+' : '-';
    final categoryKey = tx.subCategoryKey ?? tx.categoryKey;
    final category = categoryKey != null ? _categoryByKey[categoryKey] : null;
    final icon = category?.iconName ?? 'category';
    final title = (tx.subCategory ?? '').isNotEmpty
        ? tx.subCategory!
        : (tx.category ?? '未分类');
    final parent = (tx.subCategory ?? '').isNotEmpty ? (tx.category ?? '') : '';
    final note = (tx.note ?? '').trim();
    final hasNote = note.isNotEmpty;
    final showSmartBadge =
        _showSmartTagBadge && tx.smartTagKeys.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final updated = await showTransactionDetailSheet(context, tx.id);
        if (updated == true && mounted) {
          await _load();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CategoryService.buildIcon(
                  icon,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            if (parent.isNotEmpty) parent,
                            _dateFormat.format(tx.timestamp),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                      if (showSmartBadge) ...[
                        const SizedBox(width: 6),
                        _buildSmartTagBadge(),
                      ],
                    ],
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '$amountPrefix${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartTagBadge() {
    final badge = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: JiveTheme.primaryGreen.withOpacity(0.4)),
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 12,
        color: JiveTheme.primaryGreen,
      ),
    );
    return Tooltip(
      message: '该交易由智能标签自动打标',
      triggerMode: TooltipTriggerMode.longPress,
      child: badge,
    );
  }
}

enum _TransactionSortField { date, amount, category, account, tag }

enum _TransactionSortDirection { desc, asc }

abstract class _TransactionListItem {
  const _TransactionListItem();
}

class _TransactionDayHeader extends _TransactionListItem {
  final DateTime date;
  final double income;
  final double expense;
  final int count;

  const _TransactionDayHeader({
    required this.date,
    required this.income,
    required this.expense,
    required this.count,
  });
}

class _TransactionEntryItem extends _TransactionListItem {
  final JiveTransaction transaction;

  const _TransactionEntryItem(this.transaction);
}
