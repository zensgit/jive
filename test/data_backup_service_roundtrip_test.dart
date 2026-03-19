import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/import_job_model.dart';
import 'package:jive/core/database/project_model.dart';
import 'package:jive/core/database/tag_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/repository/sync_cursor_store.dart';
import 'package:jive/core/repository/sync_lease.dart';
import 'package:jive/core/repository/sync_lease_store.dart';
import 'package:jive/core/service/data_backup_service.dart';
import 'package:jive/core/service/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory rootDir;
  late Directory isarDir;
  late Directory documentsDir;
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
    SharedPreferences.setMockInitialValues({});
    rootDir = await Directory.systemTemp.createTemp('jive_backup_roundtrip_');
    isarDir = Directory('${rootDir.path}/isar')..createSync(recursive: true);
    documentsDir = Directory('${rootDir.path}/documents')
      ..createSync(recursive: true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return documentsDir.path;
            }
            return null;
          },
        );

    isar = await Isar.open(DatabaseService.schemas, directory: isarDir.path);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await isar.close(deleteFromDisk: true);
    if (rootDir.existsSync()) {
      rootDir.deleteSync(recursive: true);
    }
  });

  test(
    'backup export and import perform round-trip with representative data',
    () async {
      final account = JiveAccount()
        ..key = 'acc_cash_main'
        ..name = '主钱包'
        ..type = 'asset'
        ..subType = 'cash'
        ..currency = 'CNY'
        ..iconName = 'wallet'
        ..order = 1
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..openingBalance = 88.5
        ..updatedAt = DateTime(2026, 3, 13, 9);
      final category = JiveCategory()
        ..key = 'cat_food'
        ..name = '餐饮'
        ..iconName = 'restaurant'
        ..order = 1
        ..isSystem = false
        ..isHidden = false
        ..isIncome = false
        ..updatedAt = DateTime(2026, 3, 13, 9, 1);
      final tag = JiveTag()
        ..key = 'tag_lunch'
        ..name = '午餐'
        ..iconName = 'restaurant'
        ..order = 1
        ..isArchived = false
        ..usageCount = 1
        ..createdAt = DateTime(2026, 3, 13, 9, 2)
        ..updatedAt = DateTime(2026, 3, 13, 9, 2);
      final project = JiveProject()
        ..name = '日本旅行'
        ..description = '备份项目'
        ..iconName = 'flight'
        ..colorHex = '#3366FF'
        ..budget = 9999
        ..status = 'active'
        ..createdAt = DateTime(2026, 3, 13, 9, 2)
        ..updatedAt = DateTime(2026, 3, 13, 9, 4)
        ..sortOrder = 1;
      final transaction = JiveTransaction()
        ..amount = 25.5
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 3, 12, 12, 30)
        ..type = 'expense'
        ..note = '备份回归午餐'
        ..category = '餐饮'
        ..categoryKey = 'cat_food'
        ..tagKeys = ['tag_lunch']
        ..updatedAt = DateTime(2026, 3, 13, 9, 3);
      final importJob = JiveImportJob()
        ..createdAt = DateTime(2026, 3, 13, 8, 0)
        ..updatedAt = DateTime(2026, 3, 13, 8, 5)
        ..finishedAt = DateTime(2026, 3, 13, 8, 6)
        ..status = 'review'
        ..sourceType = 'csv'
        ..entryType = 'file'
        ..fileName = 'backup_seed.csv'
        ..payloadText = 'seed payload'
        ..totalCount = 1
        ..insertedCount = 1;

      await isar.writeTxn(() async {
        final accountId = await isar.collection<JiveAccount>().put(account);
        await isar.collection<JiveCategory>().put(category);
        await isar.collection<JiveTag>().put(tag);
        final projectId = await isar.collection<JiveProject>().put(project);
        transaction.accountId = accountId;
        transaction.projectId = projectId;
        await isar.collection<JiveTransaction>().put(transaction);
        await isar.collection<JiveImportJob>().put(importJob);
      });

      final file = await JiveDataBackupService.exportToFile(isar);
      expect(file.existsSync(), isTrue);
      expect(file.path.startsWith(documentsDir.path), isTrue);
      final exportedPayload = jsonDecode(await file.readAsString()) as Map;
      final exportedSyncCursors = Map<String, dynamic>.from(
        exportedPayload['syncCursors'] as Map,
      );
      expect(exportedSyncCursors['version'], 1);
      expect(exportedSyncCursors['checksum'], isA<String>());
      expect(exportedSyncCursors['capturedAt'], isA<String>());
      expect(
        exportedSyncCursors.keys.toSet(),
        containsAll({
          'version',
          'capturedAt',
          'checksum',
          'account',
          'category',
          'project',
          'tag',
          'transaction',
        }),
      );

      await SyncLeaseStore.save(
        SyncLease(
          leaseId: 'lease_before_import',
          scope: 'backup_restore',
          ownerId: 'user_001',
          deviceId: 'android_emulator',
          version: 7,
          issuedAt: DateTime(2026, 3, 13, 9, 30),
          expiresAt: DateTime(2026, 3, 13, 10, 30),
        ),
      );

      await isar.writeTxn(() async {
        await isar.collection<JiveAccount>().clear();
        await isar.collection<JiveCategory>().clear();
        await isar.collection<JiveProject>().clear();
        await isar.collection<JiveTag>().clear();
        await isar.collection<JiveTransaction>().clear();
        await isar.collection<JiveImportJob>().clear();
      });

      final summary = await JiveDataBackupService.importFromFile(
        isar,
        file,
        clearBefore: true,
      );

      expect(summary.accounts, 1);
      expect(summary.categories, 1);
      expect(summary.tags, 1);
      expect(summary.transactions, 1);
      expect(summary.importJobs, 1);
      expect(summary.projects, 1);
      expect(summary.sourceSchemaVersion, JiveDataBackupService.schemaVersion);
      expect(summary.importedSyncCursorCount, 5);
      expect(summary.clearedSyncLease, isTrue);

      final restoredAccount = await isar
          .collection<JiveAccount>()
          .where()
          .findFirst();
      final restoredCategory = await isar
          .collection<JiveCategory>()
          .where()
          .findFirst();
      final restoredTag = await isar.collection<JiveTag>().where().findFirst();
      final restoredProject = await isar
          .collection<JiveProject>()
          .where()
          .findFirst();
      final restoredTransaction = await isar
          .collection<JiveTransaction>()
          .where()
          .findFirst();
      final restoredJob = await isar
          .collection<JiveImportJob>()
          .where()
          .findFirst();

      expect(restoredAccount?.name, '主钱包');
      expect(restoredAccount?.openingBalance, 88.5);
      expect(restoredCategory?.iconName, 'restaurant');
      expect(restoredTag?.name, '午餐');
      expect(restoredProject?.name, '日本旅行');
      expect(restoredTransaction?.note, '备份回归午餐');
      expect(restoredTransaction?.projectId, restoredProject?.id);
      expect(restoredTransaction?.tagKeys, ['tag_lunch']);
      expect(
        restoredTransaction?.updatedAt.isAtSameMomentAs(
          DateTime(2026, 3, 13, 9, 3),
        ),
        isTrue,
      );
      expect(restoredJob?.sourceType, 'csv');
      expect(restoredJob?.status, 'review');

      final restoredSnapshot = await SyncCursorStore.loadSnapshot();
      expect(restoredSnapshot.count, 5);
      expect(
        restoredSnapshot.cursors['transaction']?.lastId,
        restoredTransaction?.id,
      );
      expect(await SyncLeaseStore.load(), isNull);
    },
  );
}
