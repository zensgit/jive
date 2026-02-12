import 'package:isar/isar.dart';

part 'tag_model.g.dart';

@collection
class JiveTag {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key; // stable UUID string

  late String name;
  String? colorHex;
  String? iconName;
  String? iconText;

  @Index()
  String? groupKey;

  @Index()
  String? redirectCategoryKey;

  late int order;
  late bool isArchived;
  late int usageCount;
  DateTime? lastUsedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class JiveTagGroup {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key; // stable UUID string

  late String name;
  String? colorHex;
  String? iconName;
  String? iconText;

  late int order;
  late bool isArchived;

  late DateTime createdAt;
  late DateTime updatedAt;
}
