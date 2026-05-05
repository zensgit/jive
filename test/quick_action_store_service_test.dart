import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:jive/core/database/quick_action_model.dart';
import 'package:jive/core/database/template_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/model/quick_action.dart';
import 'package:jive/core/service/quick_action_service.dart';
import 'package:jive/core/service/quick_action_store_service.dart';

void main() {
  late Directory dir;
  late Isar isar;
  late QuickActionService service;
  late QuickActionStoreService store;

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
    dir = await Directory.systemTemp.createTemp('jive_quick_action_test_');
    isar = await Isar.open([
      JiveTemplateSchema,
      JiveQuickActionSchema,
      JiveTransactionSchema,
    ], directory: dir.path);
    service = QuickActionService(isar);
    store = QuickActionStoreService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('syncs templates into persistent quick actions', () async {
    final templateId = await _putTemplate(
      isar,
      _template(
        name: '早餐',
        amount: 15,
        accountId: 7,
        categoryKey: 'food',
        category: '餐饮',
        usageCount: 3,
        isPinned: true,
      ),
    );

    final actions = await service.getActions();

    expect(actions, hasLength(1));
    expect(actions.single.id, 'template:$templateId');
    expect(actions.single.name, '早餐');
    expect(actions.single.mode, QuickActionMode.direct);
    expect(actions.single.defaultAmount, 15);
    expect(actions.single.legacyTemplateId, templateId);

    final records = await isar.jiveQuickActions.where().findAll();
    expect(records, hasLength(1));
    expect(records.single.stableId, 'template:$templateId');
    expect(records.single.source, 'template');
    expect(records.single.legacyTemplateId, templateId);
    expect(records.single.usageCount, 3);
    expect(records.single.archived, isFalse);
  });

  test('findActionById resolves persistent and legacy template ids', () async {
    final templateId = await _putTemplate(
      isar,
      _template(name: '午餐', accountId: 8, categoryKey: 'food'),
    );

    final persistent = await service.findActionById('template:$templateId');
    final legacy = await service.findActionById('$templateId');

    expect(persistent, isNotNull);
    expect(persistent!.mode, QuickActionMode.confirm);
    expect(legacy, isNotNull);
    expect(legacy!.id, 'template:$templateId');
  });

  test('markUsed updates quick action and legacy template usage', () async {
    final templateId = await _putTemplate(
      isar,
      _template(
        name: '咖啡',
        amount: 18,
        accountId: 7,
        categoryKey: 'food',
        usageCount: 2,
      ),
    );
    final action = (await service.getActions()).single;

    await service.markUsed(action);

    final record = await isar.jiveQuickActions.getByStableId(
      'template:$templateId',
    );
    final template = await isar.jiveTemplates.get(templateId);

    expect(record, isNotNull);
    expect(record!.usageCount, 3);
    expect(record.lastUsedAt, isNotNull);
    expect(template, isNotNull);
    expect(template!.usageCount, 3);
    expect(template.lastUsedAt, isNotNull);
  });

  test('presentation metadata survives template sync', () async {
    final templateId = await _putTemplate(
      isar,
      _template(
        name: '咖啡',
        amount: 18,
        accountId: 7,
        categoryKey: 'food',
        usageCount: 2,
      ),
    );
    await service.getActions();

    await store.updatePresentation(
      'template:$templateId',
      iconName: 'local_cafe',
      colorHex: '#EF6C00',
      showOnHome: false,
      isPinned: true,
    );
    await store.syncFromTemplates();

    final record = await isar.jiveQuickActions.getByStableId(
      'template:$templateId',
    );
    final template = await isar.jiveTemplates.get(templateId);
    final visibleActions = await service.getActions();
    final hiddenAction = await service.findActionById('template:$templateId');

    expect(record, isNotNull);
    expect(record!.iconName, 'local_cafe');
    expect(record.colorHex, '#EF6C00');
    expect(record.showOnHome, isFalse);
    expect(record.isPinned, isTrue);
    expect(template!.isPinned, isTrue);
    expect(visibleActions, isEmpty);
    expect(hiddenAction, isNotNull);
    expect(hiddenAction!.id, 'template:$templateId');
  });

  test('moveAction updates manual order', () async {
    final firstId = await _putTemplate(
      isar,
      _template(name: '早餐', amount: 10, accountId: 1, categoryKey: 'food'),
    );
    final secondId = await _putTemplate(
      isar,
      _template(name: '午餐', amount: 20, accountId: 1, categoryKey: 'food'),
    );
    expect((await service.getActions()).map((action) => action.id), [
      'template:$firstId',
      'template:$secondId',
    ]);

    await store.moveAction('template:$secondId', -1);

    expect((await service.getActions()).map((action) => action.id), [
      'template:$secondId',
      'template:$firstId',
    ]);
  });

  test('saveTransaction writes transaction and marks action used', () async {
    final templateId = await _putTemplate(
      isar,
      _template(
        name: '早餐',
        amount: 15,
        accountId: 7,
        categoryKey: 'food',
        category: '餐饮',
      ),
    );
    final action = (await service.getActions()).single;

    final tx = await service.saveTransaction(action);

    expect(tx.id, greaterThan(0));
    expect(tx.source, 'quick_action');
    expect(tx.amount, 15);
    expect(tx.accountId, 7);
    expect(tx.categoryKey, 'food');
    expect(tx.quickActionId, templateId);

    final record = await isar.jiveQuickActions.getByStableId(
      'template:$templateId',
    );
    expect(record!.usageCount, 1);
  });

  test(
    'archives template-backed quick actions when template is removed',
    () async {
      final templateId = await _putTemplate(
        isar,
        _template(name: '旧模板', amount: 10, accountId: 1, categoryKey: 'food'),
      );
      expect(await service.getActions(), hasLength(1));

      await isar.writeTxn(() async {
        await isar.jiveTemplates.delete(templateId);
      });
      final actions = await service.getActions();
      final record = await isar.jiveQuickActions.getByStableId(
        'template:$templateId',
      );

      expect(actions, isEmpty);
      expect(record, isNotNull);
      expect(record!.archived, isTrue);
    },
  );
}

Future<int> _putTemplate(Isar isar, JiveTemplate template) async {
  return isar.writeTxn(() async {
    return isar.jiveTemplates.put(template);
  });
}

JiveTemplate _template({
  required String name,
  String type = 'expense',
  double amount = 0,
  int? accountId,
  int? toAccountId,
  String? categoryKey,
  String? subCategoryKey,
  String? category,
  String? subCategory,
  String? note,
  int usageCount = 0,
  bool isPinned = false,
}) {
  return JiveTemplate()
    ..name = name
    ..type = type
    ..amount = amount
    ..accountId = accountId
    ..toAccountId = toAccountId
    ..categoryKey = categoryKey
    ..subCategoryKey = subCategoryKey
    ..category = category
    ..subCategory = subCategory
    ..note = note
    ..usageCount = usageCount
    ..isPinned = isPinned
    ..createdAt = DateTime(2026, 5, 5, 9);
}
