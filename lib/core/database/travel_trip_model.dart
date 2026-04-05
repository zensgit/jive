import 'package:isar/isar.dart';

part 'travel_trip_model.g.dart';

@collection
class JiveTravelTrip {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  late String destination;

  String? note;

  /// 'planning' | 'active' | 'completed' | 'reviewed'
  @Index()
  String status = 'planning';

  late String baseCurrency;

  double? budget;

  DateTime? startDate;
  DateTime? endDate;

  late DateTime createdAt;
  late DateTime updatedAt;
}
