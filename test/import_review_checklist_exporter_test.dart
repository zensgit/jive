import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:jive/feature/import/import_failure_report_exporter.dart';

void main() {
  test('export writes review checklist with expected file naming', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'jive_review_export_test_',
    );
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    final writes = <String, String>{};
    ImportReviewChecklistSharePayload? shared;
    final exporter = ImportReviewChecklistExporter(
      now: () => DateTime(2026, 2, 17, 11, 22, 33),
      resolveTempDirectory: () async => tempDir,
      writeFileText: (path, content) async {
        writes[path] = content;
      },
      shareFile: (payload) async {
        shared = payload;
      },
    );

    const csv = 'lineNumber,selected\\n1,yes\\n';
    final result = await exporter.export(
      const ImportReviewChecklistExportRequest(
        csv: csv,
        previewFilterName: 'selected',
        previewFilterLabel: '仅已选',
        visibleCount: 1,
      ),
    );

    expect(result.fileName, 'jive_import_review_selected_20260217_112233.csv');
    expect(result.filePath, '${tempDir.path}/${result.fileName}');
    expect(writes[result.filePath], csv);
    expect(shared, isNotNull);
    expect(shared?.filePath, result.filePath);
    expect(shared?.subject, 'Jive 导入复核清单');
    expect(shared?.text, '导入复核清单（1 条，筛选：仅已选）');
  });

  test('export bubbles review share errors to caller', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'jive_review_export_test_error_',
    );
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    var writeCalled = false;
    final exporter = ImportReviewChecklistExporter(
      now: () => DateTime(2026, 2, 17, 12, 0, 0),
      resolveTempDirectory: () async => tempDir,
      writeFileText: (_, __) async {
        writeCalled = true;
      },
      shareFile: (_) async {
        throw Exception('review share failed');
      },
    );

    await expectLater(
      () => exporter.export(
        const ImportReviewChecklistExportRequest(
          csv: 'lineNumber,selected\\n',
          previewFilterName: 'all',
          previewFilterLabel: '全部',
          visibleCount: 0,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(writeCalled, isTrue);
  });

  test('export keeps non-ascii filter segment with hash fallback', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'jive_review_export_test_non_ascii_',
    );
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    final exporter = ImportReviewChecklistExporter(
      now: () => DateTime(2026, 2, 17, 12, 1, 0),
      resolveTempDirectory: () async => tempDir,
      writeFileText: (_, __) async {},
      shareFile: (_) async {},
    );

    final result = await exporter.export(
      const ImportReviewChecklistExportRequest(
        csv: 'lineNumber,selected\\n',
        previewFilterName: '仅已选',
        previewFilterLabel: '仅已选',
        visibleCount: 0,
      ),
    );

    expect(
      result.fileName,
      matches(RegExp(r'^jive_import_review_u[0-9a-f]+_20260217_120100\.csv$')),
    );
  });
}
