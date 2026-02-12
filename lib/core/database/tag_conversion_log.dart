import 'package:isar/isar.dart';

part 'tag_conversion_log.g.dart';

@collection
class JiveTagConversionLog {
  Id id = Isar.autoIncrement;

  @Index()
  late String tagKey;
  late String tagName;

  @Index()
  late String categoryKey;
  String? parentCategoryKey;

  late String categoryName;
  String? parentCategoryName;
  late bool categoryIsIncome;

  late String migratePolicy;
  late bool keepTagActive;
  late int taggedTransactionCount;
  late int updatedTransactionCount;
  late int skippedExistingCategoryCount;
  late int skippedTypeMismatchCount;
  late int skippedUnknownCategoryCount;
  late int skippedByPolicyCount;
  List<int> updatedTransactionIds = [];

  late DateTime createdAt;
}
