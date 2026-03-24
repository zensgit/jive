import 'package:isar/isar.dart';

part 'book_model.g.dart';

@collection
class JiveBook {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key; // 唯一标识 (例如: "book_default")

  late String name; // 显示名称 (例如: "默认账本")
  String? iconName; // 图标名称
  String? colorHex; // 自定义颜色
  late String currency; // 默认币种 (例如: "CNY")

  late int order; // 排序权重
  late bool isDefault; // 是否默认账本
  late bool isArchived; // 是否归档

  late DateTime createdAt;
  late DateTime updatedAt;
}
