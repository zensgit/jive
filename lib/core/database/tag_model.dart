import 'package:isar/isar.dart';

part 'tag_model.g.dart';

@collection
class JiveTag {
  Id id = Isar.autoIncrement;

  /// 标签名称（不含 #）
  @Index(unique: true)
  late String name;

  /// 标签颜色（十六进制）
  String? colorHex;

  /// 使用次数
  int usageCount = 0;

  /// 创建时间
  late DateTime createdAt;

  /// 最后使用时间
  DateTime? lastUsedAt;

  /// 是否隐藏
  bool isHidden = false;
}
