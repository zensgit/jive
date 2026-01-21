import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/widgets/transaction_filter_sheet.dart';
import '../../core/service/category_service.dart';

class CategoryTransactionsScreen extends StatefulWidget {
  final String title;
  final String? filterCategoryKey;
  final String? filterSubCategoryKey;

  const CategoryTransactionsScreen({
    super.key,
    required this.title,
    this.filterCategoryKey,
    this.filterSubCategoryKey,
  });

  @override
  State<CategoryTransactionsScreen> createState() => _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState extends State<CategoryTransactionsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  String? _error;
  List<JiveTransaction> _transactions = [];
  Map<String, JiveCategory> _categoryByKey = {};
  final DateFormat _dateFormat = DateFormat('MM-dd HH:mm');
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

  static const double _floatingBarHeight = 60;

  @override
  void initState() {
    super.initState();
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
        _isar = await Isar.open(
          [
            JiveTransactionSchema,
            JiveCategorySchema,
            JiveCategoryOverrideSchema,
            JiveAccountSchema,
            JiveAutoDraftSchema,
            JiveTagSchema,
            JiveTagGroupSchema,
          ],
          directory: dir.path,
        );
      }

      final categories = await _isar.collection<JiveCategory>().where().findAll();
      final categoryMap = {for (final c in categories) c.key: c};
      final accounts = await _isar.collection<JiveAccount>().where().findAll();
      final accountMap = {for (final a in accounts) a.id: a};

      final String? subKey =
          (widget.filterSubCategoryKey != null && widget.filterSubCategoryKey!.isNotEmpty)
              ? widget.filterSubCategoryKey
              : null;
      final String? categoryKey =
          (widget.filterCategoryKey != null && widget.filterCategoryKey!.isNotEmpty)
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
        txs = await _isar.jiveTransactions
            .filter()
            .categoryKeyEqualTo(categoryKey)
            .sortByTimestampDesc()
            .findAll();
      } else {
        txs = await _isar.jiveTransactions.where().sortByTimestampDesc().findAll();
      }
      DateTime? minDate;
      DateTime? maxDate;
      final years = <int>{};
      for (final tx in txs) {
        final timestamp = tx.timestamp;
        years.add(timestamp.year);
        minDate = minDate == null || timestamp.isBefore(minDate) ? timestamp : minDate;
        maxDate = maxDate == null || timestamp.isAfter(maxDate) ? timestamp : maxDate;
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
          _categoryByKey = categoryMap;
          _accountById = accountMap;
          _transactions = txs;
          _minTransactionDate = minDate;
          _maxTransactionDate = maxDate;
          _transactionYears = years;
          _isLoading = false;
        });
      }
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
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    final bottomInset = _floatingBarHeight + 32;
    return Stack(
      children: [
        if (_transactions.isEmpty)
          Center(
            child: Text('暂无账单', style: TextStyle(color: Colors.grey.shade600)),
          )
        else if (visible.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Center(
              child: Text('没有符合条件的账单', style: TextStyle(color: Colors.grey.shade600)),
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildTransactionTile(visible[index]),
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

  Widget _buildFloatingToolsBar() {
    final hasSearch = _hasSearchFilters();
    final hasFilters = _searchCategoryKey != null ||
        _searchAccountId != null ||
        (_searchTag?.isNotEmpty ?? false);
    return Material(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: SizedBox(
        height: _floatingBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '查找账单',
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
              filled: true,
              isDense: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIconConstraints: const BoxConstraints(minHeight: 32, minWidth: 0),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _openSearchSheet,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.tune, size: 18, color: Colors.grey.shade700),
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
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  if (hasSearch)
                    IconButton(
                      onPressed: _clearSearch,
                      icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSearchSheet() async {
    FocusScope.of(context).unfocus();
    final categories = _categoryByKey.values
        .where((category) => !category.isHidden)
        .toList()
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
        final enabledYears =
            _transactionYears.isNotEmpty ? _transactionYears : null;
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
      _searchTag =
          (normalizedTag == null || normalizedTag.isEmpty) ? null : normalizedTag;
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

  bool _withinDateRange(DateTime timestamp, DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);
    return !timestamp.isBefore(start) && !timestamp.isAfter(end);
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
    final title = (tx.subCategory ?? '').isNotEmpty ? tx.subCategory! : (tx.category ?? '未分类');
    final parent = (tx.subCategory ?? '').isNotEmpty ? (tx.category ?? '') : '';

    return Container(
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
                Text(
                  [if (parent.isNotEmpty) parent, _dateFormat.format(tx.timestamp)].join(' · '),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: amountColor),
          ),
        ],
      ),
    );
  }
}
