import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/account_book_delete_transfer_policy_service.dart';
import 'package:jive/core/service/account_book_import_sync_conflict_report_service.dart';
import 'package:jive/core/service/account_book_switch_sync_governance_service.dart';
import 'package:jive/core/service/import_edit_reconciliation_governance_service.dart';

void main() {
  final switchService = AccountBookSwitchSyncGovernanceService();
  final deleteService = AccountBookDeleteTransferPolicyService();
  final importService = ImportEditReconciliationGovernanceService();
  final reportService = AccountBookImportSyncConflictReportService();

  test(
    'evaluate returns ready when book switch delete transfer and import edit all pass',
    () {
      final report = reportService.evaluate(
        AccountBookImportSyncConflictReportInput(
          scope: 'account_book_import_sync',
          switchSyncResult: switchService.evaluate(
            const AccountBookSwitchSyncGovernanceInput(
              currentBookId: 'ab_001',
              targetBookId: 'ab_002',
              pendingSyncJobs: 0,
              willRefreshStatistics: true,
              willRefreshCalendar: true,
              willRefreshHome: true,
              willEmitEventBus: true,
              switchCountLast5Minutes: 1,
            ),
          ),
          deleteTransferResult: deleteService.evaluate(
            const AccountBookDeleteTransferPolicyInput(
              operatorRole: AccountBookDeleteTransferRole.owner,
              deleteRequested: true,
              isSharedBook: false,
              pendingBillCount: 12,
              hasTransferTarget: true,
              transferTargetBookId: 'ab_archive',
              transferTargetBookName: '归档账本',
              directDeleteSelected: false,
              containsDebtBills: false,
              containsReimburseBills: false,
            ),
          ),
          importEditResult: importService.evaluate(
            const ImportEditReconciliationGovernanceInput(
              action: ImportEditReconciliationAction.saveBillEdit,
              billRecordValid: true,
              transferRecordValid: true,
              amountValid: true,
              categorySelected: true,
              bookBound: true,
              assetBound: true,
              tagCount: 3,
              sameCategoryBatchExists: false,
              changeCategoryRequested: false,
              previewCropAvailable: true,
              fromAssetValid: true,
              toAssetValid: true,
              sameTransferAsset: false,
              serviceChargeValid: true,
              timeSelected: true,
              resultPayloadReady: true,
            ),
          ),
        ),
      );

      expect(report.status, AccountBookImportSyncConflictStatus.ready);
      expect(report.mode, AccountBookImportSyncConflictMode.direct);
      expect(report.reason, contains('均已通过'));
    },
  );

  test('evaluate returns review when switch still has pending sync jobs', () {
    final report = reportService.evaluate(
      AccountBookImportSyncConflictReportInput(
        scope: 'account_book_import_sync',
        switchSyncResult: switchService.evaluate(
          const AccountBookSwitchSyncGovernanceInput(
            currentBookId: 'ab_001',
            targetBookId: 'ab_002',
            pendingSyncJobs: 2,
            willRefreshStatistics: true,
            willRefreshCalendar: true,
            willRefreshHome: true,
            willEmitEventBus: true,
            switchCountLast5Minutes: 1,
          ),
        ),
        deleteTransferResult: deleteService.evaluate(
          const AccountBookDeleteTransferPolicyInput(
            operatorRole: AccountBookDeleteTransferRole.owner,
            deleteRequested: true,
            isSharedBook: false,
            pendingBillCount: 12,
            hasTransferTarget: true,
            transferTargetBookId: 'ab_archive',
            transferTargetBookName: '归档账本',
            directDeleteSelected: false,
            containsDebtBills: false,
            containsReimburseBills: false,
          ),
        ),
        importEditResult: importService.evaluate(
          const ImportEditReconciliationGovernanceInput(
            action: ImportEditReconciliationAction.saveBillEdit,
            billRecordValid: true,
            transferRecordValid: true,
            amountValid: true,
            categorySelected: true,
            bookBound: true,
            assetBound: true,
            tagCount: 3,
            sameCategoryBatchExists: false,
            changeCategoryRequested: false,
            previewCropAvailable: true,
            fromAssetValid: true,
            toAssetValid: true,
            sameTransferAsset: false,
            serviceChargeValid: true,
            timeSelected: true,
            resultPayloadReady: true,
          ),
        ),
      ),
    );

    expect(report.status, AccountBookImportSyncConflictStatus.review);
    expect(report.reason, contains('存在待同步任务'));
  });

  test(
    'evaluate returns block when delete transfer and import edit both conflict',
    () {
      final report = reportService.evaluate(
        AccountBookImportSyncConflictReportInput(
          scope: 'account_book_import_sync',
          switchSyncResult: switchService.evaluate(
            const AccountBookSwitchSyncGovernanceInput(
              currentBookId: 'ab_001',
              targetBookId: 'ab_002',
              pendingSyncJobs: 0,
              willRefreshStatistics: true,
              willRefreshCalendar: true,
              willRefreshHome: true,
              willEmitEventBus: true,
              switchCountLast5Minutes: 1,
            ),
          ),
          deleteTransferResult: deleteService.evaluate(
            const AccountBookDeleteTransferPolicyInput(
              operatorRole: AccountBookDeleteTransferRole.owner,
              deleteRequested: true,
              isSharedBook: false,
              pendingBillCount: 8,
              hasTransferTarget: false,
              transferTargetBookId: '',
              transferTargetBookName: '',
              directDeleteSelected: false,
              containsDebtBills: false,
              containsReimburseBills: false,
            ),
          ),
          importEditResult: importService.evaluate(
            const ImportEditReconciliationGovernanceInput(
              action: ImportEditReconciliationAction.saveBillEdit,
              billRecordValid: true,
              transferRecordValid: true,
              amountValid: true,
              categorySelected: true,
              bookBound: false,
              assetBound: true,
              tagCount: 3,
              sameCategoryBatchExists: false,
              changeCategoryRequested: false,
              previewCropAvailable: true,
              fromAssetValid: true,
              toAssetValid: true,
              sameTransferAsset: false,
              serviceChargeValid: true,
              timeSelected: true,
              resultPayloadReady: true,
            ),
          ),
        ),
      );

      expect(report.status, AccountBookImportSyncConflictStatus.block);
      expect(report.reason, contains('存在账单但未指定转移目标'));
      expect(report.reason, contains('目标账本未绑定'));
    },
  );

  test('exports json markdown csv payloads', () {
    final report = reportService.evaluate(
      AccountBookImportSyncConflictReportInput(
        scope: 'account_book_import_sync',
        switchSyncResult: switchService.evaluate(
          const AccountBookSwitchSyncGovernanceInput(
            currentBookId: 'ab_001',
            targetBookId: 'ab_002',
            pendingSyncJobs: 0,
            willRefreshStatistics: true,
            willRefreshCalendar: true,
            willRefreshHome: true,
            willEmitEventBus: true,
            switchCountLast5Minutes: 1,
          ),
        ),
        deleteTransferResult: deleteService.evaluate(
          const AccountBookDeleteTransferPolicyInput(
            operatorRole: AccountBookDeleteTransferRole.owner,
            deleteRequested: true,
            isSharedBook: false,
            pendingBillCount: 12,
            hasTransferTarget: true,
            transferTargetBookId: 'ab_archive',
            transferTargetBookName: '归档账本',
            directDeleteSelected: false,
            containsDebtBills: false,
            containsReimburseBills: false,
          ),
        ),
        importEditResult: importService.evaluate(
          const ImportEditReconciliationGovernanceInput(
            action: ImportEditReconciliationAction.saveBillEdit,
            billRecordValid: true,
            transferRecordValid: true,
            amountValid: true,
            categorySelected: true,
            bookBound: true,
            assetBound: true,
            tagCount: 3,
            sameCategoryBatchExists: false,
            changeCategoryRequested: false,
            previewCropAvailable: true,
            fromAssetValid: true,
            toAssetValid: true,
            sameTransferAsset: false,
            serviceChargeValid: true,
            timeSelected: true,
            resultPayloadReady: true,
          ),
        ),
      ),
    );

    expect(report.exportJson(), contains('"status": "ready"'));
    expect(report.exportMarkdown(), contains('# 账本导入同步冲突回归报告'));
    expect(report.exportCsv(), contains('field,value'));
    expect(report.exportCsv(), contains('status,ready'));

    final reportDir = Directory(
      '${Directory.current.path}/build/reports/account-book-import-sync',
    )..createSync(recursive: true);
    final jsonFile = File(
      '${reportDir.path}/account-book-import-sync-conflict.json',
    );
    jsonFile.writeAsStringSync(report.exportJson());
    final markdownFile = File(
      '${reportDir.path}/account-book-import-sync-conflict.md',
    );
    markdownFile.writeAsStringSync(report.exportMarkdown());
    final csvFile = File(
      '${reportDir.path}/account-book-import-sync-conflict.csv',
    );
    csvFile.writeAsStringSync(report.exportCsv());
  });
}
