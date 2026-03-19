import 'dart:convert';

import 'sync_runtime_service.dart';

enum SyncRuntimeTelemetryStatus { ready, review, block }

class SyncRuntimeTelemetryInput {
  const SyncRuntimeTelemetryInput({
    required this.scope,
    required this.initialDisposition,
    required this.restoredDisposition,
    required this.reboundDisposition,
    required this.importedSyncCursorCount,
    required this.restoredSnapshotValid,
    required this.sameDeviceRetained,
    required this.leaseClearedBeforeRestore,
    required this.staleWriterBlocked,
    required this.reboundWriterAllowed,
  });

  final String scope;
  final SyncRuntimeOpenDisposition initialDisposition;
  final SyncRuntimeOpenDisposition restoredDisposition;
  final SyncRuntimeOpenDisposition reboundDisposition;
  final int importedSyncCursorCount;
  final bool restoredSnapshotValid;
  final bool sameDeviceRetained;
  final bool leaseClearedBeforeRestore;
  final bool staleWriterBlocked;
  final bool reboundWriterAllowed;

  Map<String, dynamic> toJson() {
    return {
      'scope': scope,
      'initialDisposition': initialDisposition.name,
      'restoredDisposition': restoredDisposition.name,
      'reboundDisposition': reboundDisposition.name,
      'importedSyncCursorCount': importedSyncCursorCount,
      'restoredSnapshotValid': restoredSnapshotValid,
      'sameDeviceRetained': sameDeviceRetained,
      'leaseClearedBeforeRestore': leaseClearedBeforeRestore,
      'staleWriterBlocked': staleWriterBlocked,
      'reboundWriterAllowed': reboundWriterAllowed,
    };
  }
}

class SyncRuntimeTelemetryReport {
  const SyncRuntimeTelemetryReport({
    required this.input,
    required this.status,
    required this.telemetryLevel,
    required this.reason,
    required this.action,
    required this.recommendation,
    required this.generatedAt,
  });

  final SyncRuntimeTelemetryInput input;
  final SyncRuntimeTelemetryStatus status;
  final String telemetryLevel;
  final String reason;
  final String action;
  final String recommendation;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'telemetryLevel': telemetryLevel,
      'reason': reason,
      'action': action,
      'recommendation': recommendation,
      'generatedAt': generatedAt.toIso8601String(),
      'input': input.toJson(),
    };
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String exportMarkdown() {
    return '''
# Sync Runtime 遥测回归报告

- status: ${status.name}
- telemetryLevel: $telemetryLevel
- reason: $reason
- action: $action
- recommendation: $recommendation
- generatedAt: ${generatedAt.toIso8601String()}

## Input
- scope: ${input.scope}
- initialDisposition: ${input.initialDisposition.name}
- restoredDisposition: ${input.restoredDisposition.name}
- reboundDisposition: ${input.reboundDisposition.name}
- importedSyncCursorCount: ${input.importedSyncCursorCount}
- restoredSnapshotValid: ${input.restoredSnapshotValid}
- sameDeviceRetained: ${input.sameDeviceRetained}
- leaseClearedBeforeRestore: ${input.leaseClearedBeforeRestore}
- staleWriterBlocked: ${input.staleWriterBlocked}
- reboundWriterAllowed: ${input.reboundWriterAllowed}
''';
  }

  String exportCsv() {
    final rows = <List<String>>[
      ['field', 'value'],
      ['status', status.name],
      ['telemetryLevel', telemetryLevel],
      ['reason', reason],
      ['action', action],
      ['recommendation', recommendation],
      ['generatedAt', generatedAt.toIso8601String()],
      ['scope', input.scope],
      ['initialDisposition', input.initialDisposition.name],
      ['restoredDisposition', input.restoredDisposition.name],
      ['reboundDisposition', input.reboundDisposition.name],
      ['importedSyncCursorCount', input.importedSyncCursorCount.toString()],
      ['restoredSnapshotValid', input.restoredSnapshotValid.toString()],
      ['sameDeviceRetained', input.sameDeviceRetained.toString()],
      ['leaseClearedBeforeRestore', input.leaseClearedBeforeRestore.toString()],
      ['staleWriterBlocked', input.staleWriterBlocked.toString()],
      ['reboundWriterAllowed', input.reboundWriterAllowed.toString()],
    ];
    return rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
  }

  String _csvEscape(String raw) {
    if (raw.contains(',') || raw.contains('"') || raw.contains('\n')) {
      return '"${raw.replaceAll('"', '""')}"';
    }
    return raw;
  }
}

class SyncRuntimeTelemetryReportService {
  const SyncRuntimeTelemetryReportService();

  SyncRuntimeTelemetryReport evaluate(SyncRuntimeTelemetryInput input) {
    final blockReasons = <String>[];
    final reviewReasons = <String>[];

    if (input.scope.trim().isEmpty) {
      blockReasons.add('scope 为空，无法关联 sync runtime 事件');
    }
    if (!input.restoredSnapshotValid) {
      blockReasons.add('restore 后 checkpoint snapshot 不可恢复');
    }
    if (input.importedSyncCursorCount <= 0) {
      blockReasons.add('restore 后没有恢复任何 sync cursor');
    }
    if (!input.sameDeviceRetained) {
      blockReasons.add('restore/rebind 过程中 device identity 发生漂移');
    }
    if (!input.staleWriterBlocked) {
      blockReasons.add('旧 lease 仍然可写，存在 stale writer 风险');
    }
    if (!input.reboundWriterAllowed) {
      blockReasons.add('新 owner rebound 后无法继续写入');
    }
    if (!input.leaseClearedBeforeRestore) {
      reviewReasons.add('restore 前未确认清理旧 lease，建议补 telemetry');
    }
    if (input.initialDisposition != SyncRuntimeOpenDisposition.issued) {
      reviewReasons.add('初次 runtime 不是 issued，建议检查预热态污染');
    }
    if (input.restoredDisposition != SyncRuntimeOpenDisposition.issued) {
      reviewReasons.add('restore 后 reopen 不是 issued，需确认是否错误复用了旧 lease');
    }
    if (input.reboundDisposition != SyncRuntimeOpenDisposition.rebound) {
      reviewReasons.add('owner 轮换后没有进入 rebound，需复核 runtime owner 旋转逻辑');
    }

    final status = _resolveStatus(blockReasons, reviewReasons);
    final reasons = <String>[...blockReasons, ...reviewReasons];

    return SyncRuntimeTelemetryReport(
      input: input,
      status: status,
      telemetryLevel: _resolveLevel(status),
      reason: reasons.isEmpty
          ? 'sync runtime restore/rebind telemetry 完整'
          : reasons.join('；'),
      action: _resolveAction(status),
      recommendation: _resolveRecommendation(status),
      generatedAt: DateTime.now(),
    );
  }

  String exportJson(SyncRuntimeTelemetryReport report) {
    return report.exportJson();
  }

  String exportMarkdown(SyncRuntimeTelemetryReport report) =>
      report.exportMarkdown();

  String exportCsv(SyncRuntimeTelemetryReport report) => report.exportCsv();

  SyncRuntimeTelemetryStatus _resolveStatus(
    List<String> blockReasons,
    List<String> reviewReasons,
  ) {
    if (blockReasons.isNotEmpty) {
      return SyncRuntimeTelemetryStatus.block;
    }
    if (reviewReasons.isNotEmpty) {
      return SyncRuntimeTelemetryStatus.review;
    }
    return SyncRuntimeTelemetryStatus.ready;
  }

  String _resolveLevel(SyncRuntimeTelemetryStatus status) {
    switch (status) {
      case SyncRuntimeTelemetryStatus.ready:
        return 'T1_READY';
      case SyncRuntimeTelemetryStatus.review:
        return 'T2_REVIEW';
      case SyncRuntimeTelemetryStatus.block:
        return 'T3_BLOCK';
    }
  }

  String _resolveAction(SyncRuntimeTelemetryStatus status) {
    switch (status) {
      case SyncRuntimeTelemetryStatus.ready:
        return '允许继续运行 sync runtime regression 车道';
      case SyncRuntimeTelemetryStatus.review:
        return '补齐 telemetry 细节后重新回归';
      case SyncRuntimeTelemetryStatus.block:
        return '停止放行并修复 runtime restore/rebind 链路';
    }
  }

  String _resolveRecommendation(SyncRuntimeTelemetryStatus status) {
    switch (status) {
      case SyncRuntimeTelemetryStatus.ready:
        return '建议将报告与 Android artifacts 一起归档';
      case SyncRuntimeTelemetryStatus.review:
        return '建议增加 restore/rebind 事件字段并复跑设备回归';
      case SyncRuntimeTelemetryStatus.block:
        return '建议优先修复 stale writer 或 checkpoint 恢复问题';
    }
  }
}
