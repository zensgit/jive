import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/auto_draft_model.dart';
import 'package:jive/core/database/bill_relation_model.dart';
import 'package:jive/core/database/installment_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/installment_service.dart';
import 'package:jive/core/service/reimbursement_service.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late InstallmentService installmentService;
  late ReimbursementService reimbursementService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pubCache =
        Platform.environment['PUB_CACHE'] ??
        '${Platform.environment['HOME']}/.pub-cache';
    String? libPath;
    if (Platform.isMacOS) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    } else if (Platform.isLinux) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/linux/libisar.so';
    } else if (Platform.isWindows) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/windows/isar.dll';
    }
    if (libPath == null || !File(libPath).existsSync()) {
      throw StateError('Isar core library not found for tests.');
    }
    await Isar.initializeIsarCore(libraries: {Abi.current(): libPath});
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('jive_install_refund_test_');
    isar = await Isar.open([
      JiveAccountSchema,
      JiveAutoDraftSchema,
      JiveTransactionSchema,
      JiveInstallmentSchema,
      JiveBillRelationSchema,
    ], directory: dir.path);
    installmentService = InstallmentService(isar);
    reimbursementService = ReimbursementService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  Future<JiveAccount> seedCreditAccount() async {
    final account = JiveAccount()
      ..key = 'acct_credit_test'
      ..name = '测试信用卡'
      ..type = 'liability'
      ..subType = 'credit'
      ..groupName = '信用账户'
      ..currency = 'CNY'
      ..iconName = 'credit_card'
      ..colorHex = '#EF5350'
      ..order = 1
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveAccount>().put(account);
    });
    return account;
  }

  test(
    'buildPlanPreview splits principal and fee with average_first',
    () async {
      final account = await seedCreditAccount();
      final installment = JiveInstallment()
        ..key = 'ins_preview'
        ..name = 'iPhone 分期'
        ..accountId = account.id
        ..currency = 'CNY'
        ..principalAmount = 1000
        ..totalFee = 60
        ..totalPeriods = 3
        ..feeType = InstallmentFeeType.average.value
        ..remainderType = InstallmentRemainderType.averageFirst.value
        ..startDate = DateTime(2026, 1, 10, 9, 30)
        ..nextDueAt = DateTime(2026, 1, 10, 9, 30);

      final plan = installmentService.buildPlanPreview(installment);

      expect(plan.length, 3);
      expect(plan[0].principal, 333.34);
      expect(plan[1].principal, 333.33);
      expect(plan[2].principal, 333.33);
      expect(plan[0].fee, 20.0);
      expect(plan[1].fee, 20.0);
      expect(plan[2].fee, 20.0);
      final principalSum = plan.fold<double>(0, (p, e) => p + e.principal);
      final feeSum = plan.fold<double>(0, (p, e) => p + e.fee);
      expect(principalSum, closeTo(1000, 0.001));
      expect(feeSum, closeTo(60, 0.001));
    },
  );

  test('processDueInstallments in draft mode is idempotent', () async {
    final account = await seedCreditAccount();
    final installment = JiveInstallment()
      ..key = 'ins_draft_1'
      ..name = '测试分期'
      ..accountId = account.id
      ..currency = 'CNY'
      ..principalAmount = 200
      ..totalFee = 0
      ..totalPeriods = 2
      ..feeType = InstallmentFeeType.average.value
      ..remainderType = InstallmentRemainderType.averageFirst.value
      ..commitMode = InstallmentCommitMode.draft.value
      ..startDate = DateTime(2026, 1, 1, 10)
      ..nextDueAt = DateTime(2026, 1, 1, 10);
    await installmentService.createInstallment(installment);

    final first = await installmentService.processDueInstallments(
      now: DateTime(2026, 1, 1, 23, 59),
    );
    expect(first.generatedDrafts, 1);
    expect(first.committedTransactions, 0);

    final second = await installmentService.processDueInstallments(
      now: DateTime(2026, 1, 1, 23, 59),
    );
    expect(second.generatedDrafts, 0);
    expect(second.committedTransactions, 0);

    final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
    expect(drafts.length, 1);
  });

  test(
    'processDueInstallments in commit mode creates transaction and finishes',
    () async {
      final account = await seedCreditAccount();
      final installment = JiveInstallment()
        ..key = 'ins_commit_1'
        ..name = '测试分期入账'
        ..accountId = account.id
        ..currency = 'CNY'
        ..principalAmount = 120
        ..totalFee = 12
        ..totalPeriods = 1
        ..feeType = InstallmentFeeType.first.value
        ..remainderType = InstallmentRemainderType.averageFirst.value
        ..commitMode = InstallmentCommitMode.commit.value
        ..startDate = DateTime(2026, 2, 1, 9)
        ..nextDueAt = DateTime(2026, 2, 1, 9);
      await installmentService.createInstallment(installment);

      final result = await installmentService.processDueInstallments(
        now: DateTime(2026, 2, 2),
      );
      expect(result.generatedDrafts, 0);
      expect(result.committedTransactions, 1);
      expect(result.finishedInstallments, 1);

      final txs = await isar.collection<JiveTransaction>().where().findAll();
      expect(txs.length, 1);
      expect(txs.first.amount, 132);
      expect(txs.first.type, 'expense');

      final refreshed = await isar
          .collection<JiveInstallment>()
          .where()
          .findFirst();
      expect(refreshed, isNotNull);
      expect(refreshed!.status, InstallmentStatus.finished.value);
      expect(refreshed.isActive, isFalse);
    },
  );

  test('reimbursement and refund create linked bills and summary', () async {
    final account = await seedCreditAccount();
    final source = JiveTransaction()
      ..amount = 100
      ..source = 'Manual'
      ..timestamp = DateTime(2026, 3, 1, 8)
      ..type = 'expense'
      ..accountId = account.id
      ..categoryKey = 'food'
      ..subCategoryKey = 'lunch';
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(source);
    });

    final reimburseTx = await reimbursementService.createReimbursement(
      sourceTransactionId: source.id,
      amount: 70,
      accountId: account.id,
      timestamp: DateTime(2026, 3, 2, 9),
    );
    expect(reimburseTx.type, 'income');

    final refundTx = await reimbursementService.createRefund(
      sourceTransactionId: source.id,
      amount: 20,
      accountId: account.id,
      timestamp: DateTime(2026, 3, 3, 10),
    );
    expect(refundTx.type, 'income');

    final summary = await reimbursementService.getSettlementSummary(source.id);
    expect(summary.reimbursementCount, 1);
    expect(summary.refundCount, 1);
    expect(summary.reimbursementTotal, 70);
    expect(summary.refundTotal, 20);
    expect(summary.netRecovered, 90);
  });

  test('refund count is capped at 25 per source bill', () async {
    final account = await seedCreditAccount();
    final source = JiveTransaction()
      ..amount = 500
      ..source = 'Manual'
      ..timestamp = DateTime(2026, 4, 1)
      ..type = 'expense'
      ..accountId = account.id;
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(source);
    });

    for (var i = 0; i < ReimbursementService.maxRefundCountPerBill; i++) {
      await reimbursementService.createRefund(
        sourceTransactionId: source.id,
        amount: 1,
        accountId: account.id,
      );
    }

    expect(
      () => reimbursementService.createRefund(
        sourceTransactionId: source.id,
        amount: 1,
        accountId: account.id,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
