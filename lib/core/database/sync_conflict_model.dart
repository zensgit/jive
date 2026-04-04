import 'package:isar/isar.dart';

part 'sync_conflict_model.g.dart';

@collection
class JiveSyncConflict {
  Id id = Isar.autoIncrement;

  /// Which table: transactions, accounts, categories, tags, budgets
  @Index()
  String table = '';

  /// The local_id of the conflicting record
  int localId = 0;

  /// JSON of the local version
  String localJson = '';

  /// JSON of the remote version
  String remoteJson = '';

  /// Local updatedAt
  DateTime localUpdatedAt = DateTime.now();

  /// Remote updatedAt
  DateTime remoteUpdatedAt = DateTime.now();

  /// Resolution status: pending, keepLocal, keepRemote
  @Index()
  String status = 'pending';

  /// When the conflict was detected
  DateTime detectedAt = DateTime.now();

  /// When the conflict was resolved (null if pending)
  DateTime? resolvedAt;
}
