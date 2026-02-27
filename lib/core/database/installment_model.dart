import 'package:isar/isar.dart';

part 'installment_model.g.dart';

@collection
class JiveInstallment {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String name;

  /// 信用卡账户（liability + credit）
  @Index()
  late int accountId;

  String? categoryKey;
  String? subCategoryKey;
  String? note;

  late String currency;
  late double principalAmount;
  double totalFee = 0;

  /// 总期数
  late int totalPeriods;

  /// 已执行期数（已生成草稿或已入账）
  int executedPeriods = 0;

  /// average | first | last
  String feeType = InstallmentFeeType.average.value;

  /// average_first | average_last | round_first | round_last | int_first | int_last
  String remainderType = InstallmentRemainderType.averageFirst.value;

  /// 是否将剩余本金计入信用卡欠款
  bool includePrincipalInLiability = true;

  /// 是否将剩余利息计入信用卡欠款
  bool includeFeeInLiability = true;

  /// draft | commit
  String commitMode = InstallmentCommitMode.draft.value;

  @Index()
  late DateTime startDate;

  @Index()
  late DateTime nextDueAt;

  DateTime? finishedAt;

  /// active | finished | prepaid | cancelled
  @Index()
  String status = InstallmentStatus.active.value;

  bool isActive = true;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

enum InstallmentFeeType {
  average('average'),
  first('first'),
  last('last');

  final String value;

  const InstallmentFeeType(this.value);

  static InstallmentFeeType fromValue(String value) {
    return InstallmentFeeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InstallmentFeeType.average,
    );
  }
}

enum InstallmentRemainderType {
  averageFirst('average_first'),
  averageLast('average_last'),
  roundFirst('round_first'),
  roundLast('round_last'),
  intFirst('int_first'),
  intLast('int_last');

  final String value;

  const InstallmentRemainderType(this.value);

  static InstallmentRemainderType fromValue(String value) {
    return InstallmentRemainderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InstallmentRemainderType.averageFirst,
    );
  }
}

enum InstallmentStatus {
  active('active'),
  finished('finished'),
  prepaid('prepaid'),
  cancelled('cancelled');

  final String value;

  const InstallmentStatus(this.value);

  static InstallmentStatus fromValue(String value) {
    return InstallmentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InstallmentStatus.active,
    );
  }
}

enum InstallmentCommitMode {
  draft('draft'),
  commit('commit');

  final String value;

  const InstallmentCommitMode(this.value);

  static InstallmentCommitMode fromValue(String value) {
    return InstallmentCommitMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InstallmentCommitMode.draft,
    );
  }
}

class InstallmentPlanItem {
  final int period;
  final DateTime dueAt;
  final double principal;
  final double fee;

  const InstallmentPlanItem({
    required this.period,
    required this.dueAt,
    required this.principal,
    required this.fee,
  });

  double get total => principal + fee;
}
