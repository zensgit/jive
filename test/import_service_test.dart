import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/auto_draft_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/core/database/import_job_record_model.dart';
import 'package:jive/core/database/tag_model.dart';
import 'package:jive/core/database/tag_rule_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/import_service.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late ImportService service;

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
    dir = await Directory.systemTemp.createTemp('jive_import_service_test_');
    isar = await Isar.open([
      JiveAutoDraftSchema,
      JiveTransactionSchema,
      JiveCategorySchema,
      JiveCategoryOverrideSchema,
      JiveAccountSchema,
      JiveTagSchema,
      JiveTagGroupSchema,
      JiveTagRuleSchema,
      JiveImportJobSchema,
      JiveImportJobRecordSchema,
    ], directory: dir.path);
    service = ImportService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('parseText parses csv records with header', () {
    const text =
        'date,amount,source,type,note\n'
        '2026-02-14 09:30,18.80,WeChat,expense,早餐\n'
        '2026-02-14 18:10,50.00,Alipay,expense,晚餐';

    final records = service.parseText(text, sourceType: ImportSourceType.csv);

    expect(records.length, 2);
    expect(records.first.amount, 18.8);
    expect(records.first.source, 'WeChat');
    expect(records.first.type, 'expense');
    expect(records.first.rawText, '早餐');
  });

  test('parseText parses loose wechat text lines', () {
    const text =
        '2026-02-14 12:01 微信支付 ￥23.50 午餐\n'
        '2026-02-14 19:20 微信收款 ￥88.00 报销到账';

    final records = service.parseText(
      text,
      sourceType: ImportSourceType.wechat,
    );

    expect(records.length, 2);
    expect(records.first.amount, 23.5);
    expect(records.first.type, 'expense');
    expect(records.last.type, 'income');
    expect(records.first.confidence, lessThan(1));
    expect(records.first.hasWarnings, isTrue);
  });

  test('parseText produces confidence and warnings for anomaly records', () {
    const text = '支付通知 ￥88888.00 未知来源';
    final records = service.parseText(text, sourceType: ImportSourceType.ocr);

    expect(records.length, 1);
    expect(records.first.amount, 88888);
    expect(records.first.confidence, lessThan(1));
    expect(records.first.warnings.any((item) => item.contains('金额较大')), isTrue);
    expect(
      records.first.warnings.any((item) => item.contains('来源未识别')),
      isTrue,
    );
  });

  test('importFromText writes job and retry keeps history chain', () async {
    const payload = '仅测试任务流转，不含可导入金额';

    final first = await service.importFromText(
      text: payload,
      sourceType: ImportSourceType.ocr,
      entryType: ImportEntryType.text,
    );

    expect(first.jobId, greaterThan(0));
    expect(first.totalCount, 1);
    expect(first.invalidCount, 1);
    expect(first.hasError, isFalse);

    final firstJob = await isar.collection<JiveImportJob>().get(first.jobId);
    expect(firstJob, isNotNull);
    expect(firstJob!.status, 'review');
    expect(firstJob.retryCount, 0);
    expect(firstJob.duplicatePolicy, 'keep_latest');
    expect(firstJob.decisionSummaryJson, isNotEmpty);

    final second = await service.retryJob(first.jobId);

    final secondJob = await isar.collection<JiveImportJob>().get(second.jobId);
    expect(secondJob, isNotNull);
    expect(secondJob!.retryFromJobId, first.jobId);
    expect(secondJob.retryCount, 1);
    expect(secondJob.status, 'review');
    expect(secondJob.duplicatePolicy, 'keep_latest');
  });

  test(
    'importPreparedRecords writes selected preview records into job stats',
    () async {
      const payload =
          'date,amount,source,type,note\n'
          '2026-02-14 09:30,18.80,WeChat,expense,早餐\n'
          '2026-02-14 10:00,0,WeChat,expense,无效行\n'
          '2026-02-14 12:00,32.50,Alipay,expense,午餐';

      final parsed = service.parseText(
        payload,
        sourceType: ImportSourceType.csv,
      );
      expect(parsed.length, 3);

      final selected = [parsed[1]];
      final result = await service.importPreparedRecords(
        records: selected,
        payloadText: payload,
        sourceType: ImportSourceType.csv,
        entryType: ImportEntryType.text,
      );

      expect(result.totalCount, 1);
      expect(result.insertedCount, 0);
      expect(result.duplicateCount, 0);
      expect(result.invalidCount, 1);

      final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
      expect(drafts.length, 0);

      final job = await isar.collection<JiveImportJob>().get(result.jobId);
      expect(job, isNotNull);
      expect(job!.status, 'review');
      expect(job.totalCount, 1);
      expect(job.insertedCount, 0);
      expect(job.invalidCount, 1);
    },
  );

  test(
    'estimateDuplicateRisk reports in-batch and existing duplicates',
    () async {
      final existingTx = JiveTransaction()
        ..amount = 18.8
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 2, 14, 9, 30)
        ..rawText = '早餐'
        ..type = 'expense';
      final existingDraft = JiveAutoDraft()
        ..amount = 32.5
        ..source = 'Alipay'
        ..timestamp = DateTime(2026, 2, 14, 12, 0)
        ..rawText = '午餐'
        ..type = 'expense'
        ..dedupKey = 'Alipay|32.50|午餐'
        ..createdAt = DateTime(2026, 2, 14, 12, 1);

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().put(existingTx);
        await isar.collection<JiveAutoDraft>().put(existingDraft);
      });

      final records = <ImportParsedRecord>[
        ImportParsedRecord(
          amount: 18.8,
          source: 'WeChat',
          timestamp: DateTime(2026, 2, 14, 9, 30),
          rawText: '早餐',
          type: 'expense',
          lineNumber: 1,
        ),
        ImportParsedRecord(
          amount: 18.8,
          source: 'WeChat',
          timestamp: DateTime(2026, 2, 14, 9, 35),
          rawText: '早餐',
          type: 'expense',
          lineNumber: 2,
        ),
        ImportParsedRecord(
          amount: 32.5,
          source: 'Alipay',
          timestamp: DateTime(2026, 2, 14, 12, 0),
          rawText: '午餐',
          type: 'expense',
          lineNumber: 3,
        ),
        ImportParsedRecord(
          amount: 0,
          source: 'Import',
          timestamp: DateTime(2026, 2, 14, 12, 0),
          rawText: '无效',
          type: null,
          lineNumber: 4,
        ),
      ];

      final estimate = await service.estimateDuplicateRisk(records);
      expect(estimate.validCount, 3);
      expect(estimate.inBatchDuplicates, 1);
      expect(estimate.existingDuplicates, 3);
      expect(estimate.duplicateRate, closeTo(4 / 3, 0.001));
    },
  );

  test(
    'analyzeDuplicateRisk returns risk items with batch/existing flags',
    () async {
      final existingTx = JiveTransaction()
        ..amount = 50
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 2, 10, 8, 0)
        ..rawText = '早餐'
        ..type = 'expense';
      final existingDraft = JiveAutoDraft()
        ..amount = 66
        ..source = 'Alipay'
        ..timestamp = DateTime(2026, 2, 12, 12, 0)
        ..rawText = '午餐'
        ..type = 'expense'
        ..dedupKey = 'Alipay|66.00|午餐'
        ..createdAt = DateTime(2026, 2, 12, 12, 1);
      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().put(existingTx);
        await isar.collection<JiveAutoDraft>().put(existingDraft);
      });

      final records = <ImportParsedRecord>[
        ImportParsedRecord(
          amount: 50,
          source: 'WeChat',
          timestamp: DateTime(2026, 2, 14, 9, 30),
          rawText: '早餐',
          type: 'expense',
          lineNumber: 1,
        ),
        ImportParsedRecord(
          amount: 50,
          source: 'WeChat',
          timestamp: DateTime(2026, 2, 14, 9, 31),
          rawText: '早餐',
          type: 'expense',
          lineNumber: 2,
        ),
        ImportParsedRecord(
          amount: 66,
          source: 'Alipay',
          timestamp: DateTime(2026, 2, 13, 10, 0),
          rawText: '午餐',
          type: 'expense',
          lineNumber: 3,
        ),
        ImportParsedRecord(
          amount: 12,
          source: 'UnionPay',
          timestamp: DateTime(2026, 2, 13, 11, 0),
          rawText: '地铁',
          type: 'expense',
          lineNumber: 4,
        ),
      ];

      final review = await service.analyzeDuplicateRisk(records);
      expect(review.highRiskCount, 3);
      expect(review.inBatchCount, 2);
      expect(review.existingCount, 3);

      final byIndex = review.byRecordIndex;
      expect(byIndex.containsKey(0), isTrue);
      expect(byIndex[0]!.inBatchDuplicate, isTrue);
      expect(byIndex[0]!.existingDuplicate, isTrue);
      expect(byIndex.containsKey(1), isTrue);
      expect(byIndex[1]!.inBatchDuplicate, isTrue);
      expect(byIndex[1]!.existingDuplicate, isTrue);
      expect(byIndex.containsKey(2), isTrue);
      expect(byIndex[2]!.inBatchDuplicate, isFalse);
      expect(byIndex[2]!.existingDuplicate, isTrue);
      expect(byIndex.containsKey(3), isFalse);
      expect(byIndex[2]!.latestExistingTimestamp, DateTime(2026, 2, 12, 12, 0));
    },
  );

  test(
    'importPreparedRecords keep_latest skips older duplicates and persists record decisions',
    () async {
      final existingTx = JiveTransaction()
        ..amount = 10
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 2, 14, 10, 0)
        ..rawText = '早餐'
        ..type = 'expense';
      final existingTx2 = JiveTransaction()
        ..amount = 20
        ..source = 'Alipay'
        ..timestamp = DateTime(2026, 2, 14, 13, 0)
        ..rawText = '午餐'
        ..type = 'expense';
      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().put(existingTx);
        await isar.collection<JiveTransaction>().put(existingTx2);
      });

      final records = <ImportParsedRecord>[
        ImportParsedRecord(
          amount: 10,
          source: 'WeChat',
          timestamp: DateTime(2026, 2, 14, 9, 0),
          rawText: '早餐',
          type: 'expense',
          lineNumber: 1,
        ),
        ImportParsedRecord(
          amount: 20,
          source: 'Alipay',
          timestamp: DateTime(2026, 2, 14, 11, 0),
          rawText: '午餐',
          type: 'expense',
          lineNumber: 2,
        ),
        ImportParsedRecord(
          amount: 20,
          source: 'Alipay',
          timestamp: DateTime(2026, 2, 14, 12, 0),
          rawText: '午餐',
          type: 'expense',
          lineNumber: 3,
        ),
      ];

      final result = await service.importPreparedRecords(
        records: records,
        payloadText: 'payload',
        sourceType: ImportSourceType.ocr,
        duplicatePolicy: ImportDuplicatePolicy.keepLatest,
      );

      expect(result.skippedByDuplicateDecisionCount, 3);
      expect(result.duplicatePolicy, 'keep_latest');
      expect(
        result.insertedCount + result.duplicateCount + result.invalidCount,
        0,
      );

      final job = await isar.collection<JiveImportJob>().get(result.jobId);
      expect(job, isNotNull);
      final nonNullJob = job!;
      expect(nonNullJob.skippedByDuplicateDecisionCount, 3);
      expect(nonNullJob.duplicatePolicy, 'keep_latest');

      final jobRecords = await service.listJobRecords(result.jobId, limit: 20);
      expect(jobRecords.length, 3);
      final decisions = jobRecords.map((item) => item.decision).toList();
      expect(decisions.contains('skipped_keep_latest_existing_newer'), isTrue);
      final skippedKeepLatest = jobRecords
          .where(
            (item) => item.decision == 'skipped_keep_latest_existing_newer',
          )
          .length;
      expect(skippedKeepLatest, 3);

      final summary = await service.getJobDetailSummary(result.jobId);
      expect(summary.highRiskCount, 3);
      expect(summary.skippedByDuplicateDecisionCount, 3);
      expect(
        summary.decisionBreakdown['skipped_keep_latest_existing_newer'],
        3,
      );

      final decisionSummary = jsonDecode(nonNullJob.decisionSummaryJson!);
      expect(decisionSummary['policy'], 'keep_latest');
      expect(decisionSummary['recordWriteFailed'], isFalse);
    },
  );

  test('importPreparedRecords skip_all skips all high risk records', () async {
    final existingTx = JiveTransaction()
      ..amount = 15
      ..source = 'WeChat'
      ..timestamp = DateTime(2026, 2, 14, 8, 0)
      ..rawText = '咖啡'
      ..type = 'expense';
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(existingTx);
    });

    final records = <ImportParsedRecord>[
      ImportParsedRecord(
        amount: 15,
        source: 'WeChat',
        timestamp: DateTime(2026, 2, 14, 9, 0),
        rawText: '咖啡',
        type: 'expense',
        lineNumber: 1,
      ),
      ImportParsedRecord(
        amount: 40,
        source: 'Alipay',
        timestamp: DateTime(2026, 2, 14, 10, 0),
        rawText: '打车',
        type: 'expense',
        lineNumber: 2,
      ),
      ImportParsedRecord(
        amount: 40,
        source: 'Alipay',
        timestamp: DateTime(2026, 2, 14, 10, 5),
        rawText: '打车',
        type: 'expense',
        lineNumber: 3,
      ),
    ];

    final result = await service.importPreparedRecords(
      records: records,
      payloadText: 'payload',
      sourceType: ImportSourceType.ocr,
      duplicatePolicy: ImportDuplicatePolicy.skipAll,
    );

    expect(result.skippedByDuplicateDecisionCount, 3);
    expect(result.duplicatePolicy, 'skip_all');
    expect(
      result.insertedCount + result.duplicateCount + result.invalidCount,
      0,
    );

    final jobRecords = await service.listJobRecords(result.jobId, limit: 20);
    expect(jobRecords.length, 3);
    final skipped = jobRecords
        .where((item) => item.decision == 'skipped_policy')
        .length;
    expect(skipped, 3);

    final summary = await service.getJobDetailSummary(result.jobId);
    expect(summary.decisionBreakdown['skipped_policy'], 3);
    final job = await isar.collection<JiveImportJob>().get(result.jobId);
    expect(job, isNotNull);
    final decisionSummary = jsonDecode(job!.decisionSummaryJson!);
    expect(decisionSummary['policy'], 'skip_all');
  });

  test(
    'listJobRecords supports decision/risk filters and stable pagination',
    () async {
      final now = DateTime(2026, 2, 15, 10, 0);
      final job = JiveImportJob()
        ..createdAt = now
        ..updatedAt = now
        ..status = 'review'
        ..sourceType = 'ocr'
        ..entryType = 'text'
        ..duplicatePolicy = 'keep_latest'
        ..totalCount = 4;
      await isar.writeTxn(() async {
        final jobId = await isar.collection<JiveImportJob>().put(job);
        job.id = jobId;
        await isar.collection<JiveImportJobRecord>().putAll([
          JiveImportJobRecord()
            ..jobId = job.id
            ..sourceLineNumber = 3
            ..amount = 20
            ..source = 'A'
            ..timestamp = now
            ..type = 'expense'
            ..confidence = 0.9
            ..warningsJson = '[]'
            ..dedupKey = 'a'
            ..riskLevel = 'batch'
            ..decision = 'skipped_policy'
            ..decisionReason = 'case_a'
            ..createdAt = now,
          JiveImportJobRecord()
            ..jobId = job.id
            ..sourceLineNumber = 1
            ..amount = 10
            ..source = 'B'
            ..timestamp = now
            ..type = 'expense'
            ..confidence = 0.8
            ..warningsJson = '[]'
            ..dedupKey = 'b'
            ..riskLevel = 'none'
            ..decision = 'inserted'
            ..decisionReason = 'case_b'
            ..createdAt = now,
          JiveImportJobRecord()
            ..jobId = job.id
            ..sourceLineNumber = 2
            ..amount = 30
            ..source = 'C'
            ..timestamp = now
            ..type = 'expense'
            ..confidence = 0.7
            ..warningsJson = '[]'
            ..dedupKey = 'c'
            ..riskLevel = 'existing'
            ..decision = 'skipped_keep_latest_existing_newer'
            ..decisionReason = 'case_c'
            ..createdAt = now,
          JiveImportJobRecord()
            ..jobId = job.id
            ..sourceLineNumber = 4
            ..amount = 40
            ..source = 'D'
            ..timestamp = now
            ..type = 'expense'
            ..confidence = 0.95
            ..warningsJson = '[]'
            ..dedupKey = 'd'
            ..riskLevel = 'batch'
            ..decision = 'skipped_policy'
            ..decisionReason = 'case_d'
            ..createdAt = now,
        ]);
      });

      final skippedPolicyOnly = await service.listJobRecords(
        job.id,
        decision: 'skipped_policy',
        limit: 20,
      );
      expect(skippedPolicyOnly.length, 2);
      expect(
        skippedPolicyOnly.every((item) => item.decision == 'skipped_policy'),
        isTrue,
      );

      final batchOnly = await service.listJobRecords(
        job.id,
        riskLevel: 'batch',
        limit: 20,
      );
      expect(batchOnly.length, 2);
      expect(batchOnly.every((item) => item.riskLevel == 'batch'), isTrue);

      final page = await service.listJobRecords(job.id, limit: 2, offset: 1);
      expect(page.length, 2);
      expect(page.first.sourceLineNumber, 2);
      expect(page.last.sourceLineNumber, 3);
    },
  );
}
