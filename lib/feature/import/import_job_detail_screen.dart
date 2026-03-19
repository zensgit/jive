import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/import_job_model.dart';
import '../../core/database/import_job_record_model.dart';
import '../../core/repository/import_job_history_repository.dart';
import '../../core/service/database_service.dart';
import '../../core/service/import_service.dart';

class ImportJobDetailScreen extends StatefulWidget {
  final int jobId;
  final JiveImportJob? debugJob;
  final ImportJobDetailSummary? debugSummary;
  final List<JiveImportJobRecord>? debugRecords;

  const ImportJobDetailScreen({
    super.key,
    required this.jobId,
    this.debugJob,
    this.debugSummary,
    this.debugRecords,
  });

  @override
  State<ImportJobDetailScreen> createState() => _ImportJobDetailScreenState();
}

class _DedupGroupSummary {
  final String dedupKey;
  final List<JiveImportJobRecord> records;

  const _DedupGroupSummary({required this.dedupKey, required this.records});

  int get count => records.length;
  DateTime get latestTimestamp => records
      .map((record) => record.timestamp)
      .reduce((left, right) => left.isAfter(right) ? left : right);
  double get totalAmount => records.fold(0.0, (sum, item) => sum + item.amount);
  bool get hasHighRisk => records.any((record) => record.riskLevel != 'none');
  bool get hasBatchRisk => records.any(
    (record) => record.riskLevel == 'batch' || record.riskLevel == 'both',
  );
  bool get hasExistingRisk => records.any(
    (record) => record.riskLevel == 'existing' || record.riskLevel == 'both',
  );
  bool get hasBothRisk => records.any((record) => record.riskLevel == 'both');

  bool matchesRiskType(_DedupGroupRiskTypeFilter filter) {
    switch (filter) {
      case _DedupGroupRiskTypeFilter.all:
        return true;
      case _DedupGroupRiskTypeFilter.batch:
        return hasBatchRisk;
      case _DedupGroupRiskTypeFilter.existing:
        return hasExistingRisk;
      case _DedupGroupRiskTypeFilter.both:
        return hasBothRisk;
    }
  }
}

enum _DedupGroupSort { latestTime, totalAmount }

enum _DedupGroupRiskTypeFilter { all, batch, existing, both }

enum _GroupExportScope { currentPage, allPages }

class _GroupExportOptions {
  final _GroupExportScope scope;
  final int? topNByAmount;

  const _GroupExportOptions({required this.scope, required this.topNByAmount});
}

class _ImportJobDetailScreenState extends State<ImportJobDetailScreen> {
  final TextEditingController _groupSearchController = TextEditingController();

  ImportService? _service;
  JiveImportJob? _job;
  ImportJobDetailSummary? _summary;
  List<JiveImportJobRecord> _records = const [];
  List<JiveImportJobRecord>? _fixtureRecords;
  bool _isLoading = true;
  String? _error;
  String _decisionFilter = 'all';
  String _riskFilter = 'all';
  bool _groupByDedupKey = false;
  bool _groupHighRiskOnly = false;
  _DedupGroupSort _groupSort = _DedupGroupSort.latestTime;
  _DedupGroupRiskTypeFilter _groupRiskTypeFilter =
      _DedupGroupRiskTypeFilter.all;
  String _groupSearchQuery = '';
  int _groupPageSize = 20;
  int _groupPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _groupSearchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.debugJob != null &&
        widget.debugSummary != null &&
        widget.debugRecords != null) {
      final fixtureRecords = List<JiveImportJobRecord>.from(
        widget.debugRecords!,
      );
      if (!mounted) return;
      setState(() {
        _service = null;
        _job = widget.debugJob;
        _summary = widget.debugSummary;
        _fixtureRecords = fixtureRecords;
        _records = _filterFixtureRecords(fixtureRecords);
        _isLoading = false;
        _error = null;
      });
      return;
    }
    try {
      final isar = await DatabaseService.getInstance();
      final service = ImportService(isar);
      final jobRepository = ImportJobHistoryRepository(isar);
      final job = await jobRepository.getJob(widget.jobId);
      if (job == null) {
        throw StateError('任务不存在 #${widget.jobId}');
      }
      final summary = await service.getJobDetailSummary(widget.jobId);
      final records = await service.listJobRecords(
        widget.jobId,
        decision: _decisionFilter,
        riskLevel: _riskFilter,
        limit: 1000,
      );
      if (!mounted) return;
      setState(() {
        _service = service;
        _job = job;
        _summary = summary;
        _fixtureRecords = null;
        _records = records;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _reloadRecords() async {
    final fixtureRecords = _fixtureRecords;
    if (fixtureRecords != null) {
      if (!mounted) return;
      setState(() {
        _records = _filterFixtureRecords(fixtureRecords);
      });
      return;
    }
    final service = _service;
    if (service == null) return;
    final records = await service.listJobRecords(
      widget.jobId,
      decision: _decisionFilter,
      riskLevel: _riskFilter,
      limit: 1000,
    );
    if (!mounted) return;
    setState(() {
      _records = records;
    });
  }

  List<JiveImportJobRecord> _filterFixtureRecords(
    List<JiveImportJobRecord> records,
  ) {
    final filtered = records.where((record) {
      if (_decisionFilter != 'all' && record.decision != _decisionFilter) {
        return false;
      }
      if (_riskFilter != 'all' && record.riskLevel != _riskFilter) {
        return false;
      }
      return true;
    }).toList();
    filtered.sort(_compareJobRecords);
    return filtered;
  }

  Future<void> _exportCurrentView() async {
    final summary = _summary;
    if (summary == null) return;
    if (_groupByDedupKey) {
      final groups = _buildDedupGroups(
        _records,
        highRiskOnly: _groupHighRiskOnly,
        sort: _groupSort,
        riskTypeFilter: _groupRiskTypeFilter,
        searchQuery: _groupSearchQuery,
      );
      if (groups.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前分组筛选下没有可导出记录')));
        return;
      }
      final pageCount = _groupPageCount(groups.length);
      final pageIndex = _effectiveGroupPageIndex(groups.length);
      final groupsInCurrentPage = _paginateGroups(
        groups,
        pageIndex: pageIndex,
        pageSize: _groupPageSize,
      );
      final options = await _showGroupExportOptionsDialog(
        totalGroups: groups.length,
        currentPageGroups: groupsInCurrentPage.length,
        currentPage: pageIndex + 1,
        totalPages: pageCount,
      );
      if (options == null) {
        return;
      }
      var exportGroups = options.scope == _GroupExportScope.currentPage
          ? groupsInCurrentPage
          : groups;
      if (options.topNByAmount != null &&
          options.topNByAmount! > 0 &&
          exportGroups.length > options.topNByAmount!) {
        final ranked = List<_DedupGroupSummary>.from(exportGroups)
          ..sort(_compareGroupsByAmount);
        exportGroups = ranked.take(options.topNByAmount!).toList();
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/import_job_${widget.jobId}_groups_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      final buffer = StringBuffer();
      buffer.writeln('任务ID,${summary.jobId}');
      buffer.writeln('策略,${_policyLabel(summary.duplicatePolicy)}');
      buffer.writeln('总计,${summary.totalCount}');
      buffer.writeln('新增,${summary.insertedCount}');
      buffer.writeln('重复,${summary.duplicateCount}');
      buffer.writeln('无效,${summary.invalidCount}');
      buffer.writeln('策略跳过,${summary.skippedByDuplicateDecisionCount}');
      buffer.writeln('高风险,${summary.highRiskCount}');
      buffer.writeln('筛选-决策,${_decisionLabel(_decisionFilter)}');
      buffer.writeln('筛选-风险,${_riskLabel(_riskFilter)}');
      buffer.writeln('筛选-分组风险,${_groupRiskTypeLabel(_groupRiskTypeFilter)}');
      buffer.writeln('筛选-仅高风险,${_groupHighRiskOnly ? '是' : '否'}');
      buffer.writeln('筛选-关键词,${_csvSafe(_groupSearchQuery.trim())}');
      buffer.writeln('导出-范围,${_groupExportScopeLabel(options.scope)}');
      buffer.writeln('导出-TopN金额,${options.topNByAmount ?? '全部'}');
      if (options.scope == _GroupExportScope.currentPage) {
        buffer.writeln('导出-页码,${pageIndex + 1}/$pageCount');
      }
      buffer.writeln('');
      buffer.writeln(
        'dedupKey,count,totalAmount,latestTimestamp,hasHighRisk,hasBatchRisk,hasExistingRisk,hasBothRisk,decisionBreakdown',
      );
      for (final group in exportGroups) {
        final decisionBreakdownText = _decisionBreakdown(group.records).entries
            .where((entry) => entry.value > 0)
            .map((entry) => '${_decisionLabel(entry.key)}:${entry.value}')
            .join(' | ');
        buffer.writeln(
          [
            _csvSafe(group.dedupKey),
            group.count,
            group.totalAmount.toStringAsFixed(2),
            _csvSafe(_formatDateTime(group.latestTimestamp)),
            group.hasHighRisk ? 'yes' : 'no',
            group.hasBatchRisk ? 'yes' : 'no',
            group.hasExistingRisk ? 'yes' : 'no',
            group.hasBothRisk ? 'yes' : 'no',
            _csvSafe(decisionBreakdownText),
          ].join(','),
        );
      }
      await file.writeAsString(buffer.toString(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '导入任务 #${widget.jobId} 分组汇总（${_groupExportScopeLabel(options.scope)} / TopN:${options.topNByAmount ?? '全部'}，共 ${exportGroups.length} 组）',
        ),
      );
      return;
    }
    if (_records.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前筛选下没有可导出记录')));
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/import_job_${widget.jobId}_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final buffer = StringBuffer();
    buffer.writeln('任务ID,${summary.jobId}');
    buffer.writeln('策略,${_policyLabel(summary.duplicatePolicy)}');
    buffer.writeln('总计,${summary.totalCount}');
    buffer.writeln('新增,${summary.insertedCount}');
    buffer.writeln('重复,${summary.duplicateCount}');
    buffer.writeln('无效,${summary.invalidCount}');
    buffer.writeln('策略跳过,${summary.skippedByDuplicateDecisionCount}');
    buffer.writeln('高风险,${summary.highRiskCount}');
    buffer.writeln('筛选-决策,${_decisionLabel(_decisionFilter)}');
    buffer.writeln('筛选-风险,${_riskLabel(_riskFilter)}');
    buffer.writeln('');
    buffer.writeln(
      'jobId,sourceLineNumber,amount,source,timestamp,type,confidence,riskLevel,decision,decisionReason,warnings',
    );
    for (final record in _records) {
      buffer.writeln(
        [
          record.jobId,
          record.sourceLineNumber,
          record.amount.toStringAsFixed(2),
          _csvSafe(record.source),
          _csvSafe(_formatDateTime(record.timestamp)),
          _csvSafe(record.type ?? ''),
          (record.confidence * 100).toStringAsFixed(1),
          record.riskLevel,
          record.decision,
          _csvSafe(record.decisionReason ?? ''),
          _csvSafe(_decodeWarnings(record.warningsJson)),
        ].join(','),
      );
    }
    await file.writeAsString(buffer.toString(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text:
            '导入任务 #${widget.jobId} 明细（${_decisionLabel(_decisionFilter)} / ${_riskLabel(_riskFilter)}，共 ${_records.length} 条）',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('导入任务详情')),
        body: Center(child: Text('加载失败：$_error')),
      );
    }
    final job = _job!;
    final summary = _summary!;
    final summaryJson = _parseSummaryJson(_job?.decisionSummaryJson);
    final dedupGroups = _groupByDedupKey
        ? _buildDedupGroups(
            _records,
            highRiskOnly: _groupHighRiskOnly,
            sort: _groupSort,
            riskTypeFilter: _groupRiskTypeFilter,
            searchQuery: _groupSearchQuery,
          )
        : const <_DedupGroupSummary>[];
    final dedupPageCount = _groupByDedupKey
        ? _groupPageCount(dedupGroups.length)
        : 1;
    final dedupPageIndex = _groupByDedupKey
        ? _effectiveGroupPageIndex(dedupGroups.length)
        : 0;
    final dedupPageGroups = _groupByDedupKey
        ? _paginateGroups(
            dedupGroups,
            pageIndex: dedupPageIndex,
            pageSize: _groupPageSize,
          )
        : const <_DedupGroupSummary>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('导入任务 #${job.id}', style: GoogleFonts.lato()),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          IconButton(
            onPressed: _exportCurrentView,
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: '导出当前筛选',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '任务摘要',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('总计 ${summary.totalCount}')),
                      Chip(label: Text('新增 ${summary.insertedCount}')),
                      Chip(label: Text('重复 ${summary.duplicateCount}')),
                      Chip(label: Text('无效 ${summary.invalidCount}')),
                      Chip(
                        label: Text(
                          '策略跳过 ${summary.skippedByDuplicateDecisionCount}',
                        ),
                      ),
                      Chip(label: Text('高风险 ${summary.highRiskCount}')),
                      Chip(label: Text('批内 ${summary.inBatchRiskCount}')),
                      Chip(label: Text('历史 ${summary.existingRiskCount}')),
                      Chip(
                        label: Text(
                          '策略 ${_policyLabel(summary.duplicatePolicy)}',
                        ),
                      ),
                      if (summaryJson['recordWriteFailed'] == true)
                        const Chip(label: Text('明细写入失败')),
                    ],
                  ),
                  if (summary.decisionBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('决策分布', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: summary.decisionBreakdown.entries
                          .toList()
                          .where((entry) => entry.value > 0)
                          .map(
                            (entry) => Chip(
                              label: Text(
                                '${_decisionLabel(entry.key)} ${entry.value}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '筛选',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _decisionFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('决策：全部')),
                      DropdownMenuItem(value: 'inserted', child: Text('决策：新增')),
                      DropdownMenuItem(
                        value: 'duplicate',
                        child: Text('决策：重复'),
                      ),
                      DropdownMenuItem(value: 'invalid', child: Text('决策：无效')),
                      DropdownMenuItem(
                        value: 'skipped_policy',
                        child: Text('决策：策略跳过'),
                      ),
                      DropdownMenuItem(
                        value: 'skipped_keep_latest_existing_newer',
                        child: Text('决策：历史更新(跳过)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _decisionFilter = value;
                        _groupPageIndex = 0;
                      });
                      _reloadRecords();
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _riskFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('风险：全部')),
                      DropdownMenuItem(value: 'none', child: Text('风险：无')),
                      DropdownMenuItem(value: 'batch', child: Text('风险：批内')),
                      DropdownMenuItem(value: 'existing', child: Text('风险：历史')),
                      DropdownMenuItem(value: 'both', child: Text('风险：叠加')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _riskFilter = value;
                        _groupPageIndex = 0;
                      });
                      _reloadRecords();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('当前记录 ${_records.length} 条'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '记录明细',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('按记录'),
                        selected: !_groupByDedupKey,
                        onSelected: (_) {
                          setState(() {
                            _groupByDedupKey = false;
                            _groupPageIndex = 0;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('按 dedupKey 分组'),
                        selected: _groupByDedupKey,
                        onSelected: (_) {
                          setState(() {
                            _groupByDedupKey = true;
                            _groupPageIndex = 0;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_groupByDedupKey) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('仅高风险分组'),
                          selected: _groupHighRiskOnly,
                          onSelected: (selected) {
                            setState(() {
                              _groupHighRiskOnly = selected;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('风险:全部'),
                          selected:
                              _groupRiskTypeFilter ==
                              _DedupGroupRiskTypeFilter.all,
                          onSelected: (_) {
                            setState(() {
                              _groupRiskTypeFilter =
                                  _DedupGroupRiskTypeFilter.all;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('风险:批内'),
                          selected:
                              _groupRiskTypeFilter ==
                              _DedupGroupRiskTypeFilter.batch,
                          onSelected: (_) {
                            setState(() {
                              _groupRiskTypeFilter =
                                  _DedupGroupRiskTypeFilter.batch;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('风险:历史'),
                          selected:
                              _groupRiskTypeFilter ==
                              _DedupGroupRiskTypeFilter.existing,
                          onSelected: (_) {
                            setState(() {
                              _groupRiskTypeFilter =
                                  _DedupGroupRiskTypeFilter.existing;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('风险:叠加'),
                          selected:
                              _groupRiskTypeFilter ==
                              _DedupGroupRiskTypeFilter.both,
                          onSelected: (_) {
                            setState(() {
                              _groupRiskTypeFilter =
                                  _DedupGroupRiskTypeFilter.both;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('按最新时间'),
                          selected: _groupSort == _DedupGroupSort.latestTime,
                          onSelected: (_) {
                            setState(() {
                              _groupSort = _DedupGroupSort.latestTime;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('按总金额'),
                          selected: _groupSort == _DedupGroupSort.totalAmount,
                          onSelected: (_) {
                            setState(() {
                              _groupSort = _DedupGroupSort.totalAmount;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _groupSearchController,
                      decoration: InputDecoration(
                        labelText: '搜索分组 dedupKey',
                        hintText: '输入关键词过滤分组',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _groupSearchQuery.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _groupSearchController.clear();
                                  setState(() {
                                    _groupSearchQuery = '';
                                    _groupPageIndex = 0;
                                  });
                                },
                                icon: const Icon(Icons.close),
                                tooltip: '清除分组搜索',
                              ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _groupSearchQuery = value;
                          _groupPageIndex = 0;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前分组 ${dedupGroups.length} 个（${_groupRiskTypeLabel(_groupRiskTypeFilter)}） · 第 ${dedupPageIndex + 1}/$dedupPageCount 页',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('20/页'),
                          selected: _groupPageSize == 20,
                          onSelected: (_) {
                            setState(() {
                              _groupPageSize = 20;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('50/页'),
                          selected: _groupPageSize == 50,
                          onSelected: (_) {
                            setState(() {
                              _groupPageSize = 50;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('100/页'),
                          selected: _groupPageSize == 100,
                          onSelected: (_) {
                            setState(() {
                              _groupPageSize = 100;
                              _groupPageIndex = 0;
                            });
                          },
                        ),
                        IconButton(
                          onPressed: dedupPageIndex > 0
                              ? () {
                                  setState(() {
                                    _groupPageIndex = dedupPageIndex - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: '上一页',
                        ),
                        IconButton(
                          onPressed: dedupPageIndex + 1 < dedupPageCount
                              ? () {
                                  setState(() {
                                    _groupPageIndex = dedupPageIndex + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: '下一页',
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('当前筛选下无记录'),
                    )
                  else if (_groupByDedupKey && dedupGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('当前分组筛选下无记录'),
                    )
                  else
                    ...(_groupByDedupKey
                        ? _buildDedupGroupTiles(dedupPageGroups)
                        : _records.map(_buildRecordTile)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(JiveImportJobRecord record) {
    final title =
        '第${record.sourceLineNumber}行  ¥${record.amount.toStringAsFixed(2)}  ${_decisionLabel(record.decision)}';
    final subtitle =
        '${_formatDateTime(record.timestamp)} · ${record.source} · 风险:${_riskLabel(record.riskLevel)}';
    final warningText = _decodeWarnings(record.warningsJson);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(subtitle),
          if ((record.decisionReason ?? '').trim().isNotEmpty)
            Text(
              '原因：${record.decisionReason}',
              style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
            ),
          if (warningText.isNotEmpty)
            Text(
              '警告：$warningText',
              style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
            ),
        ],
      ),
    );
  }

  List<_DedupGroupSummary> _buildDedupGroups(
    List<JiveImportJobRecord> records, {
    required bool highRiskOnly,
    required _DedupGroupSort sort,
    required _DedupGroupRiskTypeFilter riskTypeFilter,
    required String searchQuery,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final grouped = <String, List<JiveImportJobRecord>>{};
    for (final record in records) {
      final key = record.dedupKey.trim().isEmpty ? '(empty)' : record.dedupKey;
      grouped.putIfAbsent(key, () => <JiveImportJobRecord>[]).add(record);
    }
    final groups = <_DedupGroupSummary>[];
    for (final entry in grouped.entries) {
      final sortedRecords = List<JiveImportJobRecord>.from(entry.value)
        ..sort(_compareJobRecords);
      final summary = _DedupGroupSummary(
        dedupKey: entry.key,
        records: sortedRecords,
      );
      if (highRiskOnly && !summary.hasHighRisk) {
        continue;
      }
      if (!summary.matchesRiskType(riskTypeFilter)) {
        continue;
      }
      if (normalizedQuery.isNotEmpty &&
          !summary.dedupKey.toLowerCase().contains(normalizedQuery)) {
        continue;
      }
      groups.add(summary);
    }
    groups.sort((a, b) {
      switch (sort) {
        case _DedupGroupSort.latestTime:
          final latestComp = b.latestTimestamp.compareTo(a.latestTimestamp);
          if (latestComp != 0) return latestComp;
          final countComp = b.count.compareTo(a.count);
          if (countComp != 0) return countComp;
          return b.totalAmount.compareTo(a.totalAmount);
        case _DedupGroupSort.totalAmount:
          final amountComp = b.totalAmount.compareTo(a.totalAmount);
          if (amountComp != 0) return amountComp;
          final latestComp = b.latestTimestamp.compareTo(a.latestTimestamp);
          if (latestComp != 0) return latestComp;
          return b.count.compareTo(a.count);
      }
    });
    return groups;
  }

  int _groupPageCount(int totalGroups) {
    if (totalGroups <= 0) return 1;
    return ((totalGroups - 1) ~/ _groupPageSize) + 1;
  }

  int _effectiveGroupPageIndex(int totalGroups) {
    final maxIndex = _groupPageCount(totalGroups) - 1;
    if (_groupPageIndex < 0) return 0;
    if (_groupPageIndex > maxIndex) return maxIndex;
    return _groupPageIndex;
  }

  List<_DedupGroupSummary> _paginateGroups(
    List<_DedupGroupSummary> groups, {
    required int pageIndex,
    required int pageSize,
  }) {
    if (groups.isEmpty) return const [];
    final safePageSize = pageSize <= 0 ? groups.length : pageSize;
    final safePageIndex = pageIndex < 0 ? 0 : pageIndex;
    final start = safePageIndex * safePageSize;
    if (start >= groups.length) {
      return const [];
    }
    final end = (start + safePageSize).clamp(0, groups.length);
    return groups.sublist(start, end);
  }

  int _compareGroupsByAmount(_DedupGroupSummary a, _DedupGroupSummary b) {
    final byAmount = b.totalAmount.compareTo(a.totalAmount);
    if (byAmount != 0) return byAmount;
    final byLatest = b.latestTimestamp.compareTo(a.latestTimestamp);
    if (byLatest != 0) return byLatest;
    return b.count.compareTo(a.count);
  }

  Future<_GroupExportOptions?> _showGroupExportOptionsDialog({
    required int totalGroups,
    required int currentPageGroups,
    required int currentPage,
    required int totalPages,
  }) async {
    var scope = _GroupExportScope.currentPage;
    final topNController = TextEditingController();
    String? errorText;
    final result = await showDialog<_GroupExportOptions>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('导出分组选项'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前筛选共 $totalGroups 组'),
                  Text('当前页：$currentPage/$totalPages（$currentPageGroups 组）'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('仅导出当前页'),
                        selected: scope == _GroupExportScope.currentPage,
                        onSelected: (_) {
                          setDialogState(() {
                            scope = _GroupExportScope.currentPage;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('导出全部页'),
                        selected: scope == _GroupExportScope.allPages,
                        onSelected: (_) {
                          setDialogState(() {
                            scope = _GroupExportScope.allPages;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: topNController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Top N（按金额）',
                      hintText: '留空表示不限制',
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
                    final raw = topNController.text.trim();
                    int? topN;
                    if (raw.isNotEmpty) {
                      topN = int.tryParse(raw);
                      if (topN == null || topN <= 0) {
                        setDialogState(() {
                          errorText = 'Top N 需要输入正整数';
                        });
                        return;
                      }
                    }
                    Navigator.pop(
                      dialogContext,
                      _GroupExportOptions(scope: scope, topNByAmount: topN),
                    );
                  },
                  child: const Text('导出'),
                ),
              ],
            );
          },
        );
      },
    );
    topNController.dispose();
    return result;
  }

  Iterable<Widget> _buildDedupGroupTiles(
    List<_DedupGroupSummary> groups,
  ) sync* {
    for (final group in groups) {
      yield _buildDedupGroupTile(group);
    }
  }

  Widget _buildDedupGroupTile(_DedupGroupSummary group) {
    final decisions = _decisionBreakdown(group.records);
    final decisionText = decisions.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${_decisionLabel(entry.key)} ${entry.value}')
        .join(' / ');
    final keyText = group.dedupKey.length > 80
        ? '${group.dedupKey.substring(0, 80)}...'
        : group.dedupKey;
    return Container(
      key: ValueKey<String>('dedup_group_${group.dedupKey}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            keyText,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '记录 ${group.count} 条 · 总金额 ¥${group.totalAmount.toStringAsFixed(2)} · 最新 ${_formatDateTime(group.latestTimestamp)}',
          ),
          Text('决策：$decisionText'),
          if (group.hasHighRisk)
            const Text(
              '包含高风险重复',
              style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showDedupGroupDialog(group),
              child: const Text('查看组内记录'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDedupGroupDialog(_DedupGroupSummary group) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('dedupKey 分组（${group.count} 条）'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  group.dedupKey,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...group.records.map(_buildRecordTile),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _decisionBreakdown(List<JiveImportJobRecord> records) {
    final map = <String, int>{};
    for (final record in records) {
      map[record.decision] = (map[record.decision] ?? 0) + 1;
    }
    return map;
  }

  int _compareJobRecords(JiveImportJobRecord a, JiveImportJobRecord b) {
    final lineComp = a.sourceLineNumber.compareTo(b.sourceLineNumber);
    if (lineComp != 0) return lineComp;
    return a.id.compareTo(b.id);
  }

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  String _csvSafe(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _decodeWarnings(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '[]') return '';
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded.map((item) => '$item').join(' | ');
      }
    } catch (_) {
      // ignore
    }
    return text;
  }

  Map<String, dynamic> _parseSummaryJson(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return const {};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }

  String _policyLabel(String raw) {
    switch (raw) {
      case 'keep_all':
        return '全保留';
      case 'skip_all':
        return '全跳过';
      case 'keep_latest':
      default:
        return '仅保留最新';
    }
  }

  String _decisionLabel(String raw) {
    switch (raw) {
      case 'inserted':
        return '新增';
      case 'duplicate':
        return '重复';
      case 'invalid':
        return '无效';
      case 'skipped_policy':
        return '策略跳过';
      case 'skipped_keep_latest_existing_newer':
        return '历史更新(跳过)';
      case 'all':
        return '全部';
      default:
        return raw;
    }
  }

  String _riskLabel(String raw) {
    switch (raw) {
      case 'none':
        return '无';
      case 'batch':
        return '批内';
      case 'existing':
        return '历史';
      case 'both':
        return '叠加';
      case 'all':
        return '全部';
      default:
        return raw;
    }
  }

  String _groupRiskTypeLabel(_DedupGroupRiskTypeFilter filter) {
    switch (filter) {
      case _DedupGroupRiskTypeFilter.all:
        return '风险全部';
      case _DedupGroupRiskTypeFilter.batch:
        return '批内风险';
      case _DedupGroupRiskTypeFilter.existing:
        return '历史风险';
      case _DedupGroupRiskTypeFilter.both:
        return '叠加风险';
    }
  }

  String _groupExportScopeLabel(_GroupExportScope scope) {
    switch (scope) {
      case _GroupExportScope.currentPage:
        return '当前页';
      case _GroupExportScope.allPages:
        return '全部页';
    }
  }
}
