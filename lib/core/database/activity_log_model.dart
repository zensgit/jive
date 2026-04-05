import 'package:isar/isar.dart';

part 'activity_log_model.g.dart';

/// Tracks data changes for accountability, especially in shared ledgers.
@collection
class JiveActivityLog {
  Id id = Isar.autoIncrement;

  /// Action type: 'create', 'update', 'delete'
  late String action;

  /// Entity type: 'transaction', 'account', 'budget', 'category', 'goal', 'ledger'
  @Index()
  late String entityType;

  /// ID of the affected entity
  late int entityId;

  /// Human-readable description of the entity
  late String entityName;

  /// User ID who performed the action
  late String userId;

  /// Display name of the user
  late String userName;

  /// Optional JSON diff or description of the change
  String? details;

  /// Which book/ledger this change belongs to
  @Index()
  String? bookKey;

  /// When the action was performed
  @Index()
  DateTime createdAt = DateTime.now();
}
