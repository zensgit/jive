import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/repository/sync_cursor_store.dart';
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
    rootDir = await Directory.systemTemp.createTemp(
      'jive_backup_migration_regression_',
    );
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

  test('importFromFile repairs legacy transactions during restore', () async {
    final legacyBackupFile = File('${rootDir.path}/legacy_backup.json');
    await legacyBackupFile.writeAsString(
      jsonEncode({
        'accounts': [
          {
            'id': 11,
            'key': 'acc_cash_main',
            'name': '主钱包',
            'type': 'asset',
            'subType': 'cash',
            'currency': 'CNY',
            'iconName': 'wallet',
            'order': 1,
            'includeInBalance': true,
            'isHidden': false,
            'isArchived': false,
            'openingBalance': 88.5,
            'updatedAt': '2026-03-13T09:00:00.000',
          },
        ],
        'categories': [
          {
            'id': 21,
            'key': 'cat_food',
            'name': '餐饮',
            'iconName': 'restaurant',
            'order': 1,
            'isSystem': false,
            'isHidden': false,
            'isIncome': false,
            'updatedAt': '2026-03-13T09:01:00.000',
          },
          {
            'id': 22,
            'key': 'cat_food_breakfast',
            'name': '早餐',
            'iconName': 'breakfast_dining',
            'parentKey': 'cat_food',
            'order': 2,
            'isSystem': false,
            'isHidden': false,
            'isIncome': false,
            'updatedAt': '2026-03-13T09:02:00.000',
          },
        ],
        'transactions': [
          {
            'id': 31,
            'amount': 18.5,
            'source': 'legacy_csv',
            'timestamp': '2026-03-12T08:30:00.000',
            'category': '餐饮',
            'subCategory': '早餐',
            'note': 'legacy import',
            'tagKeys': ['tag_breakfast'],
          },
        ],
      }),
    );

    final summary = await JiveDataBackupService.importFromFile(
      isar,
      legacyBackupFile,
      clearBefore: true,
    );

    final restoredTransaction = await isar
        .collection<JiveTransaction>()
        .where()
        .findFirst();

    expect(
      summary.sourceSchemaVersion,
      JiveDataBackupService.legacySchemaVersion,
    );
    expect(summary.transactions, 1);
    expect(summary.repairedTransactionCategoryKeys, 1);
    expect(summary.repairedTransactionAccountIds, 1);
    expect(restoredTransaction?.categoryKey, 'cat_food');
    expect(restoredTransaction?.subCategoryKey, 'cat_food_breakfast');
    expect(restoredTransaction?.accountId, 11);
    expect(restoredTransaction?.type, 'expense');
    expect(restoredTransaction?.updatedAt, isNotNull);
    final restoredSnapshot = await SyncCursorStore.loadSnapshot();
    expect(restoredSnapshot.count, 0);
  });

  test(
    'importFromFile rejects future backup schema without clearing data',
    () async {
      final seededAccount = JiveAccount()
        ..key = 'seeded_account'
        ..name = '现有账户'
        ..type = 'asset'
        ..subType = 'cash'
        ..currency = 'CNY'
        ..iconName = 'wallet'
        ..order = 1
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = DateTime(2026, 3, 13, 10);

      await isar.writeTxn(() async {
        await isar.collection<JiveAccount>().put(seededAccount);
      });

      final futureBackupFile = File('${rootDir.path}/future_backup.json');
      await futureBackupFile.writeAsString(
        jsonEncode({
          'schemaVersion': JiveDataBackupService.schemaVersion + 1,
          'accounts': <Map<String, dynamic>>[],
          'categories': <Map<String, dynamic>>[],
          'transactions': <Map<String, dynamic>>[],
        }),
      );

      await expectLater(
        () => JiveDataBackupService.importFromFile(
          isar,
          futureBackupFile,
          clearBefore: true,
        ),
        throwsA(
          predicate(
            (error) =>
                error is StateError &&
                error.toString().contains(
                  '高于当前支持版本 ${JiveDataBackupService.schemaVersion}',
                ),
          ),
        ),
      );

      final accounts = await isar.collection<JiveAccount>().where().findAll();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, '现有账户');
    },
  );
}
