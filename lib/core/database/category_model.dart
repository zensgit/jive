import 'package:isar/isar.dart';

part 'category_model.g.dart';

// Trigger rebuild
@collection
class JiveCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;          // 唯一标识 (例如: "sys_food_lunch")

  late String name;         // 显示名称 (用户可修改)
  late String iconName;     // 图标名称 (例如: "restaurant")
  String? colorHex;         // 自定义颜色 (#RRGGBB)

  @Index()
  String? parentKey;        // 父分类 Key (空则为一级)

  late int order;           // 排序权重 (越小越前)
  
  late bool isSystem;       // 是否系统预置 (预置分类不可彻底删除，只能隐藏)
  late bool isHidden;       // 是否隐藏
  late bool isIncome;       // true=收入, false=支出

  late DateTime updatedAt;  // 同步用
}
