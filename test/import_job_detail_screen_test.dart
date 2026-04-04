import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';
import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/core/database/import_job_record_model.dart';
import 'package:jive/core/service/import_service.dart';
import 'package:jive/feature/import/import_job_detail_screen.dart';

void main() {
  setUpAll(() async => setupGoogleFontsForTests());

  testWidgets('dedup groups can switch sort by latest time and total amount', (
    WidgetTester tester,
  ) async {
    final job = _buildJob(id: 9001);
    final summary = _buildSummary(jobId: job.id, totalCount: 2);
    final records = <JiveImportJobRecord>[
      _buildRecord(
        id: 1,
        jobId: job.id,
        line: 1,
        dedupKey: 'group_new_small',
        riskLevel: 'batch',
        amount: 10,
        timestamp: DateTime(2026, 2, 10, 12, 0),
      ),
      _buildRecord(
        id: 2,
        jobId: job.id,
        line: 2,
        dedupKey: 'group_old_large',
        riskLevel: 'existing',
        amount: 120,
        timestamp: DateTime(2026, 2, 9, 12, 0),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ImportJobDetailScreen(
          jobId: job.id,
          debugJob: job,
          debugSummary: summary,
          debugRecords: records,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('按 dedupKey 分组'));
    await tester.pumpAndSettle();

    final groupNew = find.byKey(
      const ValueKey<String>('dedup_group_group_new_small'),
    );
    final groupOld = find.byKey(
      const ValueKey<String>('dedup_group_group_old_large'),
    );
    expect(groupNew, findsOneWidget);
    expect(groupOld, findsOneWidget);
    expect(
      tester.getTopLeft(groupNew).dy < tester.getTopLeft(groupOld).dy,
      isTrue,
    );

    await tester.ensureVisible(find.text('按总金额'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按总金额'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(groupOld).dy < tester.getTopLeft(groupNew).dy,
      isTrue,
    );
  });

  testWidgets(
    'dedup groups support high-risk and risk-type filtering with empty state',
    (WidgetTester tester) async {
      final job = _buildJob(id: 9002);
      final summary = _buildSummary(jobId: job.id, totalCount: 2);
      final records = <JiveImportJobRecord>[
        _buildRecord(
          id: 11,
          jobId: job.id,
          line: 1,
          dedupKey: 'group_none',
          riskLevel: 'none',
          amount: 8,
          timestamp: DateTime(2026, 2, 8, 12, 0),
        ),
        _buildRecord(
          id: 12,
          jobId: job.id,
          line: 2,
          dedupKey: 'group_batch',
          riskLevel: 'batch',
          amount: 12,
          timestamp: DateTime(2026, 2, 8, 13, 0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ImportJobDetailScreen(
            jobId: job.id,
            debugJob: job,
            debugSummary: summary,
            debugRecords: records,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('按 dedupKey 分组'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('仅高风险分组'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('仅高风险分组'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('dedup_group_group_none')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('dedup_group_group_batch')),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('风险:叠加'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('风险:叠加'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('dedup_group_group_batch')),
        findsNothing,
      );
      expect(find.text('当前分组筛选下无记录'), findsOneWidget);
    },
  );

  testWidgets('dedup groups support keyword search by dedupKey', (
    WidgetTester tester,
  ) async {
    final job = _buildJob(id: 9003);
    final summary = _buildSummary(jobId: job.id, totalCount: 2);
    final records = <JiveImportJobRecord>[
      _buildRecord(
        id: 21,
        jobId: job.id,
        line: 1,
        dedupKey: 'wechat_group_001',
        riskLevel: 'batch',
        amount: 20,
        timestamp: DateTime(2026, 2, 8, 14, 0),
      ),
      _buildRecord(
        id: 22,
        jobId: job.id,
        line: 2,
        dedupKey: 'alipay_group_002',
        riskLevel: 'existing',
        amount: 30,
        timestamp: DateTime(2026, 2, 8, 15, 0),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ImportJobDetailScreen(
          jobId: job.id,
          debugJob: job,
          debugSummary: summary,
          debugRecords: records,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('按 dedupKey 分组'));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.ensureVisible(searchField);
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'wechat');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('dedup_group_wechat_group_001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dedup_group_alipay_group_002')),
      findsNothing,
    );

    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('dedup_group_wechat_group_001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dedup_group_alipay_group_002')),
      findsOneWidget,
    );
  });

  testWidgets('dedup groups support pagination and next page export context', (
    WidgetTester tester,
  ) async {
    final job = _buildJob(id: 9004);
    final records = <JiveImportJobRecord>[];
    for (var i = 0; i < 25; i++) {
      records.add(
        _buildRecord(
          id: 300 + i,
          jobId: job.id,
          line: i + 1,
          dedupKey: 'page_group_$i',
          riskLevel: 'batch',
          amount: i.toDouble() + 1,
          timestamp: DateTime(2026, 2, 1, 8, i),
        ),
      );
    }
    final summary = _buildSummary(jobId: job.id, totalCount: records.length);

    await tester.pumpWidget(
      MaterialApp(
        home: ImportJobDetailScreen(
          jobId: job.id,
          debugJob: job,
          debugSummary: summary,
          debugRecords: records,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('按 dedupKey 分组'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('dedup_group_page_group_24')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dedup_group_page_group_0')),
      findsNothing,
    );

    await tester.ensureVisible(find.byTooltip('下一页'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('下一页'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('dedup_group_page_group_0')),
      findsOneWidget,
    );
    expect(find.textContaining('第 2/2 页'), findsOneWidget);
  });
}

JiveImportJob _buildJob({required int id}) {
  final now = DateTime(2026, 2, 10, 9, 0);
  final job = JiveImportJob();
  job.id = id;
  job.createdAt = now;
  job.updatedAt = now;
  job.finishedAt = now;
  job.status = 'review';
  job.sourceType = 'csv';
  job.entryType = 'file';
  job.totalCount = 2;
  job.insertedCount = 0;
  job.duplicateCount = 2;
  job.invalidCount = 0;
  job.skippedByDuplicateDecisionCount = 0;
  job.duplicatePolicy = 'keep_latest';
  return job;
}

ImportJobDetailSummary _buildSummary({
  required int jobId,
  required int totalCount,
}) {
  return ImportJobDetailSummary(
    jobId: jobId,
    totalCount: totalCount,
    insertedCount: 0,
    duplicateCount: totalCount,
    invalidCount: 0,
    skippedByDuplicateDecisionCount: 0,
    duplicatePolicy: 'keep_latest',
    highRiskCount: totalCount,
    inBatchRiskCount: 1,
    existingRiskCount: 1,
    decisionBreakdown: const {'duplicate': 2},
  );
}

JiveImportJobRecord _buildRecord({
  required int id,
  required int jobId,
  required int line,
  required String dedupKey,
  required String riskLevel,
  required double amount,
  required DateTime timestamp,
}) {
  final record = JiveImportJobRecord();
  record.id = id;
  record.jobId = jobId;
  record.sourceLineNumber = line;
  record.amount = amount;
  record.source = 'fixture';
  record.timestamp = timestamp;
  record.type = 'expense';
  record.confidence = 0.95;
  record.warningsJson = '[]';
  record.dedupKey = dedupKey;
  record.riskLevel = riskLevel;
  record.decision = 'duplicate';
  record.decisionReason = null;
  record.createdAt = timestamp;
  return record;
}
