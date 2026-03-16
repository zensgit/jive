import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/project_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/repository/sync_checkpoint_snapshot.dart';
import 'package:jive/core/repository/sync_cursor.dart';
import 'package:jive/core/repository/sync_cursor_store.dart';
import 'package:jive/core/repository/sync_lease.dart';
import 'package:jive/core/repository/sync_lease_store.dart';
import 'package:jive/core/service/credential_bundle_lease_governance_service.dart';
import 'package:jive/core/service/data_backup_service.dart';
import 'package:jive/core/service/database_service.dart';
import 'package:jive/core/service/sync_runtime_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory rootDir;
  late Directory documentsDir;

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
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    rootDir = await Directory.systemTemp.createTemp(
      'jive_backup_restore_regression_',
    );
    documentsDir = Directory('${rootDir.path}/documents')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationDocumentsDirectory' ||
                call.method == 'getTemporaryDirectory') {
              return documentsDir.path;
            }
            return null;
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (rootDir.existsSync()) {
      rootDir.deleteSync(recursive: true);
    }
  });

  test(
    'backup restore clears stale sync lease and keeps checkpoint integrity',
    () async {
      final isarDir = Directory(
        '${documentsDir.path}/jive_regression_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}',
      )..createSync(recursive: true);
      final isar = await Isar.open(
        DatabaseService.schemas,
        directory: isarDir.path,
      );

      try {
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
        final project = JiveProject()
          ..name = '旅行基金'
          ..status = 'active'
          ..createdAt = DateTime(2026, 3, 13, 9, 2)
          ..updatedAt = DateTime(2026, 3, 13, 9, 2);
        final tx = JiveTransaction()
          ..amount = 66.6
          ..source = 'Manual'
          ..timestamp = DateTime(2026, 3, 13, 8, 30)
          ..type = 'expense'
          ..categoryKey = 'cat_food'
          ..category = '餐饮'
          ..updatedAt = DateTime(2026, 3, 13, 9, 3);

        await isar.writeTxn(() async {
          final accountId = await isar.collection<JiveAccount>().put(account);
          final projectId = await isar.collection<JiveProject>().put(project);
          await isar.collection<JiveCategory>().put(category);
          tx.accountId = accountId;
          tx.projectId = projectId;
          await isar.collection<JiveTransaction>().put(tx);
        });

        final runtimeService = SyncRuntimeService(
          appInstanceId: 'host_regression_runtime',
        );
        final runtime = await runtimeService.openRuntime(
          scope: 'cloud_sync',
          ownerId: 'user_001',
          now: DateTime.utc(2026, 3, 13, 10, 0, 0),
          snapshot: SyncCheckpointSnapshot(
            cursors: {
              'transaction': SyncCursor(
                entityType: 'transaction',
                updatedAt: DateTime.utc(2026, 3, 13, 10, 0, 0),
                lastId: tx.id,
              ),
            },
            capturedAt: DateTime.utc(2026, 3, 13, 10, 0, 0),
          ),
        );

        final exportFile = await JiveDataBackupService.exportToFile(isar);
        final exportPayload =
            jsonDecode(await exportFile.readAsString()) as Map;
        final exportedSnapshot = SyncCheckpointSnapshot.fromJson(
          exportPayload['syncCursors'],
        );
        expect(exportedSnapshot.isRestorable, isTrue);
        expect(exportedSnapshot.cursors['transaction']?.lastId, tx.id);

        await SyncLeaseStore.save(
          SyncLease(
            leaseId: runtime.session.lease.leaseId,
            scope: runtime.session.lease.scope,
            ownerId: runtime.session.lease.ownerId,
            deviceId: runtime.session.lease.deviceId,
            version: runtime.session.lease.version,
            issuedAt: runtime.session.lease.issuedAt,
            expiresAt: runtime.session.lease.expiresAt,
          ),
        );

        await isar.writeTxn(() async {
          await isar.collection<JiveTransaction>().clear();
          await isar.collection<JiveCategory>().clear();
          await isar.collection<JiveProject>().clear();
          await isar.collection<JiveAccount>().clear();
        });

        final summary = await JiveDataBackupService.importFromFile(
          isar,
          exportFile,
          clearBefore: true,
        );
        expect(summary.transactions, 1);
        expect(summary.projects, 1);
        expect(summary.importedSyncCursorCount, greaterThanOrEqualTo(1));
        expect(summary.clearedSyncLease, isTrue);
        expect(await SyncLeaseStore.load(), isNull);

        final restoredSnapshot = await SyncCursorStore.loadSnapshot();
        expect(restoredSnapshot.isRestorable, isTrue);
        expect(restoredSnapshot.cursors['transaction']?.lastId, tx.id);

        final leaseGate = CredentialBundleLeaseGovernanceService().evaluate(
          CredentialBundleLeaseGovernanceInput(
            action: CredentialBundleLeaseAction.blockStaleCallbackWrite,
            authSuccess: true,
            leasePresent: true,
            leaseExpired: false,
            leaseRenewed: true,
            tokenUpdated: true,
            leaseRenewedAfterTokenUpdate: true,
            staleCallbackDetected: true,
            staleCallbackWriteBlocked: false,
            sessionVersionChanged: true,
            sessionVersionBroadcastRequired: true,
            sessionVersionBroadcasted: true,
            crossTabAckCompleted: true,
            bundleVersionAligned: true,
            navigationFinished: true,
          ),
        );
        expect(leaseGate.status, CredentialBundleLeaseStatus.review);
      } finally {
        await isar.close(deleteFromDisk: true);
        if (isarDir.existsSync()) {
          isarDir.deleteSync(recursive: true);
        }
      }
    },
  );
}
