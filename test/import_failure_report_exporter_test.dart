import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:jive/feature/import/import_failure_report_exporter.dart';
import 'package:jive/feature/import/import_history_analytics.dart';

void main() {
  test('export writes csv and shares file with expected naming', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'jive_failure_export_test_',
    );
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    final writes = <String, String>{};
    ImportFailureReportSharePayload? shared;
    final exporter = ImportFailureReportExporter(
      now: () => DateTime(2026, 2, 17, 8, 9, 10),
      resolveTempDirectory: () async => tempDir,
      writeFileText: (path, content) async {
        writes[path] = content;
      },
      shareFile: (payload) async {
        shared = payload;
      },
    );

    final result = await exporter.export(
      ImportFailureReportExportRequest(
        aggregates: [
          ImportFailureReasonAggregate(
            reason: 'parse error',
            count: 2,
            latestJobId: 101,
            latestOccurredAt: DateTime(2026, 2, 16, 10, 0),
          ),
        ],
        retryableByReason: {'parse error': 1},
        blockedByReason: {'parse error': 1},
        windowName: 'd30',
        windowLabel: '30天',
        sourceName: 'wechat',
        sourceScopeLabel: '微信',
        failedCount: 2,
        retryableCount: 1,
        blockedCount: 1,
      ),
    );

    expect(
      result.fileName,
      'jive_failure_aggregate_d30_wechat_20260217_080910.csv',
    );
    expect(result.filePath, '${tempDir.path}/${result.fileName}');
    expect(writes[result.filePath], isNotNull);
    expect(writes[result.filePath], contains('"时间窗口","30天"'));
    expect(writes[result.filePath], contains('"来源范围","微信"'));
    expect(
      writes[result.filePath],
      contains('"parse error",2,101,2026-02-16T10:00:00.000,1,1,50%'),
    );
    expect(shared, isNotNull);
    expect(shared?.filePath, result.filePath);
    expect(shared?.text, 'Jive 失败聚合报表（30天 / 微信）');
  });

  test('export uses all as default source segment in file naming', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'jive_failure_export_test_all_',
    );
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    final exporter = ImportFailureReportExporter(
      now: () => DateTime(2026, 2, 17, 9, 30, 0),
      resolveTempDirectory: () async => tempDir,
      writeFileText: (_, __) async {},
      shareFile: (_) async {},
    );

    final result = await exporter.export(
      ImportFailureReportExportRequest(
        aggregates: const [],
        retryableByReason: const {},
        blockedByReason: const {},
        windowName: 'all',
        windowLabel: '全部',
        sourceName: 'all',
        sourceScopeLabel: '全部来源',
        failedCount: 0,
        retryableCount: 0,
        blockedCount: 0,
      ),
    );

    expect(
      result.fileName,
      'jive_failure_aggregate_all_all_20260217_093000.csv',
    );
  });

  test('export bubbles share errors to caller', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'jive_failure_export_test_error_',
    );
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    var writeCalled = false;
    final exporter = ImportFailureReportExporter(
      now: () => DateTime(2026, 2, 17, 10, 0, 0),
      resolveTempDirectory: () async => tempDir,
      writeFileText: (_, __) async {
        writeCalled = true;
      },
      shareFile: (_) async {
        throw Exception('share failed');
      },
    );

    await expectLater(
      () => exporter.export(
        ImportFailureReportExportRequest(
          aggregates: const [],
          retryableByReason: const {},
          blockedByReason: const {},
          windowName: 'd7',
          windowLabel: '7天',
          sourceName: 'csv',
          sourceScopeLabel: 'CSV/TSV',
          failedCount: 1,
          retryableCount: 1,
          blockedCount: 0,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(writeCalled, isTrue);
  });
}
