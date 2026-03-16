import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/core/database/import_job_record_model.dart';
import 'package:jive/core/repository/import_job_history_repository.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late ImportJobHistoryRepository repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pubCache =
        Platform.environment['PUB_CACHE'] ??
        '${Platform.environment['HOME']}/.pub-cache';
    String? libPath;
    if (Platform.isMacOS) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    } else if (Platform.isLinux) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/linux/libisar.so';
    } else if (Platform.isWindows) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/windows/isar.dll';
    }
    if (libPath != null && File(libPath).existsSync()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): libPath});
    } else {
      throw StateError('Isar core library not found for tests.');
    }
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('jive_import_job_repo_test_');
    isar = await Isar.open([
      JiveImportJobSchema,
      JiveImportJobRecordSchema,
    ], directory: dir.path);
    repository = ImportJobHistoryRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('create mark finish and query import job history', () async {
    final createdAt = DateTime(2026, 3, 15, 10, 0);
    final jobId = await repository.createPendingJob(
      createdAt: createdAt,
      sourceType: 'csv',
      entryType: 'file',
      filePath: '/tmp/import.csv',
      fileName: 'import.csv',
      payloadText: 'payload',
      duplicatePolicy: 'keep_latest',
      retryFromJobId: null,
    );

    await repository.markJobRunning(jobId);
    await repository.finishJob(
      jobId: jobId,
      status: 'review',
      totalCount: 3,
      insertedCount: 2,
      duplicateCount: 1,
      invalidCount: 0,
      skippedByDuplicateDecisionCount: 0,
      duplicatePolicy: 'keep_latest',
      decisionSummaryJson: '{"highRisk":1}',
    );

    final saved = await repository.getJob(jobId);
    expect(saved, isNotNull);
    expect(saved!.status, 'review');
    expect(saved.insertedCount, 2);
    expect(saved.duplicateCount, 1);

    final recent = await repository.listRecentJobs();
    expect(recent, hasLength(1));
    expect(recent.first.id, jobId);
  });

  test('save records filters and exports snapshot', () async {
    final jobId = await repository.createPendingJob(
      createdAt: DateTime(2026, 3, 15, 11, 0),
      sourceType: 'csv',
      entryType: 'text',
      filePath: null,
      fileName: null,
      payloadText: 'payload',
      duplicatePolicy: 'keep_latest',
      retryFromJobId: null,
    );

    final saved = await repository.saveJobRecords([
      JiveImportJobRecord()
        ..jobId = jobId
        ..sourceLineNumber = 2
        ..amount = 12.5
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 3, 15, 8, 0)
        ..type = 'expense'
        ..confidence = 0.9
        ..warningsJson = '[]'
        ..dedupKey = 'a'
        ..riskLevel = 'none'
        ..decision = 'inserted'
        ..decisionReason = 'inserted'
        ..createdAt = DateTime(2026, 3, 15, 11, 0),
      JiveImportJobRecord()
        ..jobId = jobId
        ..sourceLineNumber = 3
        ..amount = 12.5
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 3, 15, 8, 1)
        ..type = 'expense'
        ..confidence = 0.4
        ..warningsJson = '["duplicate"]'
        ..dedupKey = 'a'
        ..riskLevel = 'batch'
        ..decision = 'duplicate'
        ..decisionReason = 'duplicate_in_draft'
        ..createdAt = DateTime(2026, 3, 15, 11, 0),
    ]);

    expect(saved, isTrue);

    final duplicates = await repository.listJobRecords(
      jobId,
      decision: 'duplicate',
      riskLevel: 'batch',
    );
    expect(duplicates, hasLength(1));
    expect(duplicates.first.sourceLineNumber, 3);

    final snapshot = await repository.exportSnapshot();
    expect(snapshot.jobs, hasLength(1));
    expect(snapshot.records, hasLength(2));
  });
}
