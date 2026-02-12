import 'package:isar/isar.dart';

part 'project_model.g.dart';

@collection
class JiveProject {
  Id id = Isar.autoIncrement;

  /// 项目名称
  @Index()
  late String name;

  /// 项目描述
  String? description;

  /// 项目图标
  String? iconName;

  /// 项目颜色
  String? colorHex;

  /// 预算金额（0表示不限）
  double budget = 0;

  /// 开始日期
  DateTime? startDate;

  /// 结束日期（计划）
  DateTime? endDate;

  /// 实际结束日期
  DateTime? completedDate;

  /// 项目状态: active, completed, archived
  String status = 'active';

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  late DateTime updatedAt;

  /// 排序顺序
  int sortOrder = 0;
}
