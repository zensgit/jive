import 'dart:math' as math;

import 'package:isar/isar.dart';

import '../database/category_model.dart';
import '../database/transaction_model.dart';
import 'account_service.dart';
import 'currency_service.dart';
import 'database_service.dart';

// ── Data classes ──

class SpendingPrediction {
  final double predictedExpense;
  final double predictedIncome;
  final Map<String, double> categoryPredictions;
  final double confidence;
  final String trend; // 'increasing' | 'decreasing' | 'stable'

  const SpendingPrediction({
    required this.predictedExpense,
    required this.predictedIncome,
    required this.categoryPredictions,
    required this.confidence,
    required this.trend,
  });
}

class NLQueryResult {
  final String answer;
  final double? amount;
  final List<ChartDataPoint>? chartData;

  const NLQueryResult({
    required this.answer,
    this.amount,
    this.chartData,
  });
}

class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});
}

// ── Service ──

class AiPredictionService {
  final Isar isar;
  final CurrencyService currencyService;

  AiPredictionService(this.isar, this.currencyService);

  /// Create from DatabaseService singleton.
  static Future<AiPredictionService> create() async {
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    return AiPredictionService(isar, cs);
  }

  // ── Prediction ──

  /// Predict next month spending/income using weighted moving average
  /// of the last 6 months, with more recent months weighted higher.
  Future<SpendingPrediction> predictNextMonth() async {
    final currency = await currencyService.getBaseCurrency();
    final now = DateTime.now();
    // Fetch last 6 complete months (not including current month)
    final start = DateTime(now.year, now.month - 6, 1);
    final end = DateTime(now.year, now.month, 1); // start of current month

    final txs = await isar.jiveTransactions
        .filter()
        .timestampBetween(start, end, includeUpper: false)
        .findAll();

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
    final accountById = {for (final a in accounts) a.id: a};

    final categories =
        await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    // Build per-month totals
    final Map<String, double> monthExpenses = {};
    final Map<String, double> monthIncomes = {};
    final Map<String, Map<String, double>> monthCategoryAmounts = {};

    for (final tx in txs) {
      if (tx.amount <= 0) continue;
      final type = tx.type ?? 'expense';
      if (type == 'transfer') continue;

      final account = tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency = account?.currency ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != currency) {
        amount =
            await currencyService.convert(amount, txCurrency, currency) ??
                amount;
      }

      final monthKey =
          '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}';

      if (type == 'income') {
        monthIncomes[monthKey] = (monthIncomes[monthKey] ?? 0) + amount;
      } else {
        monthExpenses[monthKey] = (monthExpenses[monthKey] ?? 0) + amount;
        final catKey = tx.categoryKey ?? tx.category ?? '其他';
        monthCategoryAmounts.putIfAbsent(monthKey, () => {});
        monthCategoryAmounts[monthKey]![catKey] =
            (monthCategoryAmounts[monthKey]![catKey] ?? 0) + amount;
      }
    }

    // Sort months chronologically
    final sortedMonths = <String>{
      ...monthExpenses.keys,
      ...monthIncomes.keys,
    }.toList()
      ..sort();

    if (sortedMonths.isEmpty) {
      return const SpendingPrediction(
        predictedExpense: 0,
        predictedIncome: 0,
        categoryPredictions: {},
        confidence: 0,
        trend: 'stable',
      );
    }

    // Weighted moving average: weights = [1, 2, 3, 4, 5, 6] for 6 months
    final expenseValues =
        sortedMonths.map((m) => monthExpenses[m] ?? 0).toList();
    final incomeValues =
        sortedMonths.map((m) => monthIncomes[m] ?? 0).toList();

    final predictedExpense = _weightedAverage(expenseValues);
    final predictedIncome = _weightedAverage(incomeValues);

    // Per-category predictions
    final allCatKeys = <String>{};
    for (final m in sortedMonths) {
      allCatKeys.addAll((monthCategoryAmounts[m] ?? {}).keys);
    }

    final Map<String, double> categoryPredictions = {};
    for (final catKey in allCatKeys) {
      final values = sortedMonths
          .map((m) => monthCategoryAmounts[m]?[catKey] ?? 0.0)
          .toList();
      final predicted = _weightedAverage(values);
      if (predicted > 0) {
        final catName = categoryMap[catKey]?.name ?? catKey;
        categoryPredictions[catName] = predicted;
      }
    }

    // Confidence based on coefficient of variation (lower variance = higher confidence)
    final confidence = _calculateConfidence(expenseValues);

    // Trend detection
    final trend = _detectTrend(expenseValues);

    return SpendingPrediction(
      predictedExpense: predictedExpense,
      predictedIncome: predictedIncome,
      categoryPredictions: categoryPredictions,
      confidence: confidence,
      trend: trend,
    );
  }

  double _weightedAverage(List<double> values) {
    if (values.isEmpty) return 0;
    double weightedSum = 0;
    double weightTotal = 0;
    for (int i = 0; i < values.length; i++) {
      final weight = (i + 1).toDouble();
      weightedSum += values[i] * weight;
      weightTotal += weight;
    }
    return weightedSum / weightTotal;
  }

  double _calculateConfidence(List<double> values) {
    if (values.length < 2) return 0.3;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0.3;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final cv = math.sqrt(variance) / mean; // coefficient of variation
    // Map CV to confidence: CV=0 -> 1.0, CV=1 -> 0.2
    return (1.0 - cv * 0.8).clamp(0.1, 1.0);
  }

  String _detectTrend(List<double> values) {
    if (values.length < 2) return 'stable';
    // Compare average of first half vs second half
    final mid = values.length ~/ 2;
    final firstHalf = values.sublist(0, mid);
    final secondHalf = values.sublist(mid);
    final firstAvg = firstHalf.isEmpty
        ? 0.0
        : firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.isEmpty
        ? 0.0
        : secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    if (firstAvg == 0) return 'stable';
    final change = (secondAvg - firstAvg) / firstAvg;
    if (change > 0.1) return 'increasing';
    if (change < -0.1) return 'decreasing';
    return 'stable';
  }

  // ── Natural Language Query ──

  /// Parse a Chinese natural language question about finances and return
  /// a structured answer.
  Future<NLQueryResult> queryNaturalLanguage(String question) async {
    final q = question.trim();

    // Determine time range
    final timeRange = _parseTimeRange(q);

    // Determine query intent
    if (RegExp(r'占比|比例|百分比').hasMatch(q)) {
      return _handleCategoryPercentage(q, timeRange);
    }
    if (RegExp(r'哪个月.*最多|哪月.*最多').hasMatch(q)) {
      return _handleMaxMonth(q, timeRange);
    }
    if (RegExp(r'哪个月.*最少|哪月.*最少').hasMatch(q)) {
      return _handleMinMonth(q, timeRange);
    }
    if (RegExp(r'哪个.*最多|哪.*分类.*最多').hasMatch(q)) {
      return _handleTopCategory(q, timeRange);
    }
    if (RegExp(r'哪个.*最少|哪.*分类.*最少').hasMatch(q)) {
      return _handleBottomCategory(q, timeRange);
    }
    if (RegExp(r'平均|日均').hasMatch(q)) {
      return _handleAverage(q, timeRange);
    }
    if (RegExp(r'存了|结余|余额|节省').hasMatch(q)) {
      return _handleSavings(q, timeRange);
    }
    if (RegExp(r'收入').hasMatch(q)) {
      return _handleIncome(q, timeRange);
    }
    // Default: expense query (花了多少 / total expense)
    return _handleExpense(q, timeRange);
  }

  // ── Time range parsing ──

  _TimeRange _parseTimeRange(String q) {
    final now = DateTime.now();

    if (q.contains('上个月') || q.contains('上月')) {
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month, 1);
      return _TimeRange(start, end, '上个月');
    }
    if (q.contains('这个月') || q.contains('本月')) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return _TimeRange(start, end, '本月');
    }
    if (q.contains('今年') || q.contains('本年')) {
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year + 1, 1, 1);
      return _TimeRange(start, end, '今年');
    }
    if (q.contains('去年') || q.contains('上年')) {
      final start = DateTime(now.year - 1, 1, 1);
      final end = DateTime(now.year, 1, 1);
      return _TimeRange(start, end, '去年');
    }
    // Default: current month
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return _TimeRange(start, end, '本月');
  }

  // ── Category matching ──

  Future<String?> _matchCategory(String q) async {
    final categories =
        await isar.collection<JiveCategory>().where().findAll();
    for (final c in categories) {
      if (c.parentKey != null) continue; // skip sub-categories
      if (q.contains(c.name)) return c.key;
    }
    // Common aliases
    const aliases = <String, List<String>>{
      '餐饮': ['吃饭', '吃的', '餐饮', '饭钱', '外卖'],
      '交通': ['交通', '打车', '地铁', '公交'],
      '购物': ['购物', '买东西', '网购'],
      '娱乐': ['娱乐', '玩', '游戏'],
      '住房': ['房租', '住房', '水电'],
    };
    for (final entry in aliases.entries) {
      for (final alias in entry.value) {
        if (q.contains(alias)) {
          // Find category with this name
          for (final c in categories) {
            if (c.name == entry.key && c.parentKey == null) return c.key;
          }
        }
      }
    }
    return null;
  }

  // ── Query helpers ──

  Future<List<JiveTransaction>> _fetchTransactions(
    _TimeRange range, {
    String? type,
    String? categoryKey,
  }) async {
    var query = isar.jiveTransactions
        .filter()
        .timestampBetween(range.start, range.end, includeUpper: false);
    if (type != null) {
      query = query.typeEqualTo(type);
    }
    if (categoryKey != null) {
      query = query.categoryKeyEqualTo(categoryKey);
    }
    return query.findAll();
  }

  Future<double> _sumTransactions(
    List<JiveTransaction> txs,
    String currency,
    Map<int, dynamic> accountById,
  ) async {
    double total = 0;
    for (final tx in txs) {
      if (tx.amount <= 0) continue;
      final account = tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency =
          (account as dynamic)?.currency as String? ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != currency) {
        amount =
            await currencyService.convert(amount, txCurrency, currency) ??
                amount;
      }
      total += amount;
    }
    return total;
  }

  Future<_QueryContext> _buildContext() async {
    final currency = await currencyService.getBaseCurrency();
    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
    final accountById = {for (final a in accounts) a.id: a};
    return _QueryContext(currency, accountById);
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      final wan = amount / 10000;
      return '${wan.toStringAsFixed(wan.truncateToDouble() == wan ? 0 : 2)}万';
    }
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }

  // ── Intent handlers ──

  Future<NLQueryResult> _handleExpense(String q, _TimeRange range) async {
    final ctx = await _buildContext();
    final categoryKey = await _matchCategory(q);
    final txs =
        await _fetchTransactions(range, type: 'expense', categoryKey: categoryKey);
    final total = await _sumTransactions(txs, ctx.currency, ctx.accountById);

    final categories =
        await isar.collection<JiveCategory>().where().findAll();
    final catName = categoryKey != null
        ? categories.where((c) => c.key == categoryKey).firstOrNull?.name ??
            categoryKey
        : null;

    final prefix = catName != null ? '${range.label}$catName' : range.label;
    return NLQueryResult(
      answer: '$prefix共支出 ¥${_formatAmount(total)}，共 ${txs.length} 笔交易。',
      amount: total,
    );
  }

  Future<NLQueryResult> _handleIncome(String q, _TimeRange range) async {
    final ctx = await _buildContext();
    final txs = await _fetchTransactions(range, type: 'income');
    final total = await _sumTransactions(txs, ctx.currency, ctx.accountById);

    return NLQueryResult(
      answer: '${range.label}总收入 ¥${_formatAmount(total)}，共 ${txs.length} 笔。',
      amount: total,
    );
  }

  Future<NLQueryResult> _handleSavings(String q, _TimeRange range) async {
    final ctx = await _buildContext();
    final incomeTxs = await _fetchTransactions(range, type: 'income');
    final expenseTxs = await _fetchTransactions(range, type: 'expense');
    final income =
        await _sumTransactions(incomeTxs, ctx.currency, ctx.accountById);
    final expense =
        await _sumTransactions(expenseTxs, ctx.currency, ctx.accountById);
    final savings = income - expense;

    final verb = savings >= 0 ? '存了' : '超支了';
    return NLQueryResult(
      answer:
          '${range.label}收入 ¥${_formatAmount(income)}，支出 ¥${_formatAmount(expense)}，$verb ¥${_formatAmount(savings.abs())}。',
      amount: savings,
    );
  }

  Future<NLQueryResult> _handleAverage(String q, _TimeRange range) async {
    final ctx = await _buildContext();
    final txs = await _fetchTransactions(range, type: 'expense');
    final total = await _sumTransactions(txs, ctx.currency, ctx.accountById);
    final days = range.end.difference(range.start).inDays;
    final daily = days > 0 ? total / days : 0.0;

    return NLQueryResult(
      answer: '${range.label}日均支出 ¥${_formatAmount(daily)}。',
      amount: daily,
    );
  }

  Future<NLQueryResult> _handleTopCategory(
      String q, _TimeRange range) async {
    final result = await _getCategoryRanking(range);
    if (result.isEmpty) {
      return const NLQueryResult(answer: '该时段暂无支出记录。');
    }
    final top = result.first;
    return NLQueryResult(
      answer:
          '${range.label}花费最多的是${top.label}，共 ¥${_formatAmount(top.value)}。',
      amount: top.value,
      chartData: result.take(5).toList(),
    );
  }

  Future<NLQueryResult> _handleBottomCategory(
      String q, _TimeRange range) async {
    final result = await _getCategoryRanking(range);
    if (result.isEmpty) {
      return const NLQueryResult(answer: '该时段暂无支出记录。');
    }
    final bottom = result.last;
    return NLQueryResult(
      answer:
          '${range.label}花费最少的是${bottom.label}，共 ¥${_formatAmount(bottom.value)}。',
      amount: bottom.value,
      chartData: result.take(5).toList(),
    );
  }

  Future<NLQueryResult> _handleCategoryPercentage(
      String q, _TimeRange range) async {
    final ctx = await _buildContext();
    final categoryKey = await _matchCategory(q);
    final allTxs = await _fetchTransactions(range, type: 'expense');
    final totalAll =
        await _sumTransactions(allTxs, ctx.currency, ctx.accountById);

    if (categoryKey == null || totalAll == 0) {
      return const NLQueryResult(answer: '未能识别分类或暂无支出数据。');
    }

    final catTxs = allTxs
        .where((tx) =>
            (tx.categoryKey ?? tx.category) == categoryKey)
        .toList();
    final catTotal =
        await _sumTransactions(catTxs, ctx.currency, ctx.accountById);
    final pct = (catTotal / totalAll * 100).toStringAsFixed(1);

    final categories =
        await isar.collection<JiveCategory>().where().findAll();
    final catName =
        categories.where((c) => c.key == categoryKey).firstOrNull?.name ??
            categoryKey;

    return NLQueryResult(
      answer: '${range.label}$catName支出占总支出的 $pct%。',
      amount: catTotal,
    );
  }

  Future<NLQueryResult> _handleMaxMonth(String q, _TimeRange range) async {
    final result = await _getMonthlyRanking(range);
    if (result.isEmpty) {
      return const NLQueryResult(answer: '该时段暂无支出记录。');
    }
    final top = result.first;
    return NLQueryResult(
      answer: '花费最多的是${top.label}，共 ¥${_formatAmount(top.value)}。',
      amount: top.value,
      chartData: result,
    );
  }

  Future<NLQueryResult> _handleMinMonth(String q, _TimeRange range) async {
    final result = await _getMonthlyRanking(range);
    if (result.isEmpty) {
      return const NLQueryResult(answer: '该时段暂无支出记录。');
    }
    final bottom = result.last;
    return NLQueryResult(
      answer: '花费最少的是${bottom.label}，共 ¥${_formatAmount(bottom.value)}。',
      amount: bottom.value,
      chartData: result,
    );
  }

  // ── Ranking helpers ──

  Future<List<ChartDataPoint>> _getCategoryRanking(_TimeRange range) async {
    final ctx = await _buildContext();
    final txs = await _fetchTransactions(range, type: 'expense');
    final categories =
        await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    final Map<String, double> catAmounts = {};
    for (final tx in txs) {
      if (tx.amount <= 0) continue;
      final account = tx.accountId != null ? ctx.accountById[tx.accountId] : null;
      final txCurrency =
          (account as dynamic)?.currency as String? ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != ctx.currency) {
        amount =
            await currencyService.convert(amount, txCurrency, ctx.currency) ??
                amount;
      }
      final key = tx.categoryKey ?? tx.category ?? '其他';
      catAmounts[key] = (catAmounts[key] ?? 0) + amount;
    }

    final entries = catAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .map((e) => ChartDataPoint(
              label: categoryMap[e.key]?.name ?? e.key,
              value: e.value,
            ))
        .toList();
  }

  Future<List<ChartDataPoint>> _getMonthlyRanking(_TimeRange range) async {
    final ctx = await _buildContext();
    final txs = await _fetchTransactions(range, type: 'expense');

    final Map<String, double> monthAmounts = {};
    for (final tx in txs) {
      if (tx.amount <= 0) continue;
      final account = tx.accountId != null ? ctx.accountById[tx.accountId] : null;
      final txCurrency =
          (account as dynamic)?.currency as String? ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != ctx.currency) {
        amount =
            await currencyService.convert(amount, txCurrency, ctx.currency) ??
                amount;
      }
      final key =
          '${tx.timestamp.year}年${tx.timestamp.month}月';
      monthAmounts[key] = (monthAmounts[key] ?? 0) + amount;
    }

    final entries = monthAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .map((e) => ChartDataPoint(label: e.key, value: e.value))
        .toList();
  }
}

// ── Private helpers ──

class _TimeRange {
  final DateTime start;
  final DateTime end;
  final String label;

  const _TimeRange(this.start, this.end, this.label);
}

class _QueryContext {
  final String currency;
  final Map<int, dynamic> accountById;

  const _QueryContext(this.currency, this.accountById);
}
