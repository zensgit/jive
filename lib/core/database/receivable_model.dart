import 'package:isar/isar.dart';

part 'receivable_model.g.dart';

/// 应收/应付类型
class ReceivableType {
  static const String receivable = 'receivable'; // 应收（别人欠我）
  static const String payable = 'payable'; // 应付（我欠别人）
}

/// 应收/应付状态
class ReceivableStatus {
  static const String pending = 'pending'; // 待结算
  static const String partial = 'partial'; // 部分结算
  static const String completed = 'completed'; // 已结清
  static const String badDebt = 'bad_debt'; // 坏账
}

@collection
class JiveReceivable {
  Id id = Isar.autoIncrement;

  /// 对方姓名
  @Index()
  late String personName;

  /// 金额
  late double amount;

  /// 备注
  String? note;

  /// 类型: receivable | payable
  @Index()
  late String type;

  /// 状态: pending | partial | completed | bad_debt
  @Index()
  late String status;

  /// 已付金额
  double paidAmount = 0;

  /// 到期日（可选）
  DateTime? dueDate;

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  late DateTime updatedAt;

  /// 剩余金额
  double get remainingAmount => amount - paidAmount;

  /// 是否已结清
  bool get isCompleted => status == ReceivableStatus.completed;

  /// 是否逾期
  bool get isOverdue =>
      !isCompleted &&
      status != ReceivableStatus.badDebt &&
      dueDate != null &&
      DateTime.now().isAfter(dueDate!);
}
