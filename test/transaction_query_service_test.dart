import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/tag_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/model/transaction_list_filter_state.dart';
import 'package:jive/core/model/transaction_query_spec.dart';
import 'package:jive/core/service/transaction_query_service.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late TransactionQueryService service;

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
    dir = await Directory.systemTemp.createTemp('jive_tx_query_test_');
    isar = await Isar.open([
      JiveTransactionSchema,
      JiveCategorySchema,
      JiveCategoryOverrideSchema,
      JiveAccountSchema,
      JiveTagSchema,
      JiveTagGroupSchema,
    ], directory: dir.path);
    service = TransactionQueryService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test(
    'query applies date/account/budget/tag/keyword filters together',
    () async {
      final now = DateTime(2026, 2, 19, 12);
      final food = JiveCategory()
        ..name = '餐饮'
        ..key = 'food'
        ..iconName = 'restaurant'
        ..order = 0
        ..isSystem = false
        ..isHidden = false
        ..isIncome = false
        ..updatedAt = now;
      final other = JiveCategory()
        ..name = '其他'
        ..key = 'other'
        ..iconName = 'receipt_long'
        ..order = 1
        ..isSystem = false
        ..isHidden = false
        ..isIncome = false
        ..updatedAt = now
        ..excludeFromBudget = true;
      final account = JiveAccount()
        ..key = 'acct_cash'
        ..name = '现金'
        ..type = 'asset'
        ..subType = 'cash'
        ..currency = 'CNY'
        ..iconName = 'account_balance_wallet'
        ..order = 0
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = now;
      final tag = JiveTag()
        ..name = '早餐'
        ..key = 'tag_breakfast'
        ..groupKey = 'default'
        ..order = 0
        ..isArchived = false
        ..usageCount = 0
        ..createdAt = now
        ..updatedAt = now;

      await isar.writeTxn(() async {
        await isar.collection<JiveCategory>().putAll([food, other]);
        await isar.collection<JiveAccount>().put(account);
        await isar.collection<JiveTag>().put(tag);
        await isar.collection<JiveTransaction>().putAll([
          JiveTransaction()
            ..amount = 20
            ..source = '微信'
            ..timestamp = DateTime(2026, 2, 10, 8, 30)
            ..type = 'expense'
            ..categoryKey = 'food'
            ..category = '餐饮'
            ..accountId = account.id
            ..note = 'coffee 早餐'
            ..tagKeys = ['tag_breakfast'],
          JiveTransaction()
            ..amount = 30
            ..source = '微信'
            ..timestamp = DateTime(2026, 2, 11, 8, 30)
            ..type = 'expense'
            ..categoryKey = 'other'
            ..category = '其他'
            ..accountId = account.id
            ..note = 'coffee 代付',
          JiveTransaction()
            ..amount = 99
            ..source = '支付宝'
            ..timestamp = DateTime(2026, 2, 12, 9, 0)
            ..type = 'expense'
            ..categoryKey = 'food'
            ..category = '餐饮'
            ..accountId = account.id
            ..note = 'lunch',
        ]);
      });

      final spec = TransactionQuerySpec(
        keyword: 'coffee',
        filterState: TransactionListFilterState(
          accountId: account.id,
          tag: '早餐',
          dateRange: DateTimeRange(
            start: DateTime(2026, 2, 10),
            end: DateTime(2026, 2, 13),
          ),
          budgetFilter: BudgetInclusionFilter.includedOnly,
        ),
      );
      final page = await service.query(
        spec,
        pageSize: 20,
        categoryByKey: {food.key: food, other.key: other},
        accountById: {account.id: account},
        tagByKey: {tag.key: tag},
      );

      expect(page.items.length, 1);
      expect(page.items.first.note, contains('coffee'));
      expect(page.items.first.categoryKey, 'food');
    },
  );

  test('query supports stable timestamp/id pagination', () async {
    final now = DateTime(2026, 2, 19, 12);
    final category = JiveCategory()
      ..name = '餐饮'
      ..key = 'food'
      ..iconName = 'restaurant'
      ..order = 0
      ..isSystem = false
      ..isHidden = false
      ..isIncome = false
      ..updatedAt = now;
    final account = JiveAccount()
      ..key = 'acct_cash'
      ..name = '现金'
      ..type = 'asset'
      ..subType = 'cash'
      ..currency = 'CNY'
      ..iconName = 'account_balance_wallet'
      ..order = 0
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..updatedAt = now;

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().put(category);
      await isar.collection<JiveAccount>().put(account);
      final txs = List.generate(250, (index) {
        return JiveTransaction()
          ..amount = index.toDouble()
          ..source = 'seed'
          ..timestamp = DateTime(2026, 2, 1).add(Duration(minutes: index))
          ..type = 'expense'
          ..categoryKey = 'food'
          ..accountId = account.id
          ..note = 'seed-$index';
      });
      await isar.collection<JiveTransaction>().putAll(txs);
    });

    final spec = TransactionQuerySpec(
      filterState: TransactionListFilterState(accountId: account.id),
    );
    final first = await service.query(
      spec,
      pageSize: 100,
      categoryByKey: {category.key: category},
      accountById: {account.id: account},
      tagByKey: const {},
    );
    expect(first.items.length, 100);
    expect(first.hasMore, isTrue);
    expect(first.nextCursor, isNotNull);

    final second = await service.query(
      spec,
      cursor: first.nextCursor,
      pageSize: 100,
      categoryByKey: {category.key: category},
      accountById: {account.id: account},
      tagByKey: const {},
    );
    expect(second.items.length, 100);
    final firstIds = first.items.map((tx) => tx.id).toSet();
    expect(second.items.every((tx) => !firstIds.contains(tx.id)), isTrue);

    final third = await service.query(
      spec,
      cursor: second.nextCursor,
      pageSize: 100,
      categoryByKey: {category.key: category},
      accountById: {account.id: account},
      tagByKey: const {},
    );
    expect(third.items.length, 50);
    expect(third.hasMore, isFalse);
    expect(third.nextCursor, isNull);
  });
}
