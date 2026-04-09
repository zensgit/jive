import 'package:isar/isar.dart';

import '../sync/sync_key_generator.dart';

part 'account_model.g.dart';

@collection
class JiveAccount {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String name;
  late String type; // asset | liability
  String? subType;
  String? groupName;

  late String currency;
  late String iconName;
  String? colorHex;

  late int order;
  late bool includeInBalance;
  late bool isHidden;
  late bool isArchived;

  int? billingDay;
  int? repaymentDay;
  double? creditLimit;

  double openingBalance = 0;

  @Index()
  String syncKey = SyncKeyGenerator.generate('acct'); // 稳定云端同步标识

  late DateTime updatedAt;
  @Index()
  int? bookId; // 多账本支持 - null 表示默认账本
}
