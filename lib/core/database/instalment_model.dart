import 'package:isar/isar.dart';

part 'instalment_model.g.dart';

@collection
class JiveInstalment {
  Id id = Isar.autoIncrement;

  late String name;
  late double totalAmount;
  late int instalmentCount;
  late int paidCount;
  late double monthlyAmount;
  late DateTime startDate;

  @Index()
  late DateTime nextPaymentDate;

  int? accountId;
  String? categoryKey;
  String? note;

  @Index()
  late String status;

  late DateTime createdAt;
}
