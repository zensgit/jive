import 'package:isar/isar.dart';

import '../database/receivable_model.dart';

class ReceivableService {
  final Isar _isar;

  ReceivableService(this._isar);

  /// 创建应收/应付记录
  Future<JiveReceivable> create({
    required String personName,
    required double amount,
    required String type,
    DateTime? dueDate,
    String? note,
  }) async {
    final now = DateTime.now();
    final item = JiveReceivable()
      ..personName = personName.trim()
      ..amount = amount
      ..type = type
      ..status = ReceivableStatus.pending
      ..dueDate = dueDate
      ..note = note
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveReceivables.put(item);
    });
    return item;
  }

  /// 记录付款，自动更新状态
  Future<void> recordPayment(int id, double amount) async {
    final item = await _isar.jiveReceivables.get(id);
    if (item == null) return;

    item.paidAmount += amount;
    item.updatedAt = DateTime.now();

    if (item.paidAmount >= item.amount) {
      item.status = ReceivableStatus.completed;
    } else if (item.paidAmount > 0) {
      item.status = ReceivableStatus.partial;
    }

    await _isar.writeTxn(() async {
      await _isar.jiveReceivables.put(item);
    });
  }

  /// 标记为坏账
  Future<void> markBadDebt(int id) async {
    final item = await _isar.jiveReceivables.get(id);
    if (item == null) return;

    item.status = ReceivableStatus.badDebt;
    item.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveReceivables.put(item);
    });
  }

  /// 按类型获取列表
  Future<List<JiveReceivable>> getByType(String type) async {
    return _isar.jiveReceivables
        .filter()
        .typeEqualTo(type)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 获取汇总
  Future<ReceivableSummary> getSummary() async {
    final all = await _isar.jiveReceivables
        .filter()
        .not()
        .statusEqualTo(ReceivableStatus.badDebt)
        .findAll();

    double totalReceivable = 0;
    double totalPayable = 0;
    int overdueCount = 0;

    for (final item in all) {
      if (item.isCompleted) continue;
      if (item.type == ReceivableType.receivable) {
        totalReceivable += item.remainingAmount;
      } else {
        totalPayable += item.remainingAmount;
      }
      if (item.isOverdue) overdueCount++;
    }

    return ReceivableSummary(
      totalReceivable: totalReceivable,
      totalPayable: totalPayable,
      overdueCount: overdueCount,
    );
  }

  /// 删除记录
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveReceivables.delete(id);
    });
  }
}

class ReceivableSummary {
  final double totalReceivable;
  final double totalPayable;
  final int overdueCount;

  const ReceivableSummary({
    required this.totalReceivable,
    required this.totalPayable,
    required this.overdueCount,
  });

  double get netBalance => totalReceivable - totalPayable;
}
