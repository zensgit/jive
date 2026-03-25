import 'package:isar/isar.dart';

import '../database/debt_model.dart';

class DebtService {
  final Isar _isar;

  DebtService(this._isar);

  /// 创建借贷记录
  Future<JiveDebt> createDebt({
    required String type,
    required String personName,
    required double amount,
    required DateTime borrowDate,
    String? personContact,
    String? note,
    DateTime? dueDate,
    String currency = 'CNY',
  }) async {
    final now = DateTime.now();
    final debt = JiveDebt()
      ..type = type
      ..personName = personName.trim()
      ..personContact = personContact
      ..amount = amount
      ..currency = currency
      ..borrowDate = borrowDate
      ..dueDate = dueDate
      ..note = note
      ..status = DebtStatus.active
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveDebts.put(debt);
    });
    return debt;
  }

  /// 记录还款
  Future<void> recordPayment({
    required JiveDebt debt,
    required double amount,
    required DateTime paymentDate,
    String? note,
    int? transactionId,
  }) async {
    final payment = JiveDebtPayment()
      ..debtId = debt.id
      ..amount = amount
      ..paymentDate = paymentDate
      ..note = note
      ..transactionId = transactionId
      ..createdAt = DateTime.now();

    debt.paidAmount += amount;
    debt.updatedAt = DateTime.now();

    // 自动结清
    if (debt.paidAmount >= debt.amount) {
      debt.status = DebtStatus.settled;
      debt.settledDate = paymentDate;
    }

    if (transactionId != null && !debt.transactionIds.contains(transactionId)) {
      debt.transactionIds = [...debt.transactionIds, transactionId];
    }

    await _isar.writeTxn(() async {
      await _isar.jiveDebtPayments.put(payment);
      await _isar.jiveDebts.put(debt);
    });
  }

  /// 获取活跃的借贷
  Future<List<JiveDebt>> getActiveDebts() async {
    return _isar.jiveDebts
        .filter()
        .statusEqualTo(DebtStatus.active)
        .sortByBorrowDateDesc()
        .findAll();
  }

  /// 获取已结清的借贷
  Future<List<JiveDebt>> getSettledDebts() async {
    return _isar.jiveDebts
        .filter()
        .statusEqualTo(DebtStatus.settled)
        .sortByBorrowDateDesc()
        .findAll();
  }

  /// 获取某条借贷的还款记录
  Future<List<JiveDebtPayment>> getPayments(int debtId) async {
    return _isar.jiveDebtPayments
        .filter()
        .debtIdEqualTo(debtId)
        .sortByPaymentDateDesc()
        .findAll();
  }

  /// 手动结清
  Future<void> settleDebt(JiveDebt debt) async {
    debt.status = DebtStatus.settled;
    debt.settledDate = DateTime.now();
    debt.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveDebts.put(debt);
    });
  }

  /// 删除借贷
  Future<void> deleteDebt(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveDebtPayments.filter().debtIdEqualTo(id).deleteAll();
      await _isar.jiveDebts.delete(id);
    });
  }

  /// 汇总统计
  Future<DebtSummary> getSummary() async {
    final active = await getActiveDebts();
    double totalLent = 0;
    double totalBorrowed = 0;
    int overdueCount = 0;

    for (final d in active) {
      if (d.type == DebtType.lent) {
        totalLent += d.remainingAmount;
      } else {
        totalBorrowed += d.remainingAmount;
      }
      if (d.isOverdue) overdueCount++;
    }

    return DebtSummary(
      totalLent: totalLent,
      totalBorrowed: totalBorrowed,
      activeCount: active.length,
      overdueCount: overdueCount,
    );
  }
}

class DebtSummary {
  final double totalLent;
  final double totalBorrowed;
  final int activeCount;
  final int overdueCount;

  const DebtSummary({
    required this.totalLent,
    required this.totalBorrowed,
    required this.activeCount,
    required this.overdueCount,
  });

  double get netBalance => totalLent - totalBorrowed;
}
