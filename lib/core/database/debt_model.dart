import 'package:isar/isar.dart';

part 'debt_model.g.dart';

/// 借贷状态
class DebtStatus {
  static const String active = 'active';
  static const String settled = 'settled';
}

/// 借贷类型
class DebtType {
  static const String lent = 'lent'; // 我借出（别人欠我）
  static const String borrowed = 'borrowed'; // 我借入（我欠别人）
}

@collection
class JiveDebt {
  Id id = Isar.autoIncrement;

  /// 借贷类型: lent / borrowed
  @Index()
  late String type;

  /// 对方姓名
  @Index()
  late String personName;

  /// 对方联系方式（可选）
  String? personContact;

  /// 原始金额
  late double amount;

  /// 币种
  String currency = 'CNY';

  /// 已还金额
  double paidAmount = 0;

  /// 备注
  String? note;

  /// 借贷日期
  late DateTime borrowDate;

  /// 预计还款日（可选）
  DateTime? dueDate;

  /// 实际结清日
  DateTime? settledDate;

  /// 状态: active / settled
  @Index()
  String status = DebtStatus.active;

  /// 关联的交易 ID 列表
  List<int> transactionIds = [];

  late DateTime createdAt;
  late DateTime updatedAt;

  /// 剩余金额
  double get remainingAmount => amount - paidAmount;

  /// 是否已结清
  bool get isSettled => status == DebtStatus.settled;

  /// 是否逾期
  bool get isOverdue =>
      !isSettled && dueDate != null && DateTime.now().isAfter(dueDate!);
}

/// 还款记录
@collection
class JiveDebtPayment {
  Id id = Isar.autoIncrement;

  /// 关联的借贷 ID
  @Index()
  late int debtId;

  /// 还款金额
  late double amount;

  /// 还款日期
  late DateTime paymentDate;

  /// 备注
  String? note;

  /// 关联的交易 ID（可选）
  int? transactionId;

  late DateTime createdAt;
}
