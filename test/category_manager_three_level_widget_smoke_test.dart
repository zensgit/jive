import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/book_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/utils/logger_util.dart';
import 'package:jive/feature/category/category_create_screen.dart';
import 'package:jive/feature/category/category_manager_screen.dart';

import 'test_helpers.dart';

void main() {
  late Directory loggerDir;
  late Directory isarDir;
  late Isar isar;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupGoogleFontsForTests();
    loggerDir = await Directory.systemTemp.createTemp(
      'jive_category_manager_logger_test_',
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
    isarDir = await Directory.systemTemp.createTemp(
      'jive_category_manager_three_level_',
    );
    isar = await Isar.open([
      JiveBookSchema,
      JiveCategorySchema,
      JiveCategoryOverrideSchema,
      JiveTransactionSchema,
    ], directory: isarDir.path);
    await _seedThreeLevelBase(isar);
  });

  tearDown(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    if (isarDir.existsSync()) {
      isarDir.deleteSync(recursive: true);
    }
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
    'second-level category action opens third-level create screen with full path',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CategoryManagerScreen(
            isar: isar,
            onlyUserCategories: true,
            bootstrapDefaults: false,
            initialCategories: _threeLevelBaseCategories(),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await _pumpUntilFound(tester, find.byType(TextField));

      await tester.enterText(find.byType(TextField), '私家车');
      await _pumpUntilFound(
        tester,
        find.byKey(CategoryManagerScreenKeys.subCategory('travel_car')),
      );

      final middleChip = find.byKey(
        CategoryManagerScreenKeys.subCategory('travel_car'),
      );
      expect(middleChip, findsOneWidget);

      await tester.longPress(middleChip);
      await _pumpUntilFound(tester, find.text('添加下级分类'));

      await tester.tap(find.text('添加下级分类'));
      await _pumpUntilFound(tester, find.text('添加下级分类 · 出行 / 私家车'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('添加下级分类 · 出行 / 私家车'), findsOneWidget);
      final createScreen = tester.widget<CategoryCreateScreen>(
        find.byType(CategoryCreateScreen),
      );
      expect(createScreen.nameLabel, '下级分类名称');
    },
  );
}

Future<void> _seedThreeLevelBase(Isar isar) async {
  await isar.writeTxn(() async {
    await isar.jiveCategorys.putAll(_threeLevelBaseCategories());
  });
}

List<JiveCategory> _threeLevelBaseCategories() {
  final now = DateTime(2026, 5, 11);
  final parent = JiveCategory()
    ..key = 'travel'
    ..name = '出行'
    ..iconName = 'directions_car'
    ..order = 0
    ..isSystem = false
    ..isHidden = false
    ..isIncome = false
    ..updatedAt = now;
  final middle = JiveCategory()
    ..key = 'travel_car'
    ..name = '私家车'
    ..iconName = 'directions_car'
    ..parentKey = parent.key
    ..order = 0
    ..isSystem = false
    ..isHidden = false
    ..isIncome = false
    ..updatedAt = now;
  return [parent, middle];
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
