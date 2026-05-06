import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/book_model.dart';
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
    'add transaction entry offers save current state as quick action',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AddTransactionScreen(
            isar: harness.isar,
            bootstrapDefaults: false,
            initialParentCategories: [harness.parent],
            initialSubCategories: [harness.child],
            initialAccounts: [harness.account],
            initialAccountBalances: {harness.account.id: 0},
            initialTags: const [],
            initialProjects: const [],
            smartTagResolver: (_) async => const [],
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(AddTransactionScreenKeys.amountKey('1')),
      );

      await tester.tap(find.byKey(AddTransactionScreenKeys.amountKey('1')));
      await tester.tap(
        find.byKey(AddTransactionScreenKeys.subCategory('custom_coffee')),
      );
      await tester.pump();
      await tester.tap(find.byKey(AddTransactionScreenKeys.noteCollapsed));
      await tester.pump();
      await tester.enterText(
        find.byKey(AddTransactionScreenKeys.noteTextField),
        '每天一杯',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(
        find.byKey(AddTransactionScreenKeys.saveQuickActionButton),
        findsOneWidget,
      );
    },
  );

  test('quick action seed captures amount category account and note', () {
    final seed = buildAddTransactionQuickActionSeed(
      amountText: '1+2×3',
      selectedTime: DateTime(2026, 5, 6, 9, 30),
      txType: TransactionType.expense,
      isSplitMode: false,
      selectedAccount: harness.account,
      selectedToAccount: null,
      selectedParent: harness.parent,
      selectedSub: harness.grandchild,
      categoryUniverse: [harness.parent, harness.child, harness.grandchild],
      note: ' 每天一杯 ',
      currentBookId: 42,
      widgetBookId: null,
      selectedTagKeys: const ['morning'],
    );

    expect(seed, isNotNull);
    expect(seed!.amount, 7);
    expect(seed.source, 'quick_action_seed');
    expect(seed.timestamp, DateTime(2026, 5, 6, 9, 30));
    expect(seed.type, 'expense');
    expect(seed.accountId, harness.account.id);
    expect(seed.categoryKey, 'custom_food');
    expect(seed.subCategoryKey, 'custom_pourover');
    expect(seed.category, '自定义餐饮');
    expect(seed.subCategory, '手冲');
    expect(seed.note, '每天一杯');
    expect(seed.bookId, 42);
    expect(seed.tagKeys, ['morning']);
  });

  testWidgets(
    'add transaction entry saves three-level category as top and leaf keys',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      JiveTransaction? savedTransaction;
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
                      initialSubCategories: [harness.child, harness.grandchild],
                      initialAccounts: [harness.account],
                      initialAccountBalances: {harness.account.id: 0},
                      initialTags: const [],
                      initialProjects: const [],
                      smartTagResolver: (_) async => const [],
                      transactionSaver: (tx) async {
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
      await tester.tap(
        find.byKey(AddTransactionScreenKeys.subCategory('custom_pourover')),
      );
      await tester.pump();
      await tester.tap(find.byKey(AddTransactionScreenKeys.saveButton));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });

      expect(savedTransaction, isNotNull);
      expect(savedTransaction!.categoryKey, 'custom_food');
      expect(savedTransaction!.subCategoryKey, 'custom_pourover');
      expect(savedTransaction!.category, '自定义餐饮');
      expect(savedTransaction!.subCategory, '手冲');
      expect(savedTransaction!.rawText, '自定义餐饮 / 自制咖啡 / 手冲');
    },
  );

  testWidgets('shared scene save asks before creating transaction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    JiveTransaction? savedTransaction;
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
                    initialBooks: [harness.sharedBook],
                    bookId: harness.sharedBook.id,
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
    await tester.tap(
      find.byKey(AddTransactionScreenKeys.subCategory('custom_coffee')),
    );
    await tester.pump();

    await tester.tap(find.byKey(AddTransactionScreenKeys.saveButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(AddTransactionScreenKeys.sharedSceneSaveDialog),
      findsOneWidget,
    );
    expect(find.text('保存到共享场景？'), findsOneWidget);
    expect(find.textContaining('其他成员也能看到'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(saverCalls, 0);
    expect(find.byKey(AddTransactionScreenKeys.saveButton), findsOneWidget);

    await tester.tap(find.byKey(AddTransactionScreenKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续保存'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    expect(saverCalls, 1);
    expect(savedTransaction, isNotNull);
    expect(savedTransaction!.bookId, harness.sharedBook.id);
  });

  testWidgets('local scene save does not ask for shared confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    JiveTransaction? savedTransaction;
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
                    initialBooks: [harness.localBook],
                    bookId: harness.localBook.id,
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
    await tester.tap(
      find.byKey(AddTransactionScreenKeys.subCategory('custom_coffee')),
    );
    await tester.pump();

    await tester.tap(find.byKey(AddTransactionScreenKeys.saveButton));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });

    expect(
      find.byKey(AddTransactionScreenKeys.sharedSceneSaveDialog),
      findsNothing,
    );
    expect(saverCalls, 1);
    expect(savedTransaction, isNotNull);
    expect(savedTransaction!.bookId, harness.localBook.id);
  });

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

  testWidgets('scene template prioritizes category candidates in entry UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final travelBook = _book(id: 7, key: 'book_travel', name: '✈️ 旅行出差');
    final shopping = _category(
      key: 'shopping',
      name: '购物',
      iconName: 'shopping_bag',
      order: 0,
    );
    final transport = _category(
      key: 'transport',
      name: '交通',
      iconName: 'directions_bus',
      order: 10,
    );
    final food = _category(
      key: 'food',
      name: '餐饮',
      iconName: 'restaurant',
      order: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AddTransactionScreen(
          isar: harness.isar,
          bootstrapDefaults: false,
          initialCurrentBook: travelBook,
          initialParentCategories: [shopping, food, transport],
          initialSubCategories: const [],
          initialAccounts: [harness.account],
          initialAccountBalances: {harness.account.id: 0},
          initialTags: const [],
          initialProjects: const [],
        ),
      ),
    );

    await _pumpUntilFound(
      tester,
      find.byKey(AddTransactionScreenKeys.parentCategory('transport')),
    );

    final transportLeft = tester
        .getTopLeft(
          find.byKey(AddTransactionScreenKeys.parentCategory('transport')),
        )
        .dx;
    final shoppingLeft = tester
        .getTopLeft(
          find.byKey(AddTransactionScreenKeys.parentCategory('shopping')),
        )
        .dx;

    expect(transportLeft, lessThan(shoppingLeft));
  });

  testWidgets(
    'scene book prioritizes account candidates with default fallback',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final travelBook = _book(id: 7, key: 'book_travel', name: '✈️ 旅行出差');
      final defaultCash = _account(id: 10, key: 'cash', name: '现金');
      final travelCard = _account(
        id: 11,
        key: 'travel_card',
        name: '旅行卡',
        bookId: 7,
        order: 10,
      );
      final otherBookCard = _account(
        id: 12,
        key: 'other_card',
        name: '其它账本卡',
        bookId: 8,
        order: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AddTransactionScreen(
            isar: harness.isar,
            bootstrapDefaults: false,
            initialCurrentBook: travelBook,
            initialParentCategories: [harness.parent],
            initialSubCategories: [harness.child],
            initialAccounts: [defaultCash, otherBookCard, travelCard],
            initialAccountBalances: const {10: 0, 11: 0, 12: 0},
            initialTags: const [],
            initialProjects: const [],
          ),
        ),
      );

      await _pumpUntilFound(tester, find.text('旅行卡'));
      expect(find.text('现金'), findsNothing);
    },
  );

  testWidgets('scene account candidates fall back to default book accounts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final travelBook = _book(id: 7, key: 'book_travel', name: '✈️ 旅行出差');
    final defaultCash = _account(id: 20, key: 'cash_default', name: '现金');
    final otherBookCard = _account(
      id: 21,
      key: 'other_card',
      name: '其它账本卡',
      bookId: 8,
      order: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AddTransactionScreen(
          isar: harness.isar,
          bootstrapDefaults: false,
          initialCurrentBook: travelBook,
          initialParentCategories: [harness.parent],
          initialSubCategories: [harness.child],
          initialAccounts: [otherBookCard, defaultCash],
          initialAccountBalances: const {20: 0, 21: 0},
          initialTags: const [],
          initialProjects: const [],
        ),
      ),
    );

    await _pumpUntilFound(tester, find.text('现金'));
    expect(find.text('其它账本卡'), findsNothing);
  });
}

JiveBook _book({required int id, required String key, required String name}) {
  return JiveBook()
    ..id = id
    ..key = key
    ..name = name
    ..iconName = 'book'
    ..currency = 'CNY'
    ..order = 0
    ..isDefault = false
    ..isArchived = false
    ..createdAt = DateTime(2026, 5, 11)
    ..updatedAt = DateTime(2026, 5, 11);
}

JiveCategory _category({
  required String key,
  required String name,
  required String iconName,
  int order = 0,
  String? parentKey,
}) {
  return JiveCategory()
    ..key = key
    ..name = name
    ..iconName = iconName
    ..parentKey = parentKey
    ..order = order
    ..isSystem = false
    ..isHidden = false
    ..isIncome = false
    ..updatedAt = DateTime(2026, 5, 11);
}

JiveAccount _account({
  required int id,
  required String key,
  required String name,
  int? bookId,
  int order = 0,
}) {
  return JiveAccount()
    ..id = id
    ..key = key
    ..name = name
    ..type = 'asset'
    ..subType = 'cash'
    ..groupName = '现金'
    ..currency = 'CNY'
    ..iconName = 'account_balance_wallet'
    ..bookId = bookId
    ..order = order
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..openingBalance = 0
    ..updatedAt = DateTime(2026, 5, 11);
}

class _AddTransactionHarness {
  final Directory dir;
  final Isar isar;
  late JiveAccount account;
  late JiveCategory parent;
  late JiveCategory child;
  late JiveCategory grandchild;
  late JiveBook localBook;
  late JiveBook sharedBook;

  _AddTransactionHarness({required this.dir, required this.isar});

  static Future<_AddTransactionHarness> open() async {
    final dir = await Directory.systemTemp.createTemp(
      'jive_add_transaction_test_',
    );
    final isar = await Isar.open([
      JiveAccountSchema,
      JiveBookSchema,
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
    grandchild = JiveCategory()
      ..key = 'custom_pourover'
      ..name = '手冲'
      ..iconName = 'local_drink'
      ..parentKey = child.key
      ..order = 0
      ..isSystem = false
      ..isHidden = false
      ..isIncome = false
      ..updatedAt = now;
    localBook = JiveBook()
      ..key = 'book_daily'
      ..name = '日常'
      ..currency = 'CNY'
      ..order = 0
      ..isDefault = true
      ..isArchived = false
      ..isShared = false
      ..memberCount = 1
      ..createdAt = now
      ..updatedAt = now;
    sharedBook = JiveBook()
      ..key = 'book_family'
      ..name = '家庭共享'
      ..currency = 'CNY'
      ..order = 1
      ..isDefault = false
      ..isArchived = false
      ..isShared = true
      ..sharedLedgerKey = 'ledger_family'
      ..memberCount = 2
      ..createdAt = now
      ..updatedAt = now;

    await isar.writeTxn(() async {
      account.id = await isar.jiveAccounts.put(account);
      localBook.id = await isar.jiveBooks.put(localBook);
      sharedBook.id = await isar.jiveBooks.put(sharedBook);
      await isar.jiveCategorys.putAll([parent, child, grandchild]);
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
