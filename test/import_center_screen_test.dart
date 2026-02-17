import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/feature/import/import_center_screen.dart';
import 'package:jive/feature/import/import_failure_report_exporter.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('failure aggregate supports time window switch and retry entry', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final jobs = <JiveImportJob>[
      _buildJob(
        id: 1,
        status: 'failed',
        errorMessage: 'FormatException: old issue',
        updatedAt: now.subtract(const Duration(days: 40)),
        payloadText: '',
      ),
      _buildJob(
        id: 2,
        status: 'failed',
        errorMessage: 'FormatException: new issue',
        updatedAt: now.subtract(const Duration(days: 2)),
        payloadText: 'raw fallback payload',
      ),
      _buildJob(
        id: 3,
        status: 'review',
        errorMessage: null,
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ImportCenterScreen(debugJobs: jobs)),
    );
    await tester.pumpAndSettle();
    await _scrollToHistory(tester);

    expect(find.text('最近失败原因聚合（30天）'), findsOneWidget);
    expect(find.textContaining('new issue ×1'), findsOneWidget);
    expect(find.textContaining('old issue ×1'), findsNothing);
    expect(find.text('本窗口重试可重试'), findsOneWidget);
    expect(find.text('导出失败报表'), findsOneWidget);
    expect(find.text('窗口建议：查看失败任务'), findsOneWidget);
    expect(find.text('重试可重试'), findsOneWidget);
    expect(find.text('重试最近N'), findsOneWidget);
    expect(find.text('查看失败任务'), findsOneWidget);
    expect(find.textContaining('可重试 1 条，不可重试 0 条（占比 0%）'), findsWidgets);

    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    expect(find.text('最近失败原因聚合（全部）'), findsOneWidget);
    expect(find.textContaining('old issue ×1'), findsOneWidget);
    expect(find.textContaining('可重试 1 条，不可重试 1 条（占比 50%）'), findsOneWidget);
  });

  testWidgets('failure aggregate supports source filter chips', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final jobs = <JiveImportJob>[
      _buildJob(
        id: 11,
        status: 'failed',
        errorMessage: 'FormatException: new issue',
        updatedAt: now.subtract(const Duration(days: 1)),
        payloadText: 'raw csv payload',
        sourceType: 'csv',
      ),
      _buildJob(
        id: 12,
        status: 'failed',
        errorMessage: 'FormatException: new issue',
        updatedAt: now.subtract(const Duration(days: 2)),
        payloadText: 'raw alipay payload',
        sourceType: 'alipay',
      ),
      _buildJob(
        id: 13,
        status: 'failed',
        errorMessage: 'TimeoutError: request timeout',
        updatedAt: now.subtract(const Duration(days: 1)),
        payloadText: 'raw wechat payload',
        sourceType: 'wechat',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ImportCenterScreen(debugJobs: jobs)),
    );
    await tester.pumpAndSettle();
    await _scrollToHistory(tester);

    expect(find.textContaining('new issue ×2'), findsOneWidget);

    await tester.tap(find.text('来源:支付宝'));
    await tester.pumpAndSettle();
    expect(find.textContaining('new issue ×1'), findsOneWidget);
    expect(find.textContaining('request timeout ×1'), findsNothing);

    await tester.tap(find.text('来源:微信'));
    await tester.pumpAndSettle();
    expect(find.textContaining('request timeout ×1'), findsOneWidget);
  });

  testWidgets('failure aggregate restores persisted scope on reopen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'import_failure_window': 'all',
      'import_failure_source_type': 'wechat',
    });
    final now = DateTime.now();
    final jobs = <JiveImportJob>[
      _buildJob(
        id: 14,
        status: 'failed',
        errorMessage: 'TimeoutError: request timeout',
        updatedAt: now.subtract(const Duration(days: 1)),
        payloadText: 'raw wechat payload',
        sourceType: 'wechat',
      ),
      _buildJob(
        id: 15,
        status: 'failed',
        errorMessage: 'FormatException: csv issue',
        updatedAt: now.subtract(const Duration(days: 1)),
        payloadText: 'raw csv payload',
        sourceType: 'csv',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ImportCenterScreen(debugJobs: jobs)),
    );
    await tester.pumpAndSettle();
    await _scrollToHistory(tester);

    expect(find.text('最近失败原因聚合（全部）'), findsOneWidget);
    expect(find.textContaining('request timeout ×1'), findsOneWidget);
    expect(find.textContaining('csv issue ×1'), findsNothing);
    final sourceWechatChip = find.widgetWithText(ChoiceChip, '来源:微信');
    expect(sourceWechatChip, findsOneWidget);
    expect(tester.widget<ChoiceChip>(sourceWechatChip).selected, isTrue);
  });

  testWidgets('tap export failure report calls exporter with current scope', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final jobs = <JiveImportJob>[
      _buildJob(
        id: 16,
        status: 'failed',
        errorMessage: 'TimeoutError: request timeout',
        updatedAt: now.subtract(const Duration(days: 1)),
        payloadText: 'raw timeout payload',
      ),
      _buildJob(
        id: 17,
        status: 'failed',
        errorMessage: 'TimeoutError: request timeout',
        updatedAt: now.subtract(const Duration(days: 2)),
        payloadText: null,
      ),
      _buildJob(
        id: 18,
        status: 'failed',
        errorMessage: 'FormatException: old issue',
        updatedAt: now.subtract(const Duration(days: 40)),
        payloadText: 'raw old payload',
      ),
    ];
    final requests = <ImportFailureReportExportRequest>[];
    final exporter = _FakeFailureReportExporter(
      onExport: (request) async {
        requests.add(request);
        return const ImportFailureReportExportResult(
          filePath: '/tmp/failure_report.csv',
          fileName: 'failure_report.csv',
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
    await tester.pumpAndSettle();
    await _scrollToHistory(tester);

    await _tapVisibleText(tester, '导出失败报表');
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    final request = requests.first;
    expect(request.windowName, 'd30');
    expect(request.sourceName, 'all');
    expect(request.windowLabel, '30天');
    expect(request.sourceScopeLabel, '全部来源');
    expect(request.failedCount, 2);
    expect(request.retryableCount, 1);
    expect(request.blockedCount, 1);
    expect(request.aggregates, hasLength(1));
    expect(request.aggregates.first.reason, 'request timeout');
    expect(request.aggregates.first.count, 2);
    expect(request.retryableByReason['request timeout'], 1);
    expect(request.blockedByReason['request timeout'], 1);
  });

  testWidgets(
    'tap export failure report uses selected source scope in request',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final jobs = <JiveImportJob>[
        _buildJob(
          id: 19,
          status: 'failed',
          errorMessage: 'TimeoutError: request timeout',
          updatedAt: now.subtract(const Duration(days: 1)),
          payloadText: 'raw csv payload',
          sourceType: 'csv',
        ),
        _buildJob(
          id: 20,
          status: 'failed',
          errorMessage: 'TimeoutError: request timeout',
          updatedAt: now.subtract(const Duration(days: 1)),
          payloadText: null,
          sourceType: 'wechat',
        ),
      ];
      final requests = <ImportFailureReportExportRequest>[];
      final exporter = _FakeFailureReportExporter(
        onExport: (request) async {
          requests.add(request);
          return const ImportFailureReportExportResult(
            filePath: '/tmp/failure_report_wechat.csv',
            fileName: 'failure_report_wechat.csv',
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
      await tester.pumpAndSettle();
      await _scrollToHistory(tester);

      await _tapVisibleText(tester, '来源:微信');
      await tester.pumpAndSettle();
      await _tapVisibleText(tester, '导出失败报表');
      await tester.pumpAndSettle();

      expect(requests, hasLength(1));
      final request = requests.first;
      expect(request.sourceName, 'wechat');
      expect(request.sourceScopeLabel, '微信文本');
      expect(request.failedCount, 1);
      expect(request.retryableCount, 0);
      expect(request.blockedCount, 1);
      expect(request.aggregates, hasLength(1));
      expect(request.aggregates.first.reason, 'request timeout');
      expect(request.aggregates.first.count, 1);
    },
  );

  testWidgets(
    'tap failure reason applies failed quick filter and search query',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final jobs = <JiveImportJob>[
        _buildJob(
          id: 21,
          status: 'failed',
          errorMessage: 'TimeoutError: request timeout',
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        _buildJob(
          id: 22,
          status: 'failed',
          errorMessage: 'FormatException: parse error',
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        _buildJob(
          id: 23,
          status: 'review',
          errorMessage: null,
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: ImportCenterScreen(debugJobs: jobs)),
      );
      await tester.pumpAndSettle();
      await _scrollToHistory(tester);

      await tester.ensureVisible(find.textContaining('request timeout ×1'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('request timeout ×1'));
      await tester.pumpAndSettle();

      final searchField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == '搜索任务（ID/策略/状态/来源/摘要）',
      );
      expect(searchField, findsOneWidget);
      final searchWidget = tester.widget<TextField>(searchField);
      expect(searchWidget.controller?.text, 'request timeout');

      final failedChipFinder = find.byWidgetPredicate((widget) {
        if (widget is! ChoiceChip || widget.label is! Text) {
          return false;
        }
        final label = (widget.label as Text).data ?? '';
        return label.startsWith('失败 ');
      });
      expect(failedChipFinder, findsOneWidget);
      expect(tester.widget<ChoiceChip>(failedChipFinder).selected, isTrue);

      expect(find.byType(ListTile), findsOneWidget);
    },
  );

  testWidgets(
    'tap retry-all-retryable shows unsupported message in debug mode',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final jobs = <JiveImportJob>[
        _buildJob(
          id: 31,
          status: 'failed',
          errorMessage: 'FormatException: parse issue',
          updatedAt: now.subtract(const Duration(days: 1)),
          payloadText: 'raw fallback payload',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: ImportCenterScreen(debugJobs: jobs)),
      );
      await tester.pumpAndSettle();
      await _scrollToHistory(tester);

      await _tapVisibleText(tester, '重试可重试');
      await tester.pumpAndSettle();

      expect(find.text('当前模式不可执行批量重试'), findsOneWidget);
    },
  );

  testWidgets(
    'tap window retry-all-retryable shows unsupported message in debug mode',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final jobs = <JiveImportJob>[
        _buildJob(
          id: 41,
          status: 'failed',
          errorMessage: 'TimeoutError: request timeout',
          updatedAt: now.subtract(const Duration(days: 1)),
          payloadText: 'raw fallback payload',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: ImportCenterScreen(debugJobs: jobs)),
      );
      await tester.pumpAndSettle();
      await _scrollToHistory(tester);

      await _tapVisibleText(tester, '本窗口重试可重试');
      await tester.pumpAndSettle();

      expect(find.text('当前模式不可执行批量重试'), findsOneWidget);
    },
  );

  testWidgets('format failure reason shows configure-template action', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final jobs = <JiveImportJob>[
      _buildJob(
        id: 51,
        status: 'failed',
        errorMessage: 'FormatException: invalid csv line',
        updatedAt: now.subtract(const Duration(days: 1)),
        payloadText: 'raw fallback payload',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ImportCenterScreen(debugJobs: jobs)),
    );
    await tester.pumpAndSettle();
    await _scrollToHistory(tester);

    expect(find.text('配置规则模板'), findsOneWidget);
    expect(find.text('窗口建议：配置规则模板'), findsOneWidget);
  });
}

JiveImportJob _buildJob({
  required int id,
  required String status,
  required DateTime updatedAt,
  required String? errorMessage,
  String? payloadText,
  String? filePath,
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
  job.filePath = filePath;
  job.totalCount = 3;
  job.insertedCount = 1;
  job.duplicateCount = 1;
  job.invalidCount = 1;
  job.skippedByDuplicateDecisionCount = 0;
  job.duplicatePolicy = 'keep_latest';
  job.decisionSummaryJson = '{"highRisk":1,"inBatch":1,"existing":0}';
  return job;
}

Future<void> _scrollToHistory(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('导入任务历史'),
    320,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text).first,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first, warnIfMissed: false);
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
