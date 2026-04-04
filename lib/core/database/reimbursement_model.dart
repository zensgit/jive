import 'package:isar/isar.dart';

part 'reimbursement_model.g.dart';

/// 报销状态常量
class ReimbursementStatus {
  static const String pending = 'pending'; // 待报销
  static const String submitted = 'submitted'; // 已提交
  static const String approved = 'approved'; // 已批准
  static const String received = 'received'; // 已到账
  static const String rejected = 'rejected'; // 已拒绝
}

@collection
class JiveReimbursement {
  Id id = Isar.autoIncrement;

  /// 关联的交易 ID
  @Index()
  late int transactionId;

  /// 报销金额
  late double amount;

  /// 报销标题
  late String title;

  /// 描述（可选）
  String? description;

  /// 状态: pending | submitted | approved | received | rejected
  @Index()
  String status = ReimbursementStatus.pending;

  /// 提交时间
  DateTime? submittedAt;

  /// 批准时间
  DateTime? approvedAt;

  /// 到账时间
  DateTime? receivedAt;

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  @Index()
  late DateTime updatedAt;
}
