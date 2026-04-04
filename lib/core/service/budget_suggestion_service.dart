import 'dart:math' as math;

import 'stats_aggregation_service.dart';

/// A single budget suggestion for a category or overall total.
class BudgetSuggestion {
  /// Category key, or `null` for overall total suggestion.
  final String? categoryKey;
  final String categoryName;
  final String? icon;
  final double suggestedAmount;
  final double averageSpend;
  final double maxSpend;
  final double minSpend;

  /// 0.0 -- 1.0 indicating how consistent the spending pattern is.
  /// Higher means more predictable (lower relative stddev).
  final double confidence;

  const BudgetSuggestion({
    this.categoryKey,
    required this.categoryName,
    this.icon,
    required this.suggestedAmount,
    required this.averageSpend,
    required this.maxSpend,
    required this.minSpend,
    required this.confidence,
  });
}

/// Month flagged as an anomaly.
class AnomalyMonth {
  final DateTime month;
  final double totalExpense;
  final double mean;
  final double stddev;

  const AnomalyMonth({
    required this.month,
    required this.totalExpense,
    required this.mean,
    required this.stddev,
  });
}

/// Recommends budget amounts based on historical spending.
class BudgetSuggestionService {
  final StatsAggregationService _statsService;

  BudgetSuggestionService(this._statsService);

  /// Create from singleton database.
  static Future<BudgetSuggestionService> create() async {
    final stats = await StatsAggregationService.create();
    return BudgetSuggestionService(stats);
  }

  /// Suggest per-category budgets based on the last [months] months of data.
  Future<List<BudgetSuggestion>> suggestBudgets({
    int months = 3,
    int? bookId,
  }) async {
    final now = DateTime.now();

    // Gather per-category breakdowns for each of the last N months.
    final List<List<CategoryStat>> monthlyBreakdowns = [];
    for (int i = 0; i < months; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      final breakdown = await _statsService.getCategoryBreakdown(
        m,
        isExpense: true,
        bookId: bookId,
      );
      monthlyBreakdowns.add(breakdown);
    }

    // Collect all category keys that appeared in any month.
    final allKeys = <String>{};
    for (final bd in monthlyBreakdowns) {
      for (final stat in bd) {
        allKeys.add(stat.key);
      }
    }

    // Build suggestions per category.
    final suggestions = <BudgetSuggestion>[];
    for (final key in allKeys) {
      final amounts = <double>[];
      String name = key;
      String? icon;

      for (final bd in monthlyBreakdowns) {
        final match = bd.where((s) => s.key == key);
        if (match.isNotEmpty) {
          amounts.add(match.first.amount);
          name = match.first.name;
          icon = match.first.icon;
        } else {
          amounts.add(0);
        }
      }

      if (amounts.every((a) => a == 0)) continue;

      final avg = amounts.reduce((a, b) => a + b) / amounts.length;
      final maxVal = amounts.reduce(math.max);
      final minVal = amounts.reduce(math.min);
      final stddev = _stddev(amounts, avg);
      final confidence = _confidence(avg, stddev);

      // Suggest average + 10% buffer, rounded to nearest integer.
      final suggested = (avg * 1.10).roundToDouble();

      suggestions.add(BudgetSuggestion(
        categoryKey: key,
        categoryName: name,
        icon: icon,
        suggestedAmount: suggested,
        averageSpend: avg,
        maxSpend: maxVal,
        minSpend: minVal,
        confidence: confidence,
      ));
    }

    // Sort by suggested amount descending.
    suggestions.sort((a, b) => b.suggestedAmount.compareTo(a.suggestedAmount));
    return suggestions;
  }

  /// Suggest an overall monthly budget.
  Future<BudgetSuggestion> suggestTotalBudget({
    int months = 3,
    int? bookId,
  }) async {
    final now = DateTime.now();
    final totals = <double>[];

    for (int i = 0; i < months; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      final summary = await _statsService.getMonthSummary(
        m,
        bookId: bookId,
      );
      totals.add(summary.totalExpense);
    }

    final avg = totals.reduce((a, b) => a + b) / totals.length;
    final maxVal = totals.reduce(math.max);
    final minVal = totals.reduce(math.min);
    final stddev = _stddev(totals, avg);
    final confidence = _confidence(avg, stddev);
    final suggested = (avg * 1.10).roundToDouble();

    return BudgetSuggestion(
      categoryKey: null,
      categoryName: '总预算',
      suggestedAmount: suggested,
      averageSpend: avg,
      maxSpend: maxVal,
      minSpend: minVal,
      confidence: confidence,
    );
  }

  /// Detect months where total spending was >2 standard deviations above mean.
  ///
  /// Looks back [lookbackMonths] months (default 6) to build the baseline.
  Future<List<AnomalyMonth>> detectAnomalyMonths({
    int lookbackMonths = 6,
    int? bookId,
  }) async {
    final now = DateTime.now();
    final data = <(DateTime, double)>[];

    for (int i = 0; i < lookbackMonths; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      final summary = await _statsService.getMonthSummary(
        m,
        bookId: bookId,
      );
      data.add((m, summary.totalExpense));
    }

    if (data.length < 3) return [];

    final amounts = data.map((d) => d.$2).toList();
    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    final stddev = _stddev(amounts, avg);

    if (stddev == 0) return [];

    final anomalies = <AnomalyMonth>[];
    for (final (month, expense) in data) {
      if (expense > avg + 2 * stddev) {
        anomalies.add(AnomalyMonth(
          month: month,
          totalExpense: expense,
          mean: avg,
          stddev: stddev,
        ));
      }
    }

    return anomalies;
  }

  // -- helpers --

  double _stddev(List<double> values, double mean) {
    if (values.length < 2) return 0;
    final sumSq =
        values.fold<double>(0, (s, v) => s + (v - mean) * (v - mean));
    return math.sqrt(sumSq / values.length);
  }

  /// Confidence: 1.0 when stddev is 0 (perfectly consistent),
  /// approaching 0.0 as coefficient of variation grows.
  double _confidence(double mean, double stddev) {
    if (mean <= 0) return 0;
    final cv = stddev / mean; // coefficient of variation
    // Map cv to 0..1: confidence = 1 / (1 + cv)
    return 1.0 / (1.0 + cv);
  }
}
