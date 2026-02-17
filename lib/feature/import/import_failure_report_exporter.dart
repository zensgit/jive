import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'import_history_analytics.dart';

typedef ImportReportNow = DateTime Function();
typedef ImportReportDirectoryResolver = Future<Directory> Function();
typedef ImportReportWriteFile = Future<void> Function(
  String filePath,
  String content,
);
typedef ImportReportShareFile = Future<void> Function(
  ImportReportSharePayload payload,
);

class ImportReportSharePayload {
  final String filePath;
  final String text;
  final String? subject;

  const ImportReportSharePayload({
    required this.filePath,
    required this.text,
    this.subject,
  });
}

class _ImportCsvExportResult {
  final String filePath;
  final String fileName;

  const _ImportCsvExportResult({required this.filePath, required this.fileName});
}

class _ImportCsvExporterInfrastructure {
  final ImportReportNow _now;
  final ImportReportDirectoryResolver _resolveTempDirectory;
  final ImportReportWriteFile _writeFileText;
  final ImportReportShareFile _shareFile;

  _ImportCsvExporterInfrastructure({
    required ImportReportNow now,
    required ImportReportDirectoryResolver resolveTempDirectory,
    required ImportReportWriteFile writeFileText,
    required ImportReportShareFile shareFile,
  }) : _now = now,
       _resolveTempDirectory = resolveTempDirectory,
       _writeFileText = writeFileText,
       _shareFile = shareFile;

  Future<_ImportCsvExportResult> exportCsv({
    required String filePrefix,
    required List<String> nameSegments,
    required String csv,
    required String shareText,
    String? shareSubject,
  }) async {
    final now = _now();
    final fileName = _buildFileName(
      prefix: filePrefix,
      nameSegments: nameSegments,
      now: now,
    );
    final dir = await _resolveTempDirectory();
    final filePath = '${dir.path}/$fileName';
    await _writeFileText(filePath, csv);
    await _shareFile(
      ImportReportSharePayload(
        filePath: filePath,
        text: shareText,
        subject: shareSubject,
      ),
    );
    return _ImportCsvExportResult(filePath: filePath, fileName: fileName);
  }

  String _buildFileName({
    required String prefix,
    required List<String> nameSegments,
    required DateTime now,
  }) {
    final segments = <String>[prefix];
    for (final raw in nameSegments) {
      final segment = _sanitizeFileSegment(raw);
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
    }
    segments.add(_timestamp(now));
    return '${segments.join('_')}.csv';
  }

  String _sanitizeFileSegment(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return '';
    final replaced = lower
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return replaced;
  }

  String _timestamp(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}_'
        '${value.hour.toString().padLeft(2, '0')}${value.minute.toString().padLeft(2, '0')}${value.second.toString().padLeft(2, '0')}';
  }
}

class ImportFailureReportExportRequest {
  final List<ImportFailureReasonAggregate> aggregates;
  final Map<String, int> retryableByReason;
  final Map<String, int> blockedByReason;
  final String windowName;
  final String windowLabel;
  final String sourceName;
  final String sourceScopeLabel;
  final int failedCount;
  final int retryableCount;
  final int blockedCount;

  const ImportFailureReportExportRequest({
    required this.aggregates,
    required this.retryableByReason,
    required this.blockedByReason,
    required this.windowName,
    required this.windowLabel,
    required this.sourceName,
    required this.sourceScopeLabel,
    required this.failedCount,
    required this.retryableCount,
    required this.blockedCount,
  });
}

class ImportFailureReportSharePayload {
  final String filePath;
  final String text;

  const ImportFailureReportSharePayload({
    required this.filePath,
    required this.text,
  });
}

class ImportFailureReportExportResult {
  final String filePath;
  final String fileName;
  final String csv;

  const ImportFailureReportExportResult({
    required this.filePath,
    required this.fileName,
    required this.csv,
  });
}

typedef ImportFailureReportShareFile = Future<void> Function(
  ImportFailureReportSharePayload payload,
);

class ImportFailureReportExporter {
  final _ImportCsvExporterInfrastructure _infrastructure;

  ImportFailureReportExporter({
    ImportReportNow? now,
    ImportReportDirectoryResolver? resolveTempDirectory,
    ImportReportWriteFile? writeFileText,
    ImportFailureReportShareFile? shareFile,
  }) : _infrastructure = _ImportCsvExporterInfrastructure(
         now: now ?? DateTime.now,
         resolveTempDirectory: resolveTempDirectory ?? getTemporaryDirectory,
         writeFileText: writeFileText ?? _defaultWriteFileText,
         shareFile: (payload) async {
           final share = shareFile ?? _defaultFailureShareFile;
           await share(
             ImportFailureReportSharePayload(
               filePath: payload.filePath,
               text: payload.text,
             ),
           );
         },
       );

  Future<ImportFailureReportExportResult> export(
    ImportFailureReportExportRequest request,
  ) async {
    final csv = buildImportFailureAggregateCsv(
      aggregates: request.aggregates,
      retryableByReason: request.retryableByReason,
      blockedByReason: request.blockedByReason,
      windowLabel: request.windowLabel,
      sourceScopeLabel: request.sourceScopeLabel,
      failedCount: request.failedCount,
      retryableCount: request.retryableCount,
      blockedCount: request.blockedCount,
    );
    final exported = await _infrastructure.exportCsv(
      filePrefix: 'jive_failure_aggregate',
      nameSegments: [request.windowName, request.sourceName],
      csv: csv,
      shareText:
          'Jive 失败聚合报表（${request.windowLabel} / ${request.sourceScopeLabel}）',
    );
    return ImportFailureReportExportResult(
      filePath: exported.filePath,
      fileName: exported.fileName,
      csv: csv,
    );
  }
}

class ImportReviewChecklistExportRequest {
  final String csv;
  final String previewFilterName;
  final String previewFilterLabel;
  final int visibleCount;

  const ImportReviewChecklistExportRequest({
    required this.csv,
    required this.previewFilterName,
    required this.previewFilterLabel,
    required this.visibleCount,
  });
}

class ImportReviewChecklistSharePayload {
  final String filePath;
  final String text;
  final String subject;

  const ImportReviewChecklistSharePayload({
    required this.filePath,
    required this.text,
    required this.subject,
  });
}

class ImportReviewChecklistExportResult {
  final String filePath;
  final String fileName;
  final String csv;

  const ImportReviewChecklistExportResult({
    required this.filePath,
    required this.fileName,
    required this.csv,
  });
}

typedef ImportReviewChecklistShareFile = Future<void> Function(
  ImportReviewChecklistSharePayload payload,
);

class ImportReviewChecklistExporter {
  final _ImportCsvExporterInfrastructure _infrastructure;

  ImportReviewChecklistExporter({
    ImportReportNow? now,
    ImportReportDirectoryResolver? resolveTempDirectory,
    ImportReportWriteFile? writeFileText,
    ImportReviewChecklistShareFile? shareFile,
  }) : _infrastructure = _ImportCsvExporterInfrastructure(
         now: now ?? DateTime.now,
         resolveTempDirectory: resolveTempDirectory ?? getTemporaryDirectory,
         writeFileText: writeFileText ?? _defaultWriteFileText,
         shareFile: (payload) async {
           final share = shareFile ?? _defaultReviewShareFile;
           await share(
             ImportReviewChecklistSharePayload(
               filePath: payload.filePath,
               text: payload.text,
               subject: payload.subject ?? 'Jive 导入复核清单',
             ),
           );
         },
       );

  Future<ImportReviewChecklistExportResult> export(
    ImportReviewChecklistExportRequest request,
  ) async {
    final exported = await _infrastructure.exportCsv(
      filePrefix: 'jive_import_review',
      nameSegments: [request.previewFilterName],
      csv: request.csv,
      shareText:
          '导入复核清单（${request.visibleCount} 条，筛选：${request.previewFilterLabel}）',
      shareSubject: 'Jive 导入复核清单',
    );
    return ImportReviewChecklistExportResult(
      filePath: exported.filePath,
      fileName: exported.fileName,
      csv: request.csv,
    );
  }
}

Future<void> _defaultWriteFileText(String filePath, String content) async {
  final file = File(filePath);
  await file.writeAsString(content);
}

Future<void> _defaultFailureShareFile(
  ImportFailureReportSharePayload payload,
) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(payload.filePath)], text: payload.text),
  );
}

Future<void> _defaultReviewShareFile(
  ImportReviewChecklistSharePayload payload,
) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(payload.filePath)],
      subject: payload.subject,
      text: payload.text,
    ),
  );
}
