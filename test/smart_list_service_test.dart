import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/database/smart_list_model.dart';
import 'package:jive/core/model/transaction_list_filter_state.dart';
import 'package:jive/core/service/smart_list_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Isar isar;
  late SmartListService service;

  setUpAll(() async {
    await _initializeIsarCore();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('jive_smart_list_service_');
    isar = await Isar.open([JiveSmartListSchema], directory: dir.path);
    final prefs = await SharedPreferences.getInstance();
    service = SmartListService(isar, prefs: prefs);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('round trips filter state fields and describes summary', () {
    final range = DateTimeRange(
      start: DateTime(2026, 5, 1),
      end: DateTime(2026, 5, 7, 23, 59),
    );
    final smartList = service.fromFilterState(
      name: '本周餐饮',
      filterState: TransactionListFilterState(
        categoryKey: 'food',
        accountId: 42,
        tag: ' 午餐 ',
        dateRange: range,
      ),
      keyword: '咖啡',
      bookId: 7,
      transactionType: 'expense',
      minAmount: 50,
      maxAmount: 200,
    );

    expect(smartList.name, '本周餐饮');
    expect(smartList.categoryKeys, 'food');
    expect(smartList.tagKeys, '午餐');
    expect(smartList.accountId, 42);
    expect(smartList.bookId, 7);
    expect(smartList.transactionType, 'expense');
    expect(smartList.minAmount, 50);
    expect(smartList.maxAmount, 200);
    expect(smartList.dateRangeType, 'custom');
    expect(smartList.customStartDate, range.start);
    expect(smartList.customEndDate, range.end);
    expect(smartList.keyword, '咖啡');

    final restored = service.buildFilterState(smartList);
    expect(restored.categoryKey, 'food');
    expect(restored.accountId, 42);
    expect(restored.tag, '午餐');
    expect(restored.dateRange?.start, range.start);
    expect(restored.dateRange?.end, range.end);

    final summary = service.describeSummary(smartList);
    expect(summary, contains('分类: food'));
    expect(summary, contains('标签: 午餐'));
    expect(summary, contains('支出'));
    expect(summary, contains('50-200'));
    expect(summary, contains('自定义日期'));
    expect(summary, contains('"咖啡"'));
  });

  test('orders pinned smart lists before regular saved views', () async {
    final food = await service.create(name: '餐饮', categoryKeys: 'food');
    final large = await service.create(
      name: '大额',
      minAmount: 100,
      maxAmount: 999,
    );
    final travel = await service.create(name: '旅行', tagKeys: 'travel');

    food.sortOrder = 20;
    large
      ..sortOrder = 10
      ..isPinned = true;
    travel.sortOrder = 30;
    await service.update(food);
    await service.update(large);
    await service.update(travel);

    final allNames = (await service.getAll()).map((item) => item.name).toList();
    expect(allNames, ['大额', '餐饮', '旅行']);

    final pinnedNames = (await service.getPinned())
        .map((item) => item.name)
        .toList();
    expect(pinnedNames, ['大额']);
  });

  test('default view resolves and clears when deleted', () async {
    final view = await service.create(name: '默认餐饮', categoryKeys: 'food');

    expect(await service.getDefaultId(), isNull);
    expect(await service.getDefaultView(), isNull);

    await service.setDefaultView(view);
    expect(await service.getDefaultId(), view.id);
    expect((await service.getDefaultView())?.name, '默认餐饮');

    await service.delete(view.id);

    expect(await service.getDefaultId(), isNull);
    expect(await service.getDefaultView(), isNull);
    expect(await service.getAll(), isEmpty);
  });
}

Future<void> _initializeIsarCore() async {
  final pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final libPath = switch (Abi.current()) {
    Abi.macosArm64 || Abi.macosX64 =>
      '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib',
    Abi.linuxX64 =>
      '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/linux/libisar.so',
    Abi.windowsX64 =>
      '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/windows/isar.dll',
    _ => null,
  };
  if (libPath != null) {
    await Isar.initializeIsarCore(libraries: {Abi.current(): libPath});
  }
}
