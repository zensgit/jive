import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/service/category_share_service.dart';

void main() {
  late Directory dir;
  late Isar isar;
  late CategoryShareService service;

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
    dir = await Directory.systemTemp.createTemp('jive_category_share_test_');
    isar = await Isar.open([
      JiveCategorySchema,
      JiveCategoryOverrideSchema,
    ], directory: dir.path);
    service = CategoryShareService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('previewNames shows full three-level category paths', () {
    final jsonData = jsonEncode([
      {'key': 'transport', 'name': '出行', 'parentKey': null},
      {'key': 'car', 'name': '私家车', 'parentKey': 'transport'},
      {'key': 'fuel', 'name': '加油', 'parentKey': 'car'},
    ]);

    expect(service.previewNames(jsonData), ['出行', '出行 / 私家车', '出行 / 私家车 / 加油']);
  });

  test('export and import preserve three-level parent keys', () async {
    final transport = _category(key: 'transport', name: '出行');
    final car = _category(key: 'car', name: '私家车', parentKey: transport.key);
    final fuel = _category(key: 'fuel', name: '加油', parentKey: car.key);

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().putAll([transport, car, fuel]);
    });

    final export = await service.exportCategories();
    expect(export.categoryCount, 3);
    expect(service.previewNames(export.jsonData), [
      '出行',
      '出行 / 私家车',
      '出行 / 私家车 / 加油',
    ]);

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().clear();
    });

    final imported = await service.importCategories(export.jsonData);
    expect(imported, 3);

    final categories = await isar.collection<JiveCategory>().where().findAll();
    final byKey = {for (final category in categories) category.key: category};
    expect(byKey['transport']?.parentKey, isNull);
    expect(byKey['car']?.parentKey, 'transport');
    expect(byKey['fuel']?.parentKey, 'car');
  });
}

JiveCategory _category({
  required String key,
  required String name,
  String? parentKey,
}) {
  return JiveCategory()
    ..key = key
    ..name = name
    ..parentKey = parentKey
    ..iconName = 'category'
    ..order = 0
    ..isSystem = false
    ..isHidden = false
    ..isIncome = false
    ..updatedAt = DateTime(2026, 5, 10);
}
