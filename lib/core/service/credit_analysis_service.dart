import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/transaction_model.dart';

/// Analysis result for a single credit-card account.
class CreditAnalysis {
  final int accountId;
  final String accountName;
  final double creditLimit;
  final double currentBalance;
  final double utilizationRate;
  final double avgMonthlySpend;
  final double paymentRate;

  const CreditAnalysis({
    required this.accountId,
    required this.accountName,
    required this.creditLimit,
    required this.currentBalance,
    required this.utilizationRate,
    required this.avgMonthlySpend,
    required this.paymentRate,
  });
}

/// Service that computes credit-card utilization and payment metrics.
class CreditAnalysisService {
  final Isar _isar;

  CreditAnalysisService(this._isar);

  /// Analyse a single credit-card account.
  Future<CreditAnalysis> getCreditUtilization(int accountId) async {
    final account = await _isar.collection<JiveAccount>().get(accountId);
    if (account == null) {
      return CreditAnalysis(
        accountId: accountId,
        accountName: '未知',
        creditLimit: 0,
        currentBalance: 0,
        utilizationRate: 0,
        avgMonthlySpend: 0,
        paymentRate: 0,
      );
    }

    final limit = account.creditLimit ?? 0;
    final balance = await _computeBalance(accountId);
    final utilization = limit > 0 ? (balance.abs() / limit).clamp(0.0, 1.0) : 0.0;

    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

    final txs = await _isar.jiveTransactions
        .filter()
        .accountIdEqualTo(accountId)
        .timestampGreaterThan(sixMonthsAgo)
        .findAll();

    double totalSpend = 0;
    double totalPayments = 0;
    for (final tx in txs) {
      if (tx.type == 'expense') {
        totalSpend += tx.amount;
      } else if (tx.type == 'income' || tx.type == 'transfer') {
        totalPayments += tx.amount;
      }
    }

    // Count months with data (at least 1, cap at 6).
    final months = _monthsBetween(sixMonthsAgo, now).clamp(1, 6);
    final avgSpend = totalSpend / months;
    final paymentRate = totalSpend > 0 ? (totalPayments / totalSpend).clamp(0.0, 2.0) : 0.0;

    return CreditAnalysis(
      accountId: accountId,
      accountName: account.name,
      creditLimit: limit,
      currentBalance: balance,
      utilizationRate: utilization,
      avgMonthlySpend: avgSpend,
      paymentRate: paymentRate,
    );
  }

  /// Analyse all credit-card accounts.
  Future<List<CreditAnalysis>> getAllCreditAnalysis() async {
    final accounts = await _isar
        .collection<JiveAccount>()
        .filter()
        .typeEqualTo('liability')
        .and()
        .creditLimitGreaterThan(0)
        .findAll();

    final results = <CreditAnalysis>[];
    for (final acct in accounts) {
      results.add(await getCreditUtilization(acct.id));
    }
    return results;
  }

  // ── helpers ──────────────────────────────────────────────────────────

  Future<double> _computeBalance(int accountId) async {
    final txs = await _isar.jiveTransactions
        .filter()
        .accountIdEqualTo(accountId)
        .findAll();

    double balance = 0;
    for (final tx in txs) {
      if (tx.type == 'expense') {
        balance -= tx.amount;
      } else if (tx.type == 'income') {
        balance += tx.amount;
      }
    }
    return balance;
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }
}
