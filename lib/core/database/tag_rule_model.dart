import 'package:isar/isar.dart';

part 'tag_rule_model.g.dart';

@collection
class JiveTagRule {
  Id id = Isar.autoIncrement;

  @Index()
  late String tagKey;

  late bool isEnabled;

  String? applyType; // expense | income | transfer | all
  double? minAmount;
  double? maxAmount;
  List<int> accountIds = [];
  String? categoryKey;
  String? subCategoryKey;
  List<String> keywords = [];

  late DateTime createdAt;
  late DateTime updatedAt;
}
