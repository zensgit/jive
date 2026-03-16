import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/feature/import/import_center_screen.dart';
import 'package:jive/feature/import/import_failure_report_exporter.dart';

Future<void> _pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 40,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) return;
  }
}

Future<void> _scrollToHistory(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('导入任务历史'),
    320,
    scrollable: find.byType(Scrollable).first,
  );
  await _pumpUntilSettled(tester);
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text).first,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await _pumpUntilSettled(tester);
  await tester.tap(find.text(text).first, warnIfMissed: false);
  await _pumpUntilSettled(tester);
}

JiveImportJob _buildJob({
  required int id,
  required String status,
  required DateTime updatedAt,
  required String? errorMessage,
  String? payloadText,
  String sourceType = 'csv',
}) {
  final job = JiveImportJob();
  job.id = id;
  job.createdAt = updatedAt.subtract(const Duration(minutes: 5));
  job.updatedAt = updatedAt;
  job.finishedAt = updatedAt;
  job.status = status;
  job.sourceType = sourceType;
  job.entryType = 'file';
  job.errorMessage = errorMessage;
  job.payloadText = payloadText;
  job.totalCount = 3;
  job.insertedCount = 1;
  job.duplicateCount = 1;
  job.invalidCount = 1;
  job.skippedByDuplicateDecisionCount = 0;
  job.duplicatePolicy = 'keep_latest';
  job.decisionSummaryJson = '{"highRisk":1,"inBatch":1,"existing":0}';
  return job;
}

class _FakeFailureReportExporter extends ImportFailureReportExporter {
  final Future<ImportFailureReportExportResult> Function(
    ImportFailureReportExportRequest request,
  )
  onExport;

  _FakeFailureReportExporter({required this.onExport});

  @override
  Future<ImportFailureReportExportResult> export(
    ImportFailureReportExportRequest request,
  ) {
    return onExport(request);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'ImportCenter failure analytics supports scope filter and export',
    (tester) async {
      final now = DateTime.now();
      final jobs = <JiveImportJob>[
        _buildJob(
          id: 101,
          status: 'failed',
          errorMessage: 'FormatException: csv issue',
          updatedAt: now.subtract(const Duration(days: 40)),
          payloadText: 'old raw payload',
          sourceType: 'csv',
        ),
        _buildJob(
          id: 102,
          status: 'failed',
          errorMessage: 'TimeoutError: request timeout',
          updatedAt: now.subtract(const Duration(days: 1)),
          payloadText: 'wechat raw payload',
          sourceType: 'wechat',
        ),
        _buildJob(
          id: 103,
          status: 'review',
          errorMessage: null,
          updatedAt: now.subtract(const Duration(hours: 3)),
          sourceType: 'alipay',
        ),
      ];
      final requests = <ImportFailureReportExportRequest>[];
      final exporter = _FakeFailureReportExporter(
        onExport: (request) async {
          requests.add(request);
          return const ImportFailureReportExportResult(
            filePath: '/tmp/import_center_failure_smoke.csv',
            fileName: 'import_center_failure_smoke.csv',
            csv: 'meta,value',
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ImportCenterScreen(
            debugJobs: jobs,
            failureReportExporter: exporter,
          ),
        ),
      );
      await _pumpUntilSettled(tester);
      await _scrollToHistory(tester);

      expect(find.text('最近失败原因聚合（30天）'), findsOneWidget);
      expect(find.textContaining('request timeout ×1'), findsOneWidget);
      expect(find.textContaining('csv issue ×1'), findsNothing);

      await _tapVisibleText(tester, '全部');
      expect(find.text('最近失败原因聚合（全部）'), findsOneWidget);
      expect(find.textContaining('csv issue ×1'), findsOneWidget);

      await _tapVisibleText(tester, '来源:微信');
      expect(find.textContaining('request timeout ×1'), findsOneWidget);
      expect(find.textContaining('csv issue ×1'), findsNothing);

      await _tapVisibleText(tester, '导出失败报表');
      expect(
        find.text('已导出失败报表：import_center_failure_smoke.csv'),
        findsOneWidget,
      );
      expect(requests, hasLength(1));
      expect(requests.first.sourceName, 'wechat');
      expect(requests.first.windowName, 'all');
      expect(requests.first.failedCount, 1);
    },
  );
}
