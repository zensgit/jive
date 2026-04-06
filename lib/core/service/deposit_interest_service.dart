import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/fixed_deposit_model.dart';
import '../database/transaction_model.dart';
import 'transaction_service.dart';

/// Service that automatically detects matured fixed deposits and records
/// the corresponding interest as income transactions.
class DepositInterestService {
  final Isar isar;

  static const _processedKeyPrefix = 'deposit_interest_processed_';

  DepositInterestService(this.isar);

  /// Return all deposits whose maturity date has passed but are still active.
  Future<List<JiveFixedDeposit>> checkMaturedDeposits() async {
    final now = DateTime.now();
    return isar.jiveFixedDeposits
        .filter()
        .statusEqualTo('active')
        .maturityDateLessThan(now)
        .findAll();
  }

  /// Calculate the earned interest for [deposit] and create an income
  /// transaction of category '利息'.  Updates the deposit status to 'matured'.
  Future<void> calculateAndRecordInterest(JiveFixedDeposit deposit) async {
    final interest = deposit.expectedInterest;
    if (interest <= 0) return;

    final tx = JiveTransaction()
      ..amount = interest
      ..source = 'system'
      ..timestamp = deposit.maturityDate
      ..type = 'income'
      ..category = '其他'
      ..subCategory = '利息'
      ..note = '定期存款到期利息: ${deposit.name}'
      ..accountId = deposit.accountId;

    TransactionService.touchSyncMetadata(tx);

    await isar.writeTxn(() async {
      await isar.jiveTransactions.put(tx);

      deposit.status = 'matured';
      deposit.updatedAt = DateTime.now();
      await isar.jiveFixedDeposits.put(deposit);
    });

    // Mark as processed so we don't re-process on next launch.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_processedKeyPrefix${deposit.id}', true);
  }

  /// Check all active deposits and record interest for newly-matured ones.
  /// Returns the number of deposits processed.
  Future<int> processAllMaturedDeposits() async {
    final prefs = await SharedPreferences.getInstance();
    final matured = await checkMaturedDeposits();
    int count = 0;

    for (final deposit in matured) {
      final alreadyProcessed =
          prefs.getBool('$_processedKeyPrefix${deposit.id}') ?? false;
      if (alreadyProcessed) continue;

      try {
        await calculateAndRecordInterest(deposit);
        count++;
      } catch (e) {
        debugPrint('Failed to process deposit ${deposit.id}: $e');
      }
    }

    return count;
  }
}
