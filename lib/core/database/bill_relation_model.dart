import 'package:isar/isar.dart';

part 'bill_relation_model.g.dart';

/// 账单关联（报销/退款追踪）
@collection
class JiveBillRelation {
  Id id = Isar.autoIncrement;

  @Index()
  late int sourceTransactionId;

  @Index()
  int linkedTransactionId = 0;

  /// reimbursement | refund
  @Index()
  late String relationType;

  late double amount;
  late String currency;

  @Index()
  String? groupKey; // 同一次批量操作的分组

  String? note;

  // 结清状态
  bool isSettled = false;
  DateTime? settledAt;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

enum BillRelationType {
  reimbursement('reimbursement'),
  refund('refund');

  final String value;
  const BillRelationType(this.value);
  static BillRelationType fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => reimbursement);
}

class BillSettlementSummary {
  final int sourceTransactionId;
  final int reimbursementCount;
  final int refundCount;
  final double reimbursementTotal;
  final double refundTotal;
  final double netRecovered;

  const BillSettlementSummary({
    required this.sourceTransactionId,
    required this.reimbursementCount,
    required this.refundCount,
    required this.reimbursementTotal,
    required this.refundTotal,
    required this.netRecovered,
  });
}
