import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/reconcile_service.dart';
import '../../core/widgets/date_range_picker_sheet.dart';
import '../../core/widgets/transaction_filter_sheet.dart';
import '../transactions/transaction_detail_screen.dart';

class AccountReconcileScreen extends StatefulWidget {
  final int accountId;
  final VoidCallback? onDataChanged;

  const AccountReconcileScreen({
    super.key,
    required this.accountId,
    this.onDataChanged,
  });

  @override
  State<AccountReconcileScreen> createState() => _AccountReconcileScreenState();
}

class _AccountReconcileScreenState extends State<AccountReconcileScreen> {
  late final NumberFormat _currency = NumberFormat.currency(symbol: "¥");
  late final DateFormat _dayFormat = DateFormat('MM-dd');
  late final NumberFormat _timeFormat = NumberFormat('00');

  Isar? _isar;
  bool _isLoading = true;
  String? _errorMessage;
  JiveAccount? _account;
  ReconcileResult? _result;
  final Map<String, JiveCategory> _categoryByKey = {};
  final Map<int, JiveAccount> _accountById = {};
  late DateTime _startDate;
  late DateTime _endDate;
  final TextEditingController _statementController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  double? _statementBalance;
  double _discrepancy = 0;
  Set<DateTime> _highlightDays = {};
  _ReconcileFilter _filter = _ReconcileFilter.all;
  _SummaryMode _summaryMode = _SummaryMode.all;
  _ReconcileSortField _sortField = _ReconcileSortField.date;
  _ReconcileSortDirection _sortDirection = _ReconcileSortDirection.desc;
  bool _groupByDay = true;
  String _searchQuery = '';
  String? _searchCategoryKey;
  int? _searchAccountId;
  String? _searchTag;
  DateTimeRange? _searchDateRange;
  DateTime? _minTransactionDate;
  DateTime? _maxTransactionDate;
  Set<int> _transactionYears = {};

  static const double _floatingBarHeight = 118;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = _endOfDay(now);
    _loadData();
  }

  @override
  void dispose() {
    _statementController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadViewPrefs();
      final isar = await _ensureIsar();
      final account = await isar.collection<JiveAccount>().get(
        widget.accountId,
      );
      if (account == null) {
        throw StateError('account_missing');
      }

      final categories = await isar
          .collection<JiveCategory>()
          .where()
          .findAll();
      final accounts = await isar.collection<JiveAccount>().where().findAll();

      final storedStatement = await _loadStatementBalance();
      final result = await ReconcileService(isar).reconcileAccount(
        accountId: widget.accountId,
        start: _startDate,
        end: _endDate,
      );

      if (!mounted) return;
      setState(() {
        _account = account;
        _result = result;
        _categoryByKey
          ..clear()
          ..addEntries(categories.map((c) => MapEntry(c.key, c)));
        _accountById
          ..clear()
          ..addEntries(accounts.map((a) => MapEntry(a.id, a)));
        _statementBalance = storedStatement;
        _statementController.text = storedStatement != null
            ? _formatStatementInput(storedStatement)
            : '';
        _minTransactionDate = result.minDate;
        _maxTransactionDate = result.maxDate;
        _transactionYears = result.transactionYears;
        _updateDiscrepancy(result);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is StateError ? '账户不存在' : '加载失败，请重试';
        _isLoading = false;
      });
    }
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<void> _pickDateRange() async {
    FocusScope.of(context).unfocus();
    final minDate = _minTransactionDate;
    final maxDate = _maxTransactionDate;
    final now = DateTime.now();
    final viewStart = DateTime((minDate?.year ?? now.year) - 1, 1, 1);
    final viewEnd = DateTime((maxDate?.year ?? now.year) + 1, 12, 31);
    final enabledYears = _transactionYears.isNotEmpty
        ? _transactionYears
        : null;
    final initialRange = DateTimeRange(
      start: minDate != null && _startDate.isBefore(minDate)
          ? minDate
          : _startDate,
      end: maxDate != null && _endDate.isAfter(maxDate) ? maxDate : _endDate,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DateRangePickerSheet(
          initialRange: initialRange,
          firstDay: viewStart,
          lastDay: viewEnd,
          minSelectableDay: minDate,
          maxSelectableDay: maxDate,
          enabledYears: enabledYears,
          bottomLabel: '选择对账日期范围',
          onChanged: (range) async {
            if (range == null) {
              final fallbackStart = minDate ?? DateTime.now();
              final fallbackEnd = maxDate ?? DateTime.now();
              setState(() {
                _startDate = _startOfDay(fallbackStart);
                _endDate = _endOfDay(fallbackEnd);
              });
              await _loadData();
              return;
            }
            setState(() {
              _startDate = _startOfDay(range.start);
              _endDate = _endOfDay(range.end);
            });
            await _loadData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountName = _account?.name ?? '账户';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$accountName 对账',
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: '选择日期',
          ),
          if (kDebugMode)
            IconButton(
              onPressed: _seedTestData,
              icon: const Icon(Icons.science_outlined),
              tooltip: '生成测试数据',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _seedTestData() async {
    final isar = await _ensureIsar();
    final account =
        _account ?? await isar.collection<JiveAccount>().get(widget.accountId);
    if (account == null) {
      _showSnack('账户不存在，无法生成测试数据');
      return;
    }

    final existingCount = _result?.entries.length ?? 0;
    if (!mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成测试数据'),
        content: Text(
          existingCount == 0
              ? '将在当前账户和日期范围内追加测试数据。'
              : '当前范围已有 $existingCount 条数据，将追加测试数据，是否继续？',
        ),
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

    final categories = await isar.collection<JiveCategory>().where().findAll();
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    final expenseCategories = categories
        .where((cat) => !cat.isIncome && !cat.isHidden)
        .toList();
    final incomeCategories = categories
        .where((cat) => cat.isIncome && !cat.isHidden)
        .toList();
    JiveAccount? otherAccount;
    for (final candidate in accounts) {
      if (candidate.id != account.id) {
        otherAccount = candidate;
        break;
      }
    }

    final expenseAmounts = [18.5, 36.0, 58.0, 120.0];
    final incomeAmounts = [520.0, 1300.0];
    final transferAmounts = otherAccount == null ? <double>[] : [200.0, 150.0];
    final totalCount =
        expenseAmounts.length + incomeAmounts.length + transferAmounts.length;
    final timestamps = _buildSampleTimestamps(totalCount);
    var timeIndex = 0;

    JiveCategory? pickCategory(List<JiveCategory> list, int index) {
      if (list.isEmpty) return null;
      return list[index % list.length];
    }

    final inserts = <JiveTransaction>[];
    for (var i = 0; i < expenseAmounts.length; i++) {
      final cat = pickCategory(expenseCategories, i);
      inserts.add(
        JiveTransaction()
          ..amount = expenseAmounts[i]
          ..source = 'Manual'
          ..type = 'expense'
          ..timestamp = timestamps[timeIndex++]
          ..accountId = account.id
          ..categoryKey = cat?.key
          ..category = cat?.name
          ..note = '测试数据 支出${i + 1}',
      );
    }
    for (var i = 0; i < incomeAmounts.length; i++) {
      final cat = pickCategory(incomeCategories, i);
      inserts.add(
        JiveTransaction()
          ..amount = incomeAmounts[i]
          ..source = 'Manual'
          ..type = 'income'
          ..timestamp = timestamps[timeIndex++]
          ..accountId = account.id
          ..categoryKey = cat?.key
          ..category = cat?.name
          ..note = '测试数据 收入${i + 1}',
      );
    }
    if (otherAccount != null) {
      for (var i = 0; i < transferAmounts.length; i++) {
        final isOut = i.isEven;
        inserts.add(
          JiveTransaction()
            ..amount = transferAmounts[i]
            ..source = 'Manual'
            ..type = 'transfer'
            ..timestamp = timestamps[timeIndex++]
            ..accountId = isOut ? account.id : otherAccount.id
            ..toAccountId = isOut ? otherAccount.id : account.id
            ..note = isOut ? '测试数据 转出' : '测试数据 转入',
        );
      }
    }

    await isar.writeTxn(() async {
      await isar.jiveTransactions.putAll(inserts);
    });
    await _loadData();
    widget.onDataChanged?.call();
    _showSnack('已生成 ${inserts.length} 条测试数据');
  }

  List<DateTime> _buildSampleTimestamps(int count) {
    if (count <= 0) return [];
    final start = _startOfDay(_startDate);
    final maxDays = _endDate.difference(_startDate).inDays;
    final daysSpan = maxDays < 0 ? 0 : maxDays;
    final list = <DateTime>[];
    for (var i = 0; i < count; i++) {
      final offset = daysSpan == 0 ? 0 : (i * daysSpan ~/ count);
      final hour = 9 + (i % 9);
      final minute = (i * 7) % 60;
      final day = start.add(Duration(days: offset));
      list.add(DateTime(day.year, day.month, day.day, hour, minute));
    }
    return list;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }
    final result = _result;
    if (result == null) {
      return _buildErrorState('暂无数据');
    }
    final summary = _resolveSummary(result);
    final items = _buildListItems(result);
    final bottomInset = _floatingBarHeight + 32;
    return Stack(
      children: [
        CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: _buildQuickRanges()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            SliverToBoxAdapter(child: _buildSummaryModeToggle()),
            SliverToBoxAdapter(
              child: _buildSummaryCard(summary, _summaryTitle()),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: _buildEmptyState(),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.only(top: 8, bottom: bottomInset),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    if (item is _ReconcileDayHeader) {
                      return _buildDayHeader(item);
                    }
                    if (item is _ReconcileGroupHeader) {
                      return _buildGroupHeader(item);
                    }
                    final entryItem = item as _ReconcileEntryItem;
                    return _buildEntryRow(entryItem.entry);
                  }, childCount: items.length),
                ),
              ),
          ],
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

  Widget _buildQuickRanges() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildQuickRangeChip('本月', _QuickRange.currentMonth),
          _buildQuickRangeChip('上月', _QuickRange.lastMonth),
          _buildQuickRangeChip('近7天', _QuickRange.last7Days),
          if (kDebugMode) _buildQuickRangeChip('测试数据', _QuickRange.debugSeed),
        ],
      ),
    );
  }

  Widget _buildQuickRangeChip(String label, _QuickRange range) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      onPressed: () {
        if (range == _QuickRange.debugSeed) {
          _seedTestData();
        } else {
          _applyQuickRange(range);
        }
      },
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildFilterChip('全部', _ReconcileFilter.all),
          _buildFilterChip('收入', _ReconcileFilter.income),
          _buildFilterChip('支出', _ReconcileFilter.expense),
          _buildFilterChip('转账', _ReconcileFilter.transfer),
        ],
      ),
    );
  }

  Widget _buildSummaryModeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Text(
            '汇总范围',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          _buildSummaryModeChip('全部', _SummaryMode.all),
          const SizedBox(width: 8),
          _buildSummaryModeChip('筛选', _SummaryMode.filtered),
        ],
      ),
    );
  }

  Widget _buildSummaryModeChip(String label, _SummaryMode mode) {
    final selected = _summaryMode == mode;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      selected: selected,
      selectedColor: JiveTheme.primaryGreen.withValues(alpha: 0.18),
      onSelected: (_) {
        setState(() => _summaryMode = mode);
        _persistViewPrefs();
      },
    );
  }

  Widget _buildFilterChip(String label, _ReconcileFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      selected: selected,
      selectedColor: JiveTheme.primaryGreen.withValues(alpha: 0.18),
      onSelected: (_) {
        setState(() => _filter = value);
        _persistViewPrefs();
      },
    );
  }

  Widget _buildSummaryCard(ReconcileSummary summary, String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem('收入', summary.income, Colors.green),
              const SizedBox(width: 12),
              _buildSummaryItem('支出', summary.expense, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSummaryItem('转入', summary.transferIn, Colors.teal),
              const SizedBox(width: 12),
              _buildSummaryItem('转出', summary.transferOut, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryItem(
                '净变动',
                summary.netChange,
                JiveTheme.primaryGreen,
              ),
              const SizedBox(width: 12),
              _buildSummaryItem('期末', summary.endBalance, Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '期初 ${_currency.format(summary.startBalance)}',
            style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 12),
          ),
          if (_summaryMode == _SummaryMode.filtered) ...[
            const SizedBox(height: 4),
            Text(
              '筛选汇总用于观察净变动，不代表真实余额',
              style: GoogleFonts.lato(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatementInput()),
              const SizedBox(width: 12),
              _buildDiscrepancyBadge(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '差异 = 账单期末 - 计算期末',
            style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementInput() {
    return TextField(
      controller: _statementController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: '账单期末余额',
        hintText: '输入银行账单余额',
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        final parsed = _parseAmount(value);
        setState(() {
          _statementBalance = parsed;
          _updateDiscrepancy(_result);
        });
        _persistStatementBalance(parsed);
      },
    );
  }

  Widget _buildDiscrepancyBadge() {
    final hasInput = _statementBalance != null;
    final color = !hasInput
        ? Colors.grey
        : (_discrepancy.abs() < 0.01 ? Colors.green : Colors.redAccent);
    final text = !hasInput
        ? '差异 --'
        : '差异 ${_formatSignedCurrency(_discrepancy)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currency.format(value),
              style: GoogleFonts.rubik(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingToolsBar() {
    final hasSearch = _hasSearchFilters();
    final hasFilters =
        _searchCategoryKey != null ||
        _searchAccountId != null ||
        (_searchTag?.isNotEmpty ?? false);
    final rangeLabel = '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';
    return Material(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: SizedBox(
        height: _floatingBarHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '日期范围 $rangeLabel',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDateRange,
                    style: TextButton.styleFrom(
                      foregroundColor: JiveTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 28),
                      textStyle: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('修改'),
                  ),
                ],
              ),
            ),
            Expanded(
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
                      icon: Icon(
                        Icons.sort,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        return TransactionFilterSheet(
          categories: categories,
          accounts: accounts,
          initialCategoryKey: _searchCategoryKey,
          initialAccountId: _searchAccountId,
          initialTag: _searchTag,
          initialDateRange: _searchDateRange,
          showDateRange: false,
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
    var groupByDay = _groupByDay;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '排列方式',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _ReconcileSortField.values.map((value) {
                        final label = _sortFieldLabel(value);
                        return ChoiceChip(
                          label: Text(label),
                          selected: field == value,
                          selectedColor: JiveTheme.primaryGreen.withValues(alpha: 
                            0.18,
                          ),
                          onSelected: (_) => setModalState(() => field = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '顺序',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _ReconcileSortDirection.values.map((value) {
                        final label = _sortDirectionLabel(value, field);
                        return ChoiceChip(
                          label: Text(label),
                          selected: direction == value,
                          selectedColor: JiveTheme.primaryGreen.withValues(alpha: 
                            0.18,
                          ),
                          onSelected: (_) =>
                              setModalState(() => direction = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '分组',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('按日期分组'),
                      value: groupByDay,
                      onChanged: (value) =>
                          setModalState(() => groupByDay = value),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _sortField = field;
                            _sortDirection = direction;
                            _groupByDay = groupByDay;
                          });
                          await _persistViewPrefs();
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JiveTheme.primaryGreen,
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

  String _sortSummary() {
    final field = _sortFieldLabel(_sortField);
    final direction = _sortDirectionLabel(_sortDirection, _sortField);
    return '$field $direction';
  }

  String _sortFieldLabel(_ReconcileSortField field) {
    switch (field) {
      case _ReconcileSortField.amount:
        return '金额';
      case _ReconcileSortField.category:
        return '分类';
      case _ReconcileSortField.account:
        return '账户';
      case _ReconcileSortField.tag:
        return '标签';
      case _ReconcileSortField.date:
        return '日期';
    }
  }

  String _sortDirectionLabel(
    _ReconcileSortDirection direction,
    _ReconcileSortField field,
  ) {
    if (field == _ReconcileSortField.date) {
      return direction == _ReconcileSortDirection.desc ? '新→旧' : '旧→新';
    }
    if (field == _ReconcileSortField.amount) {
      return direction == _ReconcileSortDirection.desc ? '大→小' : '小→大';
    }
    return direction == _ReconcileSortDirection.desc ? 'Z→A' : 'A→Z';
  }

  Widget _buildDayHeader(_ReconcileDayHeader header) {
    final highlighted = _highlightDays.contains(header.day);
    final dateLabel = _dayFormat.format(header.day);
    final weekdayLabel = _weekdayLabel(header.day);
    final countLabel = '${header.count}笔';
    final incomeLabel = _currency.format(header.income);
    final expenseLabel = _currency.format(header.expense);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Container(
        padding: highlighted
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : EdgeInsets.zero,
        decoration: highlighted
            ? BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$dateLabel $weekdayLabel · $countLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            if (highlighted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '可能差异',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '收 $incomeLabel',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.green.shade600,
                    ),
                  ),
                  TextSpan(
                    text: ' / ',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  TextSpan(
                    text: '支 $expenseLabel',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(_ReconcileGroupHeader header) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Text(
            header.label,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${header.count} 笔',
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(ReconcileEntry entry) {
    final tx = entry.transaction;
    final type = tx.type ?? 'expense';
    final isTransfer = type == 'transfer';
    final isIncome = type == 'income';
    final signed = entry.signedAmount;
    final amountPrefix = signed >= 0 ? '+ ' : '- ';
    final amountColor = isTransfer
        ? Colors.blueGrey
        : (signed >= 0 ? Colors.green : Colors.redAccent);
    final displayAmount = tx.amount.abs();
    final title = isTransfer ? _transferTitle(tx) : _categoryTitle(tx);
    final subtitle = isTransfer ? _transferSubtitle(tx) : _categorySubtitle(tx);
    final timeLabel = _formatTime(tx.timestamp);

    final iconMeta = _buildIconMeta(isTransfer, isIncome);
    return InkWell(
      onTap: () async {
        final changed = await showTransactionDetailSheet(context, tx.id);
        if (changed == true) {
          await _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconMeta.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconMeta.icon, color: iconMeta.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty ? timeLabel : '$subtitle • $timeLabel',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${_currency.format(displayAmount)}',
                  style: GoogleFonts.rubik(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '余额 ${_currency.format(entry.runningBalance)}',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        '暂无对账记录',
        style: GoogleFonts.lato(color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: GoogleFonts.lato(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadData, child: const Text('重试')),
        ],
      ),
    );
  }

  List<_ReconcileListItem> _buildListItems(ReconcileResult result) {
    final items = <_ReconcileListItem>[];
    final entries = _applyListFilters(result.entries);
    if (entries.isEmpty) return items;

    if (_groupByDay) {
      final grouped = <DateTime, List<ReconcileEntry>>{};
      for (final entry in entries) {
        grouped.putIfAbsent(entry.day, () => []).add(entry);
      }
      final days = grouped.keys.toList()
        ..sort((a, b) {
          if (_sortField == _ReconcileSortField.date) {
            final compare = a.compareTo(b);
            return _sortDirection == _ReconcileSortDirection.desc
                ? -compare
                : compare;
          }
          return b.compareTo(a);
        });
      for (final day in days) {
        final dayEntries = grouped[day] ?? const [];
        var income = 0.0;
        var expense = 0.0;
        for (final entry in dayEntries) {
          final type = entry.transaction.type ?? 'expense';
          if (type == 'income') {
            income += entry.transaction.amount.abs();
          } else if (type == 'expense') {
            expense += entry.transaction.amount.abs();
          }
        }
        final sorted = _sortEntries(dayEntries);
        items.add(
          _ReconcileDayHeader(
            day: day,
            count: dayEntries.length,
            income: income,
            expense: expense,
          ),
        );
        items.addAll(sorted.map(_ReconcileEntryItem.new));
      }
      return items;
    }

    if (_sortField == _ReconcileSortField.amount) {
      final sorted = _sortEntries(entries);
      for (final entry in sorted) {
        items.add(_ReconcileEntryItem(entry));
      }
      return items;
    }

    if (_sortField == _ReconcileSortField.date) {
      final sorted = _sortEntries(entries);
      for (final entry in sorted) {
        items.add(_ReconcileEntryItem(entry));
      }
      return items;
    }

    final grouped = <String, List<ReconcileEntry>>{};
    for (final entry in entries) {
      final label = _groupLabel(entry);
      grouped.putIfAbsent(label, () => []).add(entry);
    }
    final labels = grouped.keys.toList();
    labels.sort((a, b) {
      final compare = a.compareTo(b);
      return _sortDirection == _ReconcileSortDirection.desc
          ? -compare
          : compare;
    });
    for (final label in labels) {
      final groupEntries = grouped[label]!;
      groupEntries.sort((a, b) {
        final timeCompare = b.transaction.timestamp.compareTo(
          a.transaction.timestamp,
        );
        if (timeCompare != 0) return timeCompare;
        return b.transaction.id.compareTo(a.transaction.id);
      });
      items.add(
        _ReconcileGroupHeader(label: label, count: groupEntries.length),
      );
      items.addAll(groupEntries.map(_ReconcileEntryItem.new));
    }
    return items;
  }

  List<ReconcileEntry> _applyListFilters(List<ReconcileEntry> entries) {
    final filtered = _applyFilter(entries);
    if (filtered.isEmpty) return const [];
    return _applySearch(filtered);
  }

  List<ReconcileEntry> _applyFilter(List<ReconcileEntry> entries) {
    if (_filter == _ReconcileFilter.all) return entries;
    return entries.where((entry) {
      final type = entry.transaction.type ?? 'expense';
      if (_filter == _ReconcileFilter.income) return type == 'income';
      if (_filter == _ReconcileFilter.expense) return type == 'expense';
      return type == 'transfer';
    }).toList();
  }

  List<ReconcileEntry> _applySearch(List<ReconcileEntry> entries) {
    final query = _searchQuery.trim().toLowerCase();
    final tagQuery = _searchTag?.trim();
    final amountQuery = double.tryParse(query);

    return entries.where((entry) {
      final tx = entry.transaction;

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

      final searchText = _entrySearchText(entry);
      if (searchText.contains(query)) return true;

      if (amountQuery != null) {
        final amountText = tx.amount.toStringAsFixed(2);
        if (amountText.contains(query)) return true;
      }

      return false;
    }).toList();
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

  List<ReconcileEntry> _sortEntries(List<ReconcileEntry> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      int compare;
      switch (_sortField) {
        case _ReconcileSortField.amount:
          compare = a.transaction.amount.compareTo(b.transaction.amount);
          break;
        case _ReconcileSortField.category:
          compare = _categoryGroupLabel(a).compareTo(_categoryGroupLabel(b));
          break;
        case _ReconcileSortField.account:
          compare = _accountGroupLabel(a).compareTo(_accountGroupLabel(b));
          break;
        case _ReconcileSortField.tag:
          compare = _tagGroupLabel(a).compareTo(_tagGroupLabel(b));
          break;
        case _ReconcileSortField.date:
          compare = a.transaction.timestamp.compareTo(b.transaction.timestamp);
          break;
      }
      if (compare == 0) {
        compare = a.transaction.id.compareTo(b.transaction.id);
      }
      return _sortDirection == _ReconcileSortDirection.desc
          ? -compare
          : compare;
    });
    return sorted;
  }

  String _entrySearchText(ReconcileEntry entry) {
    final tx = entry.transaction;
    final category = _categoryTitle(tx);
    final subCategory = _categorySubtitle(tx);
    final account = _resolveAccountName(tx.accountId);
    final counter = _counterAccountName(tx);
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

  String _groupLabel(ReconcileEntry entry) {
    switch (_sortField) {
      case _ReconcileSortField.category:
        return _categoryGroupLabel(entry);
      case _ReconcileSortField.account:
        return _accountGroupLabel(entry);
      case _ReconcileSortField.tag:
        return _tagGroupLabel(entry);
      case _ReconcileSortField.date:
      case _ReconcileSortField.amount:
        return '';
    }
  }

  String _categoryGroupLabel(ReconcileEntry entry) {
    final title = _categoryTitle(entry.transaction).trim();
    return title.isEmpty ? '未分类' : title;
  }

  String _accountGroupLabel(ReconcileEntry entry) {
    final tx = entry.transaction;
    if (tx.type == 'transfer') {
      return _counterAccountName(tx);
    }
    return _resolveAccountName(tx.accountId);
  }

  String _counterAccountName(JiveTransaction tx) {
    if (tx.accountId == widget.accountId) {
      return _resolveAccountName(tx.toAccountId);
    }
    if (tx.toAccountId == widget.accountId) {
      return _resolveAccountName(tx.accountId);
    }
    return _resolveAccountName(tx.accountId);
  }

  String _tagGroupLabel(ReconcileEntry entry) {
    final tags = _extractNoteTags(entry.transaction.note);
    if (tags.isEmpty) return '无标签';
    return tags.first;
  }

  List<String> _extractNoteTags(String? note) {
    final raw = note?.trim() ?? '';
    if (raw.isEmpty) return const [];
    final tokens = raw
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();
    return tokens;
  }

  bool _noteHasTag(String? note, String tag) {
    final raw = note?.trim() ?? '';
    if (raw.isEmpty) return false;
    final pattern = RegExp('(^|\\s)${RegExp.escape(tag)}(?=\\s|\$)');
    return pattern.hasMatch(raw);
  }

  ReconcileSummary _resolveSummary(ReconcileResult result) {
    if (_summaryMode == _SummaryMode.all) {
      return result.summary;
    }
    final filtered = _applyFilter(result.entries);
    return _summaryFromEntries(filtered, result.summary.startBalance);
  }

  ReconcileSummary _summaryFromEntries(
    List<ReconcileEntry> entries,
    double startBalance,
  ) {
    double income = 0;
    double expense = 0;
    double transferIn = 0;
    double transferOut = 0;
    double netChange = 0;
    for (final entry in entries) {
      final type = entry.transaction.type ?? 'expense';
      if (type == 'transfer') {
        if (entry.signedAmount >= 0) {
          transferIn += entry.transaction.amount;
        } else {
          transferOut += entry.transaction.amount;
        }
      } else if (type == 'income') {
        income += entry.transaction.amount;
      } else {
        expense += entry.transaction.amount;
      }
      netChange += entry.signedAmount;
    }
    final endBalance = startBalance + netChange;
    return ReconcileSummary(
      startBalance: startBalance,
      endBalance: endBalance,
      income: income,
      expense: expense,
      transferIn: transferIn,
      transferOut: transferOut,
      netChange: netChange,
    );
  }

  String _summaryTitle() {
    if (_summaryMode == _SummaryMode.filtered) {
      return '期间汇总（筛选）';
    }
    return '期间汇总';
  }

  String _categoryTitle(JiveTransaction tx) {
    return _displayCategoryName(tx.categoryKey, tx.category);
  }

  String _categorySubtitle(JiveTransaction tx) {
    final sub = _displayCategoryName(tx.subCategoryKey, tx.subCategory);
    if (sub == '未分类') {
      return tx.note?.trim() ?? '';
    }
    return sub;
  }

  String _transferTitle(JiveTransaction tx) {
    if (tx.accountId == widget.accountId) return '转出';
    if (tx.toAccountId == widget.accountId) return '转入';
    return '转账';
  }

  String _transferSubtitle(JiveTransaction tx) {
    final fromName = _resolveAccountName(tx.accountId);
    final toName = _resolveAccountName(tx.toAccountId);
    if (tx.accountId == widget.accountId) {
      return toName.isEmpty ? '到其他账户' : '到 $toName';
    }
    if (tx.toAccountId == widget.accountId) {
      return fromName.isEmpty ? '来自其他账户' : '来自 $fromName';
    }
    if (fromName.isEmpty && toName.isEmpty) {
      return '';
    }
    if (fromName.isEmpty) return '到 $toName';
    if (toName.isEmpty) return '来自 $fromName';
    return '$fromName → $toName';
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '未分类';
  }

  String _resolveAccountName(int? accountId) {
    if (accountId == null) return '';
    return _accountById[accountId]?.name ?? '';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  String _formatTime(DateTime time) {
    return '${_dayFormat.format(time)} ${_two(time.hour)}:${_two(time.minute)}';
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

  String _two(int value) {
    return _timeFormat.format(value);
  }

  String _formatSignedCurrency(double value) {
    final prefix = value >= 0 ? '+ ' : '- ';
    return '$prefix${_currency.format(value.abs())}';
  }

  String _formatStatementInput(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceAll(RegExp(r'\.?0+$'), '');
  }

  _IconMeta _buildIconMeta(bool isTransfer, bool isIncome) {
    if (isTransfer) {
      return _IconMeta(
        icon: Icons.swap_horiz,
        color: Colors.blueGrey,
        background: Colors.blueGrey.shade50,
      );
    }
    if (isIncome) {
      return _IconMeta(
        icon: Icons.arrow_downward,
        color: Colors.green,
        background: Colors.green.shade50,
      );
    }
    return _IconMeta(
      icon: Icons.arrow_upward,
      color: Colors.redAccent,
      background: Colors.red.shade50,
    );
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  void _applyQuickRange(_QuickRange range) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (range) {
      case _QuickRange.currentMonth:
        start = DateTime(now.year, now.month, 1);
        end = _endOfDay(now);
        break;
      case _QuickRange.lastMonth:
        final thisMonth = DateTime(now.year, now.month, 1);
        final lastMonth = DateTime(thisMonth.year, thisMonth.month - 1, 1);
        start = lastMonth;
        end = thisMonth.subtract(const Duration(milliseconds: 1));
        break;
      case _QuickRange.last7Days:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        end = _endOfDay(now);
        break;
      case _QuickRange.debugSeed:
        _seedTestData();
        return;
    }
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _loadData();
  }

  double? _parseAmount(String raw) {
    final cleaned = raw
        .replaceAll(',', '')
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<double?> _loadStatementBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_statementKey());
    if (stored == null || stored.isEmpty) return null;
    return double.tryParse(stored);
  }

  Future<void> _persistStatementBalance(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _statementKey();
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value.toString());
  }

  Future<void> _loadViewPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedFilter = prefs.getString(_filterKey());
    final storedSummary = prefs.getString(_summaryKey());
    final storedSort = prefs.getString(_sortKey());
    final storedDirection = prefs.getString(_sortDirectionKey());
    final storedGrouping = prefs.getBool(_groupByDayKey());
    if (storedFilter != null) {
      _filter = _ReconcileFilter.values.firstWhere(
        (value) => value.name == storedFilter,
        orElse: () => _ReconcileFilter.all,
      );
    }
    if (storedSummary != null) {
      _summaryMode = _SummaryMode.values.firstWhere(
        (value) => value.name == storedSummary,
        orElse: () => _SummaryMode.all,
      );
    }
    if (storedSort != null) {
      _sortField = _ReconcileSortField.values.firstWhere(
        (value) => value.name == storedSort,
        orElse: () => _ReconcileSortField.date,
      );
    }
    if (storedDirection != null) {
      _sortDirection = _ReconcileSortDirection.values.firstWhere(
        (value) => value.name == storedDirection,
        orElse: () => _ReconcileSortDirection.desc,
      );
    }
    if (storedGrouping != null) {
      _groupByDay = storedGrouping;
    }
  }

  Future<void> _persistViewPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_filterKey(), _filter.name);
    await prefs.setString(_summaryKey(), _summaryMode.name);
    await prefs.setString(_sortKey(), _sortField.name);
    await prefs.setString(_sortDirectionKey(), _sortDirection.name);
    await prefs.setBool(_groupByDayKey(), _groupByDay);
  }

  String _statementKey() {
    return 'reconcile_statement_v1_${widget.accountId}_${_formatKeyDate(_startDate)}_${_formatKeyDate(_endDate)}';
  }

  String _filterKey() {
    return 'reconcile_filter_v1_${widget.accountId}';
  }

  String _summaryKey() {
    return 'reconcile_summary_v1_${widget.accountId}';
  }

  String _sortKey() {
    return 'reconcile_sort_v1_${widget.accountId}';
  }

  String _sortDirectionKey() {
    return 'reconcile_sort_dir_v1_${widget.accountId}';
  }

  String _groupByDayKey() {
    return 'reconcile_group_by_day_v1_${widget.accountId}';
  }

  String _formatKeyDate(DateTime date) {
    return '${date.year}${_two(date.month)}${_two(date.day)}';
  }

  void _updateDiscrepancy(ReconcileResult? result) {
    if (result == null || _statementBalance == null) {
      _discrepancy = 0;
      _highlightDays = {};
      return;
    }
    final discrepancy = _statementBalance! - result.summary.endBalance;
    _discrepancy = discrepancy;
    _highlightDays = _pickHighlightDays(result.dayNetChanges, discrepancy);
  }

  Set<DateTime> _pickHighlightDays(
    Map<DateTime, double> dayNetChanges,
    double discrepancy,
  ) {
    if (discrepancy.abs() < 0.01 || dayNetChanges.isEmpty) {
      return {};
    }
    final entries = dayNetChanges.entries.toList();
    entries.sort((a, b) {
      final diffA = (a.value - discrepancy).abs();
      final diffB = (b.value - discrepancy).abs();
      return diffA.compareTo(diffB);
    });
    final count = entries.length < 3 ? entries.length : 3;
    return entries.take(count).map((entry) => entry.key).toSet();
  }
}

enum _QuickRange { currentMonth, lastMonth, last7Days, debugSeed }

enum _ReconcileFilter { all, income, expense, transfer }

enum _SummaryMode { all, filtered }

class _IconMeta {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconMeta({
    required this.icon,
    required this.color,
    required this.background,
  });
}

abstract class _ReconcileListItem {
  const _ReconcileListItem();
}

class _ReconcileDayHeader extends _ReconcileListItem {
  final DateTime day;
  final int count;
  final double income;
  final double expense;

  const _ReconcileDayHeader({
    required this.day,
    required this.count,
    required this.income,
    required this.expense,
  });
}

class _ReconcileEntryItem extends _ReconcileListItem {
  final ReconcileEntry entry;

  const _ReconcileEntryItem(this.entry);
}

class _ReconcileGroupHeader extends _ReconcileListItem {
  final String label;
  final int count;

  const _ReconcileGroupHeader({required this.label, required this.count});
}

enum _ReconcileSortField { date, amount, category, account, tag }

enum _ReconcileSortDirection { desc, asc }
