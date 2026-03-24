import 'package:isar/isar.dart';

part 'merchant_memory_model.g.dart';

/// 商户记忆模型 —— 超越 Yimu 的 AutoParameter
///
/// Yimu 的 AutoParameter：
///   - 精确匹配 shopName
///   - 存最近 3 条 remark（SPLIT 分隔）
///   - 固定的 category/asset/tags
///
/// Jive 的 MerchantMemory：
///   - 模糊匹配（子串 + 别名）
///   - 频次加权分类建议（不是固定值，而是记录每次选择的频次）
///   - 时段感知（同一商户不同时段可能不同分类）
///   - 账户偏好记录
///   - 平均金额参考
///   - 最近备注历史（保留5条而非Yimu的3条）
@collection
class JiveMerchantMemory {
  Id id = Isar.autoIncrement;

  /// 标准化商户名（去空格、转小写）
  @Index(unique: true)
  late String normalizedName;

  /// 原始商户名（首次出现时的形式）
  late String displayName;

  /// 商户别名列表（用于模糊匹配）
  List<String> aliases = [];

  /// 最常用的父分类 Key
  String? topCategoryKey;

  /// 最常用的子分类 Key
  String? topSubCategoryKey;

  /// 分类使用频次 JSON: {"cat_food:sub_lunch": 12, "cat_food:sub_dinner": 5}
  /// 用于频次加权推荐，而非 Yimu 的固定值
  String categoryFrequencyJson = '{}';

  /// 最常用的账户 ID
  int? preferredAccountId;

  /// 账户使用频次 JSON: {"1": 8, "3": 2}
  String accountFrequencyJson = '{}';

  /// 关联的标签 Keys
  List<String> tagKeys = [];

  /// 最近备注历史（最新在前，保留 5 条）
  List<String> recentRemarks = [];

  /// 平均交易金额（参考值）
  double averageAmount = 0;

  /// 总交易次数
  int transactionCount = 0;

  /// 最后一次交易时间
  DateTime? lastTransactionAt;

  /// 来源 App（WeChat, Alipay, Manual 等）
  String? primarySource;

  /// 是否由用户手动确认过（高置信度）
  bool isUserConfirmed = false;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
