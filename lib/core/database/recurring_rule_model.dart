import 'package:isar/isar.dart';

part 'recurring_rule_model.g.dart';

@collection
class JiveRecurringRule {
  Id id = Isar.autoIncrement;

  late String name;

  /// expense | income | transfer
  late String type;

  late double amount;

  int? accountId;
  int? toAccountId;

  String? categoryKey;
  String? subCategoryKey;

  String? note;
  List<String> tagKeys = [];

  int? projectId;

  /// draft | commit
  late String commitMode;

  late DateTime startDate;
  DateTime? endDate;

  /// day | week | month | year
  late String intervalType;
  late int intervalValue;

  int? dayOfMonth;
  int? dayOfWeek;

  @Index()
  late DateTime nextRunAt;

  DateTime? lastRunAt;

  late bool isActive;

  late DateTime createdAt;
  late DateTime updatedAt;
}
