import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/feature/import/import_history_analytics.dart';

void main() {
  test(
    'aggregateImportFailureReasons groups and sorts by count and latest time',
    () {
      final jobs = <JiveImportJob>[
        _buildJob(
          id: 1,
          status: 'failed',
          errorMessage: 'FormatException: invalid csv line',
          updatedAt: DateTime(2026, 2, 15, 10, 0),
        ),
        _buildJob(
          id: 2,
          status: 'failed',
          errorMessage: 'FormatException: invalid csv line',
          updatedAt: DateTime(2026, 2, 15, 12, 0),
        ),
        _buildJob(
          id: 3,
          status: 'failed',
          errorMessage: 'TimeoutError: request timeout',
          updatedAt: DateTime(2026, 2, 15, 11, 0),
        ),
        _buildJob(
          id: 4,
          status: 'review',
          errorMessage: 'FormatException: invalid csv line',
          updatedAt: DateTime(2026, 2, 15, 13, 0),
        ),
      ];

      final result = aggregateImportFailureReasons(jobs, maxItems: 5);

      expect(result.length, 2);
      expect(result.first.reason, 'invalid csv line');
      expect(result.first.count, 2);
      expect(result.first.latestJobId, 2);
      expect(result.last.reason, 'request timeout');
      expect(result.last.count, 1);
    },
  );

  test('aggregateImportFailureReasons supports since time window', () {
    final jobs = <JiveImportJob>[
      _buildJob(
        id: 11,
        status: 'failed',
        errorMessage: 'FormatException: old issue',
        updatedAt: DateTime(2025, 12, 1, 10, 0),
      ),
      _buildJob(
        id: 12,
        status: 'failed',
        errorMessage: 'FormatException: new issue',
        updatedAt: DateTime(2026, 2, 15, 10, 0),
      ),
    ];

    final result = aggregateImportFailureReasons(
      jobs,
      maxItems: 5,
      since: DateTime(2026, 1, 1),
    );

    expect(result.length, 1);
    expect(result.first.reason, 'new issue');
    expect(result.first.latestJobId, 12);
  });

  test('normalizeImportFailureReason handles empty and long messages', () {
    expect(normalizeImportFailureReason(null), '未知失败');
    expect(normalizeImportFailureReason('   '), '未知失败');
    expect(normalizeImportFailureReason('StateError: bad state'), 'bad state');

    final long =
        'FormatException: this is a very long error message that should be trimmed for aggregation display because it is too verbose';
    final normalized = normalizeImportFailureReason(long);
    expect(normalized.length, lessThanOrEqualTo(59));
    expect(normalized.endsWith('...'), isTrue);
  });

  test('evaluateImportJobRetryability resolves payload and file fallback', () {
    final payloadFirst = evaluateImportJobRetryability(
      payloadText: 'raw csv',
      filePath: '/tmp/missing.csv',
      fileExists: false,
    );
    expect(payloadFirst.canRetry, isTrue);
    expect(payloadFirst.source, 'payload');
    expect(payloadFirst.blockReason, isEmpty);

    final fileFallback = evaluateImportJobRetryability(
      payloadText: '   ',
      filePath: '/tmp/source.csv',
      fileExists: true,
    );
    expect(fileFallback.canRetry, isTrue);
    expect(fileFallback.source, 'file');
    expect(fileFallback.blockReason, isEmpty);

    final missingFile = evaluateImportJobRetryability(
      payloadText: null,
      filePath: '/tmp/missing.csv',
      fileExists: false,
    );
    expect(missingFile.canRetry, isFalse);
    expect(missingFile.source, 'none');
    expect(missingFile.blockReason, '原文件不存在且无原始文本');

    final missingAll = evaluateImportJobRetryability(
      payloadText: '',
      filePath: '',
      fileExists: false,
    );
    expect(missingAll.canRetry, isFalse);
    expect(missingAll.source, 'none');
    expect(missingAll.blockReason, '原始导入内容缺失');
  });

  test('summarizeImportReasonCounts merges and sorts top items', () {
    final summary = summarizeImportReasonCounts({
      '原因B': 1,
      '原因A': 2,
      ' 原因A ': 1,
      '': 4,
      '无效': 0,
    }, maxItems: 3);

    expect(summary, '未知原因 ×4，原因A ×3，原因B ×1');
    expect(summarizeImportReasonCounts({}, maxItems: 3), isEmpty);
    expect(summarizeImportReasonCounts({'A': 1}, maxItems: 0), isEmpty);
  });

  test('suggestImportFailureAction returns action by top reason', () {
    expect(
      suggestImportFailureAction({'原始导入内容缺失': 2, 'timeout': 1}),
      '补齐原始导入内容后重试',
    );
    expect(
      suggestImportFailureAction({'FormatException: invalid csv line': 3}),
      '检查导入文件格式并更新解析规则',
    );
    expect(suggestImportFailureAction({'request timeout': 2}), '检查网络连接后再次重试');
    expect(
      suggestImportFailureAction({'unknown issue': 1}),
      '打开任务详情查看错误并修正源数据',
    );
    expect(suggestImportFailureAction({}), isEmpty);
  });

  test('deriveImportFailureActionSuggestion maps action label and kind', () {
    final missing = deriveImportFailureActionSuggestion({
      '原始导入内容缺失': 2,
      'request timeout': 1,
    });
    expect(missing.kind, ImportFailureActionKind.filterFailedJobs);
    expect(missing.actionLabel, '筛选失败任务');
    expect(missing.reasonKeyword, '原始导入内容缺失');

    final format = deriveImportFailureActionSuggestion({'invalid csv line': 3});
    expect(format.kind, ImportFailureActionKind.openRuleTemplate);
    expect(format.actionLabel, '配置规则模板');

    final network = deriveImportFailureActionSuggestion({'request timeout': 3});
    expect(network.kind, ImportFailureActionKind.refreshJobs);
    expect(network.actionLabel, '刷新任务');

    final empty = deriveImportFailureActionSuggestion({});
    expect(empty.kind, ImportFailureActionKind.none);
    expect(empty.hasAction, isFalse);
  });
}

JiveImportJob _buildJob({
  required int id,
  required String status,
  required String errorMessage,
  required DateTime updatedAt,
}) {
  final job = JiveImportJob();
  job.id = id;
  job.createdAt = updatedAt.subtract(const Duration(hours: 1));
  job.updatedAt = updatedAt;
  job.finishedAt = updatedAt;
  job.status = status;
  job.sourceType = 'csv';
  job.entryType = 'file';
  job.errorMessage = errorMessage;
  job.totalCount = 0;
  job.insertedCount = 0;
  job.duplicateCount = 0;
  job.invalidCount = 0;
  job.skippedByDuplicateDecisionCount = 0;
  job.duplicatePolicy = 'keep_latest';
  return job;
}
