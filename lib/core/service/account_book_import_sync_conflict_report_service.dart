import 'dart:convert';

import 'account_book_delete_transfer_policy_service.dart';
import 'account_book_switch_sync_governance_service.dart';
import 'import_edit_reconciliation_governance_service.dart';

enum AccountBookImportSyncConflictStatus {
  ready('ready'),
  review('review'),
  block('block');

  const AccountBookImportSyncConflictStatus(this.value);
  final String value;
}

enum AccountBookImportSyncConflictMode {
  direct('direct'),
  manualReview('manual_review'),
  blocked('blocked');

  const AccountBookImportSyncConflictMode(this.value);
  final String value;
}

class AccountBookImportSyncConflictReportInput {
  const AccountBookImportSyncConflictReportInput({
    required this.scope,
    required this.switchSyncResult,
    required this.deleteTransferResult,
    required this.importEditResult,
  });

  final String scope;
  final AccountBookSwitchSyncGovernanceResult switchSyncResult;
  final AccountBookDeleteTransferPolicyResult deleteTransferResult;
  final ImportEditReconciliationGovernanceResult importEditResult;

  Map<String, dynamic> toJson() {
    return {
      'scope': scope,
      'switchSync': switchSyncResult.toJson(),
      'deleteTransfer': deleteTransferResult.toJson(),
      'importEdit': importEditResult.toJson(),
    };
  }
}

class AccountBookImportSyncConflictReportResult {
  const AccountBookImportSyncConflictReportResult({
    required this.input,
    required this.status,
    required this.mode,
    required this.reason,
    required this.action,
    required this.recommendation,
    required this.evaluatedAt,
  });

  final AccountBookImportSyncConflictReportInput input;
  final AccountBookImportSyncConflictStatus status;
  final AccountBookImportSyncConflictMode mode;
  final String reason;
  final String action;
  final String recommendation;
  final DateTime evaluatedAt;

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'mode': mode.value,
      'reason': reason,
      'action': action,
      'recommendation': recommendation,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'input': input.toJson(),
    };
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String exportMarkdown() {
    return '''
# 账本导入同步冲突回归报告

- status: ${status.value}
- mode: ${mode.value}
- reason: $reason
- action: $action
- recommendation: $recommendation
- evaluatedAt: ${evaluatedAt.toIso8601String()}

## Input
- scope: ${input.scope}
- switchSync.status: ${input.switchSyncResult.status.value}
- switchSync.mode: ${input.switchSyncResult.mode.value}
- switchSync.reason: ${input.switchSyncResult.reason}
- deleteTransfer.status: ${input.deleteTransferResult.status.value}
- deleteTransfer.mode: ${input.deleteTransferResult.mode.value}
- deleteTransfer.reason: ${input.deleteTransferResult.reason}
- importEdit.status: ${input.importEditResult.status.value}
- importEdit.mode: ${input.importEditResult.mode.value}
- importEdit.reason: ${input.importEditResult.reason}
''';
  }

  String exportCsv() {
    final rows = <List<String>>[
      ['field', 'value'],
      ['status', status.value],
      ['mode', mode.value],
      ['reason', reason],
      ['action', action],
      ['recommendation', recommendation],
      ['evaluatedAt', evaluatedAt.toIso8601String()],
      ['scope', input.scope],
      ['switchSync.status', input.switchSyncResult.status.value],
      ['switchSync.mode', input.switchSyncResult.mode.value],
      ['switchSync.reason', input.switchSyncResult.reason],
      ['deleteTransfer.status', input.deleteTransferResult.status.value],
      ['deleteTransfer.mode', input.deleteTransferResult.mode.value],
      ['deleteTransfer.reason', input.deleteTransferResult.reason],
      ['importEdit.status', input.importEditResult.status.value],
      ['importEdit.mode', input.importEditResult.mode.value],
      ['importEdit.reason', input.importEditResult.reason],
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

class AccountBookImportSyncConflictReportService {
  AccountBookImportSyncConflictReportResult evaluate(
    AccountBookImportSyncConflictReportInput input,
  ) {
    final issues = <String>[];
    final highest = _maxSeverity(
      switchStatus: input.switchSyncResult.status,
      deleteStatus: input.deleteTransferResult.status,
      importStatus: input.importEditResult.status,
    );

    if (input.switchSyncResult.status != AccountBookSwitchSyncStatus.ready) {
      issues.add('账本切换：${input.switchSyncResult.reason}');
    }
    if (input.deleteTransferResult.status !=
        AccountBookDeleteTransferStatus.ready) {
      issues.add('账本删除转移：${input.deleteTransferResult.reason}');
    }
    if (input.importEditResult.status != ImportEditReconciliationStatus.ready) {
      issues.add('导入编辑回写：${input.importEditResult.reason}');
    }

    final status = _resolveStatus(highest);
    final mode = _resolveMode(highest);

    return AccountBookImportSyncConflictReportResult(
      input: input,
      status: status,
      mode: mode,
      reason: issues.isEmpty ? '账本切换、删除转移、导入回写链路均已通过' : issues.join('；'),
      action: _resolveAction(status),
      recommendation: _resolveRecommendation(status),
      evaluatedAt: DateTime.now(),
    );
  }

  int _maxSeverity({
    required AccountBookSwitchSyncStatus switchStatus,
    required AccountBookDeleteTransferStatus deleteStatus,
    required ImportEditReconciliationStatus importStatus,
  }) {
    final severities = <int>[
      _switchSeverity(switchStatus),
      _deleteSeverity(deleteStatus),
      _importSeverity(importStatus),
    ];
    severities.sort();
    return severities.last;
  }

  int _switchSeverity(AccountBookSwitchSyncStatus status) {
    switch (status) {
      case AccountBookSwitchSyncStatus.ready:
        return 0;
      case AccountBookSwitchSyncStatus.review:
        return 1;
      case AccountBookSwitchSyncStatus.block:
        return 2;
    }
  }

  int _deleteSeverity(AccountBookDeleteTransferStatus status) {
    switch (status) {
      case AccountBookDeleteTransferStatus.ready:
        return 0;
      case AccountBookDeleteTransferStatus.review:
        return 1;
      case AccountBookDeleteTransferStatus.block:
        return 2;
    }
  }

  int _importSeverity(ImportEditReconciliationStatus status) {
    switch (status) {
      case ImportEditReconciliationStatus.ready:
        return 0;
      case ImportEditReconciliationStatus.review:
        return 1;
      case ImportEditReconciliationStatus.block:
        return 2;
    }
  }

  AccountBookImportSyncConflictStatus _resolveStatus(int severity) {
    switch (severity) {
      case 0:
        return AccountBookImportSyncConflictStatus.ready;
      case 1:
        return AccountBookImportSyncConflictStatus.review;
      default:
        return AccountBookImportSyncConflictStatus.block;
    }
  }

  AccountBookImportSyncConflictMode _resolveMode(int severity) {
    switch (severity) {
      case 0:
        return AccountBookImportSyncConflictMode.direct;
      case 1:
        return AccountBookImportSyncConflictMode.manualReview;
      default:
        return AccountBookImportSyncConflictMode.blocked;
    }
  }

  String _resolveAction(AccountBookImportSyncConflictStatus status) {
    switch (status) {
      case AccountBookImportSyncConflictStatus.ready:
        return '允许继续执行账本切换、删除转移与导入回写链路';
      case AccountBookImportSyncConflictStatus.review:
        return '保留人工复核后再继续跨账本导入/删除流程';
      case AccountBookImportSyncConflictStatus.block:
        return '阻断当前链路并先修复账本或导入冲突';
    }
  }

  String _resolveRecommendation(AccountBookImportSyncConflictStatus status) {
    switch (status) {
      case AccountBookImportSyncConflictStatus.ready:
        return '建议与 release regression suite 一起归档回归结果';
      case AccountBookImportSyncConflictStatus.review:
        return '建议先处理待同步任务、共享账本复核或批量回写确认';
      case AccountBookImportSyncConflictStatus.block:
        return '建议优先修复转移目标、账本绑定或事件广播缺失问题';
    }
  }
}
