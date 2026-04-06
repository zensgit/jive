import 'package:isar/isar.dart';

part 'billing_cycle_model.g.dart';

@collection
class JiveBillingCycle {
  Id id = Isar.autoIncrement;

  @Index()
  late int accountId;

  late String accountName;

  /// 账单日（1-31）
  late int billingDay;

  /// 还款日（1-31）
  late int dueDay;

  /// 提前提醒天数
  int reminderDaysBefore = 3;

  bool isEnabled = true;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
