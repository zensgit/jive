import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/smart_list_model.dart';
import 'package:jive/core/model/transaction_list_filter_state.dart';
import 'package:jive/core/service/smart_list_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;
  late Isar isar;
  late SharedPreferences prefs;
  late SmartListService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _initializeIsarCore();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dir = await Directory.systemTemp.createTemp('jive_smart_list_test_');
    isar = await Isar.open(
      [JiveSmartListSchema],
      name: 'smart_list_${DateTime.now().microsecondsSinceEpoch}',
      directory: dir.path,
    );
    service = SmartListService(isar, prefs: prefs);
  });

  tearDown(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('default view resolves by id and is cleared when deleted', () async {
    final view = await service.create(
      name: '本月餐饮',
      categoryKeys: 'food,lunch',
      keyword: '午餐',
    );

    await service.setDefaultView(view);

    expect(await service.getDefaultId(), view.id);
    expect((await service.getDefaultView())?.name, '本月餐饮');

    await service.delete(view.id);

    expect(await service.getDefaultId(), isNull);
    expect(await service.getDefaultView(), isNull);
  });

  test('getAll keeps pinned views first then sort order', () async {
    final later = await service.create(name: '后建普通视图');
    final pinned = await service.create(name: '置顶视图');
    final early = await service.create(name: '先展示普通视图');

    pinned
      ..isPinned = true
      ..sortOrder = 99;
    later.sortOrder = 2;
    early.sortOrder = 1;
    await service.update(pinned);
    await service.update(later);
    await service.update(early);

    final names = (await service.getAll()).map((view) => view.name).toList();

    expect(names, ['置顶视图', '先展示普通视图', '后建普通视图']);
  });

  test('filter snapshot preserves fixed category, tag, account, and date', () {
    final range = DateTimeRange(
      start: DateTime(2026, 5, 1),
      end: DateTime(2026, 5, 7, 23, 59),
    );
    final snapshot = service.fromFilterState(
      name: '加油超过 50',
      filterState: TransactionListFilterState(
        categoryKey: 'fuel',
        accountId: 8,
        tag: ' 私家车 ',
        dateRange: range,
      ),
      keyword: '中石化',
      bookId: 3,
      transactionType: 'expense',
      minAmount: 50,
    );

    expect(snapshot.categoryKeys, 'fuel');
    expect(snapshot.tagKeys, '私家车');
    expect(snapshot.accountId, 8);
    expect(snapshot.bookId, 3);
    expect(snapshot.transactionType, 'expense');
    expect(snapshot.minAmount, 50);
    expect(snapshot.dateRangeType, 'custom');
    expect(snapshot.customStartDate, range.start);
    expect(snapshot.customEndDate, range.end);
    expect(snapshot.keyword, '中石化');

    final restored = service.buildFilterState(snapshot);

    expect(restored.categoryKey, 'fuel');
    expect(restored.normalizedTag, '私家车');
    expect(restored.accountId, 8);
    expect(restored.dateRange?.start, range.start);
    expect(restored.dateRange?.end, range.end);
  });

  test('buildFilterState uses first value from multi-value saved filters', () {
    final smartList = JiveSmartList()
      ..name = '多分类视图'
      ..categoryKeys = 'food, lunch'
      ..tagKeys = 'family, travel'
      ..createdAt = DateTime(2026);

    final filter = service.buildFilterState(smartList);

    expect(filter.categoryKey, 'food');
    expect(filter.normalizedTag, 'family');
  });
}

Future<void> _initializeIsarCore() async {
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
    return;
  }
  throw StateError('Isar core library not found for tests.');
}
