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

  testWidgets(
    'ImportCenter supports preview duplicate resolution and confirm import',
    (tester) async {
      final isar = await DatabaseService.getInstance();
      final existing = JiveTransaction()
        ..amount = 18.8
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 3, 15, 8, 0)
        ..rawText = '早餐'
        ..type = 'expense';

      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().put(existing);
      });

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
          '2026-03-15 08:00,18.80,WeChat,expense,早餐\n'
          '2026-03-15 08:05,18.80,WeChat,expense,早餐\n'
          '2026-03-15 09:00,52.00,Alipay,expense,午餐';
      await tester.enterText(textField, payload);
      await _pumpUntilSettled(tester);

      await _tapVisibleText(tester, '解析文本到预览区');

      expect(find.text('导入预览（先勾选，再导入）'), findsOneWidget);
      expect(find.text('批内重复 1'), findsOneWidget);
      expect(find.text('历史重复 2'), findsOneWidget);
      expect(find.text('高风险 2'), findsOneWidget);

      await _tapVisibleText(tester, '重复: 全跳过');
      expect(find.text('已跳过全部高风险重复项'), findsOneWidget);
      expect(find.text('已选择 1'), findsOneWidget);

      await _tapVisibleText(tester, '确认导入所选记录');
      expect(find.textContaining('导入完成：新增 1'), findsOneWidget);

      final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
      expect(drafts.length, 1);
      expect(drafts.first.amount, 52);
      expect(drafts.first.source, 'Alipay');

      final jobs = await isar
          .collection<JiveImportJob>()
          .where()
          .sortByCreatedAtDesc()
          .findAll();
      expect(jobs, isNotEmpty);
      expect(jobs.first.insertedCount, 1);
      expect(jobs.first.totalCount, 1);
      expect(jobs.first.duplicateCount, 0);
      expect(jobs.first.invalidCount, 0);
    },
  );
}
