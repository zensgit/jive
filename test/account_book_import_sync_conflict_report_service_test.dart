import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/account_book_delete_transfer_policy_service.dart';
import 'package:jive/core/service/account_book_import_sync_conflict_report_service.dart';
import 'package:jive/core/service/account_book_switch_sync_governance_service.dart';
import 'package:jive/core/service/import_edit_reconciliation_governance_service.dart';

void main() {
  final service = AccountBookImportSyncConflictReportService();

  AccountBookImportSyncConflictReportInput input({
    AccountBookSwitchSyncStatus switchStatus =
        AccountBookSwitchSyncStatus.ready,
    AccountBookDeleteTransferStatus deleteStatus =
        AccountBookDeleteTransferStatus.ready,
    ImportEditReconciliationStatus importStatus =
        ImportEditReconciliationStatus.ready,
  }) {
    return AccountBookImportSyncConflictReportInput(
      scope: 'release_regression',
      switchSyncResult: AccountBookSwitchSyncGovernanceResult(
        status: switchStatus,
        mode: switchStatus == AccountBookSwitchSyncStatus.ready
            ? AccountBookSwitchSyncMode.direct
            : AccountBookSwitchSyncMode.manualReview,
        reason: switchStatus == AccountBookSwitchSyncStatus.ready
            ? 'switch ok'
            : 'switch needs review',
      ),
      deleteTransferResult: AccountBookDeleteTransferPolicyResult(
        status: deleteStatus,
        mode: deleteStatus == AccountBookDeleteTransferStatus.ready
            ? AccountBookDeleteTransferMode.direct
            : AccountBookDeleteTransferMode.blocked,
        reason: deleteStatus == AccountBookDeleteTransferStatus.ready
            ? 'delete transfer ok'
            : 'delete transfer blocked',
      ),
      importEditResult: ImportEditReconciliationGovernanceResult(
        status: importStatus,
        mode: importStatus == ImportEditReconciliationStatus.ready
            ? ImportEditReconciliationMode.direct
            : ImportEditReconciliationMode.manualReview,
        reason: importStatus == ImportEditReconciliationStatus.ready
            ? 'import edit ok'
            : 'import edit needs review',
      ),
    );
  }

  test('evaluate returns ready when all governance checks are ready', () {
    final result = service.evaluate(input());

    expect(result.status, AccountBookImportSyncConflictStatus.ready);
    expect(result.mode, AccountBookImportSyncConflictMode.direct);
    expect(result.action, contains('允许继续执行'));
    expect(result.reason, contains('均已通过'));
  });

  test('evaluate returns review when any check requires manual review', () {
    final result = service.evaluate(
      input(importStatus: ImportEditReconciliationStatus.review),
    );

    expect(result.status, AccountBookImportSyncConflictStatus.review);
    expect(result.mode, AccountBookImportSyncConflictMode.manualReview);
    expect(result.reason, contains('导入编辑回写'));
    expect(result.action, contains('人工复核'));
  });

  test('evaluate returns block when any check blocks the flow', () {
    final result = service.evaluate(
      input(deleteStatus: AccountBookDeleteTransferStatus.block),
    );

    expect(result.status, AccountBookImportSyncConflictStatus.block);
    expect(result.mode, AccountBookImportSyncConflictMode.blocked);
    expect(result.reason, contains('账本删除转移'));
    expect(result.action, contains('阻断'));
  });

  test('exports json markdown and csv report payloads', () {
    final result = service.evaluate(
      input(switchStatus: AccountBookSwitchSyncStatus.review),
    );

    expect(result.exportJson(), contains('"status": "review"'));
    expect(result.exportJson(), contains('"scope": "release_regression"'));
    expect(result.exportMarkdown(), contains('# 账本导入同步冲突回归报告'));
    expect(result.exportMarkdown(), contains('switchSync.status: review'));
    expect(result.exportCsv(), contains('field,value'));
    expect(result.exportCsv(), contains('status,review'));
  });
}
