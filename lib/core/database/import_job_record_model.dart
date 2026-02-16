import 'package:isar/isar.dart';

part 'import_job_record_model.g.dart';

@collection
class JiveImportJobRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late int jobId;

  late int sourceLineNumber;
  late double amount;
  late String source;

  @Index()
  late DateTime timestamp;

  String? type;
  double confidence = 0;
  String warningsJson = '[]';
  String dedupKey = '';

  @Index()
  String riskLevel = 'none'; // none | batch | existing | both

  @Index()
  String decision = 'invalid'; // inserted | duplicate | invalid | skipped_policy | skipped_keep_latest_existing_newer

  String? decisionReason;

  @Index()
  late DateTime createdAt;
}
