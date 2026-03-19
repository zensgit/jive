import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/budget_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/model/transaction_list_filter_state.dart';
import '../../core/service/budget_pref_service.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../category/category_picker_screen.dart';
import '../category/category_search_delegate.dart';
import '../category/category_transactions_screen.dart';
import 'budget_exclude_screen.dart';
import 'budget_list_screen.dart';
import 'budget_settings_screen.dart';

/// yimu-like monthly budget manager:
/// - Monthly total budget dashboard card
/// - Monthly spending/remaining trend chart
/// - Category budgets list with drag reorder
class BudgetManagerDebugData {
  final BudgetSummary totalSummary;
  final String? currency;
  final DateTime? month;
  final BudgetPacingInsight? totalPacingInsight;
  final List<BudgetCategoryContribution> totalTopCategories;
  final List<BudgetSpendingAnomalyDay> totalAnomalyDays;
  final Map<String, JiveCategory> categoryByKey;

  const BudgetManagerDebugData({
    required this.totalSummary,
    this.currency,
    this.month,
    this.totalPacingInsight,
    this.totalTopCategories = const [],
    this.totalAnomalyDays = const [],
    this.categoryByKey = const {},
  });
}

class BudgetManagerScreen extends StatefulWidget {
  final BudgetManagerDebugData? debugData;

  const BudgetManagerScreen({super.key, this.debugData});

  @override
  State<BudgetManagerScreen> createState() => _BudgetManagerScreenState();
}

class _BudgetManagerScreenState extends State<BudgetManagerScreen> {
  static const Duration _loadTimeout = Duration(seconds: 12);

  bool _isLoading = true;
  String? _loadErrorMessage;

  BudgetService? _budgetService;
  Isar? _isar;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _currency;

  bool _pullToExcludeEnabled = true;
  bool _autoCopyEnabled = true;
  bool _carryoverAddEnabled = false;
  bool _carryoverReduceEnabled = false;

  JiveBudget? _totalBudget; // persisted total budget for this month/currency
  BudgetSummary? _totalSummary;
  BudgetPacingInsight? _totalPacingInsight;
  List<BudgetCategoryContribution> _totalTopCategories = const [];
  List<BudgetSpendingAnomalyDay> _totalAnomalyDays = const [];
  List<BudgetDailySpending> _totalDaily = const [];

  List<BudgetSummary> _categorySummaries = const [];
  Map<String, JiveCategory> _categoryByKey = const {};

  @override
  void initState() {
    super.initState();
    if (widget.debugData != null) {
      final debug = widget.debugData!;
      _totalSummary = debug.totalSummary;
      _totalBudget = debug.totalSummary.budget;
      _currency = debug.currency ?? debug.totalSummary.budget.currency;
      _month =
          debug.month ??
          DateTime(
            debug.totalSummary.budget.startDate.year,
            debug.totalSummary.budget.startDate.month,
            1,
          );
      _totalPacingInsight = debug.totalPacingInsight;
      _totalTopCategories = debug.totalTopCategories;
      _totalAnomalyDays = debug.totalAnomalyDays;
      _categoryByKey = debug.categoryByKey;
      _isLoading = false;
      return;
    }
    _loadPrefs().then((_) => _loadData());
  }

  Future<void> _loadPrefs() async {
    final pullEnabled = await BudgetPrefService.getBudgetPullToExcludeEnabled();
    final autoCopy = await BudgetPrefService.getBudgetMonthlyAutoCopyEnabled();
    final carryAdd = await BudgetPrefService.getBudgetCarryoverAddEnabled();
    final carryReduce =
        await BudgetPrefService.getBudgetCarryoverReduceEnabled();
    if (!mounted) return;
    setState(() {
      _pullToExcludeEnabled = pullEnabled;
      _autoCopyEnabled = autoCopy;
      _carryoverAddEnabled = carryAdd;
      _carryoverReduceEnabled = carryReduce;
    });
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
      });
    }

    try {
      final result = await _loadDataInternal().timeout(
        _loadTimeout,
        onTimeout: () => throw TimeoutException('预算数据加载超时'),
      );
      if (!mounted) return;
      setState(() {
        _budgetService = result.budgetService;
        _totalBudget = result.totalBudget;
        _totalSummary = result.totalSummary;
        _totalPacingInsight = result.totalPacingInsight;
        _totalTopCategories = result.totalTopCategories;
        _totalAnomalyDays = result.totalAnomalyDays;
        _totalDaily = result.totalDaily;
        _categorySummaries = result.categorySummaries;
        _categoryByKey = result.categoryByKey;
        _currency = result.currency;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = '预算加载超时，请稍后重试或清理测试数据';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = '加载预算失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<_BudgetManagerLoadResult> _loadDataInternal() async {
    final isar = await _ensureIsar();
    final currencyService = CurrencyService(isar);
    final budgetService = BudgetService(isar, currencyService);

    final baseCurrency = await currencyService.getBaseCurrency();
    final selectedCurrency = _currency ?? baseCurrency;

    final (start, end) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: _month,
    );

    final now = DateTime.now();
    final isCurrentMonth = start.year == now.year && start.month == now.month;
    if (_autoCopyEnabled && isCurrentMonth) {
      await budgetService.autoCopyMonthlyBudgetsIfEmpty(
        referenceMonth: start,
        carryoverAddEnabled: _carryoverAddEnabled,
        carryoverReduceEnabled: _carryoverReduceEnabled,
      );
    }

    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryByKey = {for (final c in categories) c.key: c};

    final budgets = await _loadMonthlyBudgets(
      isar,
      currency: selectedCurrency,
      startDate: start,
      endDate: end,
    );

    final totalBudget = budgets.firstWhere(
      (b) => b.categoryKey == null || b.categoryKey!.isEmpty,
      orElse: () => _virtualTotalBudget(
        currency: selectedCurrency,
        startDate: start,
        endDate: end,
      ),
    );

    final totalSummary = await budgetService.calculateBudgetUsage(totalBudget);
    final totalDays = _totalDaysInclusive(start, end);
    final insightRef = _insightReferenceDate(start, end);
    final totalDaily = await budgetService.getBudgetDailySpendingTrend(
      totalBudget,
      days: totalDays,
      referenceDate: end,
    );
    final totalPacingInsight = budgetService.buildBudgetPacingInsight(
      totalSummary,
      referenceDate: insightRef,
    );
    final totalTopCategories = await budgetService
        .getBudgetCategoryContributions(
          totalBudget,
          referenceDate: insightRef,
          limit: 4,
        );
    final totalAnomalyDays = budgetService
        .detectBudgetSpendingAnomaliesFromDaily(
          totalDaily,
          effectiveAmount: totalSummary.effectiveAmount,
          periodStart: start,
          periodEnd: end,
          referenceDate: insightRef,
          limit: 2,
        );

    final categoryBudgets = budgets
        .where((b) => b.categoryKey != null && b.categoryKey!.isNotEmpty)
        .toList();
    categoryBudgets.sort((a, b) {
      final weight = b.positionWeight.compareTo(a.positionWeight);
      if (weight != 0) return weight;
      final aName = categoryByKey[a.categoryKey!]?.name ?? a.name;
      final bName = categoryByKey[b.categoryKey!]?.name ?? b.name;
      return CategoryService.compareCategoryName(aName, bName);
    });

    final categorySummaries = <BudgetSummary>[];
    for (final b in categoryBudgets) {
      categorySummaries.add(await budgetService.calculateBudgetUsage(b));
    }

    return _BudgetManagerLoadResult(
      isar: isar,
      budgetService: budgetService,
      currency: selectedCurrency,
      totalBudget:
          totalBudget.categoryKey == null || totalBudget.categoryKey!.isEmpty
          ? (totalBudget.id == 0 ? null : totalBudget)
          : null,
      totalSummary: totalSummary,
      totalPacingInsight: totalPacingInsight,
      totalTopCategories: totalTopCategories,
      totalAnomalyDays: totalAnomalyDays,
      totalDaily: totalDaily,
      categorySummaries: categorySummaries,
      categoryByKey: categoryByKey,
    );
  }

  JiveBudget _virtualTotalBudget({
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return JiveBudget()
      ..name = '总预算'
      ..amount = 0
      ..currency = currency
      ..categoryKey = null
      ..startDate = startDate
      ..endDate = endDate
      ..period = BudgetPeriod.monthly.value
      ..isActive = true
      ..alertEnabled = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }

  Future<List<JiveBudget>> _loadMonthlyBudgets(
    Isar isar, {
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final startDayEnd = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      23,
      59,
      59,
      999,
    );
    final endDayStart = DateTime(endDate.year, endDate.month, endDate.day);
    final endDayEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    return await isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .periodEqualTo(BudgetPeriod.monthly.value)
        .currencyEqualTo(currency)
        .startDateBetween(startDay, startDayEnd)
        .endDateBetween(endDayStart, endDayEnd)
        .findAll();
  }

  Future<void> _openBudgetExclude() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const BudgetExcludeScreen()),
    );
    await _loadPrefs();
    await _loadData();
  }

  Future<void> _pullToOpenBudgetExclude() async {
    unawaited(_openBudgetExclude());
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const BudgetSettingsScreen()),
    );
    await _loadPrefs();
    await _loadData();
  }

  Future<void> _openAllBudgets() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const BudgetListScreen()),
    );
    await _loadData();
  }

  Future<void> _pickMonth() async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _MonthPickerSheet(
        initialMonth: _month,
        onPick: (m) => Navigator.pop(sheetContext, m),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _month = DateTime(selected.year, selected.month, 1));
    await _loadData();
  }

  String _formatMonth(DateTime month) {
    return '${month.month}月, ${month.year}年';
  }

  Map<String, dynamic> _currencyData(String code) {
    return CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'code': code, 'symbol': code},
    );
  }

  int _totalDaysInclusive(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final diff = endDay.difference(startDay).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  int _daysElapsedInclusive(DateTime start, DateTime end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (today.isBefore(startDay)) return 0;
    final effectiveEnd = today.isAfter(endDay) ? endDay : today;
    return effectiveEnd.difference(startDay).inDays + 1;
  }

  DateTime _insightReferenceDate(DateTime start, DateTime end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (today.isBefore(startDay)) {
      // Keep elapsed days as 0 for future periods.
      return startDay.subtract(const Duration(days: 1));
    }
    if (today.isAfter(endDay)) return endDay;
    return today;
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\\d)(?=(\\d{3})+\\.)'),
          (match) => '${match[1]},',
        );
  }

  String _formatSignedAmount(double amount) {
    final abs = _formatAmount(amount.abs());
    if (amount > 0.004) return '+$abs';
    if (amount < -0.004) return '-$abs';
    return '0.00';
  }

  String _displayCategoryName(String categoryKey) {
    if (categoryKey == '__uncategorized__') return '未分类';
    return _categoryByKey[categoryKey]?.name ?? categoryKey;
  }

  DateTimeRange _insightDateRange() {
    final (start, end) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: _month,
    );
    final ref = _insightReferenceDate(start, end);
    final endDay = ref.isBefore(start) ? start : ref;
    final startDay = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(
      endDay.year,
      endDay.month,
      endDay.day,
      23,
      59,
      59,
      999,
    );
    return DateTimeRange(start: startDay, end: rangeEnd);
  }

  Future<void> _openContributionTransactions(
    BudgetCategoryContribution item,
  ) async {
    if (item.categoryKey == '__uncategorized__') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未分类暂不支持快捷钻取')));
      return;
    }

    String? categoryKey;
    String? subCategoryKey;
    var includeSubCategories = true;
    final category = _categoryByKey[item.categoryKey];
    final parentKey = category?.parentKey?.trim();
    if (parentKey != null && parentKey.isNotEmpty) {
      categoryKey = parentKey;
      subCategoryKey = item.categoryKey;
      includeSubCategories = false;
    } else {
      categoryKey = item.categoryKey;
    }

    final range = _insightDateRange();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryTransactionsScreen(
          title: '账单 · ${_displayCategoryName(item.categoryKey)}',
          filterCategoryKey: categoryKey,
          filterSubCategoryKey: subCategoryKey,
          includeSubCategories: includeSubCategories,
          initialFilterState: TransactionListFilterState(dateRange: range),
          persistFilterState: false,
        ),
      ),
    );
  }

  Future<void> _openAnomalyDayTransactions(
    BudgetSpendingAnomalyDay item,
  ) async {
    final day = DateTime(item.day.year, item.day.month, item.day.day);
    final range = DateTimeRange(
      start: day,
      end: DateTime(day.year, day.month, day.day, 23, 59, 59, 999),
    );
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryTransactionsScreen(
          title: '账单 · 异常日 ${DateFormat('M/d').format(day)}',
          initialFilterState: TransactionListFilterState(dateRange: range),
          persistFilterState: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthText = _formatMonth(_month);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('预算管理'),
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(monthText),
          ),
          PopupMenuButton<_BudgetManagerMenuAction>(
            tooltip: '更多',
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _BudgetManagerMenuAction.allBudgets,
                child: Text('全部预算'),
              ),
              PopupMenuItem(
                value: _BudgetManagerMenuAction.exclude,
                child: Text('预算排除'),
              ),
              PopupMenuItem(
                value: _BudgetManagerMenuAction.settings,
                child: Text('预算设置'),
              ),
            ],
            onSelected: (action) async {
              switch (action) {
                case _BudgetManagerMenuAction.allBudgets:
                  await _openAllBudgets();
                case _BudgetManagerMenuAction.exclude:
                  await _openBudgetExclude();
                case _BudgetManagerMenuAction.settings:
                  await _openSettings();
              }
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadErrorMessage != null
          ? _buildLoadErrorState()
          : Builder(
              builder: (context) {
                final summary = _totalSummary;
                if (summary == null ||
                    (_budgetService == null && widget.debugData == null)) {
                  return _buildLoadErrorState(
                    title: '预算服务尚未准备好',
                    message: '请稍后重试',
                  );
                }

                final list = CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _buildTotalBudgetCard(summary),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _buildTrendCard(summary),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _buildAddCategoryBudgetButton(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '分类预算',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '长按拖动排序',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_categorySummaries.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: _buildEmptyCategoryBudgets(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverReorderableList(
                          itemCount: _categorySummaries.length,
                          itemBuilder: (context, index) {
                            final item = _categorySummaries[index];
                            return _buildCategoryBudgetTile(
                              key: ValueKey(item.budget.id),
                              index: index,
                              summary: item,
                            );
                          },
                          onReorder: _onReorderCategoryBudgets,
                        ),
                      ),
                  ],
                );

                if (!_pullToExcludeEnabled) return list;
                return RefreshIndicator(
                  onRefresh: _pullToOpenBudgetExclude,
                  child: list,
                );
              },
            ),
    );
  }

  Widget _buildLoadErrorState({String? title, String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              title ?? '预算加载失败',
              style: GoogleFonts.lato(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? _loadErrorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: JiveTheme.secondaryTextColor(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBudgetCard(BudgetSummary summary) {
    final budget = summary.budget;
    final currency = _currency ?? budget.currency;
    final currencyData = _currencyData(currency);
    final symbol = currencyData['symbol'] as String;

    final totalDays = _totalDaysInclusive(budget.startDate, budget.endDate);
    final daysElapsed = _daysElapsedInclusive(budget.startDate, budget.endDate);
    final dayAvg = daysElapsed > 0 ? summary.usedAmount / daysElapsed : 0.0;
    final dailyBudget = totalDays > 0
        ? summary.effectiveAmount / totalDays
        : 0.0;
    final allowedSoFar = dailyBudget * daysElapsed;
    final todayRemain = allowedSoFar - summary.usedAmount;

    final statusColor = switch (summary.status) {
      BudgetStatus.exceeded => Colors.red,
      BudgetStatus.warning => Colors.orange,
      BudgetStatus.normal => JiveTheme.primaryGreen,
    };

    final directAmount = budget.amount + budget.carryoverAmount;
    final hasManualTotal = budget.amount > 0 || budget.carryoverAmount != 0;
    final showEffectiveHint =
        hasManualTotal && (summary.effectiveAmount - directAmount).abs() > 0.01;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '总预算',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '编辑总预算',
                  onPressed: _editTotalBudget,
                  icon: const Icon(Icons.edit, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                ),
                const Spacer(),
                Text(
                  '剩余：$symbol ${_formatAmount(summary.remainingAmount)}',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: summary.remainingAmount < 0
                        ? Colors.red
                        : Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              '$symbol ${_formatAmount(summary.effectiveAmount)}',
              style: GoogleFonts.rubik(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            if (showEffectiveHint)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '手动预算：$symbol ${_formatAmount(directAmount)}（分类合计更高时按合计计算）',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (summary.usedPercent / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    '支出',
                    '$symbol ${_formatAmount(summary.usedAmount)}',
                  ),
                ),
                Expanded(
                  child: _metric('日均', '$symbol ${_formatAmount(dayAvg)}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    '日预算',
                    '$symbol ${_formatAmount(dailyBudget)}',
                  ),
                ),
                Expanded(
                  child: _metric(
                    '今日剩余',
                    '$symbol ${_formatAmount(todayRemain)}',
                    valueColor: todayRemain < 0 ? Colors.red : Colors.black87,
                  ),
                ),
              ],
            ),
            if (_totalPacingInsight != null) ...[
              const SizedBox(height: 12),
              _buildPacingInsightSection(
                insight: _totalPacingInsight!,
                symbol: symbol,
              ),
            ],
            if (_totalTopCategories.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildTopCategorySection(symbol: symbol),
            ],
            if (_totalAnomalyDays.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildAnomalyDaysSection(symbol: symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPacingInsightSection({
    required BudgetPacingInsight insight,
    required String symbol,
  }) {
    final headlineColor = switch (insight.projectedStatus) {
      BudgetStatus.exceeded => Colors.red.shade700,
      BudgetStatus.warning => Colors.orange.shade700,
      BudgetStatus.normal => Colors.grey.shade700,
    };

    final headline = insight.elapsedDays == 0
        ? '周期未开始，建议日预算 $symbol ${_formatAmount(insight.suggestedDailyLimit)}'
        : switch (insight.projectedStatus) {
            BudgetStatus.exceeded =>
              '按当前节奏预计超支 $symbol ${_formatAmount(insight.projectedRemainingAmount.abs())}',
            BudgetStatus.warning =>
              '按当前节奏预计触发预警（${insight.projectedUsedPercent.toStringAsFixed(1)}%）',
            BudgetStatus.normal =>
              '按当前节奏预计月末剩余 $symbol ${_formatAmount(insight.projectedRemainingAmount)}',
          };

    final paceColor = insight.paceDelta > 0
        ? Colors.red.shade700
        : JiveTheme.primaryGreen;
    final suggestedColor = insight.suggestedDailyLimit < 0
        ? Colors.red.shade700
        : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: headlineColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _metric(
                  '进度偏差',
                  '$symbol ${_formatSignedAmount(insight.paceDelta)}',
                  valueColor: paceColor,
                ),
              ),
              Expanded(
                child: _metric(
                  '建议日均',
                  '$symbol ${_formatAmount(insight.suggestedDailyLimit)}',
                  valueColor: suggestedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategorySection({required String symbol}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分类支出贡献 Top${_totalTopCategories.length}',
            style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._totalTopCategories.map((item) {
            final isDrillDownEnabled = item.categoryKey != '__uncategorized__';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('budget_top_category_${item.categoryKey}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openContributionTransactions(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayCategoryName(item.categoryKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$symbol ${_formatAmount(item.amount)} (${item.ratioPercent.toStringAsFixed(1)}%)',
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (isDrillDownEnabled) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnomalyDaysSection({required String symbol}) {
    final dateFormat = DateFormat('M/d');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '异常支出日',
            style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ..._totalAnomalyDays.map((item) {
            final dayKey = DateFormat('yyyyMMdd').format(item.day);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('budget_anomaly_day_$dayKey'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openAnomalyDayTransactions(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${dateFormat.format(item.day)} 支出 $symbol ${_formatAmount(item.amount)}（阈值 $symbol ${_formatAmount(item.thresholdAmount)}）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          '$label：',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rubik(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard(BudgetSummary summary) {
    final currency = _currency ?? summary.budget.currency;
    final currencyData = _currencyData(currency);
    final symbol = currencyData['symbol'] as String;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '预算趋势',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _legend(color: Colors.red.shade400, label: '支出'),
                const SizedBox(width: 12),
                _legend(color: JiveTheme.primaryGreen, label: '剩余'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: _buildMonthlyTrendChart(
                daily: _totalDaily,
                effectiveAmount: summary.effectiveAmount,
                symbol: symbol,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendChart({
    required List<BudgetDailySpending> daily,
    required double effectiveAmount,
    required String symbol,
  }) {
    if (daily.isEmpty) {
      return Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final cumulative = <BudgetDailySpending>[];
    var sum = 0.0;
    for (final e in daily) {
      sum += e.amount;
      cumulative.add(BudgetDailySpending(day: e.day, amount: sum));
    }

    final remain = cumulative
        .map(
          (e) => BudgetDailySpending(
            day: e.day,
            amount: (effectiveAmount - e.amount) < 0
                ? 0
                : (effectiveAmount - e.amount),
          ),
        )
        .toList();

    final spendSpots = <FlSpot>[];
    final remainSpots = <FlSpot>[];
    var maxY = effectiveAmount;
    for (var i = 0; i < cumulative.length; i++) {
      final spend = cumulative[i].amount;
      final rem = remain[i].amount;
      spendSpots.add(FlSpot(i.toDouble(), spend));
      remainSpots.add(FlSpot(i.toDouble(), rem));
      if (spend > maxY) maxY = spend;
      if (rem > maxY) maxY = rem;
    }
    final yInterval = maxY > 0 ? (maxY / 4).ceilToDouble() : 100.0;
    final dateFormat = DateFormat('d');

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval > 0 ? yInterval : 100,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval > 0 ? yInterval : 100,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                final display = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(1)}k'
                    : value.toInt().toString();
                return Text(
                  display,
                  style: GoogleFonts.lato(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: daily.length > 20 ? 5 : (daily.length > 12 ? 3 : 1),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= daily.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dateFormat.format(daily[index].day),
                    style: GoogleFonts.lato(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (daily.length - 1).toDouble(),
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.08 : 100,
        lineBarsData: [
          LineChartBarData(
            spots: spendSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: Colors.red.shade400,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.shade400.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: remainSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: JiveTheme.primaryGreen,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return const [];
              final index = touchedSpots.first.x.toInt();
              if (index < 0 || index >= cumulative.length) {
                return const [];
              }
              final spend = cumulative[index];
              final rem = remain[index];
              final text = StringBuffer()
                ..write(DateFormat('M/d').format(spend.day))
                ..write('\n支出  $symbol ${_formatAmount(spend.amount)}')
                ..write('\n剩余  $symbol ${_formatAmount(rem.amount)}');
              return [
                LineTooltipItem(
                  text.toString(),
                  GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryBudgetButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _addCategoryBudget,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Colors.black87),
            const SizedBox(width: 10),
            Text(
              '添加分类预算',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: '说明',
              onPressed: _showCategoryBudgetTip,
              icon: const Icon(
                Icons.help_outline,
                size: 20,
                color: Colors.black45,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBudgetTip() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('分类预算说明'),
        content: const Text(
          '分类预算用于控制某一类支出。\n'
          '当“总预算(手动)”小于等于分类预算合计时，总预算仅统计已设置预算的分类支出。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategoryBudgets() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.pie_chart_outline, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '你还没有任何分类预算',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(onPressed: _addCategoryBudget, child: const Text('创建预算')),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetTile({
    required Key key,
    required int index,
    required BudgetSummary summary,
  }) {
    final budget = summary.budget;
    final categoryKey = budget.categoryKey;
    final category = categoryKey == null ? null : _categoryByKey[categoryKey];
    final name = category?.name ?? budget.name;

    final currencyData = _currencyData(budget.currency);
    final symbol = currencyData['symbol'] as String;

    final percent = (summary.usedPercent / 100).clamp(0.0, 1.0);
    final statusColor = switch (summary.status) {
      BudgetStatus.exceeded => Colors.red,
      BudgetStatus.warning => Colors.orange,
      BudgetStatus.normal => JiveTheme.primaryGreen,
    };

    final iconName = category?.iconName ?? 'category';
    final iconColor =
        CategoryService.parseColorHex(category?.colorHex) ??
        JiveTheme.categoryIconInactive;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editCategoryBudget(summary),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: iconColor.withValues(alpha: 0.12),
                    child: CategoryService.buildIcon(
                      iconName,
                      size: 18,
                      color: iconColor,
                      isSystemCategory: category?.isSystem,
                      forceTinted: category?.iconForceTinted ?? false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '更多',
                    onPressed: () => _showCategoryBudgetActions(summary),
                    icon: const Icon(Icons.more_horiz),
                    visualDensity: VisualDensity.compact,
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '支出：$symbol ${_formatAmount(summary.usedAmount)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Text(
                    '$symbol ${_formatAmount(summary.usedAmount)} / ${_formatAmount(summary.effectiveAmount)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onReorderCategoryBudgets(int oldIndex, int newIndex) async {
    if (_budgetService == null) return;
    setState(() {
      final list = List<BudgetSummary>.from(_categorySummaries);
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = list.removeAt(oldIndex);
      list.insert(newIndex, moved);
      _categorySummaries = list;
    });
    try {
      final budgets = _categorySummaries.map((e) => e.budget).toList();
      await _budgetService!.updateBudgetOrder(budgets);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('排序保存失败：$e')));
      await _loadData();
    }
  }

  Future<void> _editTotalBudget() async {
    if (_budgetService == null) return;
    final currency = _currency ?? 'CNY';
    final (start, end) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: _month,
    );
    final existing = _totalBudget;

    final amount = await _promptAmount(
      title: '设置总预算',
      initial: existing?.amount ?? 0,
      currency: currency,
    );
    if (amount == null) return;

    try {
      if (existing == null) {
        await _budgetService!.createBudget(
          name: '总预算',
          amount: amount,
          currency: currency,
          categoryKey: null,
          startDate: start,
          endDate: end,
          period: BudgetPeriod.monthly.value,
          alertEnabled: true,
          alertThreshold: 80,
        );
      } else {
        existing
          ..name = existing.name.isEmpty ? '总预算' : existing.name
          ..amount = amount
          ..currency = currency
          ..startDate = start
          ..endDate = end
          ..period = BudgetPeriod.monthly.value;
        await _budgetService!.updateBudget(existing);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  Future<void> _addCategoryBudget() async {
    if (_budgetService == null) return;
    final isar = await _ensureIsar();
    if (!mounted) return;

    final onlyUserCategories = _categoryByKey.values.any(
      (c) => !c.isIncome && !c.isSystem,
    );
    final picked = await Navigator.push<CategorySearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPickerScreen(
          isIncome: false,
          onlyUserCategories: onlyUserCategories,
          isar: isar,
          title: '选择分类',
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final selectedCategory = picked.sub ?? picked.parent;

    final currency = _currency ?? 'CNY';
    final amount = await _promptAmount(
      title: '设置分类预算 · ${selectedCategory.name}',
      initial: 0,
      currency: currency,
    );
    if (amount == null) return;

    final (start, end) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: _month,
    );
    final nextWeight =
        (_categorySummaries.isEmpty
            ? 0
            : _categorySummaries
                  .map((e) => e.budget.positionWeight)
                  .reduce((a, b) => a > b ? a : b)) +
        1;

    try {
      await _budgetService!.createBudget(
        name: selectedCategory.name,
        amount: amount,
        currency: currency,
        categoryKey: selectedCategory.key,
        startDate: start,
        endDate: end,
        period: BudgetPeriod.monthly.value,
        positionWeight: nextWeight,
        alertEnabled: true,
        alertThreshold: 80,
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  Future<void> _editCategoryBudget(BudgetSummary summary) async {
    await _showCategoryBudgetActions(summary);
  }

  Future<void> _showCategoryBudgetActions(BudgetSummary summary) async {
    final action = await showModalBottomSheet<_CategoryBudgetAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑金额'),
              onTap: () => Navigator.pop(ctx, _CategoryBudgetAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除预算', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, _CategoryBudgetAction.delete),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;
    switch (action) {
      case _CategoryBudgetAction.edit:
        await _editCategoryBudgetAmount(summary);
      case _CategoryBudgetAction.delete:
        await _deleteBudget(summary.budget);
    }
  }

  Future<void> _editCategoryBudgetAmount(BudgetSummary summary) async {
    if (_budgetService == null) return;
    final budget = summary.budget;
    final amount = await _promptAmount(
      title: '编辑分类预算',
      initial: budget.amount,
      currency: budget.currency,
    );
    if (amount == null) return;
    try {
      budget.amount = amount;
      await _budgetService!.updateBudget(budget);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }

  Future<void> _deleteBudget(JiveBudget budget) async {
    if (_budgetService == null) return;
    try {
      await _budgetService!.deleteBudget(budget.id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  Future<double?> _promptAmount({
    required String title,
    required double initial,
    required String currency,
  }) async {
    final currencyData = _currencyData(currency);
    final symbol = currencyData['symbol'] as String;
    final controller = TextEditingController(
      text: initial <= 0 ? '' : _formatAmount(initial).replaceAll(',', ''),
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: '$symbol ',
                labelText: '金额',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(controller.text.trim()) ?? 0;
                  if (value <= 0) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
                    return;
                  }
                  Navigator.pop(ctx, value);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: JiveTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
    return result;
  }
}

class _BudgetManagerLoadResult {
  final Isar isar;
  final BudgetService budgetService;
  final String currency;
  final JiveBudget? totalBudget;
  final BudgetSummary totalSummary;
  final BudgetPacingInsight totalPacingInsight;
  final List<BudgetCategoryContribution> totalTopCategories;
  final List<BudgetSpendingAnomalyDay> totalAnomalyDays;
  final List<BudgetDailySpending> totalDaily;
  final List<BudgetSummary> categorySummaries;
  final Map<String, JiveCategory> categoryByKey;

  const _BudgetManagerLoadResult({
    required this.isar,
    required this.budgetService,
    required this.currency,
    required this.totalBudget,
    required this.totalSummary,
    required this.totalPacingInsight,
    required this.totalTopCategories,
    required this.totalAnomalyDays,
    required this.totalDaily,
    required this.categorySummaries,
    required this.categoryByKey,
  });
}

enum _BudgetManagerMenuAction { allBudgets, exclude, settings }

enum _CategoryBudgetAction { edit, delete }

class _MonthPickerSheet extends StatelessWidget {
  final DateTime initialMonth;
  final ValueChanged<DateTime> onPick;

  const _MonthPickerSheet({required this.initialMonth, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final base = DateTime(initialMonth.year, initialMonth.month, 1);
    final months = <DateTime>[];
    for (var offset = -12; offset <= 12; offset++) {
      months.add(DateTime(base.year, base.month + offset, 1));
    }
    months.sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '选择月份',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: months.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = months[index];
                  final isSelected =
                      m.year == initialMonth.year &&
                      m.month == initialMonth.month;
                  final label = '${m.year}年${m.month}月';
                  return ListTile(
                    title: Text(label),
                    trailing: isSelected
                        ? Icon(Icons.check, color: JiveTheme.primaryGreen)
                        : null,
                    onTap: () => onPick(m),
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
