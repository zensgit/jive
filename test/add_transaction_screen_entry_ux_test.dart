import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/merchant_memory_model.dart';
import 'package:jive/core/database/project_model.dart';
import 'package:jive/core/database/tag_model.dart';
import 'package:jive/core/database/tag_rule_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/utils/logger_util.dart';
import 'package:jive/feature/transactions/add_transaction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  late _AddTransactionHarness harness;
  late Directory loggerDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupGoogleFontsForTests();
    loggerDir = await Directory.systemTemp.createTemp(
      'jive_add_transaction_logger_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return loggerDir.path;
            }
            return null;
          },
        );
    await JiveLogger.init();

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
    SharedPreferences.setMockInitialValues({
      'budget_save_alert_enabled': false,
    });
    harness = await _AddTransactionHarness.open();
    await harness.seed();
  });

  tearDown(() async {
    await harness.dispose();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (loggerDir.existsSync()) {
      loggerDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'add transaction entry saves expression result inline note and custom category',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool? savedResult;
      JiveTransaction? savedTransaction;
      var saverCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                savedResult = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      isar: harness.isar,
                      bootstrapDefaults: false,
                      initialParentCategories: [harness.parent],
                      initialSubCategories: [harness.child],
                      initialAccounts: [harness.account],
                      initialAccountBalances: {harness.account.id: 0},
                      initialTags: const [],
                      initialProjects: const [],
                      smartTagResolver: (_) async => const [],
                      transactionSaver: (tx) async {
                        saverCalls++;
                        savedTransaction = tx;
                      },
                    ),
                  ),
                );
              },
              child: const Text('open add transaction'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open add transaction'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await _pumpUntilFound(
        tester,
        find.byKey(AddTransactionScreenKeys.amountKey('1')),
      );

      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('1')));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('+')));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('2')));
      await tester.longPress(
        find.byKey(AddTransactionScreenKeys.amountKey('+')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('+')));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('3')));
      await tester.pump();

      expect(
        tester
            .widget<Text>(find.byKey(AddTransactionScreenKeys.amountFormula))
            .data,
        contains('1+2×3'),
      );
      expect(
        tester
            .widget<Text>(find.byKey(AddTransactionScreenKeys.amountResult))
            .data,
        contains('7'),
      );

      await tester.tap(
        find.byKey(AddTransactionScreenKeys.subCategory('custom_coffee')),
      );
      await tester.pump();

      await tester.tap(find.byKey(AddTransactionScreenKeys.noteCollapsed));
      await tester.pump();
      await tester.enterText(
        find.byKey(AddTransactionScreenKeys.noteTextField),
        '内联备注',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      final saveButton = find.byKey(AddTransactionScreenKeys.saveButton);
      expect(saveButton, findsOneWidget);
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      expect(saverCalls, 1);
      await _pumpUntilFound(tester, find.text('open add transaction'));

      expect(savedResult, isTrue);
      expect(savedTransaction, isNotNull);
      final tx = savedTransaction!;
      expect(tx.amount, 7);
      expect(tx.note, '内联备注');
      expect(tx.categoryKey, 'custom_food');
      expect(tx.subCategoryKey, 'custom_coffee');
      expect(tx.category, '自定义餐饮');
      expect(tx.subCategory, '自制咖啡');
      expect(tx.type, 'expense');
      expect(tx.source, 'Manual');
      expect(tx.accountId, harness.account.id);
    },
  );

  testWidgets(
    'add transaction entry shows invalid state for divide by zero and blocks save',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var saverCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      isar: harness.isar,
                      bootstrapDefaults: false,
                      initialParentCategories: [harness.parent],
                      initialSubCategories: [harness.child],
                      initialAccounts: [harness.account],
                      initialAccountBalances: {harness.account.id: 0},
                      initialTags: const [],
                      initialProjects: const [],
                      smartTagResolver: (_) async => const [],
                      transactionSaver: (_) async {
                        saverCalls++;
                      },
                    ),
                  ),
                );
              },
              child: const Text('open add transaction'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open add transaction'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await _pumpUntilFound(
        tester,
        find.byKey(AddTransactionScreenKeys.amountKey('1')),
      );

      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('1')));
      await tester.longPress(
        find.byKey(AddTransactionScreenKeys.amountKey('-')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('-')));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('0')));
      await tester.pump();

      expect(
        tester
            .widget<Text>(find.byKey(AddTransactionScreenKeys.amountFormula))
            .data,
        contains('1÷0'),
      );
      expect(
        tester
            .widget<Text>(find.byKey(AddTransactionScreenKeys.amountResult))
            .data,
        '无效',
      );

      await tester.tap(
        find.byKey(AddTransactionScreenKeys.subCategory('custom_coffee')),
      );
      await tester.pump();
      await tester.tap(find.byKey(AddTransactionScreenKeys.saveButton));
      await tester.pump();

      expect(find.text('算式无效，请调整后再保存'), findsOneWidget);
      expect(saverCalls, 0);
      expect(
        find.byKey(AddTransactionScreenKeys.amountKey('1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'continuous entry save resets operator toggle state for next transaction',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var saverCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      isar: harness.isar,
                      bootstrapDefaults: false,
                      initialParentCategories: [harness.parent],
                      initialSubCategories: [harness.child],
                      initialAccounts: [harness.account],
                      initialAccountBalances: {harness.account.id: 0},
                      initialTags: const [],
                      initialProjects: const [],
                      smartTagResolver: (_) async => const [],
                      transactionSaver: (_) async {
                        saverCalls++;
                      },
                    ),
                  ),
                );
              },
              child: const Text('open add transaction'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open add transaction'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await _pumpUntilFound(
        tester,
        find.byKey(AddTransactionScreenKeys.amountKey('1')),
      );

      final plusKey = find.byKey(AddTransactionScreenKeys.amountKey('+'));
      final minusKey = find.byKey(AddTransactionScreenKeys.amountKey('-'));

      await tester.longPress(plusKey);
      await tester.longPress(minusKey);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(of: plusKey, matching: find.text('当前×')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: minusKey, matching: find.text('当前÷')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('AGAIN')));
      await tester.pump();
      expect(find.text('连续记账：开'), findsOneWidget);

      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('1')));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('+')));
      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('2')));
      await tester.pump();
      await tester.tap(
        find.byKey(AddTransactionScreenKeys.subCategory('custom_coffee')),
      );
      await tester.pump();

      await tester.tap(find.byKey(AddTransactionScreenKeys.saveButton));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      expect(saverCalls, 1);
      expect(
        tester
            .widget<Text>(find.byKey(AddTransactionScreenKeys.amountResult))
            .data,
        contains('0'),
      );
      expect(
        find.descendant(of: plusKey, matching: find.text('长按×')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: minusKey, matching: find.text('长按÷')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: plusKey, matching: find.text('当前×')),
        findsNothing,
      );
      expect(
        find.descendant(of: minusKey, matching: find.text('当前÷')),
        findsNothing,
      );
    },
  );
}

class _AddTransactionHarness {
  final Directory dir;
  final Isar isar;
  late JiveAccount account;
  late JiveCategory parent;
  late JiveCategory child;

  _AddTransactionHarness({required this.dir, required this.isar});

  static Future<_AddTransactionHarness> open() async {
    final dir = await Directory.systemTemp.createTemp(
      'jive_add_transaction_test_',
    );
    final isar = await Isar.open([
      JiveAccountSchema,
      JiveCategorySchema,
      JiveCategoryOverrideSchema,
      JiveTransactionSchema,
      JiveTagSchema,
      JiveTagGroupSchema,
      JiveTagRuleSchema,
      JiveProjectSchema,
      JiveMerchantMemorySchema,
    ], directory: dir.path);
    return _AddTransactionHarness(dir: dir, isar: isar);
  }

  Future<void> seed() async {
    final now = DateTime(2026, 4, 22);
    account = JiveAccount()
      ..key = 'cash'
      ..name = '现金'
      ..type = 'asset'
      ..subType = 'cash'
      ..groupName = '现金'
      ..currency = 'CNY'
      ..iconName = 'account_balance_wallet'
      ..order = 0
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..openingBalance = 0
      ..updatedAt = now;

    parent = JiveCategory()
      ..key = 'custom_food'
      ..name = '自定义餐饮'
      ..iconName = 'restaurant'
      ..order = -100
      ..isSystem = false
      ..isHidden = false
      ..isIncome = false
      ..updatedAt = now;
    child = JiveCategory()
      ..key = 'custom_coffee'
      ..name = '自制咖啡'
      ..iconName = 'local_cafe'
      ..parentKey = parent.key
      ..order = 0
      ..isSystem = false
      ..isHidden = false
      ..isIncome = false
      ..updatedAt = now;

    await isar.writeTxn(() async {
      account.id = await isar.jiveAccounts.put(account);
      await isar.jiveCategorys.putAll([parent, child]);
    });
  }

  Future<void> dispose() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}
