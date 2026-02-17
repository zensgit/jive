import '../../core/database/import_job_model.dart';

class ImportFailureReasonAggregate {
  final String reason;
  final int count;
  final int latestJobId;
  final DateTime latestOccurredAt;

  const ImportFailureReasonAggregate({
    required this.reason,
    required this.count,
    required this.latestJobId,
    required this.latestOccurredAt,
  });
}

class ImportRetryability {
  final bool canRetry;
  final String source;
  final String blockReason;

  const ImportRetryability({
    required this.canRetry,
    required this.source,
    required this.blockReason,
  });
}

enum ImportFailureActionKind {
  none,
  filterFailedJobs,
  openRuleTemplate,
  refreshJobs,
}

class ImportFailureActionSuggestion {
  final ImportFailureActionKind kind;
  final String message;
  final String actionLabel;
  final String? reasonKeyword;

  const ImportFailureActionSuggestion({
    required this.kind,
    required this.message,
    this.actionLabel = '',
    this.reasonKeyword,
  });

  const ImportFailureActionSuggestion.none()
    : kind = ImportFailureActionKind.none,
      message = '',
      actionLabel = '',
      reasonKeyword = null;

  bool get hasAction =>
      kind != ImportFailureActionKind.none && actionLabel.trim().isNotEmpty;
}

List<ImportFailureReasonAggregate> aggregateImportFailureReasons(
  List<JiveImportJob> jobs, {
  int maxItems = 5,
  DateTime? since,
}) {
  if (maxItems <= 0) return const [];
  final map = <String, ImportFailureReasonAggregate>{};
  for (final job in jobs) {
    if (job.status != 'failed') {
      continue;
    }
    final occurredAt = job.finishedAt ?? job.updatedAt;
    if (since != null && occurredAt.isBefore(since)) {
      continue;
    }
    final reason = normalizeImportFailureReason(job.errorMessage);
    final previous = map[reason];
    if (previous == null) {
      map[reason] = ImportFailureReasonAggregate(
        reason: reason,
        count: 1,
        latestJobId: job.id,
        latestOccurredAt: occurredAt,
      );
      continue;
    }
    final replaceLatest = occurredAt.isAfter(previous.latestOccurredAt);
    map[reason] = ImportFailureReasonAggregate(
      reason: reason,
      count: previous.count + 1,
      latestJobId: replaceLatest ? job.id : previous.latestJobId,
      latestOccurredAt: replaceLatest ? occurredAt : previous.latestOccurredAt,
    );
  }
  final list = map.values.toList()
    ..sort((a, b) {
      final countComp = b.count.compareTo(a.count);
      if (countComp != 0) return countComp;
      final timeComp = b.latestOccurredAt.compareTo(a.latestOccurredAt);
      if (timeComp != 0) return timeComp;
      return a.reason.compareTo(b.reason);
    });
  return list.take(maxItems).toList(growable: false);
}

String summarizeImportReasonCounts(
  Map<String, int> reasonCounts, {
  int maxItems = 3,
}) {
  if (maxItems <= 0 || reasonCounts.isEmpty) return '';
  final normalized = _normalizeReasonCounts(reasonCounts);
  if (normalized.isEmpty) return '';
  final entries = _sortedReasonEntries(normalized);
  return entries
      .take(maxItems)
      .map((entry) => '${entry.key} ×${entry.value}')
      .join('，');
}

String buildImportFailureAggregateCsv({
  required List<ImportFailureReasonAggregate> aggregates,
  required Map<String, int> retryableByReason,
  required Map<String, int> blockedByReason,
  required String windowLabel,
  required String sourceScopeLabel,
  required int failedCount,
  required int retryableCount,
  required int blockedCount,
  DateTime? generatedAt,
}) {
  final now = generatedAt ?? DateTime.now();
  final totalRetryability = retryableCount + blockedCount;
  final blockedPercent = totalRetryability <= 0
      ? 0
      : ((blockedCount * 100) / totalRetryability).round();
  final buffer = StringBuffer();
  buffer.writeln('meta,value');
  buffer.writeln('${_csvEscape('生成时间')},${_csvEscape(now.toIso8601String())}');
  buffer.writeln('${_csvEscape('时间窗口')},${_csvEscape(windowLabel)}');
  buffer.writeln('${_csvEscape('来源范围')},${_csvEscape(sourceScopeLabel)}');
  buffer.writeln('${_csvEscape('失败任务数')},$failedCount');
  buffer.writeln('${_csvEscape('可重试任务数')},$retryableCount');
  buffer.writeln('${_csvEscape('不可重试任务数')},$blockedCount');
  buffer.writeln('${_csvEscape('不可重试占比')},$blockedPercent%');
  buffer.writeln();
  buffer.writeln(
    'reason,count,latestJobId,latestOccurredAt,retryableCount,blockedCount,blockedPercent',
  );
  for (final item in aggregates) {
    final retryable = retryableByReason[item.reason] ?? 0;
    final blocked = blockedByReason[item.reason] ?? 0;
    final total = retryable + blocked;
    final reasonBlockedPercent = total <= 0
        ? 0
        : ((blocked * 100) / total).round();
    buffer.writeln(
      '${_csvEscape(item.reason)},${item.count},${item.latestJobId},${item.latestOccurredAt.toIso8601String()},$retryable,$blocked,$reasonBlockedPercent%',
    );
  }
  return buffer.toString();
}

String suggestImportFailureAction(Map<String, int> reasonCounts) {
  return deriveImportFailureActionSuggestion(reasonCounts).message;
}

ImportFailureActionSuggestion deriveImportFailureActionSuggestion(
  Map<String, int> reasonCounts,
) {
  final normalized = _normalizeReasonCounts(reasonCounts);
  if (normalized.isEmpty) {
    return const ImportFailureActionSuggestion.none();
  }
  final topReason = _sortedReasonEntries(normalized).first.key;
  final reasonLower = topReason.toLowerCase();
  if (reasonLower.contains('原文件不存在') ||
      reasonLower.contains('原始导入内容缺失') ||
      reasonLower.contains('missing')) {
    return ImportFailureActionSuggestion(
      kind: ImportFailureActionKind.filterFailedJobs,
      message: '补齐原始导入内容后重试',
      actionLabel: '筛选失败任务',
      reasonKeyword: topReason,
    );
  }
  if (reasonLower.contains('format') ||
      reasonLower.contains('parse') ||
      reasonLower.contains('csv') ||
      reasonLower.contains('json') ||
      reasonLower.contains('invalid')) {
    return ImportFailureActionSuggestion(
      kind: ImportFailureActionKind.openRuleTemplate,
      message: '检查导入文件格式并更新解析规则',
      actionLabel: '配置规则模板',
      reasonKeyword: topReason,
    );
  }
  if (reasonLower.contains('timeout') ||
      reasonLower.contains('network') ||
      reasonLower.contains('连接') ||
      reasonLower.contains('超时')) {
    return ImportFailureActionSuggestion(
      kind: ImportFailureActionKind.refreshJobs,
      message: '检查网络连接后再次重试',
      actionLabel: '刷新任务',
      reasonKeyword: topReason,
    );
  }
  return ImportFailureActionSuggestion(
    kind: ImportFailureActionKind.filterFailedJobs,
    message: '打开任务详情查看错误并修正源数据',
    actionLabel: '查看失败任务',
    reasonKeyword: topReason,
  );
}

String normalizeImportFailureReason(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) {
    return '未知失败';
  }
  var firstLine = text.split('\n').first.trim();
  firstLine = firstLine.replaceFirst(
    RegExp(r'^[A-Za-z0-9_]+Exception:\s*'),
    '',
  );
  firstLine = firstLine.replaceFirst(RegExp(r'^[A-Za-z0-9_]+Error:\s*'), '');
  firstLine = firstLine.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (firstLine.isEmpty) {
    return '未知失败';
  }
  const maxLen = 56;
  if (firstLine.length > maxLen) {
    return '${firstLine.substring(0, maxLen)}...';
  }
  return firstLine;
}

ImportRetryability evaluateImportJobRetryability({
  required String? payloadText,
  required String? filePath,
  required bool fileExists,
}) {
  final hasPayload = (payloadText ?? '').trim().isNotEmpty;
  final hasFilePath = (filePath ?? '').trim().isNotEmpty;
  if (hasPayload) {
    return const ImportRetryability(
      canRetry: true,
      source: 'payload',
      blockReason: '',
    );
  }
  if (hasFilePath && fileExists) {
    return const ImportRetryability(
      canRetry: true,
      source: 'file',
      blockReason: '',
    );
  }
  if (hasFilePath && !fileExists) {
    return const ImportRetryability(
      canRetry: false,
      source: 'none',
      blockReason: '原文件不存在且无原始文本',
    );
  }
  return const ImportRetryability(
    canRetry: false,
    source: 'none',
    blockReason: '原始导入内容缺失',
  );
}

Map<String, int> _normalizeReasonCounts(Map<String, int> reasonCounts) {
  final normalized = <String, int>{};
  for (final entry in reasonCounts.entries) {
    if (entry.value <= 0) continue;
    final reason = entry.key.trim().isEmpty ? '未知原因' : entry.key.trim();
    normalized[reason] = (normalized[reason] ?? 0) + entry.value;
  }
  return normalized;
}

List<MapEntry<String, int>> _sortedReasonEntries(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final countComp = b.value.compareTo(a.value);
      if (countComp != 0) return countComp;
      return a.key.compareTo(b.key);
    });
  return entries;
}

String _csvEscape(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
