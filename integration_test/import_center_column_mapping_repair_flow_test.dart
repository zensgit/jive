import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

  tearDown(() async {
    await _resetImportState();
  });

  testWidgets('ImportCenter repairs blocked column mapping then imports', (
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
        '总额,交易时间,渠道,一级分类,二级分类,收支类型,备注,标签\n'
        '12.50,2026-03-15 08:00,WeChat,餐饮,早餐,支出,早餐映射修复,工作日 早餐';
    await tester.enterText(textField, payload);
    await _pumpUntilSettled(tester);

    await _tapVisibleText(tester, '解析文本到预览区');

    expect(find.text('导入预览（先勾选，再导入）'), findsOneWidget);
    expect(find.text('无效 1'), findsOneWidget);
    expect(find.text('列映射阻断导入'), findsOneWidget);

    await _tapVisibleText(tester, '检查/修复列映射');
    expect(find.byType(AlertDialog), findsOneWidget);

    final amountField = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField &&
          widget.decoration.labelText == '金额列',
    );
    expect(amountField, findsOneWidget);
    await tester.scrollUntilVisible(
      amountField,
      120,
      scrollable: find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await _pumpUntilSettled(tester);
    await tester.tap(amountField, warnIfMissed: false);
    await _pumpUntilSettled(tester);
    await tester.tap(find.text('col 1: 总额').last);
    await _pumpUntilSettled(tester);

    expect(find.text('列映射已就绪'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('应用到预览'),
      ),
      warnIfMissed: false,
    );
    await _pumpUntilSettled(tester);

    expect(find.text('无效 0'), findsOneWidget);
    expect(find.text('已选择 1'), findsOneWidget);
    expect(find.text('一级 餐饮'), findsOneWidget);
    expect(find.text('二级 早餐'), findsOneWidget);
    expect(find.text('账户 WeChat'), findsOneWidget);
    expect(find.text('标签 工作日'), findsOneWidget);

    await _tapVisibleText(tester, '确认导入所选记录');
    expect(find.textContaining('导入完成：新增 1'), findsOneWidget);

    final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
    expect(drafts.length, 1);
    expect(drafts.first.amount, 12.5);
    expect(drafts.first.source, 'WeChat');
    expect(drafts.first.category, '餐饮');
    expect(drafts.first.subCategory, '早餐');
    expect(drafts.first.tagKeys, isNotEmpty);

    final jobs = await isar
        .collection<JiveImportJob>()
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    expect(jobs, isNotEmpty);
    expect(jobs.first.insertedCount, 1);
    expect(jobs.first.invalidCount, 0);
  });
}
