import 'package:isar/isar.dart';

part 'account_model.g.dart';

@collection
class JiveAccount {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String name;
  late String type; // asset | liability
  String? subType;

  late String currency;
  late String iconName;
  String? colorHex;

  late int order;
  late bool includeInBalance;
  late bool isHidden;
  late bool isArchived;

  double openingBalance = 0;

  late DateTime updatedAt;
}
