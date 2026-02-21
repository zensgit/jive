import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/core/service/import_service.dart';
import 'package:jive/feature/import/import_batch_retry_runner.dart';

void main() {
  JiveImportJob buildJob(int id) {
    final now = DateTime.now();
    return JiveImportJob()
      ..id = id
      ..createdAt = now
      ..updatedAt = now
      ..status = 'failed'
      ..sourceType = 'csv'
      ..entryType = 'text'
      ..payloadText = 'payload-$id';
  }

  ImportIngestResult resultFor(int jobId, {int inserted = 0, String? error}) {
    return ImportIngestResult(
      jobId: jobId,
      totalCount: 1,
      insertedCount: inserted,
      duplicateCount: 0,
      invalidCount: 0,
      errorMessage: error,
    );
  }

  test(
    'runner aggregates success/failure/inserted and reason summary',
    () async {
      final runner = const ImportBatchRetryRunner();
      final jobs = [buildJob(1), buildJob(2), buildJob(3)];
      final progress = <ImportBatchRetryProgress>[];

      final summary = await runner.run(
        retryableJobs: jobs,
        limit: 3,
        retryJob: (job) async {
          if (job.id == 1) return resultFor(1, inserted: 2);
          if (job.id == 2) {
            return resultFor(2, error: 'TimeoutError: request timeout');
          }
          throw Exception('boom');
        },
        onProgress: progress.add,
      );

      expect(summary.cancelled, isFalse);
      expect(summary.total, 3);
      expect(summary.processed, 3);
      expect(summary.successCount, 1);
      expect(summary.failedCount, 2);
      expect(summary.insertedCount, 2);
      expect(summary.secondaryFailureReasons['request timeout'], 1);
      expect(summary.secondaryFailureReasons['未知失败'], 1);
      expect(progress.last.processed, 3);
      expect(progress.last.total, 3);
    },
  );

  test('runner stops when cancel is requested', () async {
    final runner = const ImportBatchRetryRunner();
    final jobs = [buildJob(11), buildJob(12), buildJob(13)];
    var cancelRequested = false;
    final retried = <int>[];

    final summary = await runner.run(
      retryableJobs: jobs,
      limit: 3,
      retryJob: (job) async {
        retried.add(job.id);
        return resultFor(job.id, inserted: 1);
      },
      shouldCancel: () => cancelRequested,
      onProgress: (progress) {
        if (progress.processed >= 1) {
          cancelRequested = true;
        }
      },
    );

    expect(summary.cancelled, isTrue);
    expect(summary.total, 3);
    expect(summary.processed, 1);
    expect(summary.successCount, 1);
    expect(summary.failedCount, 0);
    expect(summary.insertedCount, 1);
    expect(retried, hasLength(1));
    expect(retried.first, 11);
  });
}
