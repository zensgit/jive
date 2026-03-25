import 'package:isar/isar.dart';
part 'savings_goal_model.g.dart';

@collection
class JiveSavingsGoal {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  String? emoji;       // e.g. "🏖️"
  String? colorHex;   // e.g. "#2E7D32"
  String? note;

  late double targetAmount;
  double currentAmount = 0;

  @Index()
  String status = 'active'; // active | achieved | abandoned

  DateTime? deadline;

  late DateTime createdAt;
  late DateTime updatedAt;
}
