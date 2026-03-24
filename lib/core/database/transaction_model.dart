import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class JiveTransaction {
  Id id = Isar.autoIncrement; // 自动生成 ID

  late double amount; // 金额
  late String source; // 来源: WeChat, Alipay

  @Index() // 加索引，方便按时间查询
  late DateTime timestamp; // 交易时间

  String? rawText; // 原始通知内容
  String? category; // 父分类 (如: 餐饮)
  String? subCategory; // 子分类 (如: 早餐)
  @Index()
  String? categoryKey; // 父分类 Key (稳定标识)
  @Index()
  String? subCategoryKey; // 子分类 Key (稳定标识)
  String? type; // expense | income | transfer
  String? note; // 备注
  @Index()
  int? accountId; // 账户 ID
  @Index()
  int? toAccountId; // 转账目标账户 ID
  double? toAmount; // 跨币种转账时的转入金额
  double? exchangeRate; // 跨币种转账时使用的汇率
  double? exchangeFee; // 换汇手续费
  String? exchangeFeeType; // 手续费类型: fixed(固定金额), percent(百分比)
  @Index()
  int? projectId; // 关联项目 ID
  List<String> tagKeys = []; // 标签 Key 列表 (UUID)
  bool excludeFromBudget = false; // 不计入预算（预算/预算统计中忽略）
  List<String> smartTagKeys = []; // 智能规则自动添加的标签 Key
  List<String> smartTagOptOutKeys = []; // 对应标签不再自动打标
  bool smartTagOptOutAll = false; // 本笔交易停用全部智能标签
  @Index()
  int? recurringRuleId; // 关联周期规则 ID
  @Index()
  String? recurringKey; // 周期入账去重 Key
  @Index()
  DateTime updatedAt = DateTime.now(); // 同步游标与增量同步使用
  @Index()
  int? bookId; // 多账本支持 - null 表示默认账本
  List<String> attachmentPaths = []; // 附件文件路径
}
