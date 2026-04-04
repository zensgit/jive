import 'package:isar/isar.dart';

import '../database/reimbursement_model.dart';

class ReimbursementWorkflowService {
  final Isar _isar;

  ReimbursementWorkflowService(this._isar);

  /// 创建报销记录
  Future<JiveReimbursement> createReimbursement({
    required int transactionId,
    required double amount,
    required String title,
    String? description,
  }) async {
    if (amount <= 0) {
      throw StateError('报销金额必须大于 0');
    }
    final now = DateTime.now();
    final item = JiveReimbursement()
      ..transactionId = transactionId
      ..amount = _round2(amount)
      ..title = title.trim()
      ..description = description?.trim()
      ..status = ReimbursementStatus.pending
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveReimbursements.put(item);
    });
    return item;
  }

  /// 更新报销状态，自动写入对应时间戳
  Future<JiveReimbursement> updateStatus(int id, String newStatus) async {
    final item = await _isar.jiveReimbursements.get(id);
    if (item == null) {
      throw StateError('找不到报销记录');
    }

    final now = DateTime.now();
    item.status = newStatus;
    item.updatedAt = now;

    switch (newStatus) {
      case ReimbursementStatus.submitted:
        item.submittedAt ??= now;
      case ReimbursementStatus.approved:
        item.approvedAt ??= now;
      case ReimbursementStatus.received:
        item.receivedAt ??= now;
    }

    await _isar.writeTxn(() async {
      await _isar.jiveReimbursements.put(item);
    });
    return item;
  }

  /// 按状态筛选报销记录
  Future<List<JiveReimbursement>> getByStatus(String status) async {
    return _isar.jiveReimbursements
        .filter()
        .statusEqualTo(status)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 获取所有报销记录
  Future<List<JiveReimbursement>> getAll() async {
    return _isar.jiveReimbursements.where().sortByUpdatedAtDesc().findAll();
  }

  /// 删除报销记录
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveReimbursements.delete(id);
    });
  }

  /// 获取报销汇总
  Future<ReimbursementSummary> getSummary() async {
    final all = await _isar.jiveReimbursements.where().findAll();

    var pendingCount = 0;
    var pendingAmount = 0.0;
    var receivedCount = 0;
    var receivedAmount = 0.0;
    var totalAmount = 0.0;

    for (final item in all) {
      totalAmount += item.amount;
      if (item.status == ReimbursementStatus.pending ||
          item.status == ReimbursementStatus.submitted ||
          item.status == ReimbursementStatus.approved) {
        pendingCount++;
        pendingAmount += item.amount;
      } else if (item.status == ReimbursementStatus.received) {
        receivedCount++;
        receivedAmount += item.amount;
      }
    }

    return ReimbursementSummary(
      pendingCount: pendingCount,
      pendingAmount: _round2(pendingAmount),
      receivedCount: receivedCount,
      receivedAmount: _round2(receivedAmount),
      totalAmount: _round2(totalAmount),
    );
  }

  double _round2(double value) {
    return (value * 100).round() / 100;
  }
}

class ReimbursementSummary {
  final int pendingCount;
  final double pendingAmount;
  final int receivedCount;
  final double receivedAmount;
  final double totalAmount;

  const ReimbursementSummary({
    required this.pendingCount,
    required this.pendingAmount,
    required this.receivedCount,
    required this.receivedAmount,
    required this.totalAmount,
  });
}
