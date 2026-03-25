import 'package:isar/isar.dart';
part 'bill_split_model.g.dart';

/// AA账单拆分 - 主记录
@collection
class JiveBillSplit {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key; // UUID

  late String title;        // e.g. "日本旅行餐费"
  late double totalAmount;
  String currency = 'CNY';

  @Index()
  String? paidByName;       // who paid upfront
  String? note;

  @Index()
  String status = 'open';   // open | settled

  int? linkedTransactionId; // optional link to JiveTransaction

  late DateTime createdAt;
  late DateTime updatedAt;
}

/// 拆分成员
@collection
class JiveSplitMember {
  Id id = Isar.autoIncrement;

  @Index()
  late int splitId; // FK → JiveBillSplit.id

  late String name;         // member name
  late double shareAmount;  // their share
  bool isPaid = false;
  DateTime? paidAt;
  String? note;

  late DateTime createdAt;
  late DateTime updatedAt;
}
