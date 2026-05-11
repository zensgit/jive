import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/service/category_path_service.dart';
import 'package:jive/core/service/category_service.dart';

void main() {
  late Directory dir;
  late Isar isar;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
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
    dir = await Directory.systemTemp.createTemp('jive_category_three_level_');
    isar = await Isar.open([JiveCategorySchema], directory: dir.path);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test(
    'creates third-level category with middle parent and compatible tx keys',
    () async {
      final service = CategoryService(isar);
      final parent = await service.createParentCategory(
        name: '出行',
        iconName: 'directions_car',
        isIncome: false,
      );
      expect(parent, isNotNull);

      final middle = await service.createSubCategory(
        parent: parent!,
        name: '私家车',
        iconName: 'directions_car',
      );
      expect(middle, isNotNull);

      final leaf = await service.createSubCategory(
        parent: middle!,
        name: '加油',
        iconName: 'local_gas_station',
      );

      expect(leaf, isNotNull);
      expect(leaf!.parentKey, middle.key);
      expect(leaf.isIncome, isFalse);

      final categories = await isar
          .collection<JiveCategory>()
          .where()
          .findAll();
      final path = const CategoryPathService().resolve(
        categories,
        subCategoryKey: leaf.key,
      );
      final txKeys = const CategoryPathService().toTransactionKeys(
        categories,
        leaf,
      );

      expect(path.displayName, '出行 / 私家车 / 加油');
      expect(txKeys.categoryKey, parent.key);
      expect(txKeys.subCategoryKey, leaf.key);
      expect(txKeys.categoryName, '出行');
      expect(txKeys.subCategoryName, '加油');
    },
  );

  test(
    'rejects duplicate third-level names under the same middle category',
    () async {
      final service = CategoryService(isar);
      final parent = await service.createParentCategory(
        name: '出行',
        iconName: 'directions_car',
        isIncome: false,
      );
      final middle = await service.createSubCategory(
        parent: parent!,
        name: '私家车',
        iconName: 'directions_car',
      );

      final first = await service.createSubCategory(
        parent: middle!,
        name: '加油',
        iconName: 'local_gas_station',
      );
      final duplicate = await service.createSubCategory(
        parent: middle,
        name: '加油',
        iconName: 'local_gas_station',
      );

      expect(first, isNotNull);
      expect(duplicate, isNull);
    },
  );
}
