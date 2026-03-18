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
  }) async {
    final currency = currencyCode ?? await currencyService.getBaseCurrency();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = end.difference(start).inDays;

    final txs = await isar.jiveTransactions
        .filter()
        .timestampBetween(start, end, includeUpper: false)
        .findAll();

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
    final accountById = {for (final a in accounts) a.id: a};

    double income = 0;
    double expense = 0;
    int count = 0;

    for (final tx in txs) {
      final type = tx.type ?? 'expense';
      if (type == 'transfer') continue;
      if (tx.amount <= 0) continue;
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
  }) async {
    final current = await getMonthSummary(month, currencyCode: currencyCode);
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final previous = await getMonthSummary(prevMonth, currencyCode: currencyCode);

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
  }) async {
    final currency = currencyCode ?? await currencyService.getBaseCurrency();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final txs = await isar.jiveTransactions
        .filter()
        .timestampBetween(start, end, includeUpper: false)
        .findAll();

    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
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
  }) async {
    final now = DateTime.now();
    final trends = <MonthTrend>[];

    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final summary = await getMonthSummary(m, currencyCode: currencyCode);
      trends.add(MonthTrend(
        month: m,
        totalIncome: summary.totalIncome,
        totalExpense: summary.totalExpense,
      ));
    }

    return trends;
  }
}
