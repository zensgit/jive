import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/model/transaction_query_spec.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/search_history_service.dart';
import '../../core/service/transaction_query_service.dart';
import '../transactions/transaction_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  Timer? _searchDebounce;

  Isar? _isar;
  TransactionQueryService? _queryService;
  Map<String, JiveCategory> _categoryByKey = {};
  Map<int, JiveAccount> _accountById = {};
  Map<String, JiveTag> _tagByKey = {};
  List<JiveTransaction> _results = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasDataChanges = false;
  String? _error;
  int _searchToken = 0;

  // Amount range filter
  double? _minAmount;
  double? _maxAmount;
  bool _showAmountFilter = false;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  // Search history
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final isar = await DatabaseService.getInstance();
      final categories = await isar
          .collection<JiveCategory>()
          .where()
          .findAll();
      final accounts = await isar.collection<JiveAccount>().where().findAll();
      final tags = await isar.collection<JiveTag>().where().findAll();

      if (!mounted) return;
      setState(() {
        _isar = isar;
        _queryService = TransactionQueryService(isar);
        _categoryByKey = {
          for (final category in categories) category.key: category,
        };
        _accountById = {for (final account in accounts) account.id: account};
        _tagByKey = {for (final tag in tags) tag.key: tag};
        _isLoading = false;
      });
      _searchHistory = await SearchHistoryService.load();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocus.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final keyword = value.trim();
    final token = ++_searchToken;

    if (keyword.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_searchTransactions(keyword, token));
    });
  }

  Future<void> _searchTransactions(String keyword, int token) async {
    final service = _queryService;
    if (service == null) return;

    try {
      // Save to history
      await SearchHistoryService.add(keyword);
      _searchHistory = await SearchHistoryService.load();

      final allResults = <JiveTransaction>[];
      TransactionQueryCursor? cursor;
      var loops = 0;

      while (loops < 200) {
        loops += 1;
        final page = await service.query(
          TransactionQuerySpec(
            keyword: keyword,
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            sortField: TransactionSortField.date,
            sortDirection: TransactionSortDirection.desc,
          ),
          cursor: cursor,
          pageSize: 100,
          categoryByKey: _categoryByKey,
          accountById: _accountById,
          tagByKey: _tagByKey,
        );
        if (!mounted || token != _searchToken) return;

        allResults.addAll(page.items);
        if (!page.hasMore || page.nextCursor == null || page.items.isEmpty) {
          break;
        }
        cursor = page.nextCursor;
      }

      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = allResults;
        _isSearching = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = [];
        _isSearching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openTransaction(JiveTransaction transaction) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(transactionId: transaction.id),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      _hasDataChanges = true;
      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty) {
        final token = ++_searchToken;
        setState(() => _isSearching = true);
        await _searchTransactions(keyword, token);
      }
    }
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _searchToken += 1;
    setState(() {
      _results = [];
      _isSearching = false;
      _error = null;
    });
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasDataChanges);
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasDataChanges),
          ),
          title: const Text(
            '全局搜索',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.grey.shade100,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildSearchField(),
            ),
            _buildAmountFilter(),
            if (_isSearching && _results.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      autofocus: true,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索备注、金额、分类、标签',
        prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 32),
        suffixIcon: hasQuery || _isSearching
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (hasQuery)
                    IconButton(
                      onPressed: _clearQuery,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      splashRadius: 18,
                    ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    final keyword = _searchController.text.trim();
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _isar == null) {
      return _buildMessageState(_error!, actionLabel: '重试', onPressed: _load);
    }
    if (keyword.isEmpty) {
      if (_searchHistory.isNotEmpty) {
        return _buildHistoryList();
      }
      return _buildMessageState('输入关键词搜索交易');
    }
    if (_isSearching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMessageState('搜索失败，请稍后重试');
    }
    if (_results.isEmpty) {
      return _buildMessageState('未找到相关交易');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildTransactionTile(_results[index]),
    );
  }

  Widget _buildMessageState(
    String message, {
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 28, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(JiveTransaction transaction) {
    final type = transaction.type ?? 'expense';
    final isIncome = type == 'income';
    final isTransfer = type == 'transfer';
    final amountColor = isTransfer
        ? Colors.blueGrey.shade700
        : (isIncome ? Colors.green.shade600 : Colors.red.shade600);
    final amountPrefix = isTransfer ? '' : (isIncome ? '+' : '-');
    final note = (transaction.note ?? '').trim();
    final category = _resolveCategoryLabel(transaction);
    final categoryModel = _resolveCategoryModel(transaction);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openTransaction(transaction),
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
                child: isTransfer
                    ? Icon(
                        Icons.swap_horiz,
                        size: 20,
                        color: Colors.blueGrey.shade700,
                      )
                    : CategoryService.buildIcon(
                        categoryModel?.iconName ?? 'category',
                        size: 20,
                        color: Colors.grey.shade700,
                        isSystemCategory: categoryModel?.isSystem,
                        forceTinted: categoryModel?.iconForceTinted ?? false,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: highlightText(category, _searchController.text.trim()),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateFormat.format(transaction.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: highlightText(note.isEmpty ? '无备注' : note, _searchController.text.trim()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  JiveCategory? _resolveCategoryModel(JiveTransaction transaction) {
    final categoryKey = transaction.subCategoryKey ?? transaction.categoryKey;
    if (categoryKey == null || categoryKey.isEmpty) return null;
    return _categoryByKey[categoryKey];
  }

  String _resolveCategoryLabel(JiveTransaction transaction) {
    final parentName = _displayCategoryName(
      transaction.categoryKey,
      transaction.category,
    );
    final subName = _displayCategoryName(
      transaction.subCategoryKey,
      transaction.subCategory,
    );
    final hasSubCategory =
        (transaction.subCategoryKey?.trim().isNotEmpty ?? false) ||
        ((transaction.subCategory ?? '').trim().isNotEmpty);

    if (hasSubCategory && subName.isNotEmpty && parentName.isNotEmpty) {
      return '$parentName · $subName';
    }
    if (subName.isNotEmpty && subName != '未分类') return subName;
    if (parentName.isNotEmpty && parentName != '未分类') return parentName;
    if ((transaction.type ?? 'expense') == 'transfer') return '转账';
    return '未分类';
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    final label = fallback?.trim() ?? '';
    if (label.isNotEmpty) return label;
    return '未分类';
  }

  Widget _buildAmountFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAmountFilter = !_showAmountFilter),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '金额筛选',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Icon(
                  _showAmountFilter ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                if (_minAmount != null || _maxAmount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_minAmount?.toStringAsFixed(0) ?? '0'} - ${_maxAmount?.toStringAsFixed(0) ?? '∞'}',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_showAmountFilter)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '最小金额',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (_) => _applyAmountFilter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _maxAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '最大金额',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (_) => _applyAmountFilter(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _applyAmountFilter() {
    _minAmount = double.tryParse(_minAmountController.text);
    _maxAmount = double.tryParse(_maxAmountController.text);
    _onSearchChanged(_searchController.text);
  }

  Widget _buildHistoryList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          children: [
            Text('最近搜索', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await SearchHistoryService.clear();
                setState(() => _searchHistory = []);
              },
              child: Text('清空', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ),
          ],
        ),
        ..._searchHistory.map((q) => ListTile(
              dense: true,
              leading: Icon(Icons.history, size: 18, color: Colors.grey.shade400),
              title: Text(q),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                onPressed: () async {
                  await SearchHistoryService.remove(q);
                  setState(() => _searchHistory.remove(q));
                },
              ),
              onTap: () {
                _searchController.text = q;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: q.length),
                );
                _onSearchChanged(q);
              },
            )),
      ],
    );
  }

  /// Highlight [keyword] in [text] with bold green.
  static Widget highlightText(String text, String keyword) {
    if (keyword.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final index = lowerText.indexOf(lowerKeyword);
    if (index < 0) return Text(text);

    return Text.rich(TextSpan(
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
        ),
        TextSpan(text: text.substring(index + keyword.length)),
      ],
    ));
  }
}
