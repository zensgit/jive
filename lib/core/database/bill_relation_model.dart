import 'package:isar/isar.dart';

part 'bill_relation_model.g.dart';

@collection
class JiveBillRelation {
  Id id = Isar.autoIncrement;

  /// 原始账单
  @Index()
  late int sourceTransactionId;

  /// 关联生成账单（报销入账或退款记录）
  @Index()
  late int linkedTransactionId;

  /// reimbursement | refund
  @Index()
  late String relationType;

  late double amount;
  late String currency;

  /// 同一次批量操作的分组 key（可选）
  @Index()
  String? groupKey;

  String? note;

  DateTime createdAt = DateTime.now();
}

enum BillRelationType {
  reimbursement('reimbursement'),
  refund('refund');

  final String value;

  const BillRelationType(this.value);

  static BillRelationType fromValue(String value) {
    return BillRelationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BillRelationType.reimbursement,
    );
  }
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
