import 'package:isar/isar.dart';
import '../database/transaction_model.dart';
import '../database/category_model.dart';
import 'account_service.dart';
import 'currency_service.dart';
import 'database_service.dart';

// ── Data classes ──

/// A single transfer flow between two accounts.
class TransferFlow {
  final String fromAccount;
  final String toAccount;
  final double amount;

  const TransferFlow({
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
  });
}

/// Aggregated capital flow data for a given period.
class CapitalFlowData {
  final Map<String, double> incomeBySource;
  final Map<String, double> expenseByCategory;
  final List<TransferFlow> transferFlows;
  final double totalIncome;
  final double totalExpense;
  final double netFlow;

  const CapitalFlowData({
    required this.incomeBySource,
    required this.expenseByCategory,
    required this.transferFlows,
    required this.totalIncome,
    required this.totalExpense,
    required this.netFlow,
  });
}

// ── Service ──

class CapitalFlowService {
  final Isar isar;
  final CurrencyService currencyService;

  CapitalFlowService(this.isar, this.currencyService);

  /// Create from DatabaseService singleton.
  static Future<CapitalFlowService> create() async {
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    return CapitalFlowService(isar, cs);
  }

  /// Get capital flow data for the last [months] months.
  Future<CapitalFlowData> getCapitalFlow(
    int months, {
    int? bookId,
  }) async {
    final baseCurrency = await currencyService.getBaseCurrency();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);

    var query = isar.jiveTransactions
        .filter()
        .timestampGreaterThan(start);
    if (bookId != null) {
      query = query.bookIdEqualTo(bookId);
    }
    final txs = await query.findAll();

    // Load categories and accounts for label resolution
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts(bookId: bookId);
    final accountById = {for (final a in accounts) a.id: a};

    final Map<String, double> incomeBySource = {};
    final Map<String, double> expenseByCategory = {};
    // Keyed by "fromId->toId"
    final Map<String, double> transferAmounts = {};

    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in txs) {
      final type = tx.type ?? 'expense';
      if (tx.amount <= 0) continue;

      // Currency conversion
      final account =
          tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency = account?.currency ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != baseCurrency) {
        amount = await currencyService.convert(
                amount, txCurrency, baseCurrency) ??
            amount;
      }

      if (type == 'income') {
        final key = tx.categoryKey ?? tx.category ?? '其他';
        final label = categoryMap[key]?.name ?? key;
        incomeBySource[label] = (incomeBySource[label] ?? 0) + amount;
        totalIncome += amount;
      } else if (type == 'expense') {
        final key = tx.categoryKey ?? tx.category ?? '其他';
        final label = categoryMap[key]?.name ?? key;
        expenseByCategory[label] = (expenseByCategory[label] ?? 0) + amount;
        totalExpense += amount;
      } else if (type == 'transfer') {
        final fromName = account?.name ?? '未知账户';
        final toAccount = tx.toAccountId != null
            ? accountById[tx.toAccountId]
            : null;
        final toName = toAccount?.name ?? '未知账户';
        final flowKey = '$fromName->$toName';
        transferAmounts[flowKey] =
            (transferAmounts[flowKey] ?? 0) + amount;
      }
    }

    // Convert transfer map to list
    final transferFlows = transferAmounts.entries.map((e) {
      final parts = e.key.split('->');
      return TransferFlow(
        fromAccount: parts[0],
        toAccount: parts[1],
        amount: e.value,
      );
    }).toList();
    transferFlows.sort((a, b) => b.amount.compareTo(a.amount));

    return CapitalFlowData(
      incomeBySource: incomeBySource,
      expenseByCategory: expenseByCategory,
      transferFlows: transferFlows,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netFlow: totalIncome - totalExpense,
    );
  }
}
