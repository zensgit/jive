import 'package:isar/isar.dart';

import '../database/import_job_model.dart';
import '../database/import_job_record_model.dart';

class ImportJobHistorySnapshot {
  const ImportJobHistorySnapshot({required this.jobs, required this.records});

  final List<JiveImportJob> jobs;
  final List<JiveImportJobRecord> records;
}

class ImportJobHistoryRepository {
  ImportJobHistoryRepository(this.isar);

  final Isar isar;

  Future<JiveImportJob?> getJob(int jobId) {
    return isar.collection<JiveImportJob>().get(jobId);
  }

  Future<List<JiveImportJob>> listRecentJobs({int limit = 20}) async {
    return isar
        .collection<JiveImportJob>()
        .where()
        .sortByCreatedAtDesc()
        .limit(limit.clamp(1, 200))
        .findAll();
  }

  Future<List<JiveImportJobRecord>> listJobRecords(
    int jobId, {
    String? decision,
    String? riskLevel,
    int limit = 200,
    int offset = 0,
  }) async {
    final records = await isar
        .collection<JiveImportJobRecord>()
        .filter()
        .jobIdEqualTo(jobId)
        .findAll();
    final filtered = records.where((record) {
      if (decision != null &&
          decision.trim().isNotEmpty &&
          decision != 'all' &&
          record.decision != decision) {
        return false;
      }
      if (riskLevel != null &&
          riskLevel.trim().isNotEmpty &&
          riskLevel != 'all' &&
          record.riskLevel != riskLevel) {
        return false;
      }
      return true;
    }).toList();
    filtered.sort((a, b) {
      final lineComp = a.sourceLineNumber.compareTo(b.sourceLineNumber);
      if (lineComp != 0) return lineComp;
      return a.id.compareTo(b.id);
    });
    if (offset >= filtered.length) return const [];
    final end = (offset + limit).clamp(0, filtered.length);
    return filtered.sublist(offset, end);
  }

  Future<int> createPendingJob({
    required DateTime createdAt,
    required String sourceType,
    required String entryType,
    required String? filePath,
    required String? fileName,
    required String? payloadText,
    required String duplicatePolicy,
    required int? retryFromJobId,
  }) async {
    final job = JiveImportJob()
      ..createdAt = createdAt
      ..updatedAt = createdAt
      ..status = 'pending'
      ..sourceType = sourceType
      ..entryType = entryType
      ..filePath = filePath
      ..fileName = fileName
      ..payloadText = payloadText
      ..duplicatePolicy = duplicatePolicy
      ..retryFromJobId = retryFromJobId;

    await isar.writeTxn(() async {
      final newId = await isar.collection<JiveImportJob>().put(job);
      job.id = newId;
    });
    return job.id;
  }

  Future<void> markJobRunning(int jobId) async {
    await _updateJob(
      jobId,
      apply: (job) {
        job.status = 'running';
        job.updatedAt = DateTime.now();
      },
    );
  }

  Future<void> finishJob({
    required int jobId,
    required String status,
    required int totalCount,
    required int insertedCount,
    required int duplicateCount,
    required int invalidCount,
    required int skippedByDuplicateDecisionCount,
    required String duplicatePolicy,
    String? decisionSummaryJson,
    String? errorMessage,
  }) async {
    await isar.writeTxn(() async {
      final job = await isar.collection<JiveImportJob>().get(jobId);
      if (job == null) return;
      job.status = status;
      job.updatedAt = DateTime.now();
      job.finishedAt = DateTime.now();
      job.totalCount = totalCount;
      job.insertedCount = insertedCount;
      job.duplicateCount = duplicateCount;
      job.invalidCount = invalidCount;
      job.skippedByDuplicateDecisionCount = skippedByDuplicateDecisionCount;
      job.duplicatePolicy = duplicatePolicy;
      job.decisionSummaryJson = decisionSummaryJson;
      job.errorMessage = errorMessage;

      if (job.retryFromJobId != null) {
        final parent = await isar.collection<JiveImportJob>().get(
          job.retryFromJobId!,
        );
        if (parent != null) {
          job.retryCount = parent.retryCount + 1;
        }
      }

      await isar.collection<JiveImportJob>().put(job);
    });
  }

  Future<bool> saveJobRecords(List<JiveImportJobRecord> records) async {
    if (records.isEmpty) return true;
    try {
      await isar.writeTxn(() async {
        await isar.collection<JiveImportJobRecord>().putAll(records);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ImportJobHistorySnapshot> exportSnapshot() async {
    final jobs = await isar.collection<JiveImportJob>().where().findAll();
    final records = await isar
        .collection<JiveImportJobRecord>()
        .where()
        .findAll();
    return ImportJobHistorySnapshot(jobs: jobs, records: records);
  }

  Future<void> replaceAll({
    required List<JiveImportJob> jobs,
    required List<JiveImportJobRecord> records,
    bool clearExisting = true,
  }) async {
    await isar.writeTxn(() async {
      if (clearExisting) {
        await isar.collection<JiveImportJob>().clear();
        await isar.collection<JiveImportJobRecord>().clear();
      }
      if (jobs.isNotEmpty) {
        await isar.collection<JiveImportJob>().putAll(jobs);
      }
      if (records.isNotEmpty) {
        await isar.collection<JiveImportJobRecord>().putAll(records);
      }
    });
  }

  Future<void> _updateJob(
    int jobId, {
    required void Function(JiveImportJob job) apply,
  }) async {
    await isar.writeTxn(() async {
      final job = await isar.collection<JiveImportJob>().get(jobId);
      if (job == null) return;
      apply(job);
      await isar.collection<JiveImportJob>().put(job);
    });
  }
}
