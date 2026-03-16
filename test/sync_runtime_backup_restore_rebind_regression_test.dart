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
import 'package:jive/core/repository/sync_lease_store.dart';
import 'package:jive/core/service/data_backup_service.dart';
import 'package:jive/core/service/database_service.dart';
import 'package:jive/core/service/sync_runtime_service.dart';
import 'package:jive/core/service/sync_runtime_telemetry_report_service.dart';

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
      'jive_sync_runtime_regression_',
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
    'backup restore keeps runtime snapshot and rebounds on owner rotation',
    () async {
      final isarDir = Directory(
        '${documentsDir.path}/jive_sync_runtime_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}',
      )..createSync(recursive: true);
      final isar = await Isar.open(
        DatabaseService.schemas,
        directory: isarDir.path,
      );

      try {
        final account = JiveAccount()
          ..key = 'acc_travel'
          ..name = '旅行账户'
          ..type = 'asset'
          ..subType = 'cash'
          ..currency = 'CNY'
          ..iconName = 'wallet'
          ..order = 1
          ..includeInBalance = true
          ..isHidden = false
          ..isArchived = false
          ..updatedAt = DateTime(2026, 3, 15, 10, 0);
        final category = JiveCategory()
          ..key = 'cat_travel_food'
          ..name = '旅行餐饮'
          ..iconName = 'restaurant'
          ..order = 1
          ..isSystem = false
          ..isHidden = false
          ..isIncome = false
          ..updatedAt = DateTime(2026, 3, 15, 10, 1);
        final project = JiveProject()
          ..name = '日本旅行'
          ..status = 'active'
          ..createdAt = DateTime(2026, 3, 15, 10, 2)
          ..updatedAt = DateTime(2026, 3, 15, 10, 2);
        final tx = JiveTransaction()
          ..amount = 199.9
          ..source = 'Manual'
          ..timestamp = DateTime(2026, 3, 15, 9, 0)
          ..type = 'expense'
          ..categoryKey = 'cat_travel_food'
          ..category = '旅行餐饮'
          ..updatedAt = DateTime(2026, 3, 15, 10, 3);

        late int accountId;
        await isar.writeTxn(() async {
          accountId = await isar.collection<JiveAccount>().put(account);
          final projectId = await isar.collection<JiveProject>().put(project);
          await isar.collection<JiveCategory>().put(category);
          tx.accountId = accountId;
          tx.projectId = projectId;
          await isar.collection<JiveTransaction>().put(tx);
        });

        final runtimeService = SyncRuntimeService(
          appInstanceId: 'host_runtime_rebind_regression',
        );
        final issued = await runtimeService.openRuntime(
          scope: 'cloud_sync',
          ownerId: 'user_001',
          now: DateTime.utc(2026, 3, 15, 11, 0, 0),
          snapshot: SyncCheckpointSnapshot(
            cursors: {
              'account': SyncCursor(
                entityType: 'account',
                updatedAt: DateTime.utc(2026, 3, 15, 11, 0, 0),
                lastId: accountId,
              ),
            },
            capturedAt: DateTime.utc(2026, 3, 15, 11, 0, 0),
          ),
        );
        final advanced = await runtimeService.advanceCursor(
          SyncCursor(
            entityType: 'transaction',
            updatedAt: DateTime.utc(2026, 3, 15, 11, 1, 0),
            lastId: tx.id,
          ),
        );

        expect(advanced.cursors['account']?.lastId, accountId);
        expect(advanced.cursors['transaction']?.lastId, tx.id);

        final exportFile = await JiveDataBackupService.exportToFile(isar);
        final exportPayload =
            jsonDecode(await exportFile.readAsString()) as Map<String, dynamic>;
        final exportedSnapshot = SyncCheckpointSnapshot.fromJson(
          exportPayload['syncCursors'] as Map<String, dynamic>,
        );
        expect(exportedSnapshot.cursors['account']?.lastId, accountId);
        expect(exportedSnapshot.cursors['transaction']?.lastId, tx.id);

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
        expect(summary.importedSyncCursorCount, greaterThanOrEqualTo(2));
        expect(summary.clearedSyncLease, isTrue);
        expect(await SyncLeaseStore.load(), isNull);

        final restoredRuntime = await runtimeService.openRuntime(
          scope: 'cloud_sync',
          ownerId: 'user_001',
          now: DateTime.utc(2026, 3, 15, 11, 5, 0),
        );
        expect(restoredRuntime.disposition, SyncRuntimeOpenDisposition.issued);
        expect(restoredRuntime.identity.deviceId, issued.identity.deviceId);
        expect(
          restoredRuntime.session.snapshot.cursors['account']?.lastId,
          accountId,
        );
        expect(
          restoredRuntime.session.snapshot.cursors['transaction']?.lastId,
          tx.id,
        );

        final reboundRuntime = await runtimeService.openRuntime(
          scope: 'cloud_sync',
          ownerId: 'user_002',
          now: DateTime.utc(2026, 3, 15, 11, 6, 0),
        );
        expect(reboundRuntime.disposition, SyncRuntimeOpenDisposition.rebound);
        expect(reboundRuntime.identity.deviceId, issued.identity.deviceId);
        expect(
          reboundRuntime.session.snapshot.cursors['transaction']?.lastId,
          tx.id,
        );
        final staleWriterBlocked = !await runtimeService.canCurrentRuntimeWrite(
          leaseId: restoredRuntime.session.lease.leaseId,
          ownerId: 'user_001',
          now: DateTime.utc(2026, 3, 15, 11, 7, 0),
        );
        final reboundWriterAllowed = await runtimeService
            .canCurrentRuntimeWrite(
              leaseId: reboundRuntime.session.lease.leaseId,
              ownerId: 'user_002',
              now: DateTime.utc(2026, 3, 15, 11, 7, 0),
            );
        expect(staleWriterBlocked, isTrue);
        expect(reboundWriterAllowed, isTrue);

        final restoredSnapshot = await SyncCursorStore.loadSnapshot();
        expect(restoredSnapshot.cursors['account']?.lastId, accountId);
        expect(restoredSnapshot.cursors['transaction']?.lastId, tx.id);

        final telemetryReport = const SyncRuntimeTelemetryReportService()
            .evaluate(
              SyncRuntimeTelemetryInput(
                scope: 'cloud_sync',
                initialDisposition: issued.disposition,
                restoredDisposition: restoredRuntime.disposition,
                reboundDisposition: reboundRuntime.disposition,
                importedSyncCursorCount: summary.importedSyncCursorCount,
                restoredSnapshotValid: restoredSnapshot.isRestorable,
                sameDeviceRetained:
                    restoredRuntime.identity.deviceId ==
                        issued.identity.deviceId &&
                    reboundRuntime.identity.deviceId ==
                        issued.identity.deviceId,
                leaseClearedBeforeRestore: summary.clearedSyncLease,
                staleWriterBlocked: staleWriterBlocked,
                reboundWriterAllowed: reboundWriterAllowed,
              ),
            );
        expect(telemetryReport.status, SyncRuntimeTelemetryStatus.ready);
        expect(
          telemetryReport.exportMarkdown(),
          contains('# Sync Runtime 遥测回归报告'),
        );
        expect(telemetryReport.exportJson(), contains('"status": "ready"'));

        final reportDir = Directory(
          '${Directory.current.path}/build/reports/sync-runtime',
        )..createSync(recursive: true);
        final jsonFile = File(
          '${reportDir.path}/host-sync-runtime-backup-restore-rebind.json',
        );
        jsonFile.writeAsStringSync(telemetryReport.exportJson());
        final markdownFile = File(
          '${reportDir.path}/host-sync-runtime-backup-restore-rebind.md',
        );
        markdownFile.writeAsStringSync(telemetryReport.exportMarkdown());
        final csvFile = File(
          '${reportDir.path}/host-sync-runtime-backup-restore-rebind.csv',
        );
        csvFile.writeAsStringSync(telemetryReport.exportCsv());
      } finally {
        await isar.close(deleteFromDisk: true);
        if (isarDir.existsSync()) {
          isarDir.deleteSync(recursive: true);
        }
      }
    },
  );
}
