import 'package:isar/isar.dart';

part 'auto_draft_model.g.dart';

@collection
class JiveAutoDraft {
  Id id = Isar.autoIncrement;

  late double amount;
  late String source;

  @Index()
  late DateTime timestamp;

  String? rawText;
  String? metadataJson;
  String? type; // expense | income | transfer

  String? category;
  String? subCategory;

  @Index()
  String? categoryKey;

  @Index()
  String? subCategoryKey;

  int? accountId;
  int? toAccountId;

  @Index()
  String? dedupKey;

  late DateTime createdAt;

  List<String> tagKeys = [];

  @Index()
  int? recurringRuleId;

  @Index()
  String? recurringKey;
}
