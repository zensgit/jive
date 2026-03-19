import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/project_model.dart';
import 'package:jive/core/database/tag_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/repository/project_sync_repository.dart';
import 'package:jive/core/repository/sync_cursor.dart';
import 'package:jive/core/repository/tag_sync_repository.dart';
import 'package:jive/core/repository/transaction_sync_repository.dart';
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
    rootDir = await Directory.systemTemp.createTemp('jive_sync_repo_tx_');
    isarDir = Directory('${rootDir.path}/isar')..createSync(recursive: true);
    isar = await Isar.open(DatabaseService.schemas, directory: isarDir.path);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (rootDir.existsSync()) {
      rootDir.deleteSync(recursive: true);
    }
  });

  test('transaction sync repository paginates by updatedAt then id', () async {
    final repository = TransactionSyncRepository(isar);

    final first = JiveTransaction()
      ..id = 30
      ..amount = 8.8
      ..source = 'Manual'
      ..timestamp = DateTime.utc(2026, 3, 13, 7, 0, 0)
      ..type = 'expense'
      ..updatedAt = DateTime.utc(2026, 3, 13, 10, 0, 0);
    final second = JiveTransaction()
      ..id = 31
      ..amount = 9.9
      ..source = 'Manual'
      ..timestamp = DateTime.utc(2026, 3, 13, 7, 5, 0)
      ..type = 'expense'
      ..updatedAt = DateTime.utc(2026, 3, 13, 10, 0, 0);
    final third = JiveTransaction()
      ..id = 32
      ..amount = 18.8
      ..source = 'Manual'
      ..timestamp = DateTime.utc(2026, 3, 13, 8, 0, 0)
      ..type = 'income'
      ..updatedAt = DateTime.utc(2026, 3, 13, 11, 0, 0);

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().putAll([third, second, first]);
    });

    final firstPage = await repository.listChangedAfter(limit: 2);
    expect(firstPage.items.map((item) => item.id).toList(), [30, 31]);
    expect(firstPage.hasMore, isTrue);
    expect(firstPage.nextCursor?.lastId, 31);

    final secondPage = await repository.listChangedAfter(
      cursor: firstPage.nextCursor,
      limit: 2,
    );
    expect(secondPage.items.map((item) => item.id).toList(), [32]);
    expect(secondPage.hasMore, isFalse);
  });

  test(
    'tag sync repository returns latest cursor from newest tag update',
    () async {
      final repository = TagSyncRepository(isar);

      final early = JiveTag()
        ..id = 40
        ..key = 'tag_food'
        ..name = '餐饮'
        ..order = 1
        ..isArchived = false
        ..usageCount = 0
        ..createdAt = DateTime.utc(2026, 3, 13, 8, 0, 0)
        ..updatedAt = DateTime.utc(2026, 3, 13, 9, 0, 0);
      final latest = JiveTag()
        ..id = 41
        ..key = 'tag_trip'
        ..name = '旅行'
        ..order = 2
        ..isArchived = false
        ..usageCount = 3
        ..createdAt = DateTime.utc(2026, 3, 13, 8, 30, 0)
        ..updatedAt = DateTime.utc(2026, 3, 13, 12, 0, 0);

      await isar.writeTxn(() async {
        await isar.collection<JiveTag>().putAll([early, latest]);
      });

      final latestCursor = await repository.latestCursor();

      expect(latestCursor?.entityType, 'tag');
      expect(
        latestCursor?.updatedAt.isAtSameMomentAs(
          DateTime.utc(2026, 3, 13, 12, 0, 0),
        ),
        isTrue,
      );
      expect(latestCursor?.lastId, 41);
    },
  );

  test(
    'project sync repository blocks mismatched cursor entity type',
    () async {
      final repository = ProjectSyncRepository(isar);
      final cursor = SyncCursor(
        entityType: 'transaction',
        updatedAt: DateTime.utc(2026, 3, 13, 10, 0, 0),
        lastId: 30,
      );

      await expectLater(
        () => repository.listChangedAfter(cursor: cursor),
        throwsA(
          predicate(
            (error) =>
                error is StateError && error.toString().contains('entityType'),
          ),
        ),
      );
    },
  );

  test('project sync repository paginates changed projects', () async {
    final repository = ProjectSyncRepository(isar);

    final first = JiveProject()
      ..id = 50
      ..name = '日本旅行'
      ..status = 'active'
      ..createdAt = DateTime.utc(2026, 3, 13, 8, 0, 0)
      ..updatedAt = DateTime.utc(2026, 3, 13, 9, 0, 0);
    final second = JiveProject()
      ..id = 51
      ..name = '装修'
      ..status = 'active'
      ..createdAt = DateTime.utc(2026, 3, 13, 8, 0, 0)
      ..updatedAt = DateTime.utc(2026, 3, 13, 10, 0, 0);

    await isar.writeTxn(() async {
      await isar.collection<JiveProject>().putAll([first, second]);
    });

    final page = await repository.listChangedAfter(
      cursor: SyncCursor(
        entityType: 'project',
        updatedAt: DateTime.utc(2026, 3, 13, 9, 0, 0),
        lastId: 50,
      ),
      limit: 10,
    );

    expect(page.items.map((item) => item.id).toList(), [51]);
    expect(page.hasMore, isFalse);
  });
}
