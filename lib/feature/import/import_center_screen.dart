import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/import_job_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/import_service.dart';
import '../auto/auto_drafts_screen.dart';
import 'import_failure_report_exporter.dart';
import 'import_history_analytics.dart';
import 'import_job_detail_screen.dart';

class ImportCenterScreen extends StatefulWidget {
  final List<JiveImportJob>? debugJobs;
  final ImportCenterDebugPreviewData? debugPreviewData;
  final ImportFailureReportExporter? failureReportExporter;
  final ImportReviewChecklistExporter? reviewChecklistExporter;

  const ImportCenterScreen({
    super.key,
    this.debugJobs,
    this.debugPreviewData,
    this.failureReportExporter,
    this.reviewChecklistExporter,
  });

  @override
  State<ImportCenterScreen> createState() => _ImportCenterScreenState();
}

class ImportCenterDebugPreviewData {
  final List<ImportParsedRecord> records;
  final List<bool>? selected;
  final String payloadText;
  final ImportSourceType sourceType;
  final ImportEntryType entryType;
  final String? filePath;
  final String? fileName;
  final ImportDuplicateEstimate duplicateEstimate;
  final ImportDuplicateReview duplicateReview;

  const ImportCenterDebugPreviewData({
    required this.records,
    this.selected,
    this.payloadText = '',
    this.sourceType = ImportSourceType.csv,
    this.entryType = ImportEntryType.text,
    this.filePath,
    this.fileName,
    this.duplicateEstimate = const ImportDuplicateEstimate.empty(),
    this.duplicateReview = const ImportDuplicateReview.empty(),
  });
}

class _PreparedImport {
  final List<ImportParsedRecord> records;
  final String payloadText;
  final ImportSourceType sourceType;
  final ImportEntryType entryType;
  final String? filePath;
  final String? fileName;
  final ImportDuplicateEstimate duplicateEstimate;
  final ImportDuplicateReview duplicateReview;

  const _PreparedImport({
    required this.records,
    required this.payloadText,
    required this.sourceType,
    required this.entryType,
    required this.filePath,
    required this.fileName,
    this.duplicateEstimate = const ImportDuplicateEstimate.empty(),
    this.duplicateReview = const ImportDuplicateReview.empty(),
  });

  int get validCount => records.where((record) => record.isValid).length;
  int get warningCount => records.where((record) => record.hasWarnings).length;
  int get lowConfidenceCount =>
      records.where((record) => record.confidence < 0.6).length;

  _PreparedImport copyWith({
    List<ImportParsedRecord>? records,
    String? payloadText,
    ImportSourceType? sourceType,
    ImportEntryType? entryType,
    String? filePath,
    String? fileName,
    ImportDuplicateEstimate? duplicateEstimate,
    ImportDuplicateReview? duplicateReview,
  }) {
    return _PreparedImport(
      records: records ?? this.records,
      payloadText: payloadText ?? this.payloadText,
      sourceType: sourceType ?? this.sourceType,
      entryType: entryType ?? this.entryType,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      duplicateEstimate: duplicateEstimate ?? this.duplicateEstimate,
      duplicateReview: duplicateReview ?? this.duplicateReview,
    );
  }
}

enum _PreviewFilter { all, selected, warning, lowConfidence, invalid }

enum _JobQuickFilter { all, failed, highRisk, skipped }

enum _FailureWindow { d7, d30, all }

enum _WorkdayAdjustMode { none, next, previous }

class _TimeShiftConfig {
  final Duration offset;
  final _WorkdayAdjustMode workdayMode;

  const _TimeShiftConfig({required this.offset, required this.workdayMode});
}

class _FailureScopePrefs {
  final _FailureWindow window;
  final ImportSourceType? sourceType;

  const _FailureScopePrefs({required this.window, required this.sourceType});
}

class _ResolvedRetryCandidate {
  final JiveImportJob job;
  final ImportRetryability retryability;

  const _ResolvedRetryCandidate({
    required this.job,
    required this.retryability,
  });
}

class _FailureRetryabilitySnapshot {
  final int retryableCount;
  final int blockedCount;

  const _FailureRetryabilitySnapshot({
    required this.retryableCount,
    required this.blockedCount,
  });

  int get total => retryableCount + blockedCount;
}

class _ImportRuleTemplate {
  final String source;
  final String? type;
  final int offsetMinutes;
  final _WorkdayAdjustMode workdayMode;
  final bool sourceOnlyWhenGeneric;

  const _ImportRuleTemplate({
    required this.source,
    required this.type,
    required this.offsetMinutes,
    required this.workdayMode,
    required this.sourceOnlyWhenGeneric,
  });

  const _ImportRuleTemplate.empty()
    : source = '',
      type = null,
      offsetMinutes = 0,
      workdayMode = _WorkdayAdjustMode.none,
      sourceOnlyWhenGeneric = true;

  bool get isActive =>
      source.trim().isNotEmpty ||
      type != null ||
      offsetMinutes != 0 ||
      workdayMode != _WorkdayAdjustMode.none;

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'type': type,
      'offsetMinutes': offsetMinutes,
      'workdayMode': workdayMode.name,
      'sourceOnlyWhenGeneric': sourceOnlyWhenGeneric,
    };
  }

  static _ImportRuleTemplate fromJson(Map<String, dynamic> json) {
    final modeRaw = '${json['workdayMode'] ?? ''}'.trim();
    var mode = _WorkdayAdjustMode.none;
    for (final value in _WorkdayAdjustMode.values) {
      if (value.name == modeRaw) {
        mode = value;
        break;
      }
    }
    final typeRaw = '${json['type'] ?? ''}'.trim();
    return _ImportRuleTemplate(
      source: '${json['source'] ?? ''}',
      type: typeRaw.isEmpty ? null : typeRaw,
      offsetMinutes: (json['offsetMinutes'] is num)
          ? (json['offsetMinutes'] as num).toInt()
          : int.tryParse('${json['offsetMinutes'] ?? '0'}') ?? 0,
      workdayMode: mode,
      sourceOnlyWhenGeneric: json['sourceOnlyWhenGeneric'] is bool
          ? json['sourceOnlyWhenGeneric'] as bool
          : true,
    );
  }

  _ImportRuleTemplate copyWith({
    String? source,
    String? type,
    bool clearType = false,
    int? offsetMinutes,
    _WorkdayAdjustMode? workdayMode,
    bool? sourceOnlyWhenGeneric,
  }) {
    return _ImportRuleTemplate(
      source: source ?? this.source,
      type: clearType ? null : (type ?? this.type),
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      workdayMode: workdayMode ?? this.workdayMode,
      sourceOnlyWhenGeneric:
          sourceOnlyWhenGeneric ?? this.sourceOnlyWhenGeneric,
    );
  }
}

class _ImportCenterScreenState extends State<ImportCenterScreen> {
  static const String _ruleTemplateKeyPrefix = 'import_rule_template_';
  static const String _failureWindowPrefKey = 'import_failure_window';
  static const String _failureSourcePrefKey = 'import_failure_source_type';

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _jobSearchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late final ImportFailureReportExporter _failureReportExporter;
  late final ImportReviewChecklistExporter _reviewChecklistExporter;

  ImportService? _importService;

  bool _isLoading = true;
  bool _isImporting = false;
  bool _isParsing = false;
  bool _isFailureReportExporting = false;
  bool _isReviewChecklistExporting = false;
  bool _hasChanges = false;

  ImportSourceType _sourceType = ImportSourceType.auto;
  ImportDuplicatePolicy _duplicatePolicy = ImportDuplicatePolicy.keepLatest;
  ImportIngestResult? _lastResult;
  _PreparedImport? _prepared;
  List<bool> _selected = const [];
  _PreviewFilter _previewFilter = _PreviewFilter.all;
  _JobQuickFilter _jobQuickFilter = _JobQuickFilter.all;
  _FailureWindow _failureWindow = _FailureWindow.d30;
  ImportSourceType? _failureSourceTypeFilter;
  String _jobSearchQuery = '';
  List<JiveImportJob> _jobs = const [];
  final Map<ImportSourceType, _ImportRuleTemplate> _ruleTemplates = {};

  bool get _isBusy => _isImporting || _isParsing;
  bool get _isExporting =>
      _isFailureReportExporting || _isReviewChecklistExporting;

  @override
  void initState() {
    super.initState();
    _failureReportExporter =
        widget.failureReportExporter ?? ImportFailureReportExporter();
    _reviewChecklistExporter =
        widget.reviewChecklistExporter ?? ImportReviewChecklistExporter();
    _init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _jobSearchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final templates = await _loadRuleTemplates();
    final failureScopePrefs = await _loadFailureScopePrefs();
    if (widget.debugJobs != null) {
      final debugPreview = widget.debugPreviewData;
      final prepared = debugPreview == null
          ? null
          : _PreparedImport(
              records: List<ImportParsedRecord>.from(debugPreview.records),
              payloadText: debugPreview.payloadText,
              sourceType: debugPreview.sourceType,
              entryType: debugPreview.entryType,
              filePath: debugPreview.filePath,
              fileName: debugPreview.fileName,
              duplicateEstimate: debugPreview.duplicateEstimate,
              duplicateReview: debugPreview.duplicateReview,
            );
      if (!mounted) return;
      setState(() {
        _ruleTemplates.clear();
        _ruleTemplates.addAll(templates);
        _failureWindow = failureScopePrefs.window;
        _failureSourceTypeFilter = failureScopePrefs.sourceType;
        _jobs = List<JiveImportJob>.from(widget.debugJobs!);
        _prepared = prepared;
        _selected = _normalizeDebugSelection(
          debugPreview?.selected,
          debugPreview?.records.length ?? 0,
        );
        if (debugPreview != null) {
          _sourceType = debugPreview.sourceType;
        }
        _isLoading = false;
      });
      return;
    }
    final isar = await DatabaseService.getInstance();
    final service = ImportService(isar);
    final jobs = await service.listRecentJobs();
    if (!mounted) return;
    setState(() {
      _importService = service;
      _ruleTemplates.clear();
      _ruleTemplates.addAll(templates);
      _failureWindow = failureScopePrefs.window;
      _failureSourceTypeFilter = failureScopePrefs.sourceType;
      _jobs = jobs;
      _isLoading = false;
    });
  }

  List<bool> _normalizeDebugSelection(List<bool>? selected, int length) {
    if (length <= 0) return const [];
    if (selected == null || selected.length != length) {
      return List<bool>.filled(length, false);
    }
    return List<bool>.from(selected);
  }

  Future<void> _refreshJobs() async {
    final service = _importService;
    if (service == null) return;
    final jobs = await service.listRecentJobs();
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
    });
  }

  Future<void> _prepareFromFile() async {
    final service = _importService;
    if (service == null) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'tsv', 'txt'],
    );
    if (picked == null || picked.files.single.path == null) return;

    final file = File(picked.files.single.path!);
    await _runPrepare(() async {
      final text = await service.readTextFromFile(file);
      final records = service.parseText(text, sourceType: _sourceType);
      return _PreparedImport(
        records: records,
        payloadText: text,
        sourceType: _sourceType,
        entryType: ImportEntryType.file,
        filePath: file.path,
        fileName: _basename(file.path),
      );
    });
  }

  Future<void> _prepareFromText() async {
    final service = _importService;
    if (service == null) return;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showMessage('请先粘贴导入文本');
      return;
    }

    await _runPrepare(() async {
      final records = service.parseText(text, sourceType: _sourceType);
      return _PreparedImport(
        records: records,
        payloadText: text,
        sourceType: _sourceType,
        entryType: ImportEntryType.text,
        filePath: null,
        fileName: null,
      );
    });
  }

  Future<void> _prepareFromImage() async {
    final service = _importService;
    if (service == null) return;

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    await _runPrepare(() async {
      final text = await service.recognizeTextFromImage(image);
      final records = service.parseText(text, sourceType: _sourceType);
      return _PreparedImport(
        records: records,
        payloadText: text,
        sourceType: _sourceType,
        entryType: ImportEntryType.image,
        filePath: image.path,
        fileName: _basename(image.path),
      );
    });
  }

  Future<void> _retryJob(JiveImportJob job) async {
    final service = _importService;
    if (service == null) return;
    await _runImport(() => service.retryJob(job.id));
  }

  Future<void> _runPrepare(Future<_PreparedImport> Function() action) async {
    setState(() {
      _isParsing = true;
      _lastResult = null;
    });

    try {
      final preparedRaw = await action();
      final template =
          _ruleTemplates[preparedRaw.sourceType] ??
          const _ImportRuleTemplate.empty();
      final templatedRecords = _applyRuleTemplate(
        preparedRaw.records,
        template,
      );
      final preparedWithTemplate = preparedRaw.copyWith(
        records: templatedRecords,
      );
      ImportDuplicateEstimate estimate = const ImportDuplicateEstimate.empty();
      ImportDuplicateReview review = const ImportDuplicateReview.empty();
      final service = _importService;
      if (service != null) {
        estimate = await service.estimateDuplicateRisk(
          preparedWithTemplate.records,
        );
        review = await service.analyzeDuplicateRisk(
          preparedWithTemplate.records,
        );
      }
      final prepared = preparedWithTemplate.copyWith(
        duplicateEstimate: estimate,
        duplicateReview: review,
      );
      if (!mounted) return;
      final selected = prepared.records
          .map((record) => record.isValid)
          .toList(growable: false);
      setState(() {
        _prepared = prepared;
        _selected = selected;
        _previewFilter = _PreviewFilter.all;
      });
      _showMessage(
        '解析完成：共 ${prepared.records.length} 条，可导入 ${prepared.validCount} 条',
      );
    } catch (e) {
      _showMessage('解析失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  Future<void> _confirmImportPrepared() async {
    final service = _importService;
    final prepared = _prepared;
    if (service == null || prepared == null) return;

    final selectedRecords = <ImportParsedRecord>[];
    for (var i = 0; i < prepared.records.length; i++) {
      if (i >= _selected.length || !_selected[i]) continue;
      selectedRecords.add(prepared.records[i]);
    }

    if (selectedRecords.isEmpty) {
      _showMessage('请至少选择 1 条有效记录');
      return;
    }

    await _runImport(
      () => service.importPreparedRecords(
        records: selectedRecords,
        payloadText: prepared.payloadText,
        sourceType: prepared.sourceType,
        entryType: prepared.entryType,
        filePath: prepared.filePath,
        fileName: prepared.fileName,
        duplicatePolicy: _duplicatePolicy,
      ),
    );
  }

  Future<void> _runImport(Future<ImportIngestResult> Function() action) async {
    setState(() {
      _isImporting = true;
      _lastResult = null;
    });

    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _hasChanges = _hasChanges || result.hasChanges;
        if (!result.hasError) {
          _prepared = null;
          _selected = const [];
          _previewFilter = _PreviewFilter.all;
        }
      });
      if (result.hasError) {
        _showMessage('导入失败: ${result.errorMessage}');
      } else {
        _showMessage(
          '导入完成：新增 ${result.insertedCount}，重复 ${result.duplicateCount}，无效 ${result.invalidCount}，策略跳过 ${result.skippedByDuplicateDecisionCount}',
        );
      }
      await _refreshJobs();
    } catch (e) {
      _showMessage('导入失败: $e');
      await _refreshJobs();
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _openDrafts() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AutoDraftsScreen()),
    );
    if (changed == true && mounted) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _openJobDetail(JiveImportJob job) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImportJobDetailScreen(jobId: job.id)),
    );
    await _refreshJobs();
  }

  void _selectAllValid(bool selected) {
    final prepared = _prepared;
    if (prepared == null) return;
    setState(() {
      _selected = prepared.records
          .map((record) => selected ? record.isValid : false)
          .toList(growable: false);
    });
  }

  void _toggleRecord(int index, bool selected) {
    if (index < 0 || index >= _selected.length) return;
    final prepared = _prepared;
    if (prepared == null || !prepared.records[index].isValid) return;
    setState(() {
      _selected[index] = selected;
    });
  }

  void _setPreviewFilter(_PreviewFilter filter) {
    setState(() {
      _previewFilter = filter;
    });
  }

  List<int> _visibleRecordIndices(_PreparedImport prepared) {
    final visible = <int>[];
    for (var i = 0; i < prepared.records.length; i++) {
      if (_matchesFilter(i, prepared.records[i], _previewFilter)) {
        visible.add(i);
      }
    }
    return visible;
  }

  bool _matchesFilter(
    int index,
    ImportParsedRecord record,
    _PreviewFilter filter,
  ) {
    switch (filter) {
      case _PreviewFilter.all:
        return true;
      case _PreviewFilter.selected:
        return index < _selected.length && _selected[index];
      case _PreviewFilter.warning:
        return record.hasWarnings;
      case _PreviewFilter.lowConfidence:
        return record.confidence < 0.6;
      case _PreviewFilter.invalid:
        return !record.isValid;
    }
  }

  Future<void> _batchEditType() async {
    if (_selectedCount() <= 0) {
      _showMessage('请先勾选记录');
      return;
    }

    var typeValue = 'expense';
    final confirmed = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('批量修改类型'),
              content: DropdownButtonFormField<String>(
                initialValue: typeValue,
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('支出')),
                  DropdownMenuItem(value: 'income', child: Text('收入')),
                  DropdownMenuItem(value: 'transfer', child: Text('转账')),
                  DropdownMenuItem(value: 'unknown', child: Text('未知')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    typeValue = value;
                  });
                },
                decoration: const InputDecoration(labelText: '新类型'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, typeValue),
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == null) return;
    await _applyBatchToSelected((record) {
      return record.copyWith(type: confirmed == 'unknown' ? null : confirmed);
    });
    _showMessage('已批量更新类型');
  }

  Future<void> _batchEditSource() async {
    if (_selectedCount() <= 0) {
      _showMessage('请先勾选记录');
      return;
    }

    final controller = TextEditingController();
    String? errorText;
    final confirmed = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('批量修改来源'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '来源（如 WeChat / Alipay / Bank）',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setDialogState(() {
                        errorText = '来源不能为空';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == null) return;
    await _applyBatchToSelected((record) => record.copyWith(source: confirmed));
    _showMessage('已批量更新来源');
  }

  Future<void> _batchShiftTime() async {
    if (_selectedCount() <= 0) {
      _showMessage('请先勾选记录');
      return;
    }

    final offsetController = TextEditingController(text: '10');
    var unit = 'minute';
    var workdayMode = _WorkdayAdjustMode.none;
    String? errorText;
    final config = await showDialog<_TimeShiftConfig>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('批量偏移时间'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: offsetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '偏移值（可为负数）',
                      hintText: '例如 10 或 -30',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    items: const [
                      DropdownMenuItem(value: 'minute', child: Text('分钟')),
                      DropdownMenuItem(value: 'hour', child: Text('小时')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        unit = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: '单位'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<_WorkdayAdjustMode>(
                    initialValue: workdayMode,
                    items: const [
                      DropdownMenuItem(
                        value: _WorkdayAdjustMode.none,
                        child: Text('不做工作日校正'),
                      ),
                      DropdownMenuItem(
                        value: _WorkdayAdjustMode.next,
                        child: Text('遇周末顺延到下个工作日'),
                      ),
                      DropdownMenuItem(
                        value: _WorkdayAdjustMode.previous,
                        child: Text('遇周末前移到上个工作日'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        workdayMode = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: '工作日规则'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw = offsetController.text.trim();
                    final value = int.tryParse(raw);
                    if (value == null) {
                      setDialogState(() {
                        errorText = '偏移值格式无效';
                      });
                      return;
                    }
                    final delta = unit == 'hour'
                        ? Duration(hours: value)
                        : Duration(minutes: value);
                    Navigator.pop(
                      dialogContext,
                      _TimeShiftConfig(offset: delta, workdayMode: workdayMode),
                    );
                  },
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );

    if (config == null) return;
    await _applyBatchToSelected(
      (record) => record.copyWith(
        timestamp: _adjustToWorkday(
          record.timestamp.add(config.offset),
          config.workdayMode,
        ),
      ),
    );
    final unitLabel = config.offset.inMinutes.abs() % 60 == 0
        ? '${config.offset.inHours} 小时'
        : '${config.offset.inMinutes} 分钟';
    _showMessage(
      '已批量偏移时间：$unitLabel（${_workdayModeLabel(config.workdayMode)}）',
    );
  }

  Future<void> _exportReviewChecklist() async {
    final prepared = _prepared;
    if (prepared == null) return;
    final visibleIndices = _visibleRecordIndices(prepared);
    if (visibleIndices.isEmpty) {
      _showMessage('当前筛选条件下没有可导出记录');
      return;
    }
    if (_isExporting) return;

    setState(() {
      _isReviewChecklistExporting = true;
    });

    try {
      final csv = _buildReviewChecklistCsv(
        prepared: prepared,
        visibleIndices: visibleIndices,
      );
      final result = await _reviewChecklistExporter.export(
        ImportReviewChecklistExportRequest(
          csv: csv,
          previewFilterName: _previewFilter.name,
          previewFilterLabel: _previewFilterLabel(_previewFilter),
          visibleCount: visibleIndices.length,
        ),
      );
      _showMessage('已导出复核清单：${result.fileName}');
    } catch (e) {
      _showMessage('导出复核清单失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isReviewChecklistExporting = false;
        });
      }
    }
  }

  Future<void> _applyBatchToSelected(
    ImportParsedRecord Function(ImportParsedRecord) mapper,
  ) async {
    final prepared = _prepared;
    if (prepared == null) return;

    final nextRecords = List<ImportParsedRecord>.from(prepared.records);
    final nextSelected = List<bool>.from(_selected);
    for (var i = 0; i < nextRecords.length; i++) {
      if (i >= nextSelected.length || !nextSelected[i]) continue;
      final updated = _recomputeRecordQuality(mapper(nextRecords[i]));
      nextRecords[i] = updated;
      if (!updated.isValid) {
        nextSelected[i] = false;
      }
    }

    setState(() {
      _prepared = prepared.copyWith(records: nextRecords);
      _selected = nextSelected;
    });

    await _refreshDuplicateInsights();
  }

  Future<void> _editRecord(int index) async {
    final prepared = _prepared;
    if (prepared == null) return;
    if (index < 0 || index >= prepared.records.length) return;

    final record = prepared.records[index];
    final amountController = TextEditingController(
      text: record.amount.toStringAsFixed(2),
    );
    final timeController = TextEditingController(
      text: _formatDateTime(record.timestamp),
    );
    final sourceController = TextEditingController(text: record.source);
    final rawTextController = TextEditingController(text: record.rawText ?? '');
    var typeValue = record.type ?? 'unknown';
    String? errorText;

    final edited = await showDialog<ImportParsedRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('编辑第 ${record.lineNumber} 行'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: '金额'),
                    ),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: '时间',
                        hintText: 'yyyy-MM-dd HH:mm',
                      ),
                    ),
                    TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(labelText: '来源'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: typeValue,
                      items: const [
                        DropdownMenuItem(value: 'unknown', child: Text('未知')),
                        DropdownMenuItem(value: 'expense', child: Text('支出')),
                        DropdownMenuItem(value: 'income', child: Text('收入')),
                        DropdownMenuItem(value: 'transfer', child: Text('转账')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          typeValue = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: '类型'),
                    ),
                    TextField(
                      controller: rawTextController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '原文'),
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', ''),
                    );
                    if (amount == null) {
                      setDialogState(() {
                        errorText = '金额格式无效';
                      });
                      return;
                    }

                    final parsedDate = _parseEditorDateTime(
                      timeController.text.trim(),
                    );
                    if (parsedDate == null) {
                      setDialogState(() {
                        errorText = '时间格式无效，示例：2026-02-15 12:30';
                      });
                      return;
                    }

                    final source = sourceController.text.trim();
                    final rawText = rawTextController.text.trim();
                    final updated = _recomputeRecordQuality(
                      record.copyWith(
                        amount: amount.abs(),
                        timestamp: parsedDate,
                        source: source.isEmpty ? 'Import' : source,
                        type: typeValue == 'unknown' ? null : typeValue,
                        rawText: rawText.isEmpty ? null : rawText,
                      ),
                    );
                    Navigator.pop(dialogContext, updated);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (edited == null || !mounted) return;
    await _replaceRecord(index, edited);
  }

  Future<void> _replaceRecord(int index, ImportParsedRecord updated) async {
    final prepared = _prepared;
    if (prepared == null) return;
    if (index < 0 || index >= prepared.records.length) return;

    final nextRecords = List<ImportParsedRecord>.from(prepared.records);
    nextRecords[index] = updated;

    final nextSelected = List<bool>.from(_selected);
    if (nextSelected.length < nextRecords.length) {
      nextSelected.addAll(
        List<bool>.filled(nextRecords.length - nextSelected.length, false),
      );
    }
    if (!updated.isValid) {
      nextSelected[index] = false;
    }

    setState(() {
      _prepared = prepared.copyWith(records: nextRecords);
      _selected = nextSelected;
    });

    await _refreshDuplicateInsights();
  }

  ImportParsedRecord _recomputeRecordQuality(ImportParsedRecord record) {
    final warnings = <String>[];
    if (record.amount <= 0) {
      warnings.add('无法识别金额');
    } else if (record.amount >= 50000) {
      warnings.add('金额较大，请确认');
    }
    final now = DateTime.now();
    if (record.timestamp.year < 2000 ||
        record.timestamp.isAfter(now.add(const Duration(days: 1)))) {
      warnings.add('时间异常，请确认');
    }
    final lowerSource = record.source.toLowerCase();
    if (lowerSource == 'import' || lowerSource == 'ocr') {
      warnings.add('来源未识别，使用默认来源');
    }
    if (record.type == null) {
      warnings.add('交易类型未知');
    }
    final confidence = record.amount <= 0
        ? 0.0
        : (1 - (warnings.length * 0.18)).clamp(0.2, 1.0).toDouble();
    return record.copyWith(confidence: confidence, warnings: warnings);
  }

  DateTime? _parseEditorDateTime(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final normalized = text.replaceAll('/', '-');
    final direct = DateTime.tryParse(normalized);
    if (direct != null) return direct;
    final withT = DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
    if (withT != null) return withT;
    final match = RegExp(
      r'^(\\d{4})-(\\d{1,2})-(\\d{1,2})\\s+(\\d{1,2}):(\\d{1,2})$',
    ).firstMatch(normalized);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }

  DateTime _adjustToWorkday(DateTime value, _WorkdayAdjustMode mode) {
    if (mode == _WorkdayAdjustMode.none) return value;
    var cursor = value;
    while (_isWeekend(cursor)) {
      cursor = mode == _WorkdayAdjustMode.next
          ? cursor.add(const Duration(days: 1))
          : cursor.subtract(const Duration(days: 1));
    }
    return cursor;
  }

  bool _isWeekend(DateTime value) {
    return value.weekday == DateTime.saturday ||
        value.weekday == DateTime.sunday;
  }

  String _workdayModeLabel(_WorkdayAdjustMode mode) {
    switch (mode) {
      case _WorkdayAdjustMode.none:
        return '不校正';
      case _WorkdayAdjustMode.next:
        return '周末顺延';
      case _WorkdayAdjustMode.previous:
        return '周末前移';
    }
  }

  Future<Map<ImportSourceType, _ImportRuleTemplate>>
  _loadRuleTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <ImportSourceType, _ImportRuleTemplate>{};
    for (final source in ImportSourceType.values) {
      final raw = prefs.getString('$_ruleTemplateKeyPrefix${source.name}');
      if (raw == null || raw.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          map[source] = _ImportRuleTemplate.fromJson(decoded);
        } else if (decoded is Map) {
          map[source] = _ImportRuleTemplate.fromJson(
            decoded.map((key, value) => MapEntry('$key', value)),
          );
        }
      } catch (_) {
        // Ignore invalid template payload and continue loading others.
      }
    }
    return map;
  }

  Future<void> _saveRuleTemplate(
    ImportSourceType sourceType,
    _ImportRuleTemplate template,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!template.isActive) {
      await prefs.remove('$_ruleTemplateKeyPrefix${sourceType.name}');
      return;
    }
    await prefs.setString(
      '$_ruleTemplateKeyPrefix${sourceType.name}',
      jsonEncode(template.toJson()),
    );
  }

  Future<_FailureScopePrefs> _loadFailureScopePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final windowRaw = (prefs.getString(_failureWindowPrefKey) ?? '').trim();
    final sourceRaw = (prefs.getString(_failureSourcePrefKey) ?? '').trim();
    var window = _FailureWindow.d30;
    for (final value in _FailureWindow.values) {
      if (value.name == windowRaw) {
        window = value;
        break;
      }
    }
    return _FailureScopePrefs(
      window: window,
      sourceType: _parseImportSourceType(sourceRaw),
    );
  }

  Future<void> _saveFailureScopePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_failureWindowPrefKey, _failureWindow.name);
    final sourceType = _failureSourceTypeFilter;
    if (sourceType == null) {
      await prefs.remove(_failureSourcePrefKey);
    } else {
      await prefs.setString(_failureSourcePrefKey, sourceType.name);
    }
  }

  void _persistFailureScopePrefs() {
    _saveFailureScopePrefs();
  }

  Future<void> _refreshDuplicateInsights() async {
    final service = _importService;
    final prepared = _prepared;
    if (service == null || prepared == null) return;
    final estimate = await service.estimateDuplicateRisk(prepared.records);
    final review = await service.analyzeDuplicateRisk(prepared.records);
    if (!mounted) return;
    if (!identical(_prepared, prepared)) return;
    setState(() {
      _prepared = prepared.copyWith(
        duplicateEstimate: estimate,
        duplicateReview: review,
      );
    });
  }

  List<ImportParsedRecord> _applyRuleTemplate(
    List<ImportParsedRecord> records,
    _ImportRuleTemplate template,
  ) {
    if (!template.isActive) return records;
    final delta = Duration(minutes: template.offsetMinutes);
    final output = <ImportParsedRecord>[];
    for (final record in records) {
      final source = template.source.trim().isEmpty
          ? record.source
          : (template.sourceOnlyWhenGeneric
                ? (_isGenericSource(record.source)
                      ? template.source.trim()
                      : record.source)
                : template.source.trim());
      final shifted = template.offsetMinutes == 0
          ? record.timestamp
          : record.timestamp.add(delta);
      final timestamp = _adjustToWorkday(shifted, template.workdayMode);
      final type = record.type ?? template.type;
      output.add(
        _recomputeRecordQuality(
          record.copyWith(source: source, timestamp: timestamp, type: type),
        ),
      );
    }
    return output;
  }

  bool _isGenericSource(String source) {
    final lower = source.trim().toLowerCase();
    return lower.isEmpty || lower == 'import' || lower == 'ocr';
  }

  String _templateSummary(_ImportRuleTemplate template) {
    if (!template.isActive) return '未配置规则模板';
    final chunks = <String>[];
    if (template.source.trim().isNotEmpty) {
      final applyMode = template.sourceOnlyWhenGeneric ? '仅默认来源' : '全部';
      chunks.add('来源=${template.source.trim()}($applyMode)');
    }
    if (template.type != null) {
      chunks.add('类型默认=${_typeLabel(template.type)}');
    }
    if (template.offsetMinutes != 0) {
      chunks.add('偏移=${template.offsetMinutes} 分钟');
    }
    if (template.workdayMode != _WorkdayAdjustMode.none) {
      chunks.add('工作日=${_workdayModeLabel(template.workdayMode)}');
    }
    return chunks.join(' · ');
  }

  Future<void> _openTemplateEditor() async {
    final current =
        _ruleTemplates[_sourceType] ?? const _ImportRuleTemplate.empty();
    final sourceController = TextEditingController(text: current.source);
    final offsetController = TextEditingController(
      text: '${current.offsetMinutes}',
    );
    var typeValue = current.type ?? 'unknown';
    var mode = current.workdayMode;
    var sourceOnlyWhenGeneric = current.sourceOnlyWhenGeneric;
    String? errorText;

    final result = await showDialog<_ImportRuleTemplate>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('规则模板（${_sourceLabel(_sourceType)}）'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(
                        labelText: '默认来源（可空）',
                        hintText: '如 WeChat / Alipay / Bank',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('来源仅覆盖默认值（Import/OCR）'),
                      value: sourceOnlyWhenGeneric,
                      onChanged: (value) {
                        setDialogState(() {
                          sourceOnlyWhenGeneric = value ?? true;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: typeValue,
                      items: const [
                        DropdownMenuItem(value: 'unknown', child: Text('不设置')),
                        DropdownMenuItem(value: 'expense', child: Text('支出')),
                        DropdownMenuItem(value: 'income', child: Text('收入')),
                        DropdownMenuItem(value: 'transfer', child: Text('转账')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          typeValue = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: '默认类型'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: offsetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '时间偏移（分钟）',
                        hintText: '例如 10 / -30',
                        errorText: errorText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<_WorkdayAdjustMode>(
                      initialValue: mode,
                      items: const [
                        DropdownMenuItem(
                          value: _WorkdayAdjustMode.none,
                          child: Text('不做工作日校正'),
                        ),
                        DropdownMenuItem(
                          value: _WorkdayAdjustMode.next,
                          child: Text('遇周末顺延到下个工作日'),
                        ),
                        DropdownMenuItem(
                          value: _WorkdayAdjustMode.previous,
                          child: Text('遇周末前移到上个工作日'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          mode = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: '工作日规则'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final offsetValue = int.tryParse(
                      offsetController.text.trim(),
                    );
                    if (offsetValue == null) {
                      setDialogState(() {
                        errorText = '时间偏移需为整数（分钟）';
                      });
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      _ImportRuleTemplate(
                        source: sourceController.text.trim(),
                        type: typeValue == 'unknown' ? null : typeValue,
                        offsetMinutes: offsetValue,
                        workdayMode: mode,
                        sourceOnlyWhenGeneric: sourceOnlyWhenGeneric,
                      ),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    await _saveRuleTemplate(_sourceType, result);
    if (!mounted) return;
    setState(() {
      _ruleTemplates[_sourceType] = result;
    });
    _showMessage('规则模板已保存');
  }

  Future<void> _clearTemplateForCurrentSource() async {
    await _saveRuleTemplate(_sourceType, const _ImportRuleTemplate.empty());
    if (!mounted) return;
    setState(() {
      _ruleTemplates.remove(_sourceType);
    });
    _showMessage('已清除当前来源模板');
  }

  Future<void> _applyTemplateToPreparedNow() async {
    final prepared = _prepared;
    if (prepared == null) {
      _showMessage('当前没有可应用的预览数据');
      return;
    }
    final template =
        _ruleTemplates[prepared.sourceType] ??
        const _ImportRuleTemplate.empty();
    if (!template.isActive) {
      _showMessage('当前来源未配置模板');
      return;
    }
    final nextRecords = _applyRuleTemplate(prepared.records, template);
    setState(() {
      _prepared = prepared.copyWith(records: nextRecords);
    });
    await _refreshDuplicateInsights();
    _showMessage('已对当前预览应用规则模板');
  }

  Future<void> _duplicateKeepAll() async {
    final prepared = _prepared;
    if (prepared == null) return;
    final review = prepared.duplicateReview;
    if (review.items.isEmpty) {
      _showMessage('当前无高风险重复记录');
      return;
    }
    final nextSelected = List<bool>.from(_selected);
    if (nextSelected.length < prepared.records.length) {
      nextSelected.addAll(
        List<bool>.filled(prepared.records.length - nextSelected.length, false),
      );
    }
    for (final item in review.items) {
      final index = item.recordIndex;
      if (index < 0 || index >= prepared.records.length) continue;
      if (prepared.records[index].isValid) {
        nextSelected[index] = true;
      }
    }
    setState(() {
      _selected = nextSelected;
    });
    _showMessage('已保留全部高风险重复项');
  }

  Future<void> _duplicateSkipAll() async {
    final prepared = _prepared;
    if (prepared == null) return;
    final review = prepared.duplicateReview;
    if (review.items.isEmpty) {
      _showMessage('当前无高风险重复记录');
      return;
    }
    final nextSelected = List<bool>.from(_selected);
    for (final item in review.items) {
      final index = item.recordIndex;
      if (index >= 0 && index < nextSelected.length) {
        nextSelected[index] = false;
      }
    }
    setState(() {
      _selected = nextSelected;
    });
    _showMessage('已跳过全部高风险重复项');
  }

  Future<void> _duplicateKeepLatest() async {
    final prepared = _prepared;
    if (prepared == null) return;
    final review = prepared.duplicateReview;
    if (review.items.isEmpty) {
      _showMessage('当前无高风险重复记录');
      return;
    }

    final nextSelected = List<bool>.from(_selected);
    if (nextSelected.length < prepared.records.length) {
      nextSelected.addAll(
        List<bool>.filled(prepared.records.length - nextSelected.length, false),
      );
    }

    final grouped = <String, List<ImportDuplicateRiskItem>>{};
    for (final item in review.items) {
      grouped
          .putIfAbsent(item.dedupKey, () => <ImportDuplicateRiskItem>[])
          .add(item);
    }

    var kept = 0;
    for (final entry in grouped.entries) {
      final items = entry.value;
      DateTime? existingLatest;
      ImportDuplicateRiskItem? latestImportItem;
      DateTime? latestImportTime;
      int latestLine = -1;

      for (final item in items) {
        final idx = item.recordIndex;
        if (idx < 0 || idx >= prepared.records.length) continue;
        final record = prepared.records[idx];
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
          latestImportTime = record.timestamp;
          latestImportItem = item;
          latestLine = record.lineNumber;
        }
      }

      for (final item in items) {
        final idx = item.recordIndex;
        if (idx >= 0 && idx < nextSelected.length) {
          nextSelected[idx] = false;
        }
      }

      if (latestImportItem != null) {
        final idx = latestImportItem.recordIndex;
        if (idx >= 0 && idx < prepared.records.length) {
          final latestRecord = prepared.records[idx];
          if (latestRecord.isValid &&
              (existingLatest == null ||
                  latestRecord.timestamp.isAfter(existingLatest))) {
            nextSelected[idx] = true;
            kept += 1;
          }
        }
      }
    }

    setState(() {
      _selected = nextSelected;
    });
    _showMessage('重复决策完成，仅保留最新 $kept 条');
  }

  String _previewFilterLabel(_PreviewFilter filter) {
    switch (filter) {
      case _PreviewFilter.all:
        return '全部';
      case _PreviewFilter.selected:
        return '仅已选';
      case _PreviewFilter.warning:
        return '仅异常';
      case _PreviewFilter.lowConfidence:
        return '低置信度';
      case _PreviewFilter.invalid:
        return '无效';
    }
  }

  String _buildReviewChecklistCsv({
    required _PreparedImport prepared,
    required List<int> visibleIndices,
  }) {
    final riskByIndex = prepared.duplicateReview.byRecordIndex;
    final buffer = StringBuffer();
    buffer.writeln(
      'lineNumber,selected,isValid,amount,timestamp,type,source,confidence,duplicateRisk,warnings,rawText',
    );
    for (final index in visibleIndices) {
      final record = prepared.records[index];
      final selected = index < _selected.length && _selected[index];
      final riskLabel = _duplicateRiskLabel(riskByIndex[index]);
      buffer.writeln(
        [
          record.lineNumber,
          selected ? 'yes' : 'no',
          record.isValid ? 'yes' : 'no',
          record.amount.toStringAsFixed(2),
          _csvSafe(_formatDateTime(record.timestamp)),
          _csvSafe(_typeLabel(record.type)),
          _csvSafe(record.source),
          (record.confidence * 100).toStringAsFixed(1),
          _csvSafe(riskLabel),
          _csvSafe(record.warnings.join(' | ')),
          _csvSafe(record.rawText ?? ''),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  String _duplicateRiskLabel(ImportDuplicateRiskItem? riskItem) {
    if (riskItem == null) return '';
    return '${riskItem.inBatchDuplicate ? 'batch' : ''}${riskItem.inBatchDuplicate && riskItem.existingDuplicate ? '+' : ''}${riskItem.existingDuplicate ? 'existing' : ''}';
  }

  String _csvSafe(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  int _selectedCount() {
    return _selected.where((value) => value).length;
  }

  void _showMessage(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '导入中心',
            style: GoogleFonts.lato(fontWeight: FontWeight.w700),
          ),
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            IconButton(
              onPressed: _isBusy ? null : _refreshJobs,
              icon: const Icon(Icons.refresh),
              tooltip: '刷新任务',
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _isBusy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildSourceCard(),
              const SizedBox(height: 12),
              _buildImportActions(),
              const SizedBox(height: 12),
              _buildTextInput(),
              const SizedBox(height: 12),
              if (_prepared != null) _buildPreparedPreview(),
              if (_prepared != null) const SizedBox(height: 12),
              if (_lastResult != null) _buildResultCard(_lastResult!),
              const SizedBox(height: 12),
              _buildJobHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard() {
    final template =
        _ruleTemplates[_sourceType] ?? const _ImportRuleTemplate.empty();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('数据来源', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ImportSourceType>(
              initialValue: _sourceType,
              items: ImportSourceType.values
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(_sourceLabel(source)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _sourceType = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              '模板：${_templateSummary(template)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: _openTemplateEditor,
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: const Text('规则模板'),
                ),
                OutlinedButton.icon(
                  onPressed: template.isActive
                      ? _clearTemplateForCurrentSource
                      : null,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('清除模板'),
                ),
                OutlinedButton.icon(
                  onPressed: _prepared != null
                      ? _applyTemplateToPreparedNow
                      : null,
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: const Text('应用到预览'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _prepareFromFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('从文件解析预览 (CSV/TSV/TXT)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _prepareFromImage,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('OCR 识别并预览（从截图）'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openDrafts,
              icon: const Icon(Icons.inbox_outlined),
              label: const Text('查看待确认草稿'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '粘贴文本导入',
              style: GoogleFonts.lato(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              minLines: 6,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '粘贴账单文本，支持微信/支付宝/OCR 导出文本',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _prepareFromText,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('解析文本到预览区'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparedPreview() {
    final prepared = _prepared!;
    final validCount = prepared.validCount;
    final invalidCount = prepared.records.length - validCount;
    final warningCount = prepared.warningCount;
    final lowConfidenceCount = prepared.lowConfidenceCount;
    final duplicateEstimate = prepared.duplicateEstimate;
    final duplicateReview = prepared.duplicateReview;
    final duplicateRiskByIndex = duplicateReview.byRecordIndex;
    final selectedCount = _selectedCount();
    final visibleIndices = _visibleRecordIndices(prepared);
    const maxPreviewItems = 30;
    final showCount = visibleIndices.length > maxPreviewItems
        ? maxPreviewItems
        : visibleIndices.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导入预览（先勾选，再导入）',
              style: GoogleFonts.lato(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('总计 ${prepared.records.length}')),
                Chip(label: Text('可导入 $validCount')),
                Chip(label: Text('无效 $invalidCount')),
                Chip(label: Text('已选择 $selectedCount')),
                Chip(label: Text('有警告 $warningCount')),
                Chip(label: Text('低置信度 $lowConfidenceCount')),
                Chip(
                  label: Text('批内重复 ${duplicateEstimate.inBatchDuplicates}'),
                ),
                Chip(
                  label: Text('历史重复 ${duplicateEstimate.existingDuplicates}'),
                ),
                Chip(label: Text('高风险 ${duplicateReview.highRiskCount}')),
              ],
            ),
            if (duplicateEstimate.totalPotentialDuplicates > 0) ...[
              const SizedBox(height: 4),
              Text(
                '预估重复率 ${(duplicateEstimate.duplicateRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
            if (duplicateReview.highRiskCount > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _duplicateKeepAll,
                    icon: const Icon(Icons.select_all_outlined),
                    label: const Text('重复: 全保留'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _duplicateSkipAll,
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('重复: 全跳过'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _duplicateKeepLatest,
                    icon: const Icon(Icons.update_outlined),
                    label: const Text('重复: 仅保留最新'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<ImportDuplicatePolicy>(
              initialValue: _duplicatePolicy,
              items: ImportDuplicatePolicy.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('重复策略：${_duplicatePolicyLabel(value)}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _duplicatePolicy = value;
                });
              },
              decoration: const InputDecoration(
                labelText: '导入重复决策策略',
                helperText: '默认：仅保留最新',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _previewFilter == _PreviewFilter.all,
                  onSelected: (_) => _setPreviewFilter(_PreviewFilter.all),
                ),
                FilterChip(
                  label: const Text('仅已选'),
                  selected: _previewFilter == _PreviewFilter.selected,
                  onSelected: (_) => _setPreviewFilter(_PreviewFilter.selected),
                ),
                FilterChip(
                  label: const Text('仅异常'),
                  selected: _previewFilter == _PreviewFilter.warning,
                  onSelected: (_) => _setPreviewFilter(_PreviewFilter.warning),
                ),
                FilterChip(
                  label: const Text('低置信度'),
                  selected: _previewFilter == _PreviewFilter.lowConfidence,
                  onSelected: (_) =>
                      _setPreviewFilter(_PreviewFilter.lowConfidence),
                ),
                FilterChip(
                  label: const Text('无效'),
                  selected: _previewFilter == _PreviewFilter.invalid,
                  onSelected: (_) => _setPreviewFilter(_PreviewFilter.invalid),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: selectedCount > 0 ? _batchEditType : null,
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('批量改类型'),
                ),
                OutlinedButton.icon(
                  onPressed: selectedCount > 0 ? _batchEditSource : null,
                  icon: const Icon(Icons.source_outlined),
                  label: const Text('批量改来源'),
                ),
                OutlinedButton.icon(
                  onPressed: selectedCount > 0 ? _batchShiftTime : null,
                  icon: const Icon(Icons.schedule_outlined),
                  label: const Text('批量偏移时间'),
                ),
                OutlinedButton.icon(
                  onPressed: visibleIndices.isNotEmpty && !_isExporting
                      ? _exportReviewChecklist
                      : null,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('导出复核清单'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _selectAllValid(true),
                  icon: const Icon(Icons.done_all),
                  label: const Text('全选有效'),
                ),
                TextButton.icon(
                  onPressed: () => _selectAllValid(false),
                  icon: const Icon(Icons.remove_done),
                  label: const Text('清空选择'),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 6),
            if (visibleIndices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('当前筛选条件下暂无记录'),
              ),
            for (var i = 0; i < showCount; i++)
              _buildPreviewRow(
                visibleIndices[i],
                prepared.records[visibleIndices[i]],
                duplicateRiskByIndex[visibleIndices[i]],
              ),
            if (visibleIndices.length > showCount)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '当前筛选命中 ${visibleIndices.length} 条，仅展示前 $showCount 条',
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: selectedCount > 0 ? _confirmImportPrepared : null,
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('确认导入所选记录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(
    int index,
    ImportParsedRecord record,
    ImportDuplicateRiskItem? riskItem,
  ) {
    final checked = index < _selected.length ? _selected[index] : false;
    final confidence = (record.confidence * 100).round();
    final confidenceColor = record.confidence >= 0.8
        ? Colors.green
        : (record.confidence >= 0.6 ? Colors.orange : Colors.redAccent);
    final title =
        '第${record.lineNumber}行  ¥${record.amount.toStringAsFixed(2)}  ${_typeLabel(record.type)}';
    final subtitle =
        '${_formatDateTime(record.timestamp)} · ${record.source}\n${record.rawText ?? ''}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: checked,
            onChanged: record.isValid
                ? (value) => _toggleRecord(index, value ?? false)
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: record.isValid ? null : Colors.orangeAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$confidence%',
                        style: TextStyle(
                          color: confidenceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editRecord(index),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: '编辑金额/时间/类型',
                    ),
                  ],
                ),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (record.warnings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      record.warnings.join(' · '),
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (riskItem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '疑似重复：${riskItem.inBatchDuplicate ? '批内' : ''}${riskItem.inBatchDuplicate && riskItem.existingDuplicate ? ' + ' : ''}${riskItem.existingDuplicate ? '历史' : ''}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ImportIngestResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近一次结果',
              style: GoogleFonts.lato(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('总计 ${result.totalCount}')),
                Chip(label: Text('新增 ${result.insertedCount}')),
                Chip(label: Text('重复 ${result.duplicateCount}')),
                Chip(label: Text('无效 ${result.invalidCount}')),
                Chip(
                  label: Text('策略跳过 ${result.skippedByDuplicateDecisionCount}'),
                ),
                Chip(
                  label: Text(
                    '策略 ${_duplicatePolicyLabelFromRaw(result.duplicatePolicy)}',
                  ),
                ),
                Chip(label: Text('任务 #${result.jobId}')),
              ],
            ),
            if (result.hasError) ...[
              const SizedBox(height: 8),
              Text(
                result.errorMessage ?? '',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ] else ...[
              ..._buildDecisionSummaryInfo(result.decisionSummaryJson),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobHistory() {
    final normalizedQuery = _jobSearchQuery.trim().toLowerCase();
    final failedWindowSince = _failureWindowSince(_failureWindow);
    final failureScopedJobs = _collectFailedJobs(
      since: failedWindowSince,
      sourceType: _failureSourceTypeFilter,
    );
    final filteredJobs = _jobs
        .where(
          (job) =>
              _matchesJobQuickFilter(job) &&
              _matchesJobSearch(job, normalizedQuery),
        )
        .toList();
    final failedCount = _jobs.where((job) => job.status == 'failed').length;
    final highRiskCount = _jobs
        .where((job) => _jobHighRiskCount(job) > 0)
        .length;
    final skippedCount = _jobs
        .where((job) => job.skippedByDuplicateDecisionCount > 0)
        .length;
    final totalFailedCount = _jobs
        .where((job) => job.status == 'failed')
        .length;
    final failureAggregates = aggregateImportFailureReasons(
      failureScopedJobs,
      maxItems: 5,
    );
    final failedCountInWindow = failureScopedJobs.length;
    final failureRetryabilitySnapshot = _buildFailureRetryabilitySnapshot(
      failedWindowSince,
      sourceType: _failureSourceTypeFilter,
    );
    final reasonRetryabilitySnapshots = _buildReasonRetryabilitySnapshots(
      failureAggregates,
      since: failedWindowSince,
      sourceType: _failureSourceTypeFilter,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导入任务历史',
              style: GoogleFonts.lato(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jobSearchController,
              decoration: InputDecoration(
                labelText: '搜索任务（ID/策略/状态/来源/摘要）',
                hintText: '例如 1024 / keep_latest / 失败 / 微信 / 风险',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _jobSearchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _jobSearchController.clear();
                          setState(() {
                            _jobSearchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                        tooltip: '清除搜索',
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _jobSearchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('全部 ${_jobs.length}'),
                  selected: _jobQuickFilter == _JobQuickFilter.all,
                  onSelected: (_) {
                    setState(() {
                      _jobQuickFilter = _JobQuickFilter.all;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text('失败 $failedCount'),
                  selected: _jobQuickFilter == _JobQuickFilter.failed,
                  onSelected: (_) {
                    setState(() {
                      _jobQuickFilter = _JobQuickFilter.failed;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text('高风险 $highRiskCount'),
                  selected: _jobQuickFilter == _JobQuickFilter.highRisk,
                  onSelected: (_) {
                    setState(() {
                      _jobQuickFilter = _JobQuickFilter.highRisk;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text('策略跳过 $skippedCount'),
                  selected: _jobQuickFilter == _JobQuickFilter.skipped,
                  onSelected: (_) {
                    setState(() {
                      _jobQuickFilter = _JobQuickFilter.skipped;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (totalFailedCount > 0) ...[
              _buildFailureAggregateCard(
                aggregates: failureAggregates,
                failedCountInWindow: failedCountInWindow,
                retryabilitySnapshot: failureRetryabilitySnapshot,
                reasonRetryabilitySnapshots: reasonRetryabilitySnapshots,
              ),
              const SizedBox(height: 8),
            ],
            if (filteredJobs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('当前筛选下暂无导入任务'),
              )
            else
              ...filteredJobs.map(_buildJobTile),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureAggregateCard({
    required List<ImportFailureReasonAggregate> aggregates,
    required int failedCountInWindow,
    required _FailureRetryabilitySnapshot retryabilitySnapshot,
    required Map<String, _FailureRetryabilitySnapshot>
    reasonRetryabilitySnapshots,
  }) {
    final blockedPercent = retryabilitySnapshot.total <= 0
        ? 0
        : ((retryabilitySnapshot.blockedCount * 100) /
                  retryabilitySnapshot.total)
              .round();
    final windowSuggestion = deriveImportFailureActionSuggestion({
      for (final item in aggregates) item.reason: item.count,
    });
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近失败原因聚合（${_failureWindowLabel(_failureWindow)}）',
            style: GoogleFonts.lato(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('7天'),
                selected: _failureWindow == _FailureWindow.d7,
                onSelected: (_) {
                  setState(() {
                    _failureWindow = _FailureWindow.d7;
                  });
                  _persistFailureScopePrefs();
                },
              ),
              ChoiceChip(
                label: const Text('30天'),
                selected: _failureWindow == _FailureWindow.d30,
                onSelected: (_) {
                  setState(() {
                    _failureWindow = _FailureWindow.d30;
                  });
                  _persistFailureScopePrefs();
                },
              ),
              ChoiceChip(
                label: const Text('全部'),
                selected: _failureWindow == _FailureWindow.all,
                onSelected: (_) {
                  setState(() {
                    _failureWindow = _FailureWindow.all;
                  });
                  _persistFailureScopePrefs();
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(_failureSourceChipLabel(null)),
                selected: _failureSourceTypeFilter == null,
                onSelected: (_) {
                  setState(() {
                    _failureSourceTypeFilter = null;
                  });
                  _persistFailureScopePrefs();
                },
              ),
              ...ImportSourceType.values.map(
                (source) => ChoiceChip(
                  label: Text(_failureSourceChipLabel(source)),
                  selected: _failureSourceTypeFilter == source,
                  onSelected: (_) {
                    setState(() {
                      _failureSourceTypeFilter = source;
                    });
                    _persistFailureScopePrefs();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '失败任务 $failedCountInWindow 条，点击原因可快速过滤或批量重试',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            '可重试 ${retryabilitySnapshot.retryableCount} 条，不可重试 ${retryabilitySnapshot.blockedCount} 条（占比 $blockedPercent%）',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isBusy ? null : _retryAllRetryableInWindow,
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('本窗口重试可重试'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isBusy || _isExporting
                  ? null
                  : () => _exportFailureAggregateReport(
                      aggregates: aggregates,
                      failedCountInWindow: failedCountInWindow,
                      retryabilitySnapshot: retryabilitySnapshot,
                      reasonRetryabilitySnapshots: reasonRetryabilitySnapshots,
                    ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('导出失败报表'),
            ),
          ),
          if (windowSuggestion.hasAction)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isBusy
                    ? null
                    : () => _handleFailureActionSuggestion(windowSuggestion),
                icon: const Icon(Icons.tips_and_updates_outlined, size: 18),
                label: Text('窗口建议：${windowSuggestion.actionLabel}'),
              ),
            ),
          const SizedBox(height: 4),
          if (aggregates.isEmpty)
            Text(
              '该时间范围内暂无失败原因可聚合',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...aggregates.map((item) {
              final reasonSnapshot =
                  reasonRetryabilitySnapshots[item.reason] ??
                  const _FailureRetryabilitySnapshot(
                    retryableCount: 0,
                    blockedCount: 0,
                  );
              final reasonAction = deriveImportFailureActionSuggestion({
                item.reason: item.count,
              });
              final reasonTotal = reasonSnapshot.total;
              final reasonBlockedPercent = reasonTotal <= 0
                  ? 0
                  : ((reasonSnapshot.blockedCount * 100) / reasonTotal).round();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _isBusy
                                ? null
                                : () => _applyFailureReasonFilter(item.reason),
                            child: Text(
                              '${item.reason} ×${item.count}（最近 #${item.latestJobId} ${_formatDateTime(item.latestOccurredAt)}）',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 2),
                            child: Text(
                              '可重试 ${reasonSnapshot.retryableCount} 条，不可重试 ${reasonSnapshot.blockedCount} 条（占比 $reasonBlockedPercent%）',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _isBusy
                            ? null
                            : () => _retryAllRetryableByReason(item.reason),
                        child: const Text('重试可重试'),
                      ),
                      TextButton(
                        onPressed: _isBusy
                            ? null
                            : () => _promptBatchRetryByReason(item.reason),
                        child: const Text('重试最近N'),
                      ),
                      if (reasonAction.hasAction)
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () => _handleFailureActionSuggestion(
                                  reasonAction,
                                ),
                          child: Text(reasonAction.actionLabel),
                        ),
                    ],
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  void _applyFailureReasonFilter(String reason) {
    _applyFailedQuickFilter(reason);
  }

  void _applyFailedQuickFilter([String? reason]) {
    final keyword = (reason ?? '').trim();
    _jobSearchController.text = keyword;
    setState(() {
      _jobQuickFilter = _JobQuickFilter.failed;
      _jobSearchQuery = keyword;
    });
  }

  Future<void> _promptBatchRetryByReason(String reason) async {
    final service = _importService;
    if (service == null) {
      _showMessage('当前模式不可执行批量重试');
      return;
    }
    final since = _failureWindowSince(_failureWindow);
    final candidates = _collectFailedJobsByReason(
      reason,
      since: since,
      sourceType: _failureSourceTypeFilter,
    );
    if (candidates.isEmpty) {
      _showMessage('未找到可重试的失败任务');
      return;
    }
    final resolved = await _resolveRetryCandidates(candidates);
    final retryableJobs = resolved
        .where((item) => item.retryability.canRetry)
        .map((item) => item.job)
        .toList(growable: false);
    final blockedSummary = _summarizeBlockedRetryReasons(resolved);
    if (retryableJobs.isEmpty) {
      _showMessage('可重试任务为 0 条：$blockedSummary');
      return;
    }
    final limit = await _showRetryCountDialog(
      reason: reason,
      maxCount: retryableJobs.length,
      totalCount: resolved.length,
      blockedSummary: blockedSummary,
    );
    if (limit == null) return;
    await _retryResolvedJobs(retryableJobs, limit: limit);
  }

  Future<void> _retryAllRetryableByReason(String reason) async {
    final service = _importService;
    if (service == null) {
      _showMessage('当前模式不可执行批量重试');
      return;
    }
    final since = _failureWindowSince(_failureWindow);
    final candidates = _collectFailedJobsByReason(
      reason,
      since: since,
      sourceType: _failureSourceTypeFilter,
    );
    if (candidates.isEmpty) {
      _showMessage('未找到可重试的失败任务');
      return;
    }
    final resolved = await _resolveRetryCandidates(candidates);
    final retryableJobs = resolved
        .where((item) => item.retryability.canRetry)
        .map((item) => item.job)
        .toList(growable: false);
    final blockedSummary = _summarizeBlockedRetryReasons(resolved);
    if (retryableJobs.isEmpty) {
      _showMessage('可重试任务为 0 条：$blockedSummary');
      return;
    }
    final confirmed = await _confirmRetryAllDialog(
      scopeLabel: '失败原因',
      reason: reason,
      retryableCount: retryableJobs.length,
      totalCount: resolved.length,
      blockedSummary: blockedSummary,
    );
    if (confirmed != true) return;
    await _retryResolvedJobs(retryableJobs, limit: retryableJobs.length);
  }

  Future<void> _retryAllRetryableInWindow() async {
    final service = _importService;
    if (service == null) {
      _showMessage('当前模式不可执行批量重试');
      return;
    }
    final since = _failureWindowSince(_failureWindow);
    final candidates = _collectFailedJobs(
      since: since,
      sourceType: _failureSourceTypeFilter,
    );
    if (candidates.isEmpty) {
      _showMessage('当前窗口没有失败任务');
      return;
    }
    final resolved = await _resolveRetryCandidates(candidates);
    final retryableJobs = resolved
        .where((item) => item.retryability.canRetry)
        .map((item) => item.job)
        .toList(growable: false);
    final blockedSummary = _summarizeBlockedRetryReasons(resolved);
    if (retryableJobs.isEmpty) {
      _showMessage('可重试任务为 0 条：$blockedSummary');
      return;
    }
    final confirmed = await _confirmRetryAllDialog(
      scopeLabel:
          '当前窗口（${_failureWindowLabel(_failureWindow)} / ${_failureSourceScopeLabel(_failureSourceTypeFilter)}）',
      retryableCount: retryableJobs.length,
      totalCount: resolved.length,
      blockedSummary: blockedSummary,
    );
    if (confirmed != true) return;
    await _retryResolvedJobs(retryableJobs, limit: retryableJobs.length);
  }

  Future<bool?> _confirmRetryAllDialog({
    required String scopeLabel,
    String? reason,
    required int retryableCount,
    required int totalCount,
    required String blockedSummary,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('一键重试可重试任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reason == null ? '范围：$scopeLabel' : '失败原因：$reason'),
              Text('将重试 $retryableCount/$totalCount 条可重试任务'),
              if (blockedSummary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '不可重试：$blockedSummary',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('开始重试'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportFailureAggregateReport({
    required List<ImportFailureReasonAggregate> aggregates,
    required int failedCountInWindow,
    required _FailureRetryabilitySnapshot retryabilitySnapshot,
    required Map<String, _FailureRetryabilitySnapshot>
    reasonRetryabilitySnapshots,
  }) async {
    if (_isExporting) return;

    setState(() {
      _isFailureReportExporting = true;
    });

    try {
      final retryableByReason = <String, int>{};
      final blockedByReason = <String, int>{};
      for (final entry in reasonRetryabilitySnapshots.entries) {
        retryableByReason[entry.key] = entry.value.retryableCount;
        blockedByReason[entry.key] = entry.value.blockedCount;
      }
      final result = await _failureReportExporter.export(
        ImportFailureReportExportRequest(
          aggregates: aggregates,
          retryableByReason: retryableByReason,
          blockedByReason: blockedByReason,
          windowName: _failureWindow.name,
          windowLabel: _failureWindowLabel(_failureWindow),
          sourceName: _failureSourceTypeFilter?.name ?? 'all',
          sourceScopeLabel: _failureSourceScopeLabel(_failureSourceTypeFilter),
          failedCount: failedCountInWindow,
          retryableCount: retryabilitySnapshot.retryableCount,
          blockedCount: retryabilitySnapshot.blockedCount,
        ),
      );
      _showMessage('已导出失败报表：${result.fileName}');
    } catch (e) {
      _showMessage('导出失败报表失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isFailureReportExporting = false;
        });
      }
    }
  }

  Future<int?> _showRetryCountDialog({
    required String reason,
    required int maxCount,
    required int totalCount,
    required String blockedSummary,
  }) async {
    final controller = TextEditingController(
      text: (maxCount > 3 ? 3 : maxCount).toString(),
    );
    String? errorText;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('批量重试失败任务'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('失败原因：$reason'),
                  Text('可重试任务：$maxCount/$totalCount 条'),
                  if (blockedSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '不可重试：$blockedSummary',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '重试最近 N 条',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw = controller.text.trim();
                    final value = int.tryParse(raw);
                    if (value == null || value <= 0 || value > maxCount) {
                      setDialogState(() {
                        errorText = '请输入 1 到 $maxCount 的整数';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('开始重试'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _retryResolvedJobs(
    List<JiveImportJob> retryableJobs, {
    required int limit,
  }) async {
    final service = _importService;
    if (service == null) return;
    if (retryableJobs.isEmpty) {
      _showMessage('未找到可重试的失败任务');
      return;
    }
    final target = retryableJobs
        .take(limit.clamp(1, retryableJobs.length))
        .toList();
    setState(() {
      _isImporting = true;
      _lastResult = null;
    });
    var successCount = 0;
    var failedCount = 0;
    var insertedCount = 0;
    final secondaryFailureReasons = <String, int>{};
    try {
      for (final job in target) {
        try {
          final result = await service.retryJob(job.id);
          if (result.hasError) {
            failedCount += 1;
            final reason = normalizeImportFailureReason(result.errorMessage);
            secondaryFailureReasons[reason] =
                (secondaryFailureReasons[reason] ?? 0) + 1;
          } else {
            successCount += 1;
          }
          insertedCount += result.insertedCount;
          if (!mounted) return;
          setState(() {
            _lastResult = result;
            _hasChanges = _hasChanges || result.hasChanges;
          });
        } catch (_) {
          failedCount += 1;
          secondaryFailureReasons['未知失败'] =
              (secondaryFailureReasons['未知失败'] ?? 0) + 1;
        }
      }
      final secondarySummary = summarizeImportReasonCounts(
        secondaryFailureReasons,
        maxItems: 3,
      );
      final secondaryAction = suggestImportFailureAction(
        secondaryFailureReasons,
      );
      final secondaryActionSuggestion = deriveImportFailureActionSuggestion(
        secondaryFailureReasons,
      );
      _showMessage(
        secondarySummary.isEmpty
            ? '批量重试完成：目标${target.length} 成功$successCount 失败$failedCount 新增$insertedCount'
            : secondaryAction.isEmpty
            ? '批量重试完成：目标${target.length} 成功$successCount 失败$failedCount 新增$insertedCount；二次失败：$secondarySummary'
            : '批量重试完成：目标${target.length} 成功$successCount 失败$failedCount 新增$insertedCount；二次失败：$secondarySummary；建议：$secondaryAction',
        actionLabel: secondaryActionSuggestion.hasAction
            ? secondaryActionSuggestion.actionLabel
            : null,
        onAction: secondaryActionSuggestion.hasAction
            ? () {
                _handleFailureActionSuggestion(secondaryActionSuggestion);
              }
            : null,
      );
      await _refreshJobs();
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<List<_ResolvedRetryCandidate>> _resolveRetryCandidates(
    List<JiveImportJob> jobs,
  ) async {
    final resolved = <_ResolvedRetryCandidate>[];
    for (final job in jobs) {
      final filePath = (job.filePath ?? '').trim();
      var fileExists = false;
      if (filePath.isNotEmpty) {
        try {
          fileExists = await File(filePath).exists();
        } catch (_) {
          fileExists = false;
        }
      }
      final retryability = evaluateImportJobRetryability(
        payloadText: job.payloadText,
        filePath: job.filePath,
        fileExists: fileExists,
      );
      resolved.add(
        _ResolvedRetryCandidate(job: job, retryability: retryability),
      );
    }
    return resolved;
  }

  String _summarizeBlockedRetryReasons(List<_ResolvedRetryCandidate> resolved) {
    final map = <String, int>{};
    for (final item in resolved) {
      if (item.retryability.canRetry) continue;
      final reason = item.retryability.blockReason.trim().isEmpty
          ? '未知原因'
          : item.retryability.blockReason.trim();
      map[reason] = (map[reason] ?? 0) + 1;
    }
    return summarizeImportReasonCounts(map, maxItems: 3);
  }

  Future<void> _handleFailureActionSuggestion(
    ImportFailureActionSuggestion suggestion,
  ) async {
    if (!mounted) return;
    switch (suggestion.kind) {
      case ImportFailureActionKind.none:
        return;
      case ImportFailureActionKind.filterFailedJobs:
        _applyFailedQuickFilter(suggestion.reasonKeyword);
        return;
      case ImportFailureActionKind.openRuleTemplate:
        final suggestedSource = _pickDominantSourceTypeForFailedReason(
          suggestion.reasonKeyword,
        );
        if (suggestedSource != null && suggestedSource != _sourceType) {
          setState(() {
            _sourceType = suggestedSource;
          });
          _showMessage('已切换模板来源：${_sourceLabel(suggestedSource)}');
        }
        await _openTemplateEditor();
        return;
      case ImportFailureActionKind.refreshJobs:
        await _refreshJobs();
        return;
    }
  }

  _FailureRetryabilitySnapshot _buildFailureRetryabilitySnapshot(
    DateTime? since, {
    required ImportSourceType? sourceType,
  }) {
    final failedJobs = _collectFailedJobs(since: since, sourceType: sourceType);
    return _buildRetryabilitySnapshotForJobs(failedJobs);
  }

  Map<String, _FailureRetryabilitySnapshot> _buildReasonRetryabilitySnapshots(
    List<ImportFailureReasonAggregate> aggregates, {
    required DateTime? since,
    required ImportSourceType? sourceType,
  }) {
    final result = <String, _FailureRetryabilitySnapshot>{};
    for (final item in aggregates) {
      final jobs = _collectFailedJobsByReason(
        item.reason,
        since: since,
        sourceType: sourceType,
      );
      result[item.reason] = _buildRetryabilitySnapshotForJobs(jobs);
    }
    return result;
  }

  List<JiveImportJob> _collectFailedJobs({
    required DateTime? since,
    required ImportSourceType? sourceType,
  }) {
    final matched = _jobs.where((job) {
      if (job.status != 'failed') return false;
      final occurredAt = _jobOccurredAt(job);
      if (since != null && occurredAt.isBefore(since)) return false;
      if (sourceType != null) {
        final parsedSource = _parseImportSourceType(job.sourceType);
        if (parsedSource != sourceType) return false;
      }
      return true;
    }).toList();
    matched.sort((a, b) => _jobOccurredAt(b).compareTo(_jobOccurredAt(a)));
    return matched;
  }

  _FailureRetryabilitySnapshot _buildRetryabilitySnapshotForJobs(
    List<JiveImportJob> jobs,
  ) {
    var retryableCount = 0;
    var blockedCount = 0;
    for (final job in jobs) {
      final filePath = (job.filePath ?? '').trim();
      var fileExists = false;
      if (filePath.isNotEmpty) {
        try {
          fileExists = File(filePath).existsSync();
        } catch (_) {
          fileExists = false;
        }
      }
      final retryability = evaluateImportJobRetryability(
        payloadText: job.payloadText,
        filePath: job.filePath,
        fileExists: fileExists,
      );
      if (retryability.canRetry) {
        retryableCount += 1;
      } else {
        blockedCount += 1;
      }
    }
    return _FailureRetryabilitySnapshot(
      retryableCount: retryableCount,
      blockedCount: blockedCount,
    );
  }

  List<JiveImportJob> _collectFailedJobsByReason(
    String reason, {
    required DateTime? since,
    required ImportSourceType? sourceType,
  }) {
    final normalizedReason = reason.trim().toLowerCase();
    final matched = _collectFailedJobs(since: since, sourceType: sourceType)
        .where((job) {
          final normalizedJobReason = normalizeImportFailureReason(
            job.errorMessage,
          ).toLowerCase();
          return normalizedJobReason == normalizedReason;
        })
        .toList();
    return matched;
  }

  DateTime _jobOccurredAt(JiveImportJob job) {
    return job.finishedAt ?? job.updatedAt;
  }

  Widget _buildJobTile(JiveImportJob job) {
    final finishedText = job.finishedAt == null
        ? '进行中'
        : '${job.finishedAt!.month.toString().padLeft(2, '0')}-${job.finishedAt!.day.toString().padLeft(2, '0')} '
              '${job.finishedAt!.hour.toString().padLeft(2, '0')}:${job.finishedAt!.minute.toString().padLeft(2, '0')}';
    final subtitle =
        '${_statusLabel(job.status)} · ${_sourceLabelFromString(job.sourceType)} · 总计${job.totalCount} 新增${job.insertedCount} 重复${job.duplicateCount} 无效${job.invalidCount} 跳过${job.skippedByDuplicateDecisionCount} · ${_duplicatePolicyLabelFromRaw(job.duplicatePolicy)}';
    final extraSummary = _jobDecisionSummaryText(job);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('#${job.id}  $finishedText'),
      subtitle: Text(
        extraSummary == null ? subtitle : '$subtitle\n$extraSummary',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: _isBusy ? null : () => _openJobDetail(job),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _isBusy ? null : () => _retryJob(job),
            icon: const Icon(Icons.refresh),
            tooltip: '重试该任务',
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  String _sourceLabel(ImportSourceType sourceType) {
    switch (sourceType) {
      case ImportSourceType.auto:
        return '自动识别';
      case ImportSourceType.csv:
        return 'CSV/TSV';
      case ImportSourceType.alipay:
        return '支付宝文本';
      case ImportSourceType.wechat:
        return '微信文本';
      case ImportSourceType.ocr:
        return 'OCR 文本';
    }
  }

  String _sourceLabelFromString(String raw) {
    final parsed = _parseImportSourceType(raw);
    if (parsed == null) return raw;
    return _sourceLabel(parsed);
  }

  ImportSourceType? _parseImportSourceType(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final value in ImportSourceType.values) {
      if (value.name == normalized) {
        return value;
      }
    }
    return null;
  }

  ImportSourceType? _pickDominantSourceTypeForFailedReason(String? reason) {
    final keyword = (reason ?? '').trim();
    if (keyword.isEmpty) return null;
    final jobs = _collectFailedJobsByReason(
      keyword,
      since: null,
      sourceType: _failureSourceTypeFilter,
    );
    final counts = <ImportSourceType, int>{};
    for (final job in jobs) {
      final sourceType = _parseImportSourceType(job.sourceType);
      if (sourceType == null) continue;
      counts[sourceType] = (counts[sourceType] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countComp = b.value.compareTo(a.value);
        if (countComp != 0) return countComp;
        return a.key.name.compareTo(b.key.name);
      });
    return entries.first.key;
  }

  String _failureWindowLabel(_FailureWindow window) {
    switch (window) {
      case _FailureWindow.d7:
        return '7天';
      case _FailureWindow.d30:
        return '30天';
      case _FailureWindow.all:
        return '全部';
    }
  }

  String _failureSourceChipLabel(ImportSourceType? sourceType) {
    if (sourceType == null) return '来源:全部';
    switch (sourceType) {
      case ImportSourceType.auto:
        return '来源:自动';
      case ImportSourceType.csv:
        return '来源:CSV';
      case ImportSourceType.alipay:
        return '来源:支付宝';
      case ImportSourceType.wechat:
        return '来源:微信';
      case ImportSourceType.ocr:
        return '来源:OCR';
    }
  }

  String _failureSourceScopeLabel(ImportSourceType? sourceType) {
    if (sourceType == null) return '全部来源';
    return _sourceLabel(sourceType);
  }

  DateTime? _failureWindowSince(_FailureWindow window) {
    final now = DateTime.now();
    switch (window) {
      case _FailureWindow.d7:
        return now.subtract(const Duration(days: 7));
      case _FailureWindow.d30:
        return now.subtract(const Duration(days: 30));
      case _FailureWindow.all:
        return null;
    }
  }

  Map<String, dynamic>? _parseDecisionSummaryJson(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _jobDecisionSummaryText(JiveImportJob job) {
    final data = _parseDecisionSummaryJson(job.decisionSummaryJson);
    if (data == null) return null;
    final chunks = <String>[];
    final highRisk = _asInt(data['highRisk']);
    final inBatch = _asInt(data['inBatch']);
    final existing = _asInt(data['existing']);
    if (highRisk != null) {
      chunks.add('风险 高$highRisk');
    }
    if (inBatch != null || existing != null) {
      chunks.add('批内${inBatch ?? 0}/历史${existing ?? 0}');
    }
    final writeFailed = data['recordWriteFailed'] == true;
    if (writeFailed) {
      chunks.add('明细落库失败');
    }
    if (chunks.isEmpty) return null;
    return chunks.join(' · ');
  }

  List<Widget> _buildDecisionSummaryInfo(String? raw) {
    final data = _parseDecisionSummaryJson(raw);
    if (data == null) return const [];
    final children = <Widget>[];
    final highRisk = _asInt(data['highRisk']);
    final inBatch = _asInt(data['inBatch']);
    final existing = _asInt(data['existing']);
    if (highRisk != null || inBatch != null || existing != null) {
      children.add(const SizedBox(height: 8));
      children.add(
        Text(
          '风险摘要：高${highRisk ?? 0}（批内${inBatch ?? 0} / 历史${existing ?? 0}）',
          style: const TextStyle(color: Colors.orangeAccent),
        ),
      );
    }
    if (data['recordWriteFailed'] == true) {
      children.add(const SizedBox(height: 4));
      children.add(
        const Text('记录明细落库失败，请关注日志', style: TextStyle(color: Colors.redAccent)),
      );
    }
    return children;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  bool _matchesJobQuickFilter(JiveImportJob job) {
    switch (_jobQuickFilter) {
      case _JobQuickFilter.all:
        return true;
      case _JobQuickFilter.failed:
        return job.status == 'failed';
      case _JobQuickFilter.highRisk:
        return _jobHighRiskCount(job) > 0;
      case _JobQuickFilter.skipped:
        return job.skippedByDuplicateDecisionCount > 0;
    }
  }

  int _jobHighRiskCount(JiveImportJob job) {
    final data = _parseDecisionSummaryJson(job.decisionSummaryJson);
    final value = _asInt(data?['highRisk']);
    return value ?? 0;
  }

  bool _matchesJobSearch(JiveImportJob job, String query) {
    if (query.isEmpty) return true;
    final summary = _jobDecisionSummaryText(job);
    final joined = <String>[
      '${job.id}',
      '#${job.id}',
      job.status,
      _statusLabel(job.status),
      job.sourceType,
      _sourceLabelFromString(job.sourceType),
      job.duplicatePolicy,
      _duplicatePolicyLabelFromRaw(job.duplicatePolicy),
      '${job.totalCount}',
      '${job.insertedCount}',
      '${job.duplicateCount}',
      '${job.invalidCount}',
      '${job.skippedByDuplicateDecisionCount}',
      job.fileName ?? '',
      job.errorMessage ?? '',
      normalizeImportFailureReason(job.errorMessage),
      summary ?? '',
      job.decisionSummaryJson ?? '',
    ].join(' ').toLowerCase();
    return joined.contains(query);
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'expense':
        return '支出';
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '未知';
    }
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index < 0) return normalized;
    return normalized.substring(index + 1);
  }

  String _statusLabel(String raw) {
    switch (raw) {
      case 'pending':
        return '等待中';
      case 'running':
        return '执行中';
      case 'review':
        return '待确认';
      case 'failed':
        return '失败';
      default:
        return raw;
    }
  }

  String _duplicatePolicyLabel(ImportDuplicatePolicy policy) {
    switch (policy) {
      case ImportDuplicatePolicy.keepLatest:
        return '仅保留最新';
      case ImportDuplicatePolicy.keepAll:
        return '全保留';
      case ImportDuplicatePolicy.skipAll:
        return '全跳过';
    }
  }

  String _duplicatePolicyLabelFromRaw(String raw) {
    switch (raw) {
      case 'keep_all':
        return _duplicatePolicyLabel(ImportDuplicatePolicy.keepAll);
      case 'skip_all':
        return _duplicatePolicyLabel(ImportDuplicatePolicy.skipAll);
      case 'keep_latest':
      default:
        return _duplicatePolicyLabel(ImportDuplicatePolicy.keepLatest);
    }
  }
}
