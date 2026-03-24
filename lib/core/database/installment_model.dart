import 'package:isar/isar.dart';

part 'installment_model.g.dart';

@collection
class JiveInstallment {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String name;

  @Index()
  late int accountId; // 信用卡账户

  String? categoryKey;
  String? subCategoryKey;
  String? note;

  late String currency;
  late double principalAmount;
  double totalFee = 0;

  late int totalPeriods;
  int executedPeriods = 0;

  /// average | first | last
  String feeType = InstallmentFeeType.average.value;
  String remainderType = InstallmentRemainderType.averageFirst.value;

  bool includePrincipalInLiability = true;
  bool includeFeeInLiability = true;

  /// draft | commit
  String commitMode = InstallmentCommitMode.draft.value;

  @Index()
  late DateTime startDate;
  @Index()
  late DateTime nextDueAt;
  DateTime? finishedAt;

  @Index()
  String status = InstallmentStatus.active.value;
  bool isActive = true;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

enum InstallmentFeeType {
  average('average'), first('first'), last('last');
  final String value;
  const InstallmentFeeType(this.value);
  static InstallmentFeeType fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => average);
}

enum InstallmentRemainderType {
  averageFirst('average_first'), averageLast('average_last'),
  roundFirst('round_first'), roundLast('round_last'),
  intFirst('int_first'), intLast('int_last');
  final String value;
  const InstallmentRemainderType(this.value);
  static InstallmentRemainderType fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => averageFirst);
}

enum InstallmentStatus {
  active('active'), finished('finished'), prepaid('prepaid'), cancelled('cancelled');
  final String value;
  const InstallmentStatus(this.value);
  static InstallmentStatus fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => active);
}

enum InstallmentCommitMode {
  draft('draft'), commit('commit');
  final String value;
  const InstallmentCommitMode(this.value);
  static InstallmentCommitMode fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => draft);
}

class InstallmentPlanItem {
  final int period;
  final DateTime dueAt;
  final double principal;
  final double fee;
  const InstallmentPlanItem({
    required this.period, required this.dueAt,
    required this.principal, required this.fee,
  });
  double get total => principal + fee;
}
