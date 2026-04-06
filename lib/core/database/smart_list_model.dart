import 'package:isar/isar.dart';

part 'smart_list_model.g.dart';

/// 保存的筛选视图 — 用户可将搜索/筛选条件命名保存，快速访问常用数据切面。
@collection
class JiveSmartList {
  Id id = Isar.autoIncrement;

  late String name; // 用户命名："本月餐饮"、"大额支出"
  String? iconName; // 图标
  String? colorHex; // 颜色

  // ── 筛选条件 ──

  /// 逗号分隔的分类 key
  String? categoryKeys;

  /// 逗号分隔的标签 key
  String? tagKeys;

  /// 关联账户 ID
  int? accountId;

  /// 关联账本 ID
  int? bookId;

  /// 交易类型: expense / income / transfer
  String? transactionType;

  /// 最小金额
  double? minAmount;

  /// 最大金额
  double? maxAmount;

  /// 日期范围类型: last7d / last30d / thisMonth / custom
  String? dateRangeType;

  /// 自定义起始日期（dateRangeType == 'custom' 时生效）
  DateTime? customStartDate;

  /// 自定义结束日期
  DateTime? customEndDate;

  /// 备注关键词
  String? keyword;

  // ── 排序 / 元数据 ──

  int sortOrder = 0;
  bool isPinned = false;
  DateTime createdAt = DateTime.now();
}
