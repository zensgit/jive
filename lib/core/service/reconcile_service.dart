import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/transaction_model.dart';

class ReconcileSummary {
  final double startBalance;
  final double endBalance;
  final double income;
  final double expense;
  final double transferIn;
  final double transferOut;
  final double netChange;

  const ReconcileSummary({
    required this.startBalance,
    required this.endBalance,
    required this.income,
    required this.expense,
    required this.transferIn,
    required this.transferOut,
    required this.netChange,
  });
}

class ReconcileEntry {
  final JiveTransaction transaction;
  final double signedAmount;
  final double runningBalance;
  final DateTime day;

  const ReconcileEntry({
    required this.transaction,
    required this.signedAmount,
    required this.runningBalance,
    required this.day,
  });
}

class ReconcileResult {
  final ReconcileSummary summary;
  final List<ReconcileEntry> entries;
  final Map<DateTime, int> dayCounts;
  final Map<DateTime, double> dayNetChanges;
  final List<double> balanceSeries;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Set<int> transactionYears;

  const ReconcileResult({
    required this.summary,
    required this.entries,
    required this.dayCounts,
    required this.dayNetChanges,
    required this.balanceSeries,
    required this.minDate,
    required this.maxDate,
    required this.transactionYears,
  });
}

class ReconcileService {
  final Isar isar;

  ReconcileService(this.isar);

  Future<ReconcileResult> reconcileAccount({
    required int accountId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (end.isBefore(start)) {
      throw ArgumentError('end must be >= start');
    }

    final account = await isar.collection<JiveAccount>().get(accountId);
    if (account == null) {
      throw StateError('Account not found');
    }

    final txs = await isar.jiveTransactions
        .filter()
        .accountIdEqualTo(accountId)
        .or()
        .toAccountIdEqualTo(accountId)
        .findAll();

    DateTime? minDate;
    DateTime? maxDate;
    final years = <int>{};
    for (final tx in txs) {
      final timestamp = tx.timestamp;
      years.add(timestamp.year);
      minDate = minDate == null || timestamp.isBefore(minDate) ? timestamp : minDate;
      maxDate = maxDate == null || timestamp.isAfter(maxDate) ? timestamp : maxDate;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (maxDate == null || today.isAfter(maxDate)) {
      maxDate = today;
    }
    if (minDate != null) {
      minDate = DateTime(minDate.year, minDate.month, minDate.day);
    }
    if (maxDate != null) {
      maxDate = DateTime(maxDate.year, maxDate.month, maxDate.day);
    }

    var currentBalance = account.openingBalance;
    for (final tx in txs) {
      currentBalance += _signedAmount(tx, accountId);
    }

    var deltaAfterEnd = 0.0;
    var deltaInRange = 0.0;
    var income = 0.0;
    var expense = 0.0;
    var transferIn = 0.0;
    var transferOut = 0.0;

    final inRange = <JiveTransaction>[];
    for (final tx in txs) {
      final signed = _signedAmount(tx, accountId);
      if (signed == 0) continue;

      if (tx.timestamp.isAfter(end)) {
        deltaAfterEnd += signed;
        continue;
      }
      if (tx.timestamp.isBefore(start)) {
        continue;
      }

      inRange.add(tx);
      deltaInRange += signed;

      final type = _normalizeType(tx);
      if (type == 'transfer') {
        if (tx.accountId == accountId && tx.toAccountId == accountId) {
          continue;
        }
        if (tx.accountId == accountId) {
          transferOut += tx.amount;
        } else if (tx.toAccountId == accountId) {
          transferIn += tx.amount;
        }
      } else if (type == 'income') {
        if (tx.accountId == accountId) {
          income += tx.amount;
        }
      } else if (tx.accountId == accountId) {
        expense += tx.amount;
      }
    }

    final endBalance = currentBalance - deltaAfterEnd;
    final startBalance = endBalance - deltaInRange;
    final netChange = income - expense + transferIn - transferOut;

    inRange.sort((a, b) {
      final timeCompare = a.timestamp.compareTo(b.timestamp);
      if (timeCompare != 0) return timeCompare;
      return a.id.compareTo(b.id);
    });

    final entries = <ReconcileEntry>[];
    final dayCounts = <DateTime, int>{};
    final dayNetChanges = <DateTime, double>{};
    final balanceSeries = <double>[startBalance];

    var running = startBalance;
    for (final tx in inRange) {
      final signed = _signedAmount(tx, accountId);
      running += signed;
      final day = _dayKey(tx.timestamp);
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      dayNetChanges[day] = (dayNetChanges[day] ?? 0) + signed;
      entries.add(ReconcileEntry(
        transaction: tx,
        signedAmount: signed,
        runningBalance: running,
        day: day,
      ));
      balanceSeries.add(running);
    }

    return ReconcileResult(
      summary: ReconcileSummary(
        startBalance: startBalance,
        endBalance: endBalance,
        income: income,
        expense: expense,
        transferIn: transferIn,
        transferOut: transferOut,
        netChange: netChange,
      ),
      entries: entries,
      dayCounts: dayCounts,
      dayNetChanges: dayNetChanges,
      balanceSeries: balanceSeries,
      minDate: minDate,
      maxDate: maxDate,
      transactionYears: years,
    );
  }

  static String _normalizeType(JiveTransaction tx) {
    final type = tx.type;
    if (type == null || type.isEmpty) return 'expense';
    return type;
  }

  static double _signedAmount(JiveTransaction tx, int accountId) {
    final type = _normalizeType(tx);
    if (type == 'transfer') {
      if (tx.accountId == accountId && tx.toAccountId == accountId) {
        return 0;
      }
      if (tx.accountId == accountId) return -tx.amount;
      if (tx.toAccountId == accountId) return tx.amount;
      return 0;
    }
    if (tx.accountId != accountId) return 0;
    if (type == 'income') return tx.amount;
    return -tx.amount;
  }

  static DateTime _dayKey(DateTime time) {
    return DateTime(time.year, time.month, time.day);
  }
}
