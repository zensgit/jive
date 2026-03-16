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

Finder _dialogField(String labelText) {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == labelText,
    ),
  );
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

  testWidgets('ImportCenter supports preview repair before confirm import', (
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
        'date,amount,source,type,note\n'
        '2026-03-15 08:00,abc,WeChat,expense,早餐待修复\n'
        '2026-03-15 09:00,18.50,Alipay,expense,午餐';
    await tester.enterText(textField, payload);
    await _pumpUntilSettled(tester);

    await _tapVisibleText(tester, '解析文本到预览区');

    expect(find.text('导入预览（先勾选，再导入）'), findsOneWidget);
    expect(find.text('无效 1'), findsOneWidget);
    expect(find.text('已选择 1'), findsOneWidget);

    final editButton = find.byTooltip('编辑金额/时间/类型').first;
    await tester.scrollUntilVisible(
      editButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpUntilSettled(tester);
    await tester.tap(editButton, warnIfMissed: false);
    await _pumpUntilSettled(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(_dialogField('金额'), '26.80');
    await _pumpUntilSettled(tester);
    await tester.enterText(_dialogField('来源'), 'WeChat');
    await _pumpUntilSettled(tester);
    await tester.enterText(_dialogField('原文'), '早餐已修复');
    await _pumpUntilSettled(tester);

    await _tapVisibleText(tester, '保存');

    expect(find.text('无效 0'), findsOneWidget);
    expect(find.text('已选择 1'), findsOneWidget);

    await _tapVisibleText(tester, '全选有效');
    expect(find.text('已选择 2'), findsOneWidget);

    await _tapVisibleText(tester, '确认导入所选记录');
    expect(find.textContaining('导入完成：新增 2'), findsOneWidget);

    final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
    expect(drafts.length, 2);
    final amounts = drafts.map((item) => item.amount).toList()..sort();
    expect(amounts, [18.5, 26.8]);

    final jobs = await isar
        .collection<JiveImportJob>()
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    expect(jobs, isNotEmpty);
    expect(jobs.first.insertedCount, 2);
    expect(jobs.first.invalidCount, 0);
    expect(jobs.first.totalCount, 2);
  });
}
