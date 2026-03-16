import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/repository/account_sync_repository.dart';
import 'package:jive/core/repository/category_sync_repository.dart';
import 'package:jive/core/repository/sync_cursor.dart';
import 'package:jive/core/service/database_service.dart';

void main() {
  late Directory rootDir;
  late Directory isarDir;
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
    rootDir = await Directory.systemTemp.createTemp('jive_sync_repo_');
    isarDir = Directory('${rootDir.path}/isar')..createSync(recursive: true);
    isar = await Isar.open(DatabaseService.schemas, directory: isarDir.path);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (rootDir.existsSync()) {
      rootDir.deleteSync(recursive: true);
    }
  });

  test(
    'sync cursor json round-trip keeps entity type timestamp and last id',
    () {
      final cursor = SyncCursor(
        entityType: 'account',
        updatedAt: DateTime.utc(2026, 3, 13, 12, 0, 0),
        lastId: 42,
      );

      final restored = SyncCursor.fromJson(cursor.toJson());

      expect(restored.entityType, 'account');
      expect(restored.updatedAt, DateTime.utc(2026, 3, 13, 12, 0, 0));
      expect(restored.lastId, 42);
    },
  );

  test('account sync repository paginates by updatedAt then id', () async {
    final repository = AccountSyncRepository(isar);

    final early = JiveAccount()
      ..id = 10
      ..key = 'acc_early'
      ..name = '早账户'
      ..type = 'asset'
      ..currency = 'CNY'
      ..iconName = 'wallet'
      ..order = 1
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..updatedAt = DateTime.utc(2026, 3, 13, 8, 0, 0);
    final tieBreaker = JiveAccount()
      ..id = 11
      ..key = 'acc_tie'
      ..name = '并列账户'
      ..type = 'asset'
      ..currency = 'CNY'
      ..iconName = 'wallet'
      ..order = 2
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..updatedAt = DateTime.utc(2026, 3, 13, 8, 0, 0);
    final latest = JiveAccount()
      ..id = 12
      ..key = 'acc_latest'
      ..name = '最新账户'
      ..type = 'asset'
      ..currency = 'USD'
      ..iconName = 'credit_card'
      ..order = 3
      ..includeInBalance = true
      ..isHidden = false
      ..isArchived = false
      ..updatedAt = DateTime.utc(2026, 3, 13, 9, 0, 0);

    await isar.writeTxn(() async {
      await isar.collection<JiveAccount>().putAll([latest, tieBreaker, early]);
    });

    final firstPage = await repository.listChangedAfter(limit: 2);
    expect(firstPage.items.map((item) => item.name).toList(), ['早账户', '并列账户']);
    expect(firstPage.hasMore, isTrue);
    expect(firstPage.nextCursor?.lastId, 11);

    final secondPage = await repository.listChangedAfter(
      cursor: firstPage.nextCursor,
      limit: 2,
    );
    expect(secondPage.items.map((item) => item.name).toList(), ['最新账户']);
    expect(secondPage.hasMore, isFalse);
  });

  test(
    'category sync repository rejects mismatched cursor entity type',
    () async {
      final repository = CategorySyncRepository(isar);
      final accountCursor = SyncCursor(
        entityType: 'account',
        updatedAt: DateTime.utc(2026, 3, 13, 8, 0, 0),
        lastId: 10,
      );

      await expectLater(
        () => repository.listChangedAfter(cursor: accountCursor),
        throwsA(
          predicate(
            (error) =>
                error is StateError && error.toString().contains('entityType'),
          ),
        ),
      );
    },
  );

  test(
    'category sync repository returns latest cursor from newest row',
    () async {
      final repository = CategorySyncRepository(isar);

      final early = JiveCategory()
        ..id = 20
        ..key = 'cat_food'
        ..name = '餐饮'
        ..iconName = 'restaurant'
        ..order = 1
        ..isSystem = false
        ..isHidden = false
        ..isIncome = false
        ..updatedAt = DateTime.utc(2026, 3, 13, 7, 0, 0);
      final latest = JiveCategory()
        ..id = 21
        ..key = 'cat_salary'
        ..name = '工资'
        ..iconName = 'payments'
        ..order = 2
        ..isSystem = false
        ..isHidden = false
        ..isIncome = true
        ..updatedAt = DateTime.utc(2026, 3, 13, 11, 0, 0);

      await isar.writeTxn(() async {
        await isar.collection<JiveCategory>().putAll([early, latest]);
      });

      final latestCursor = await repository.latestCursor();

      expect(latestCursor?.entityType, 'category');
      expect(
        latestCursor?.updatedAt.isAtSameMomentAs(
          DateTime.utc(2026, 3, 13, 11, 0, 0),
        ),
        isTrue,
      );
      expect(latestCursor?.lastId, 21);
    },
  );
}
