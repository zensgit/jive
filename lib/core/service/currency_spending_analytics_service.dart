import '../database/account_model.dart';
import '../database/currency_model.dart';
import '../database/transaction_model.dart';

typedef CurrencyAmountConverter =
    Future<double?> Function(
      double amount,
      String fromCurrency,
      String toCurrency,
    );

class MonthlySpending {
  final DateTime month;
  final double amount;

  const MonthlySpending({required this.month, required this.amount});
}

class CurrencySpendingData {
  final String currency;
  final String currencyName;
  final String? flag;
  final String symbol;
  final double totalAmount;
  final double convertedAmount;
  final int transactionCount;
  final List<MonthlySpending> monthlyData;

  const CurrencySpendingData({
    required this.currency,
    required this.currencyName,
    this.flag,
    required this.symbol,
    required this.totalAmount,
    required this.convertedAmount,
    required this.transactionCount,
    required this.monthlyData,
  });
}

class CurrencySpendingAnalyticsResult {
  final List<CurrencySpendingData> spendingByCurrency;
  final double totalConvertedSpending;

  const CurrencySpendingAnalyticsResult({
    required this.spendingByCurrency,
    required this.totalConvertedSpending,
  });
}

class CurrencySpendingAnalyticsService {
  const CurrencySpendingAnalyticsService();

  Future<CurrencySpendingAnalyticsResult> buildSpendingData({
    required List<JiveTransaction> transactions,
    required Map<int, JiveAccount> accountById,
    required String baseCurrency,
    required int selectedMonths,
    required DateTime now,
    CurrencyAmountConverter? converter,
  }) async {
    final normalizedBaseCurrency = _normalizeCurrency(baseCurrency) ?? 'CNY';
    final monthCount = selectedMonths > 0 ? selectedMonths : 1;
    final firstMonth = DateTime(now.year, now.month - monthCount + 1, 1);
    final endExclusive = DateTime(now.year, now.month + 1, 1);
    final monthSeries = List<DateTime>.generate(
      monthCount,
      (index) => DateTime(firstMonth.year, firstMonth.month + index, 1),
    );

    final grouped = <String, _CurrencyBucket>{};

    for (final tx in transactions) {
      if (tx.timestamp.isBefore(firstMonth) ||
          !tx.timestamp.isBefore(endExclusive)) {
        continue;
      }

      final currency = _resolveCurrency(
        transaction: tx,
        accountById: accountById,
        baseCurrency: normalizedBaseCurrency,
      );
      final month = DateTime(tx.timestamp.year, tx.timestamp.month, 1);

      final bucket = grouped.putIfAbsent(
        currency,
        () => _CurrencyBucket(
          monthlyTotals: {for (final monthStart in monthSeries) monthStart: 0},
        ),
      );

      bucket.total += tx.amount;
      bucket.count += 1;
      bucket.monthlyTotals[month] =
          (bucket.monthlyTotals[month] ?? 0) + tx.amount;
    }

    final spendingList = <CurrencySpendingData>[];
    var totalConvertedSpending = 0.0;

    for (final entry in grouped.entries) {
      final currency = entry.key;
      final bucket = entry.value;

      var convertedAmount = bucket.total;
      if (converter != null && currency != normalizedBaseCurrency) {
        convertedAmount =
            await converter(bucket.total, currency, normalizedBaseCurrency) ??
            bucket.total;
      }
      totalConvertedSpending += convertedAmount;

      final currencyInfo = CurrencyDefaults.getAllCurrencies().firstWhere(
        (data) => data['code'] == currency,
        orElse: () => {
          'code': currency,
          'nameZh': currency,
          'symbol': currency,
        },
      );

      spendingList.add(
        CurrencySpendingData(
          currency: currency,
          currencyName: currencyInfo['nameZh'] as String,
          flag: currencyInfo['flag'] as String?,
          symbol: currencyInfo['symbol'] as String,
          totalAmount: bucket.total,
          convertedAmount: convertedAmount,
          transactionCount: bucket.count,
          monthlyData: [
            for (final monthStart in monthSeries)
              MonthlySpending(
                month: monthStart,
                amount: bucket.monthlyTotals[monthStart] ?? 0,
              ),
          ],
        ),
      );
    }

    spendingList.sort((a, b) => b.convertedAmount.compareTo(a.convertedAmount));

    return CurrencySpendingAnalyticsResult(
      spendingByCurrency: spendingList,
      totalConvertedSpending: totalConvertedSpending,
    );
  }

  String _resolveCurrency({
    required JiveTransaction transaction,
    required Map<int, JiveAccount> accountById,
    required String baseCurrency,
  }) {
    final type = transaction.type?.trim().toLowerCase();
    if (type == 'expense' || type == 'income') {
      final accountId = transaction.accountId;
      final accountCurrency = accountId == null
          ? null
          : accountById[accountId]?.currency;
      return _normalizeCurrency(accountCurrency) ?? baseCurrency;
    }
    return baseCurrency;
  }

  String? _normalizeCurrency(String? currency) {
    if (currency == null) {
      return null;
    }
    final normalized = currency.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

class _CurrencyBucket {
  final Map<DateTime, double> monthlyTotals;
  double total = 0;
  int count = 0;

  _CurrencyBucket({required this.monthlyTotals});
}
