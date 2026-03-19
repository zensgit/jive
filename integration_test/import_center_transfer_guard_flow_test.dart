import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/auto_draft_model.dart';
import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/core/database/import_job_record_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/database_service.dart';
import 'package:jive/feature/import/import_center_screen.dart';

Future<void> _pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 40,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) return;
  }
}

Future<void> _resetImportState() async {
  final isar = await DatabaseService.getInstance();
  await isar.writeTxn(() async {
    await isar.collection<JiveImportJobRecord>().clear();
    await isar.collection<JiveImportJob>().clear();
    await isar.collection<JiveAutoDraft>().clear();
    await isar.collection<JiveTransaction>().clear();
    await isar.collection<JiveAccount>().clear();
  });
}

Future<void> _seedAccounts() async {
  final isar = await DatabaseService.getInstance();
  await isar.writeTxn(() async {
    await isar.collection<JiveAccount>().putAll([
      JiveAccount()
        ..key = 'acct_wechat'
        ..name = '微信'
        ..type = 'asset'
        ..currency = 'CNY'
        ..iconName = 'wallet'
        ..order = 0
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = DateTime(2026, 3, 15),
      JiveAccount()
        ..key = 'acct_bank'
        ..name = '招商银行'
        ..type = 'asset'
        ..currency = 'CNY'
        ..iconName = 'bank'
        ..order = 1
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = DateTime(2026, 3, 15),
    ]);
  });
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text).first,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await _pumpUntilSettled(tester);
  await tester.tap(find.text(text).first, warnIfMissed: false);
  await _pumpUntilSettled(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _resetImportState();
    await _seedAccounts();
  });

  tearDown(() async {
    await _resetImportState();
  });

  testWidgets('ImportCenter blocks transfer import without target account', (
    tester,
  ) async {
    final isar = await DatabaseService.getInstance();

    await tester.pumpWidget(const MaterialApp(home: ImportCenterScreen()));
    await _pumpUntilSettled(tester, maxSteps: 60);

    final textField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == '粘贴账单文本，支持微信/支付宝/OCR 导出文本',
    );
    expect(textField, findsOneWidget);

    const payload =
        '账户,交易时间,金额,手续费,备注\n'
        '微信,2026-03-15 09:00,188.80,1.50,转账到储蓄卡';
    await tester.enterText(textField, payload);
    await _pumpUntilSettled(tester);

    await _tapVisibleText(tester, '解析文本到预览区');

    expect(find.text('导入预览（先勾选，再导入）'), findsOneWidget);
    expect(find.text('确认导入所选记录'), findsOneWidget);

    await _tapVisibleText(tester, '确认导入所选记录');

    expect(find.text('转账导入校验'), findsOneWidget);
    expect(find.textContaining('存在 1 条阻断项'), findsOneWidget);
    expect(find.text('• 第 2 行: [阻断] 缺少转入账户'), findsOneWidget);

    await _tapVisibleText(tester, '返回检查');

    final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
    expect(drafts, isEmpty);
  });

  testWidgets(
    'ImportCenter blocks transfer import for unknown target account',
    (tester) async {
      final isar = await DatabaseService.getInstance();

      await tester.pumpWidget(const MaterialApp(home: ImportCenterScreen()));
      await _pumpUntilSettled(tester, maxSteps: 60);

      final textField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == '粘贴账单文本，支持微信/支付宝/OCR 导出文本',
      );
      expect(textField, findsOneWidget);

      const payload =
          '账户,转入账户,交易时间,金额,手续费,备注\n'
          '微信,建设银行,2026-03-15 09:00,188.80,1.50,转账到储蓄卡';
      await tester.enterText(textField, payload);
      await _pumpUntilSettled(tester);

      await _tapVisibleText(tester, '解析文本到预览区');

      expect(find.text('导入预览（先勾选，再导入）'), findsOneWidget);
      expect(find.text('确认导入所选记录'), findsOneWidget);

      await _tapVisibleText(tester, '确认导入所选记录');

      expect(find.text('转账导入校验'), findsOneWidget);
      expect(find.textContaining('存在 1 条阻断项'), findsOneWidget);
      expect(find.text('• 第 2 行: [阻断] 转入账户未在当前账户列表中命中: 建设银行'), findsOneWidget);

      await _tapVisibleText(tester, '返回检查');

      final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
      expect(drafts, isEmpty);
    },
  );
}
