import 'package:isar/isar.dart';

part 'dream_log_model.g.dart';

@collection
class JiveDreamLog {
  Id id = Isar.autoIncrement;

  @Index()
  late int goalId;

  late double amount;

  String note = '';

  late DateTime createdAt;
}
