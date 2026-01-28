import 'package:isar/isar.dart';

part 'template_model.g.dart';

@collection
class JiveTemplate {
  Id id = Isar.autoIncrement;

  /// 模板名称
  @Index()
  late String name;

  /// 模板描述（可选）
  String? description;

  /// 交易金额（0表示每次输入）
  double amount = 0;

  /// 交易类型: income, expense, transfer
  late String type;

  /// 账户ID
  int? accountId;

  /// 目标账户ID（转账用）
  int? toAccountId;

  /// 分类Key
  String? categoryKey;

  /// 子分类Key
  String? subCategoryKey;

  /// 分类名称（冗余存储）
  String? category;

  /// 子分类名称（冗余存储）
  String? subCategory;

  /// 默认备注
  String? note;

  /// 使用次数（用于排序）
  int usageCount = 0;

  /// 最后使用时间
  DateTime? lastUsedAt;

  /// 创建时间
  late DateTime createdAt;

  /// 是否置顶
  bool isPinned = false;

  /// 分组名称（可选）
  String? groupName;
}
