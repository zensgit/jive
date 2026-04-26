import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';

import '../database/auto_draft_model.dart';
import '../database/import_job_model.dart';
import '../database/import_job_record_model.dart';
import '../database/transaction_model.dart';
import '../repository/import_job_history_repository.dart';
import 'alipay_csv_parser.dart';
import 'auto_draft_service.dart';
import 'auto_settings.dart';
import 'data_reload_bus.dart';
import 'ocr_service.dart';
import 'wechat_csv_parser.dart';

enum ImportSourceType { auto, csv, alipay, wechat, ocr }

enum ImportEntryType { text, file, image }

enum ImportJobStatus { pending, running, review, failed }

enum ImportDuplicatePolicy { keepLatest, keepAll, skipAll }

class ImportParsedRecord {
  static const Object _unsetValue = Object();

  final double amount;
  final String source;
  final DateTime timestamp;
  final String? rawText;
  final String? type;
  final String? accountBookName;
  final String? accountName;
  final String? toAccountName;
  final String? parentCategoryName;
  final String? childCategoryName;
  final double? serviceCharge;
  final List<String> tagNames;
  final int lineNumber;
  final double confidence;
  final List<String> warnings;

  const ImportParsedRecord({
    required this.amount,
    required this.source,
    required this.timestamp,
    required this.rawText,
    required this.type,
    this.accountBookName,
    this.accountName,
    this.toAccountName,
    this.parentCategoryName,
    this.childCategoryName,
    this.serviceCharge,
    this.tagNames = const [],
    required this.lineNumber,
    this.confidence = 1,
    this.warnings = const [],
  });

  bool get isValid => amount > 0;
  bool get hasWarnings => warnings.isNotEmpty;

  ImportParsedRecord copyWith({
    double? amount,
    String? source,
    DateTime? timestamp,
    Object? rawText = _unsetValue,
    Object? type = _unsetValue,
    Object? accountBookName = _unsetValue,
    Object? accountName = _unsetValue,
    Object? toAccountName = _unsetValue,
    Object? parentCategoryName = _unsetValue,
    Object? childCategoryName = _unsetValue,
    Object? serviceCharge = _unsetValue,
    Object? tagNames = _unsetValue,
    int? lineNumber,
    double? confidence,
    List<String>? warnings,
  }) {
    return ImportParsedRecord(
      amount: amount ?? this.amount,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      rawText: identical(rawText, _unsetValue)
          ? this.rawText
          : rawText as String?,
      type: identical(type, _unsetValue) ? this.type : type as String?,
      accountBookName: identical(accountBookName, _unsetValue)
          ? this.accountBookName
          : accountBookName as String?,
      accountName: identical(accountName, _unsetValue)
          ? this.accountName
          : accountName as String?,
      toAccountName: identical(toAccountName, _unsetValue)
          ? this.toAccountName
          : toAccountName as String?,
      parentCategoryName: identical(parentCategoryName, _unsetValue)
          ? this.parentCategoryName
          : parentCategoryName as String?,
      childCategoryName: identical(childCategoryName, _unsetValue)
          ? this.childCategoryName
          : childCategoryName as String?,
      serviceCharge: identical(serviceCharge, _unsetValue)
          ? this.serviceCharge
          : serviceCharge as double?,
      tagNames: identical(tagNames, _unsetValue)
          ? this.tagNames
          : List<String>.from(tagNames as List<String>),
      lineNumber: lineNumber ?? this.lineNumber,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
    );
  }
}

class ImportIngestResult {
  final int jobId;
  final int totalCount;
  final int insertedCount;
  final int duplicateCount;
  final int invalidCount;
  final int skippedByDuplicateDecisionCount;
  final String duplicatePolicy;
  final String? decisionSummaryJson;
  final String? errorMessage;

  const ImportIngestResult({
    required this.jobId,
    required this.totalCount,
    required this.insertedCount,
    required this.duplicateCount,
    required this.invalidCount,
    this.skippedByDuplicateDecisionCount = 0,
    this.duplicatePolicy = 'keep_latest',
    this.decisionSummaryJson,
    this.errorMessage,
  });

  bool get hasChanges => insertedCount > 0;
  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
}

class ImportDuplicateEstimate {
  final int validCount;
  final int inBatchDuplicates;
  final int existingDuplicates;

  const ImportDuplicateEstimate({
    required this.validCount,
    required this.inBatchDuplicates,
    required this.existingDuplicates,
  });

  const ImportDuplicateEstimate.empty()
    : validCount = 0,
      inBatchDuplicates = 0,
      existingDuplicates = 0;

  int get totalPotentialDuplicates => inBatchDuplicates + existingDuplicates;

  double get duplicateRate {
    if (validCount <= 0) return 0;
    return totalPotentialDuplicates / validCount;
  }
}

class ImportDuplicateRiskItem {
  final int recordIndex;
  final int lineNumber;
  final String dedupKey;
  final bool inBatchDuplicate;
  final bool existingDuplicate;
  final DateTime? latestExistingTimestamp;

  const ImportDuplicateRiskItem({
    required this.recordIndex,
    required this.lineNumber,
    required this.dedupKey,
    required this.inBatchDuplicate,
    required this.existingDuplicate,
    required this.latestExistingTimestamp,
  });

  bool get isHighRisk => inBatchDuplicate || existingDuplicate;
}

class ImportDuplicateReview {
  final List<ImportDuplicateRiskItem> items;

  const ImportDuplicateReview({required this.items});

  const ImportDuplicateReview.empty() : items = const [];

  int get highRiskCount => items.length;
  int get inBatchCount => items.where((item) => item.inBatchDuplicate).length;
  int get existingCount => items.where((item) => item.existingDuplicate).length;

  Set<int> get highRiskIndices => items.map((item) => item.recordIndex).toSet();

  Map<int, ImportDuplicateRiskItem> get byRecordIndex => {
    for (final item in items) item.recordIndex: item,
  };
}

class ImportJobDetailSummary {
  final int jobId;
  final int totalCount;
  final int insertedCount;
  final int duplicateCount;
  final int invalidCount;
  final int skippedByDuplicateDecisionCount;
  final String duplicatePolicy;
  final int highRiskCount;
  final int inBatchRiskCount;
  final int existingRiskCount;
  final Map<String, int> decisionBreakdown;

  const ImportJobDetailSummary({
    required this.jobId,
    required this.totalCount,
    required this.insertedCount,
    required this.duplicateCount,
    required this.invalidCount,
    required this.skippedByDuplicateDecisionCount,
    required this.duplicatePolicy,
    required this.highRiskCount,
    required this.inBatchRiskCount,
    required this.existingRiskCount,
    required this.decisionBreakdown,
  });
}

class _PolicySkipDecision {
  final String decision;
  final String reason;

  const _PolicySkipDecision({required this.decision, required this.reason});
}

class _ImportRecordIngestOutcome {
  final int totalCount;
  final int insertedCount;
  final int duplicateCount;
  final int invalidCount;
  final int skippedByDuplicateDecisionCount;
  final String decisionSummaryJson;

  const _ImportRecordIngestOutcome({
    required this.totalCount,
    required this.insertedCount,
    required this.duplicateCount,
    required this.invalidCount,
    required this.skippedByDuplicateDecisionCount,
    required this.decisionSummaryJson,
  });
}

class ImportService {
  ImportService(
    this.isar, {
    OcrService? ocrService,
    ImportJobHistoryRepository? jobHistoryRepository,
  }) : _ocrService = ocrService ?? OcrService(),
       _jobHistoryRepository =
           jobHistoryRepository ?? ImportJobHistoryRepository(isar);

  final Isar isar;
  final OcrService _ocrService;
  final ImportJobHistoryRepository _jobHistoryRepository;

  static const int _maxPayloadChars = 20000;

  Future<List<JiveImportJob>> listRecentJobs({int limit = 20}) async {
    return _jobHistoryRepository.listRecentJobs(limit: limit);
  }

  Future<List<JiveImportJobRecord>> listJobRecords(
    int jobId, {
    String? decision,
    String? riskLevel,
    int limit = 200,
    int offset = 0,
  }) async {
    return _jobHistoryRepository.listJobRecords(
      jobId,
      decision: decision,
      riskLevel: riskLevel,
      limit: limit,
      offset: offset,
    );
  }

  Future<ImportJobDetailSummary> getJobDetailSummary(int jobId) async {
    final job = await isar.collection<JiveImportJob>().get(jobId);
    if (job == null) {
      throw StateError('导入任务不存在: $jobId');
    }
    final records = await isar
        .collection<JiveImportJobRecord>()
        .filter()
        .jobIdEqualTo(jobId)
        .findAll();
    final decisionBreakdown = <String, int>{};
    var highRiskCount = 0;
    var inBatchRiskCount = 0;
    var existingRiskCount = 0;
    for (final record in records) {
      decisionBreakdown[record.decision] =
          (decisionBreakdown[record.decision] ?? 0) + 1;
      switch (record.riskLevel) {
        case 'batch':
          highRiskCount += 1;
          inBatchRiskCount += 1;
          break;
        case 'existing':
          highRiskCount += 1;
          existingRiskCount += 1;
          break;
        case 'both':
          highRiskCount += 1;
          inBatchRiskCount += 1;
          existingRiskCount += 1;
          break;
      }
    }
    return ImportJobDetailSummary(
      jobId: job.id,
      totalCount: job.totalCount,
      insertedCount: job.insertedCount,
      duplicateCount: job.duplicateCount,
      invalidCount: job.invalidCount,
      skippedByDuplicateDecisionCount: job.skippedByDuplicateDecisionCount,
      duplicatePolicy: job.duplicatePolicy,
      highRiskCount: highRiskCount,
      inBatchRiskCount: inBatchRiskCount,
      existingRiskCount: existingRiskCount,
      decisionBreakdown: decisionBreakdown,
    );
  }

  Future<String> readTextFromFile(File file) async {
    final bytes = await file.readAsBytes();
    return _decodeText(bytes);
  }

  Future<String> recognizeTextFromImage(XFile imageFile) async {
    final text = await _ocrService.recognizeTextFromImagePath(imageFile.path);
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw StateError('OCR 未识别到可导入文本');
    }
    return trimmed;
  }

  Future<ImportDuplicateEstimate> estimateDuplicateRisk(
    List<ImportParsedRecord> records,
  ) async {
    final valid = records.where((record) => record.isValid).toList();
    if (valid.isEmpty) {
      return const ImportDuplicateEstimate.empty();
    }

    final keyByIndex = <String>[];
    final frequency = <String, int>{};
    for (final record in valid) {
      final key = _buildRiskDedupKey(record);
      keyByIndex.add(key);
      frequency[key] = (frequency[key] ?? 0) + 1;
    }

    var inBatchDuplicates = 0;
    for (final count in frequency.values) {
      if (count > 1) {
        inBatchDuplicates += count - 1;
      }
    }

    final existingLatestMap = await _loadExistingRiskKeyLatestMap();

    var existingDuplicates = 0;
    for (final key in keyByIndex) {
      if (existingLatestMap.containsKey(key)) {
        existingDuplicates += 1;
      }
    }

    return ImportDuplicateEstimate(
      validCount: valid.length,
      inBatchDuplicates: inBatchDuplicates,
      existingDuplicates: existingDuplicates,
    );
  }

  Future<ImportDuplicateReview> analyzeDuplicateRisk(
    List<ImportParsedRecord> records,
  ) async {
    final validEntries = <MapEntry<int, ImportParsedRecord>>[];
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.isValid) {
        validEntries.add(MapEntry(i, record));
      }
    }
    if (validEntries.isEmpty) {
      return const ImportDuplicateReview.empty();
    }

    final keyByIndex = <int, String>{};
    final groupByKey = <String, List<int>>{};
    for (final entry in validEntries) {
      final key = _buildRiskDedupKey(entry.value);
      keyByIndex[entry.key] = key;
      groupByKey.putIfAbsent(key, () => <int>[]).add(entry.key);
    }

    final existingLatestMap = await _loadExistingRiskKeyLatestMap();
    final items = <ImportDuplicateRiskItem>[];
    for (final entry in validEntries) {
      final key = keyByIndex[entry.key]!;
      final inBatch = (groupByKey[key]?.length ?? 0) > 1;
      final existingLatest = existingLatestMap[key];
      final existingDuplicate = existingLatest != null;
      if (!inBatch && !existingDuplicate) continue;
      items.add(
        ImportDuplicateRiskItem(
          recordIndex: entry.key,
          lineNumber: entry.value.lineNumber,
          dedupKey: key,
          inBatchDuplicate: inBatch,
          existingDuplicate: existingDuplicate,
          latestExistingTimestamp: existingLatest,
        ),
      );
    }
    items.sort((a, b) => a.recordIndex.compareTo(b.recordIndex));
    return ImportDuplicateReview(items: items);
  }

  Future<ImportIngestResult> retryJob(int jobId) async {
    final job = await _jobHistoryRepository.getJob(jobId);
    if (job == null) {
      throw StateError('导入任务不存在: $jobId');
    }
    final sourceType = _sourceTypeFromString(job.sourceType);
    final duplicatePolicy = _duplicatePolicyFromName(job.duplicatePolicy);

    if (job.filePath != null && job.filePath!.isNotEmpty) {
      final file = File(job.filePath!);
      if (await file.exists()) {
        return importFromFile(
          file: file,
          sourceType: sourceType,
          duplicatePolicy: duplicatePolicy,
          retryFromJobId: job.id,
        );
      }
    }

    final payload = (job.payloadText ?? '').trim();
    if (payload.isNotEmpty) {
      return importFromText(
        text: payload,
        sourceType: sourceType,
        entryType: _entryTypeFromString(job.entryType),
        filePath: job.filePath,
        fileName: job.fileName,
        duplicatePolicy: duplicatePolicy,
        retryFromJobId: job.id,
      );
    }

    throw StateError('原始导入内容已丢失，无法重试');
  }

  Future<ImportIngestResult> importFromImage({
    required XFile imageFile,
    ImportSourceType sourceType = ImportSourceType.ocr,
    ImportDuplicatePolicy duplicatePolicy = ImportDuplicatePolicy.keepLatest,
    int? retryFromJobId,
  }) async {
    final text = await recognizeTextFromImage(imageFile);
    return importFromText(
      text: text,
      sourceType: sourceType,
      entryType: ImportEntryType.image,
      filePath: imageFile.path,
      fileName: _basename(imageFile.path),
      duplicatePolicy: duplicatePolicy,
      retryFromJobId: retryFromJobId,
    );
  }

  Future<ImportIngestResult> importFromFile({
    required File file,
    ImportSourceType sourceType = ImportSourceType.auto,
    ImportDuplicatePolicy duplicatePolicy = ImportDuplicatePolicy.keepLatest,
    int? retryFromJobId,
  }) async {
    final text = await readTextFromFile(file);
    return importFromText(
      text: text,
      sourceType: sourceType,
      entryType: ImportEntryType.file,
      filePath: file.path,
      fileName: _basename(file.path),
      duplicatePolicy: duplicatePolicy,
      retryFromJobId: retryFromJobId,
    );
  }

  Future<ImportIngestResult> importFromText({
    required String text,
    ImportSourceType sourceType = ImportSourceType.auto,
    ImportEntryType entryType = ImportEntryType.text,
    String? filePath,
    String? fileName,
    ImportDuplicatePolicy duplicatePolicy = ImportDuplicatePolicy.keepLatest,
    int? retryFromJobId,
  }) async {
    final records = parseText(text, sourceType: sourceType);
    return importPreparedRecords(
      records: records,
      payloadText: text,
      sourceType: sourceType,
      entryType: entryType,
      filePath: filePath,
      fileName: fileName,
      duplicatePolicy: duplicatePolicy,
      retryFromJobId: retryFromJobId,
    );
  }

  Future<ImportIngestResult> importPreparedRecords({
    required List<ImportParsedRecord> records,
    required String payloadText,
    ImportSourceType sourceType = ImportSourceType.auto,
    ImportEntryType entryType = ImportEntryType.text,
    String? filePath,
    String? fileName,
    ImportDuplicatePolicy duplicatePolicy = ImportDuplicatePolicy.keepLatest,
    int? retryFromJobId,
  }) async {
    final createdAt = DateTime.now();
    final jobId = await _jobHistoryRepository.createPendingJob(
      createdAt: createdAt,
      sourceType: _sourceTypeName(sourceType),
      entryType: _entryTypeName(entryType),
      filePath: filePath,
      fileName: fileName,
      payloadText: _trimPayload(payloadText),
      duplicatePolicy: _duplicatePolicyName(duplicatePolicy),
      retryFromJobId: retryFromJobId,
    );

    try {
      await _updateJobStatus(jobId, ImportJobStatus.running);
      final ingest = await _importRecords(
        records,
        jobId: jobId,
        duplicatePolicy: duplicatePolicy,
      );

      await _finishJob(
        jobId: jobId,
        status: ImportJobStatus.review,
        totalCount: ingest.totalCount,
        insertedCount: ingest.insertedCount,
        duplicateCount: ingest.duplicateCount,
        invalidCount: ingest.invalidCount,
        skippedByDuplicateDecisionCount: ingest.skippedByDuplicateDecisionCount,
        duplicatePolicy: _duplicatePolicyName(duplicatePolicy),
        decisionSummaryJson: ingest.decisionSummaryJson,
        errorMessage: null,
      );

      return ImportIngestResult(
        jobId: jobId,
        totalCount: ingest.totalCount,
        insertedCount: ingest.insertedCount,
        duplicateCount: ingest.duplicateCount,
        invalidCount: ingest.invalidCount,
        skippedByDuplicateDecisionCount: ingest.skippedByDuplicateDecisionCount,
        duplicatePolicy: _duplicatePolicyName(duplicatePolicy),
        decisionSummaryJson: ingest.decisionSummaryJson,
      );
    } catch (e) {
      final message = e.toString();
      final summary = jsonEncode({
        'policy': _duplicatePolicyName(duplicatePolicy),
        'error': message,
      });
      await _finishJob(
        jobId: jobId,
        status: ImportJobStatus.failed,
        totalCount: records.length,
        insertedCount: 0,
        duplicateCount: 0,
        invalidCount: records.length,
        skippedByDuplicateDecisionCount: 0,
        duplicatePolicy: _duplicatePolicyName(duplicatePolicy),
        decisionSummaryJson: summary,
        errorMessage: message,
      );
      return ImportIngestResult(
        jobId: jobId,
        totalCount: records.length,
        insertedCount: 0,
        duplicateCount: 0,
        invalidCount: records.length,
        skippedByDuplicateDecisionCount: 0,
        duplicatePolicy: _duplicatePolicyName(duplicatePolicy),
        decisionSummaryJson: summary,
        errorMessage: message,
      );
    }
  }

  Future<_ImportRecordIngestOutcome> _importRecords(
    List<ImportParsedRecord> records, {
    required int jobId,
    ImportDuplicatePolicy duplicatePolicy = ImportDuplicatePolicy.keepLatest,
  }) async {
    var insertedCount = 0;
    var duplicateCount = 0;
    var invalidCount = 0;
    var skippedByDecisionCount = 0;

    final autoDraftService = AutoDraftService(isar);
    final duplicateReview = await analyzeDuplicateRisk(records);
    final riskByIndex = duplicateReview.byRecordIndex;
    final skipByIndex = _buildPolicySkipDecisions(
      records: records,
      review: duplicateReview,
      policy: duplicatePolicy,
    );
    final now = DateTime.now();
    final jobRecords = <JiveImportJobRecord>[];

    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      final riskItem = riskByIndex[index];
      final dedupKey = _buildRiskDedupKey(record);
      final riskLevel = _riskLevelOf(riskItem);

      if (!record.isValid) {
        invalidCount += 1;
        jobRecords.add(
          _buildJobRecord(
            jobId: jobId,
            record: record,
            dedupKey: dedupKey,
            riskLevel: riskLevel,
            decision: 'invalid',
            decisionReason: 'invalid_amount',
            createdAt: now,
          ),
        );
        continue;
      }

      final policyDecision = skipByIndex[index];
      if (policyDecision != null) {
        skippedByDecisionCount += 1;
        jobRecords.add(
          _buildJobRecord(
            jobId: jobId,
            record: record,
            dedupKey: dedupKey,
            riskLevel: riskLevel,
            decision: policyDecision.decision,
            decisionReason: policyDecision.reason,
            createdAt: now,
          ),
        );
        continue;
      }

      final capture = AutoCapture(
        amount: record.amount,
        source: record.source,
        rawText: record.rawText,
        timestamp: record.timestamp,
        type: record.type,
        accountBookName: record.accountBookName,
        accountName: record.accountName,
        toAccountName: record.toAccountName,
        parentCategoryName: record.parentCategoryName,
        childCategoryName: record.childCategoryName,
        serviceCharge: record.serviceCharge,
        tagNames: record.tagNames,
      );

      final result = await autoDraftService.ingestCapture(
        capture,
        directCommit: false,
        settings: AutoSettingsStore.defaults,
      );

      if (result.duplicate) {
        duplicateCount += 1;
        jobRecords.add(
          _buildJobRecord(
            jobId: jobId,
            record: record,
            dedupKey: dedupKey,
            riskLevel: riskLevel,
            decision: 'duplicate',
            decisionReason: 'duplicate_in_draft',
            createdAt: now,
          ),
        );
        continue;
      }

      if (result.inserted || result.merged) {
        insertedCount += 1;
        jobRecords.add(
          _buildJobRecord(
            jobId: jobId,
            record: record,
            dedupKey: dedupKey,
            riskLevel: riskLevel,
            decision: 'inserted',
            decisionReason: result.merged
                ? 'merged_existing_draft'
                : 'inserted',
            createdAt: now,
          ),
        );
        continue;
      }

      invalidCount += 1;
      jobRecords.add(
        _buildJobRecord(
          jobId: jobId,
          record: record,
          dedupKey: dedupKey,
          riskLevel: riskLevel,
          decision: 'invalid',
          decisionReason: 'no_effect',
          createdAt: now,
        ),
      );
    }

    final recordWriteFailed = !await _jobHistoryRepository.saveJobRecords(
      jobRecords,
    );

    if (insertedCount > 0) {
      DataReloadBus.notify();
    }

    final decisionSummary = jsonEncode({
      'policy': _duplicatePolicyName(duplicatePolicy),
      'highRisk': duplicateReview.highRiskCount,
      'inBatch': duplicateReview.inBatchCount,
      'existing': duplicateReview.existingCount,
      'skippedByDuplicateDecision': skippedByDecisionCount,
      'recordWriteFailed': recordWriteFailed,
    });
    return _ImportRecordIngestOutcome(
      totalCount: records.length,
      insertedCount: insertedCount,
      duplicateCount: duplicateCount,
      invalidCount: invalidCount,
      skippedByDuplicateDecisionCount: skippedByDecisionCount,
      decisionSummaryJson: decisionSummary,
    );
  }

  List<ImportParsedRecord> parseText(
    String text, {
    ImportSourceType sourceType = ImportSourceType.auto,
  }) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final effectiveSource = sourceType == ImportSourceType.auto
        ? _detectSourceType(normalized)
        : sourceType;

    // Try specialized parsers first
    if (effectiveSource == ImportSourceType.wechat ||
        WechatCsvParser.isWechatFormat(normalized)) {
      final records = WechatCsvParser.parse(normalized);
      if (records.isNotEmpty) return records;
    }
    if (effectiveSource == ImportSourceType.alipay ||
        AlipayCsvParser.isAlipayFormat(normalized)) {
      final records = AlipayCsvParser.parse(normalized);
      if (records.isNotEmpty) return records;
    }

    if (effectiveSource == ImportSourceType.csv) {
      return _parseCsv(normalized, effectiveSource);
    }

    return _parseLooseText(normalized, effectiveSource);
  }

  List<ImportParsedRecord> _parseCsv(String text, ImportSourceType sourceType) {
    final lines = text
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final delimiter = _guessDelimiter(lines.first);
    final firstCells = _splitDelimitedLine(lines.first, delimiter);
    final hasHeader = _looksLikeHeader(firstCells);

    final rows = <ImportParsedRecord>[];
    final base = DateTime.now();

    final headerMap = hasHeader ? _buildHeaderMap(firstCells) : <String, int>{};
    final start = hasHeader ? 1 : 0;

    for (var i = start; i < lines.length; i++) {
      final cells = _splitDelimitedLine(lines[i], delimiter);
      if (cells.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      final lineNumber = i + 1;
      final warnings = <String>[];
      final amountText =
          _pickValue(cells, headerMap, _amountAliases) ??
          (cells.length > 1 ? cells[1] : cells.first);
      final amount = _parseAmount(amountText);
      final normalizedAmount = amount ?? 0;
      final validAmount = amount != null && amount > 0;
      if (!validAmount) {
        warnings.add('无法识别金额');
      } else if (_isSuspiciousAmount(normalizedAmount)) {
        warnings.add('金额较大，请确认');
      }

      final dateText =
          _pickValue(cells, headerMap, _dateAliases) ??
          (cells.isNotEmpty ? cells.first : '');
      final parsedDateCandidate = _parseDate(dateText, fallbackDate: base);
      final parsedDate = parsedDateCandidate ?? base.add(Duration(seconds: i));
      if (parsedDateCandidate == null) {
        warnings.add('时间未识别，已使用默认值');
      }
      if (_isSuspiciousTimestamp(parsedDate)) {
        warnings.add('时间异常，请确认');
      }

      final sourceText =
          _pickValue(cells, headerMap, _sourceAliases) ??
          _sourceFromText(lines[i], defaultValue: _defaultSource(sourceType));
      final source = _sourceFromText(
        sourceText,
        defaultValue: _defaultSource(sourceType),
      );
      if (!_looksLikeKnownSource(sourceText)) {
        warnings.add('来源未识别，使用默认来源');
      }

      final accountBookName = _pickValue(cells, headerMap, _accountBookAliases);
      final accountName = _pickValue(cells, headerMap, _assetAliases);
      final toAccountName = _pickValue(cells, headerMap, _toAssetAliases);
      final categoryPathText = _pickValue(
        cells,
        headerMap,
        _categoryPathAliases,
      );
      final categoryPath = _splitCategoryPath(categoryPathText);
      final rawParentCategoryName = _pickValue(
        cells,
        headerMap,
        _parentCategoryAliases,
      );
      final rawChildCategoryName = _pickValue(
        cells,
        headerMap,
        _childCategoryAliases,
      );
      final parentCategoryName =
          _preferExplicitCategoryName(
            rawParentCategoryName,
            categoryPathText,
          ) ??
          categoryPath.parentName;
      final childCategoryName =
          _preferExplicitCategoryName(rawChildCategoryName, categoryPathText) ??
          categoryPath.childName;
      final tagNames = _splitTagNames(
        _pickValue(cells, headerMap, _tagAliases),
      );
      final serviceChargeText = _pickValue(
        cells,
        headerMap,
        _serviceChargeAliases,
      );
      final serviceCharge = _parseAmount(serviceChargeText ?? '');
      final typeText = _pickValue(cells, headerMap, _typeAliases);
      final noteText = _pickValue(cells, headerMap, _textAliases) ?? lines[i];
      final normalizedType = _normalizeType(typeText);
      final inferredType =
          _inferTypeFromCategoryHints(
            parentCategoryName: parentCategoryName,
            childCategoryName: childCategoryName,
          ) ??
          (((toAccountName ?? '').trim().isNotEmpty || serviceCharge != null)
              ? 'transfer'
              : null) ??
          _inferTypeFromText(noteText, sourceType);
      final resolvedType = normalizedType ?? inferredType;
      if (normalizedType == null && inferredType != null) {
        warnings.add('交易类型为推断值');
      }
      if (resolvedType == null) {
        warnings.add('交易类型未知');
      }
      if (resolvedType == 'transfer' &&
          ((toAccountName ?? '').trim().isEmpty)) {
        warnings.add('转账缺少转入账户');
      }
      if (serviceChargeText != null &&
          serviceChargeText.trim().isNotEmpty &&
          serviceCharge == null) {
        warnings.add('手续费未识别');
      }

      rows.add(
        ImportParsedRecord(
          amount: validAmount ? normalizedAmount : 0,
          source: source,
          timestamp: parsedDate,
          rawText: noteText,
          type: resolvedType,
          accountBookName: accountBookName,
          accountName: accountName,
          toAccountName: toAccountName,
          parentCategoryName: parentCategoryName,
          childCategoryName: childCategoryName,
          serviceCharge: serviceCharge,
          tagNames: tagNames,
          lineNumber: lineNumber,
          confidence: _estimateConfidence(
            valid: validAmount,
            warnings: warnings,
          ),
          warnings: warnings,
        ),
      );
    }

    return rows;
  }

  List<ImportParsedRecord> _parseLooseText(
    String text,
    ImportSourceType sourceType,
  ) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final records = <ImportParsedRecord>[];
    final now = DateTime.now();
    DateTime? contextDate;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;
      final warnings = <String>[];

      final dateOnly = _parseDateOnly(line);
      if (dateOnly != null && _parseAmount(line) == null) {
        contextDate = dateOnly;
        continue;
      }

      final amount = _parseAmount(line);
      final normalizedAmount = amount ?? 0;
      final validAmount = amount != null && amount > 0;
      if (!validAmount) {
        warnings.add('无法识别金额');
      } else if (_isSuspiciousAmount(normalizedAmount)) {
        warnings.add('金额较大，请确认');
      }

      final parsedDateCandidate = _parseDate(
        line,
        fallbackDate: contextDate ?? now,
      );
      final timestamp =
          parsedDateCandidate ?? contextDate ?? now.add(Duration(seconds: i));
      if (parsedDateCandidate == null) {
        warnings.add('时间未识别，已使用默认值');
      }
      if (_isSuspiciousTimestamp(timestamp)) {
        warnings.add('时间异常，请确认');
      }

      final source = _sourceFromText(
        line,
        defaultValue: _defaultSource(sourceType),
      );
      if (!_looksLikeKnownSource(line)) {
        warnings.add('来源未识别，使用默认来源');
      }

      final type = _inferTypeFromText(line, sourceType);
      if (type != null) {
        warnings.add('交易类型为推断值');
      } else {
        warnings.add('交易类型未知');
      }

      records.add(
        ImportParsedRecord(
          amount: validAmount ? normalizedAmount : 0,
          source: source,
          timestamp: timestamp,
          rawText: line,
          type: type,
          lineNumber: lineNumber,
          confidence: _estimateConfidence(
            valid: validAmount,
            warnings: warnings,
          ),
          warnings: warnings,
        ),
      );
    }

    return records;
  }

  Future<void> _updateJobStatus(int jobId, ImportJobStatus status) async {
    switch (status) {
      case ImportJobStatus.running:
        await _jobHistoryRepository.markJobRunning(jobId);
        return;
      case ImportJobStatus.pending:
      case ImportJobStatus.review:
      case ImportJobStatus.failed:
        throw StateError('_updateJobStatus 仅支持 running 状态过渡');
    }
  }

  Future<void> _finishJob({
    required int jobId,
    required ImportJobStatus status,
    required int totalCount,
    required int insertedCount,
    required int duplicateCount,
    required int invalidCount,
    required int skippedByDuplicateDecisionCount,
    required String duplicatePolicy,
    String? decisionSummaryJson,
    String? errorMessage,
  }) async {
    await _jobHistoryRepository.finishJob(
      jobId: jobId,
      status: _jobStatusName(status),
      totalCount: totalCount,
      insertedCount: insertedCount,
      duplicateCount: duplicateCount,
      invalidCount: invalidCount,
      skippedByDuplicateDecisionCount: skippedByDuplicateDecisionCount,
      duplicatePolicy: duplicatePolicy,
      decisionSummaryJson: decisionSummaryJson,
      errorMessage: errorMessage,
    );
  }

  Map<int, _PolicySkipDecision> _buildPolicySkipDecisions({
    required List<ImportParsedRecord> records,
    required ImportDuplicateReview review,
    required ImportDuplicatePolicy policy,
  }) {
    if (review.items.isEmpty || policy == ImportDuplicatePolicy.keepAll) {
      return const {};
    }

    final decisions = <int, _PolicySkipDecision>{};
    if (policy == ImportDuplicatePolicy.skipAll) {
      for (final item in review.items) {
        decisions[item.recordIndex] = const _PolicySkipDecision(
          decision: 'skipped_policy',
          reason: 'skip_all_high_risk',
        );
      }
      return decisions;
    }

    final grouped = <String, List<ImportDuplicateRiskItem>>{};
    for (final item in review.items) {
      grouped
          .putIfAbsent(item.dedupKey, () => <ImportDuplicateRiskItem>[])
          .add(item);
    }

    for (final entry in grouped.entries) {
      final items = entry.value;
      DateTime? existingLatest;
      ImportDuplicateRiskItem? latestImportItem;
      DateTime? latestImportTime;
      var latestLine = -1;

      for (final item in items) {
        final index = item.recordIndex;
        if (index < 0 || index >= records.length) continue;
        final record = records[index];
        if (!record.isValid) continue;
        if (item.latestExistingTimestamp != null) {
          final candidate = item.latestExistingTimestamp!;
          if (existingLatest == null || candidate.isAfter(existingLatest)) {
            existingLatest = candidate;
          }
        }
        if (latestImportTime == null ||
            record.timestamp.isAfter(latestImportTime) ||
            (record.timestamp.isAtSameMomentAs(latestImportTime) &&
                record.lineNumber > latestLine)) {
          latestImportItem = item;
          latestImportTime = record.timestamp;
          latestLine = record.lineNumber;
        }
      }

      if (latestImportItem == null) continue;
      final latestRecord = records[latestImportItem.recordIndex];
      final historyNotOlder =
          existingLatest != null &&
          !latestRecord.timestamp.isAfter(existingLatest);

      if (historyNotOlder) {
        for (final item in items) {
          decisions[item.recordIndex] = const _PolicySkipDecision(
            decision: 'skipped_keep_latest_existing_newer',
            reason: 'history_newer_or_equal',
          );
        }
        continue;
      }

      for (final item in items) {
        if (item.recordIndex == latestImportItem.recordIndex) continue;
        decisions[item.recordIndex] = const _PolicySkipDecision(
          decision: 'skipped_policy',
          reason: 'keep_latest_only_newest',
        );
      }
    }

    return decisions;
  }

  JiveImportJobRecord _buildJobRecord({
    required int jobId,
    required ImportParsedRecord record,
    required String dedupKey,
    required String riskLevel,
    required String decision,
    required String decisionReason,
    required DateTime createdAt,
  }) {
    return JiveImportJobRecord()
      ..jobId = jobId
      ..sourceLineNumber = record.lineNumber
      ..amount = record.amount
      ..source = record.source
      ..timestamp = record.timestamp
      ..type = record.type
      ..confidence = record.confidence
      ..warningsJson = jsonEncode(record.warnings)
      ..dedupKey = dedupKey
      ..riskLevel = riskLevel
      ..decision = decision
      ..decisionReason = decisionReason
      ..createdAt = createdAt;
  }

  String _riskLevelOf(ImportDuplicateRiskItem? item) {
    if (item == null) return 'none';
    if (item.inBatchDuplicate && item.existingDuplicate) return 'both';
    if (item.inBatchDuplicate) return 'batch';
    if (item.existingDuplicate) return 'existing';
    return 'none';
  }

  ImportSourceType _detectSourceType(String text) {
    final lower = text.toLowerCase();
    final firstLine = text.split('\n').first;

    if (firstLine.contains(',') || firstLine.contains('\t')) {
      return ImportSourceType.csv;
    }

    if (lower.contains('wechat') || text.contains('微信')) {
      return ImportSourceType.wechat;
    }

    if (lower.contains('alipay') || text.contains('支付宝')) {
      return ImportSourceType.alipay;
    }

    return ImportSourceType.ocr;
  }

  String _decodeText(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index < 0) return normalized;
    return normalized.substring(index + 1);
  }

  String _trimPayload(String text) {
    final normalized = text.trim();
    if (normalized.length <= _maxPayloadChars) return normalized;
    return normalized.substring(0, _maxPayloadChars);
  }

  Future<Map<String, DateTime>> _loadExistingRiskKeyLatestMap() async {
    final latestByKey = <String, DateTime>{};

    final drafts = await isar
        .collection<JiveAutoDraft>()
        .where()
        .dedupKeyIsNotNull()
        .findAll();
    for (final draft in drafts) {
      final key = draft.dedupKey?.trim();
      if (key == null || key.isEmpty) continue;
      final previous = latestByKey[key];
      if (previous == null || draft.timestamp.isAfter(previous)) {
        latestByKey[key] = draft.timestamp;
      }
    }

    final transactions = await isar
        .collection<JiveTransaction>()
        .where()
        .findAll();
    for (final tx in transactions) {
      final key = _buildRiskDedupKeyFromRaw(
        amount: tx.amount,
        source: tx.source,
        rawText: tx.rawText,
      );
      final previous = latestByKey[key];
      if (previous == null || tx.timestamp.isAfter(previous)) {
        latestByKey[key] = tx.timestamp;
      }
    }

    return latestByKey;
  }

  String _buildRiskDedupKey(ImportParsedRecord record) {
    return _buildRiskDedupKeyFromRaw(
      amount: record.amount,
      source: record.source,
      rawText: record.rawText,
    );
  }

  String _buildRiskDedupKeyFromRaw({
    required double amount,
    required String source,
    required String? rawText,
  }) {
    final normalizedText = _normalizeRiskText(rawText ?? '');
    return '${source.trim()}|${amount.toStringAsFixed(2)}|$normalizedText';
  }

  String _normalizeRiskText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u00A0', ' ')
        .toLowerCase();
  }

  String _guessDelimiter(String firstLine) {
    final commaCount = ','.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;
    return tabCount > commaCount ? '\t' : ',';
  }

  List<String> _splitDelimitedLine(String line, String delimiter) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
        if (nextIsQuote) {
          buffer.write('"');
          i += 1;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (!inQuotes && char == delimiter) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString().trim());
    return values;
  }

  bool _looksLikeHeader(List<String> cells) {
    if (cells.isEmpty) return false;
    final normalized = cells.map(_normalizeAlias).toList();
    for (final cell in normalized) {
      if (_amountAliases.contains(cell) ||
          _dateAliases.contains(cell) ||
          _sourceAliases.contains(cell) ||
          _accountBookAliases.contains(cell) ||
          _assetAliases.contains(cell) ||
          _toAssetAliases.contains(cell) ||
          _categoryPathAliases.contains(cell) ||
          _parentCategoryAliases.contains(cell) ||
          _childCategoryAliases.contains(cell) ||
          _tagAliases.contains(cell) ||
          _serviceChargeAliases.contains(cell) ||
          _typeAliases.contains(cell) ||
          _textAliases.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  Map<String, int> _buildHeaderMap(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final key = _normalizeAlias(headers[i]);
      if (key.isNotEmpty) {
        map[key] = i;
      }
    }
    return map;
  }

  String? _pickValue(
    List<String> cells,
    Map<String, int> headerMap,
    Set<String> aliases,
  ) {
    for (final alias in aliases) {
      final index = headerMap[alias];
      if (index == null) continue;
      if (index < 0 || index >= cells.length) continue;
      final value = cells[index].trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  static const Set<String> _amountAliases = {
    'amount',
    'money',
    'amt',
    '金额',
    '交易金额',
    '收支金额',
  };

  static const Set<String> _dateAliases = {
    'date',
    'time',
    'datetime',
    'timestamp',
    '交易时间',
    '时间',
    '日期',
    '入账时间',
  };

  static const Set<String> _sourceAliases = {
    'source',
    'channel',
    'from',
    '来源',
    '渠道',
  };

  static const Set<String> _accountBookAliases = {
    'ledger',
    'book',
    'accountbook',
    '账本',
    '账本名称',
    '账簿',
  };

  static const Set<String> _assetAliases = {
    'asset',
    'account',
    'wallet',
    'card',
    '账户',
    '支付方式',
    '资产',
    '钱包',
    '银行卡',
  };

  static const Set<String> _toAssetAliases = {
    'toaccount',
    'toasset',
    'targetaccount',
    'targetasset',
    '转入账户',
    '转入资产',
    '目标账户',
    '目标资产',
    '收款账户',
    '对方账户',
  };

  static const Set<String> _categoryPathAliases = {
    'categorypath',
    'fullcategory',
    '分类路径',
    '完整分类',
    '分类全路径',
    '大类/中类/小类',
    '三级分类',
  };

  static const Set<String> _parentCategoryAliases = {
    '一级分类',
    'parentcategory',
    'parentcategoryname',
    'category',
    '大类',
    '主类',
  };

  static const Set<String> _childCategoryAliases = {
    '二级分类',
    'childcategory',
    'childcategoryname',
    'subcategory',
    '子类',
    '明细分类',
  };

  static const Set<String> _tagAliases = {'tag', 'tags', '标签', '标签列'};

  static const Set<String> _serviceChargeAliases = {
    'servicecharge',
    'fee',
    '手续费',
    '服务费',
    '转账手续费',
  };

  static const Set<String> _typeAliases = {
    'type',
    'direction',
    '收支',
    '收支类型',
    '交易类型',
  };

  static const Set<String> _textAliases = {
    'raw',
    'text',
    'note',
    'remark',
    'desc',
    '摘要',
    '说明',
    '备注',
    '商户',
  };

  List<String> _splitTagNames(String? raw) {
    if (raw == null) return const [];
    return raw
        .split(RegExp(r'[,，;；、\s]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  _CategoryPathNames _splitCategoryPath(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return const _CategoryPathNames();
    final parts = text
        .split(RegExp(r'\s*(?:/|／|>|＞|\\|、)\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return const _CategoryPathNames();
    if (parts.length == 1) return _CategoryPathNames(parentName: parts.first);
    return _CategoryPathNames(parentName: parts.first, childName: parts.last);
  }

  String? _preferExplicitCategoryName(String? explicit, String? pathText) {
    final text = explicit?.trim();
    if (text == null || text.isEmpty) return null;
    if (pathText != null && text == pathText.trim()) return null;
    return text;
  }

  String? _inferTypeFromCategoryHints({
    required String? parentCategoryName,
    required String? childCategoryName,
  }) {
    final parent = (parentCategoryName ?? '').trim();
    final child = (childCategoryName ?? '').trim();
    if (parent == '收入' || child == '收入') {
      return 'income';
    }
    if (parent == '转账' || child == '转账') {
      return 'transfer';
    }
    if (parent.isNotEmpty || child.isNotEmpty) {
      return 'expense';
    }
    return null;
  }

  String _normalizeAlias(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  double? _parseAmount(String input) {
    final text = input.replaceAll(',', '');

    final withCurrency = RegExp(
      r'(?:¥|￥|rmb|cny)\s*([+-]?\d+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    if (withCurrency != null) {
      return double.tryParse(withCurrency)?.abs();
    }

    final withYuan = RegExp(
      r'([+-]?\d+(?:\.\d{1,2})?)\s*元',
    ).firstMatch(text)?.group(1);
    if (withYuan != null) {
      return double.tryParse(withYuan)?.abs();
    }

    final decimal = RegExp(r'([+-]?\d+\.\d{1,2})').firstMatch(text)?.group(1);
    if (decimal != null) {
      return double.tryParse(decimal)?.abs();
    }

    if (RegExp(r'金额|支付|付款|收款|收入|支出|转账').hasMatch(text)) {
      final integer = RegExp(r'([+-]?\d{1,8})').firstMatch(text)?.group(1);
      if (integer != null) {
        final parsed = double.tryParse(integer);
        if (parsed != null && parsed.abs() <= 1000000) {
          return parsed.abs();
        }
      }
    }

    return null;
  }

  DateTime? _parseDate(String input, {DateTime? fallbackDate}) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final unix = RegExp(r'^\d{10,13}$').firstMatch(text)?.group(0);
    if (unix != null) {
      final value = int.tryParse(unix);
      if (value != null) {
        if (unix.length == 13) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final full = RegExp(
      r'(\d{4})[\-\/.年](\d{1,2})[\-\/.月](\d{1,2})(?:日)?(?:\s+|T)?(\d{1,2})[:：](\d{1,2})(?:[:：](\d{1,2}))?',
    ).firstMatch(text);
    if (full != null) {
      return DateTime(
        int.parse(full.group(1)!),
        int.parse(full.group(2)!),
        int.parse(full.group(3)!),
        int.parse(full.group(4)!),
        int.parse(full.group(5)!),
        int.tryParse(full.group(6) ?? '0') ?? 0,
      );
    }

    final monthDayTime = RegExp(
      r'(\d{1,2})[\-\/.月](\d{1,2})(?:日)?\s*(\d{1,2})[:：](\d{1,2})(?:[:：](\d{1,2}))?',
    ).firstMatch(text);
    if (monthDayTime != null) {
      final ref = fallbackDate ?? DateTime.now();
      return DateTime(
        ref.year,
        int.parse(monthDayTime.group(1)!),
        int.parse(monthDayTime.group(2)!),
        int.parse(monthDayTime.group(3)!),
        int.parse(monthDayTime.group(4)!),
        int.tryParse(monthDayTime.group(5) ?? '0') ?? 0,
      );
    }

    final timeOnly = RegExp(
      r'(\d{1,2})[:：](\d{1,2})(?:[:：](\d{1,2}))?',
    ).firstMatch(text);
    if (timeOnly != null) {
      final ref = fallbackDate ?? DateTime.now();
      return DateTime(
        ref.year,
        ref.month,
        ref.day,
        int.parse(timeOnly.group(1)!),
        int.parse(timeOnly.group(2)!),
        int.tryParse(timeOnly.group(3) ?? '0') ?? 0,
      );
    }

    return null;
  }

  DateTime? _parseDateOnly(String input) {
    final text = input.trim();
    final full = RegExp(
      r'^(\d{4})[\-\/.年](\d{1,2})[\-\/.月](\d{1,2})(?:日)?$',
    ).firstMatch(text);
    if (full != null) {
      return DateTime(
        int.parse(full.group(1)!),
        int.parse(full.group(2)!),
        int.parse(full.group(3)!),
      );
    }

    final monthDay = RegExp(
      r'^(\d{1,2})[\-\/.月](\d{1,2})(?:日)?$',
    ).firstMatch(text);
    if (monthDay != null) {
      final now = DateTime.now();
      return DateTime(
        now.year,
        int.parse(monthDay.group(1)!),
        int.parse(monthDay.group(2)!),
      );
    }

    return null;
  }

  bool _looksLikeKnownSource(String input) {
    final lower = input.toLowerCase();
    return lower.contains('wechat') ||
        lower.contains('alipay') ||
        lower.contains('unionpay') ||
        input.contains('微信') ||
        input.contains('支付宝') ||
        input.contains('云闪付');
  }

  bool _isSuspiciousAmount(double amount) {
    return amount >= 50000;
  }

  bool _isSuspiciousTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.isAfter(now.add(const Duration(days: 1)))) return true;
    if (timestamp.year < 2000) return true;
    return false;
  }

  double _estimateConfidence({
    required bool valid,
    required List<String> warnings,
  }) {
    if (!valid) return 0;
    final value = 1 - (warnings.length * 0.18);
    if (value < 0.2) return 0.2;
    if (value > 1) return 1;
    return value;
  }

  String _sourceFromText(String input, {required String defaultValue}) {
    final lower = input.toLowerCase();
    if (lower.contains('wechat') || input.contains('微信')) return 'WeChat';
    if (lower.contains('alipay') || input.contains('支付宝')) return 'Alipay';
    if (input.contains('云闪付') || lower.contains('unionpay')) return 'UnionPay';
    return defaultValue;
  }

  String _defaultSource(ImportSourceType sourceType) {
    switch (sourceType) {
      case ImportSourceType.wechat:
        return 'WeChat';
      case ImportSourceType.alipay:
        return 'Alipay';
      case ImportSourceType.ocr:
        return 'OCR';
      case ImportSourceType.csv:
      case ImportSourceType.auto:
        return 'Import';
    }
  }

  String? _normalizeType(String? raw) {
    if (raw == null) return null;
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return null;
    if (lower == 'expense' || lower == 'income' || lower == 'transfer') {
      return lower;
    }
    if (raw.contains('收入') || raw.contains('收款') || raw.contains('到账')) {
      return 'income';
    }
    if (raw.contains('转账') || raw.contains('转入') || raw.contains('转出')) {
      return 'transfer';
    }
    if (raw.contains('支出') || raw.contains('支付') || raw.contains('付款')) {
      return 'expense';
    }
    return null;
  }

  String? _inferTypeFromText(String text, ImportSourceType sourceType) {
    final normalized = _normalizeType(text);
    if (normalized != null) return normalized;

    if (sourceType == ImportSourceType.wechat ||
        sourceType == ImportSourceType.alipay) {
      return 'expense';
    }

    return null;
  }

  String _sourceTypeName(ImportSourceType sourceType) {
    return sourceType.name;
  }

  ImportSourceType _sourceTypeFromString(String value) {
    for (final sourceType in ImportSourceType.values) {
      if (sourceType.name == value) return sourceType;
    }
    return ImportSourceType.auto;
  }

  String _entryTypeName(ImportEntryType entryType) {
    return entryType.name;
  }

  ImportEntryType _entryTypeFromString(String value) {
    for (final entryType in ImportEntryType.values) {
      if (entryType.name == value) return entryType;
    }
    return ImportEntryType.text;
  }

  String _jobStatusName(ImportJobStatus status) {
    return status.name;
  }

  String _duplicatePolicyName(ImportDuplicatePolicy policy) {
    switch (policy) {
      case ImportDuplicatePolicy.keepLatest:
        return 'keep_latest';
      case ImportDuplicatePolicy.keepAll:
        return 'keep_all';
      case ImportDuplicatePolicy.skipAll:
        return 'skip_all';
    }
  }

  ImportDuplicatePolicy _duplicatePolicyFromName(String value) {
    switch (value) {
      case 'keep_all':
        return ImportDuplicatePolicy.keepAll;
      case 'skip_all':
        return ImportDuplicatePolicy.skipAll;
      case 'keep_latest':
      default:
        return ImportDuplicatePolicy.keepLatest;
    }
  }
}

class _CategoryPathNames {
  const _CategoryPathNames({this.parentName, this.childName});

  final String? parentName;
  final String? childName;
}
