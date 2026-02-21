import '../../core/database/import_job_model.dart';
import '../../core/service/import_service.dart';
import 'import_history_analytics.dart';

class ImportBatchRetryProgress {
  final int total;
  final int processed;
  final int successCount;
  final int failedCount;
  final int insertedCount;
  final bool cancelRequested;

  const ImportBatchRetryProgress({
    required this.total,
    required this.processed,
    required this.successCount,
    required this.failedCount,
    required this.insertedCount,
    required this.cancelRequested,
  });

  const ImportBatchRetryProgress.initial({required this.total})
    : processed = 0,
      successCount = 0,
      failedCount = 0,
      insertedCount = 0,
      cancelRequested = false;

  double get ratio {
    if (total <= 0) return 0;
    return processed / total;
  }
}

class ImportBatchRetrySummary {
  final int total;
  final int processed;
  final int successCount;
  final int failedCount;
  final int insertedCount;
  final bool cancelled;
  final Map<String, int> secondaryFailureReasons;

  const ImportBatchRetrySummary({
    required this.total,
    required this.processed,
    required this.successCount,
    required this.failedCount,
    required this.insertedCount,
    required this.cancelled,
    required this.secondaryFailureReasons,
  });
}

typedef ImportBatchRetryExecutor =
    Future<ImportIngestResult> Function(JiveImportJob job);
typedef ImportBatchRetryShouldCancel = bool Function();
typedef ImportBatchRetryProgressCallback =
    void Function(ImportBatchRetryProgress progress);

class ImportBatchRetryRunner {
  const ImportBatchRetryRunner();

  Future<ImportBatchRetrySummary> run({
    required List<JiveImportJob> retryableJobs,
    required int limit,
    required ImportBatchRetryExecutor retryJob,
    ImportBatchRetryShouldCancel? shouldCancel,
    ImportBatchRetryProgressCallback? onProgress,
  }) async {
    if (retryableJobs.isEmpty) {
      return const ImportBatchRetrySummary(
        total: 0,
        processed: 0,
        successCount: 0,
        failedCount: 0,
        insertedCount: 0,
        cancelled: false,
        secondaryFailureReasons: <String, int>{},
      );
    }

    final target = retryableJobs
        .take(limit.clamp(1, retryableJobs.length))
        .toList(growable: false);
    var processed = 0;
    var successCount = 0;
    var failedCount = 0;
    var insertedCount = 0;
    var cancelled = false;
    final secondaryFailureReasons = <String, int>{};

    onProgress?.call(ImportBatchRetryProgress.initial(total: target.length));

    for (final job in target) {
      if (shouldCancel?.call() == true) {
        cancelled = true;
        break;
      }

      try {
        final result = await retryJob(job);
        if (result.hasError) {
          failedCount += 1;
          final reason = normalizeImportFailureReason(result.errorMessage);
          secondaryFailureReasons[reason] =
              (secondaryFailureReasons[reason] ?? 0) + 1;
        } else {
          successCount += 1;
        }
        insertedCount += result.insertedCount;
      } catch (_) {
        failedCount += 1;
        secondaryFailureReasons['未知失败'] =
            (secondaryFailureReasons['未知失败'] ?? 0) + 1;
      }

      processed += 1;
      final cancelRequested = shouldCancel?.call() == true;
      onProgress?.call(
        ImportBatchRetryProgress(
          total: target.length,
          processed: processed,
          successCount: successCount,
          failedCount: failedCount,
          insertedCount: insertedCount,
          cancelRequested: cancelRequested,
        ),
      );
      if (cancelRequested && processed < target.length) {
        cancelled = true;
        break;
      }
    }

    return ImportBatchRetrySummary(
      total: target.length,
      processed: processed,
      successCount: successCount,
      failedCount: failedCount,
      insertedCount: insertedCount,
      cancelled: cancelled,
      secondaryFailureReasons: secondaryFailureReasons,
    );
  }
}
