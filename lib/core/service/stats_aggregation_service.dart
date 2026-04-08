import 'package:isar/isar.dart';
import '../database/transaction_model.dart';
import '../database/category_model.dart';
import 'account_service.dart';
import 'currency_service.dart';
import 'database_service.dart';

// ── Data classes ──

class MonthSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double dailyAverage;
  final int transactionCount;
  final int daysInMonth;

  const MonthSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.dailyAverage,
    required this.transactionCount,
    required this.daysInMonth,
  });
}

class MonthComparison {
  final MonthSummary current;
  final MonthSummary previous;
  final double incomeChangePercent;
  final double expenseChangePercent;

  const MonthComparison({
    required this.current,
    required this.previous,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
  });
}

class CategoryStat {
  final String key;
  final String name;
  final String? icon;
  final double amount;
  final double percentage;
  final int count;

  const CategoryStat({
    required this.key,
    required this.name,
    this.icon,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

class MonthTrend {
  final DateTime month;
  final double totalIncome;
  final double totalExpense;

  const MonthTrend({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
  });
}

// ── Service ──

class StatsAggregationService {
  final Isar isar;
  final CurrencyService currencyService;

  StatsAggregationService(this.isar, this.currencyService);

  /// Create from DatabaseService singleton.
  static Future<StatsAggregationService> create() async {
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    return StatsAggregationService(isar, cs);
  }

  // ── Month Summary ──

  Future<MonthSummary> getMonthSummary(
    DateTime month, {
    String? currencyCode,
    int? bookId,
  }) async {
    final currency = currencyCode ?? await currencyService.getBaseCurrency();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = end.difference(start).inDays;

    var query = isar.jiveTransactions
        .filter()
        .timestampBetween(start, end, includeUpper: false);
    if (bookId != null) {
      query = query.bookIdEqualTo(bookId);
    }
    final txs = await query.findAll();

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts(bookId: bookId);
    final accountById = {for (final a in accounts) a.id: a};

    double income = 0;
    double expense = 0;
    int count = 0;

    for (final tx in txs) {
      final type = tx.type ?? 'expense';
      if (type == 'transfer') continue;
      if (tx.amount <= 0) continue;
      // 账单标记：不计入收支 -> 跳过统计汇总
      if (tx.excludeFromTotals) continue;
      count++;

      final account = tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency = account?.currency ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != currency) {
        amount = await currencyService.convert(amount, txCurrency, currency) ?? amount;
      }

      if (type == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    final now = DateTime.now();
    final elapsedDays = (month.year == now.year && month.month == now.month)
        ? now.day
        : daysInMonth;

    return MonthSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      dailyAverage: elapsedDays > 0 ? expense / elapsedDays : 0,
      transactionCount: count,
      daysInMonth: daysInMonth,
    );
  }

  // ── Month Comparison ──

  Future<MonthComparison> getMonthComparison(
    DateTime month, {
    String? currencyCode,
    int? bookId,
  }) async {
    final current = await getMonthSummary(month, currencyCode: currencyCode, bookId: bookId);
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final previous = await getMonthSummary(prevMonth, currencyCode: currencyCode, bookId: bookId);

    double incomeChange = 0;
    if (previous.totalIncome > 0) {
      incomeChange = (current.totalIncome - previous.totalIncome) / previous.totalIncome * 100;
    }
    double expenseChange = 0;
    if (previous.totalExpense > 0) {
      expenseChange = (current.totalExpense - previous.totalExpense) / previous.totalExpense * 100;
    }

    return MonthComparison(
      current: current,
      previous: previous,
      incomeChangePercent: incomeChange,
      expenseChangePercent: expenseChange,
    );
  }

  // ── Category Breakdown ──

  Future<List<CategoryStat>> getCategoryBreakdown(
    DateTime month, {
    bool isExpense = true,
    String? currencyCode,
    int? bookId,
  }) async {
    final currency = currencyCode ?? await currencyService.getBaseCurrency();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    var query = isar.jiveTransactions
        .filter()
        .timestampBetween(start, end, includeUpper: false);
    if (bookId != null) {
      query = query.bookIdEqualTo(bookId);
    }
    final txs = await query.findAll();

    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts(bookId: bookId);
    final accountById = {for (final a in accounts) a.id: a};

    final Map<String, double> amounts = {};
    final Map<String, int> counts = {};
    double total = 0;

    for (final tx in txs) {
      final type = tx.type ?? 'expense';
      if (type == 'transfer') continue;
      if (tx.amount <= 0) continue;
      if (isExpense && type != 'expense') continue;
      if (!isExpense && type != 'income') continue;

      final account = tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency = account?.currency ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != currency) {
        amount = await currencyService.convert(amount, txCurrency, currency) ?? amount;
      }

      final key = tx.categoryKey ?? tx.category ?? '其他';
      amounts[key] = (amounts[key] ?? 0) + amount;
      counts[key] = (counts[key] ?? 0) + 1;
      total += amount;
    }

    final stats = amounts.entries.map((e) {
      final cat = categoryMap[e.key];
      return CategoryStat(
        key: e.key,
        name: cat?.name ?? e.key,
        icon: cat?.iconName,
        amount: e.value,
        percentage: total > 0 ? e.value / total * 100 : 0,
        count: counts[e.key] ?? 0,
      );
    }).toList();

    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  // ── Monthly Trend ──

  Future<List<MonthTrend>> getMonthlyTrend(
    int months, {
    String? currencyCode,
    int? bookId,
  }) async {
    final now = DateTime.now();
    final trends = <MonthTrend>[];

    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final summary = await getMonthSummary(m, currencyCode: currencyCode, bookId: bookId);
      trends.add(MonthTrend(
        month: m,
        totalIncome: summary.totalIncome,
        totalExpense: summary.totalExpense,
      ));
    }

    return trends;
  }

  /// Get asset trend: end-of-month net worth for the last [months] months.
  Future<List<AssetTrendPoint>> getAssetTrend(
    int months, {
    int? bookId,
  }) async {
    final now = DateTime.now();
    final points = <AssetTrendPoint>[];
    final accountService = AccountService(isar);

    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      // End of month or today for current month
      final endOfMonth = (i == 0)
          ? now
          : DateTime(m.year, m.month + 1, 0); // last day of month

      final accounts = await accountService.getActiveAccounts(bookId: bookId);

      // Compute balances as of endOfMonth by filtering transactions up to that date
      double totalAssets = 0;
      double totalLiabilities = 0;

      for (final account in accounts) {
        final txs = await isar.jiveTransactions
            .filter()
            .timestampLessThan(endOfMonth.add(const Duration(days: 1)))
            .accountIdEqualTo(account.id)
            .findAll();

        double balance = account.openingBalance;
        for (final tx in txs) {
          final type = tx.type ?? 'expense';
          if (type == 'income') {
            balance += tx.amount;
          } else if (type == 'expense') {
            balance -= tx.amount;
          } else if (type == 'transfer') {
            if (tx.accountId == account.id) balance -= tx.amount;
            if (tx.toAccountId == account.id) balance += tx.toAmount ?? tx.amount;
          }
        }

        if (account.type == 'asset') {
          totalAssets += balance;
        } else {
          totalLiabilities += balance.abs();
        }
      }

      points.add(AssetTrendPoint(
        date: endOfMonth,
        netWorth: totalAssets - totalLiabilities,
        assets: totalAssets,
        liabilities: totalLiabilities,
      ));
    }

    return points;
  }

  /// Get spending heatmap data: weekday (0=Mon..6=Sun) × hour (0..23).
  ///
  /// Returns a 7×24 grid of total expense amounts for the given [months].
  Future<SpendingHeatmap> getSpendingHeatmap(
    int months, {
    int? bookId,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);

    var query = isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampGreaterThan(start);

    if (bookId != null) {
      query = query.bookIdEqualTo(bookId);
    }

    final transactions = await query.findAll();

    // 7 weekdays × 24 hours grid
    final grid = List.generate(7, (_) => List.filled(24, 0.0));
    var maxValue = 0.0;

    for (final tx in transactions) {
      final weekday = (tx.timestamp.weekday - 1) % 7; // 0=Mon
      final hour = tx.timestamp.hour;
      grid[weekday][hour] += tx.amount;
      if (grid[weekday][hour] > maxValue) {
        maxValue = grid[weekday][hour];
      }
    }

    return SpendingHeatmap(grid: grid, maxValue: maxValue);
  }
}

/// A single data point for asset trend over time.
class AssetTrendPoint {
  final DateTime date;
  final double netWorth;
  final double assets;
  final double liabilities;

  const AssetTrendPoint({
    required this.date,
    required this.netWorth,
    required this.assets,
    required this.liabilities,
  });
}

/// Spending heatmap: 7 weekdays × 24 hours.
class SpendingHeatmap {
  final List<List<double>> grid; // [weekday][hour]
  final double maxValue;

  const SpendingHeatmap({required this.grid, required this.maxValue});

  double get(int weekday, int hour) => grid[weekday][hour];

  /// Normalized intensity 0.0..1.0 for coloring.
  double intensity(int weekday, int hour) {
    if (maxValue <= 0) return 0;
    return grid[weekday][hour] / maxValue;
  }
}
