import 'package:isar/isar.dart';

part 'quick_action_model.g.dart';

/// Dedicated persistent record for MoneyThings-style One Touch actions.
///
/// This collection is introduced as a non-destructive shadow store over the
/// legacy template table. Existing templates are backfilled into records with
/// stable ids like `template:42`, so old deep links keep working.
@collection
class JiveQuickAction {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String stableId;

  /// `template` for backfilled records. Future sources may use `manual`,
  /// `widget`, or `shortcut` without changing the execution contract.
  late String source;

  int? legacyTemplateId;

  late String name;
  String? iconName;
  String? colorHex;

  /// Transaction type: expense / income / transfer.
  late String transactionType;

  int? bookId;
  int? accountId;
  int? toAccountId;
  String? categoryKey;
  String? subCategoryKey;
  String? categoryName;
  String? subCategoryName;
  List<String> tagKeys = [];
  double? defaultAmount;
  String? defaultNote;

  /// Stored as a string to keep Isar schema evolution simple.
  late String mode;

  bool showOnHome = true;
  bool isPinned = false;
  int sortOrder = 0;
  int usageCount = 0;
  DateTime? lastUsedAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  bool archived = false;
}
