import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/auto_draft_model.dart';
import 'package:jive/core/database/recurring_rule_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/recurring_service.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late RecurringService service;

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
    if (libPath != null && File(libPath).existsSync()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): libPath});
    } else {
      throw StateError('Isar core library not found for tests.');
    }
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('jive_recurring_test_');
    isar = await Isar.open([
      JiveRecurringRuleSchema,
      JiveAutoDraftSchema,
      JiveTransactionSchema,
    ], directory: dir.path);
    service = RecurringService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test(
    'draft mode processes due rule once and dedups by recurringKey',
    () async {
      final rule = await service.createRule(
        _buildRule(
          name: '测试草稿规则',
          commitMode: 'draft',
          intervalType: 'day',
          intervalValue: 1,
          startDate: DateTime(2024, 1, 1),
        ),
      );

      final first = await service.processDueRules(
        now: DateTime(2024, 1, 1, 23),
      );
      final second = await service.processDueRules(
        now: DateTime(2024, 1, 1, 23),
      );

      expect(first.generatedDrafts, 1);
      expect(first.committedTransactions, 0);
      expect(second.generatedDrafts, 0);
      expect(second.committedTransactions, 0);

      final drafts = await isar.collection<JiveAutoDraft>().where().findAll();
      expect(drafts.length, 1);
      expect(drafts.first.recurringRuleId, rule.id);
      expect(drafts.first.recurringKey, isNotNull);
    },
  );

  test('commit mode processes due rule once and dedups transactions', () async {
    final rule = await service.createRule(
      _buildRule(
        name: '测试入账规则',
        commitMode: 'commit',
        intervalType: 'day',
        intervalValue: 1,
        startDate: DateTime(2024, 2, 1),
      ),
    );

    final first = await service.processDueRules(now: DateTime(2024, 2, 1, 23));
    final second = await service.processDueRules(now: DateTime(2024, 2, 1, 23));

    expect(first.generatedDrafts, 0);
    expect(first.committedTransactions, 1);
    expect(second.generatedDrafts, 0);
    expect(second.committedTransactions, 0);

    final transactions = await isar
        .collection<JiveTransaction>()
        .where()
        .findAll();
    expect(transactions.length, 1);
    expect(transactions.first.recurringRuleId, rule.id);
    expect(transactions.first.recurringKey, isNotNull);
  });

  test('dayOfMonth=31 handles cross-month catch-up correctly', () async {
    final rule = await service.createRule(
      _buildRule(
        name: '月末扣款',
        commitMode: 'draft',
        intervalType: 'month',
        intervalValue: 1,
        dayOfMonth: 31,
        startDate: DateTime(2024, 1, 31),
      ),
    );

    final result = await service.processDueRules(
      now: DateTime(2024, 3, 31, 23, 59, 59),
    );

    expect(result.generatedDrafts, 3);
    expect(result.committedTransactions, 0);

    final savedRule = await isar.collection<JiveRecurringRule>().get(rule.id);
    expect(savedRule, isNotNull);
    expect(savedRule!.nextRunAt, DateTime(2024, 4, 30));
  });

  test('inactive rules are skipped', () async {
    await service.createRule(
      _buildRule(
        name: '停用规则',
        commitMode: 'draft',
        intervalType: 'day',
        intervalValue: 1,
        startDate: DateTime(2024, 1, 1),
        isActive: false,
      ),
    );

    final result = await service.processDueRules(now: DateTime(2024, 1, 10));
    expect(result.generatedDrafts, 0);
    expect(result.committedTransactions, 0);
    expect(await isar.collection<JiveAutoDraft>().count(), 0);
    expect(await isar.collection<JiveTransaction>().count(), 0);
  });

  test('weekly normalization uses next future weekday', () async {
    final rule = await service.createRule(
      _buildRule(
        name: '每周一执行',
        commitMode: 'draft',
        intervalType: 'week',
        intervalValue: 1,
        dayOfWeek: DateTime.monday,
        startDate: DateTime(2024, 1, 3, 9), // Wednesday
      ),
    );

    expect(rule.nextRunAt, DateTime(2024, 1, 8, 9));
  });

  test('updateRule recalculates nextRunAt when schedule changes', () async {
    final created = await service.createRule(
      _buildRule(
        name: '周期更新测试',
        commitMode: 'draft',
        intervalType: 'month',
        intervalValue: 1,
        dayOfMonth: 10,
        startDate: DateTime(2024, 1, 10),
      ),
    );

    created
      ..startDate = DateTime(2024, 2, 20)
      ..dayOfMonth = 25
      ..intervalType = 'month'
      ..intervalValue = 1;
    await service.updateRule(created);

    final saved = await isar.collection<JiveRecurringRule>().get(created.id);
    expect(saved, isNotNull);
    expect(saved!.nextRunAt, DateTime(2024, 2, 25));
    expect(saved.lastRunAt, isNull);
  });

  test(
    'processDueRules clamps invalid intervalValue to avoid infinite loop',
    () async {
      final created = await service.createRule(
        _buildRule(
          name: '非法间隔防护',
          commitMode: 'draft',
          intervalType: 'day',
          intervalValue: 1,
          startDate: DateTime(2024, 1, 1),
        ),
      );

      await isar.writeTxn(() async {
        created.intervalValue = 0;
        await isar.collection<JiveRecurringRule>().put(created);
      });

      final result = await service.processDueRules(
        now: DateTime(2024, 1, 1, 12),
      );
      expect(result.generatedDrafts, 1);

      final saved = await isar.collection<JiveRecurringRule>().get(created.id);
      expect(saved, isNotNull);
      expect(saved!.intervalValue, 1);
      expect(saved.nextRunAt.isAfter(DateTime(2024, 1, 1, 12)), isTrue);
    },
  );
}

JiveRecurringRule _buildRule({
  required String name,
  required String commitMode,
  required String intervalType,
  required int intervalValue,
  required DateTime startDate,
  int? dayOfMonth,
  int? dayOfWeek,
  bool isActive = true,
}) {
  final now = DateTime.now();
  return JiveRecurringRule()
    ..name = name
    ..type = 'expense'
    ..amount = 100
    ..accountId = 1
    ..toAccountId = null
    ..categoryKey = 'cat_food'
    ..subCategoryKey = 'cat_food_breakfast'
    ..note = null
    ..tagKeys = const []
    ..projectId = null
    ..commitMode = commitMode
    ..startDate = startDate
    ..endDate = null
    ..intervalType = intervalType
    ..intervalValue = intervalValue
    ..dayOfMonth = dayOfMonth
    ..dayOfWeek = dayOfWeek
    ..nextRunAt = startDate
    ..lastRunAt = null
    ..isActive = isActive
    ..createdAt = now
    ..updatedAt = now;
}
