import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class JiveTransaction {
  Id id = Isar.autoIncrement; // 自动生成 ID

  late double amount;         // 金额
  late String source;         // 来源: WeChat, Alipay
  
  @Index()                    // 加索引，方便按时间查询
  late DateTime timestamp;    // 交易时间

  String? rawText;            // 原始通知内容
  String? category;           // 父分类 (如: 餐饮)
  String? subCategory;        // 子分类 (如: 早餐)
  @Index()
  String? categoryKey;        // 父分类 Key (稳定标识)
  @Index()
  String? subCategoryKey;     // 子分类 Key (稳定标识)
  String? type;               // expense | income | transfer
  String? note;               // 备注
  @Index()
  int? accountId;             // 账户 ID
  @Index()
  int? toAccountId;           // 转账目标账户 ID
  @Index()
  int? projectId;             // 关联项目 ID
  List<String> tagKeys = [];  // 标签 Key 列表 (UUID)
  List<String> smartTagKeys = []; // 智能规则自动添加的标签 Key
}
