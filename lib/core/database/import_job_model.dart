import 'package:isar/isar.dart';

part 'import_job_model.g.dart';

@collection
class JiveImportJob {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? finishedAt;

  @Index()
  late String status;

  @Index()
  late String sourceType;

  late String entryType;

  String? filePath;
  String? fileName;

  String? payloadText;
  String? errorMessage;

  int totalCount = 0;
  int insertedCount = 0;
  int duplicateCount = 0;
  int invalidCount = 0;
  int skippedByDuplicateDecisionCount = 0;

  @Index()
  String duplicatePolicy = 'keep_latest';

  String? decisionSummaryJson;

  int retryCount = 0;

  @Index()
  int? retryFromJobId;
}
