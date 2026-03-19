import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      'jive_sync_runtime_integration_',
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

  testWidgets(
    'sync runtime survives backup restore and rebounds to new owner safely',
    (tester) async {
      final isarDir = Directory(
        '${documentsDir.path}/jive_sync_runtime_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}',
      )..createSync(recursive: true);
      final isar = await Isar.open(
        DatabaseService.schemas,
        directory: isarDir.path,
      );

      try {
        final account = JiveAccount()
          ..key = 'acc_sync_runtime'
          ..name = '同步运行态账户'
          ..type = 'asset'
          ..subType = 'cash'
          ..currency = 'CNY'
          ..iconName = 'wallet'
          ..order = 1
          ..includeInBalance = true
          ..isHidden = false
          ..isArchived = false
          ..updatedAt = DateTime(2026, 3, 15, 12, 0);
        final category = JiveCategory()
          ..key = 'cat_sync_runtime'
          ..name = '同步运行态分类'
          ..iconName = 'sync'
          ..order = 1
          ..isSystem = false
          ..isHidden = false
          ..isIncome = false
          ..updatedAt = DateTime(2026, 3, 15, 12, 1);
        final project = JiveProject()
          ..name = '同步运行态项目'
          ..status = 'active'
          ..createdAt = DateTime(2026, 3, 15, 12, 2)
          ..updatedAt = DateTime(2026, 3, 15, 12, 2);
        final tx = JiveTransaction()
          ..amount = 88.8
          ..source = 'Manual'
          ..timestamp = DateTime(2026, 3, 15, 11, 0)
          ..type = 'expense'
          ..categoryKey = 'cat_sync_runtime'
          ..category = '同步运行态分类'
          ..updatedAt = DateTime(2026, 3, 15, 12, 3);

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
          appInstanceId: 'android_runtime_rebind_flow',
        );
        final issued = await runtimeService.openRuntime(
          scope: 'cloud_sync',
          ownerId: 'user_001',
          now: DateTime.utc(2026, 3, 15, 12, 30, 0),
          snapshot: SyncCheckpointSnapshot(
            cursors: {
              'account': SyncCursor(
                entityType: 'account',
                updatedAt: DateTime.utc(2026, 3, 15, 12, 30, 0),
                lastId: accountId,
              ),
            },
            capturedAt: DateTime.utc(2026, 3, 15, 12, 30, 0),
          ),
        );

        await runtimeService.advanceCursor(
          SyncCursor(
            entityType: 'transaction',
            updatedAt: DateTime.utc(2026, 3, 15, 12, 31, 0),
            lastId: tx.id,
          ),
        );

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
        expect(summary.importedSyncCursorCount, greaterThanOrEqualTo(2));
        expect(summary.clearedSyncLease, isTrue);
        expect(await SyncLeaseStore.load(), isNull);

        final restoredRuntime = await runtimeService.openRuntime(
          scope: 'cloud_sync',
          ownerId: 'user_001',
          now: DateTime.utc(2026, 3, 15, 12, 35, 0),
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
          now: DateTime.utc(2026, 3, 15, 12, 36, 0),
        );
        expect(reboundRuntime.disposition, SyncRuntimeOpenDisposition.rebound);
        final staleWriterBlocked = !await runtimeService.canCurrentRuntimeWrite(
          leaseId: restoredRuntime.session.lease.leaseId,
          ownerId: 'user_001',
          now: DateTime.utc(2026, 3, 15, 12, 37, 0),
        );
        final reboundWriterAllowed = await runtimeService
            .canCurrentRuntimeWrite(
              leaseId: reboundRuntime.session.lease.leaseId,
              ownerId: 'user_002',
              now: DateTime.utc(2026, 3, 15, 12, 37, 0),
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
        expect(telemetryReport.exportCsv(), contains('status,ready'));
        debugPrint('SYNC_RUNTIME_TELEMETRY_JSON_START');
        debugPrint(telemetryReport.exportJson(), wrapWidth: 4096);
        debugPrint('SYNC_RUNTIME_TELEMETRY_JSON_END');
      } finally {
        await isar.close(deleteFromDisk: true);
        if (isarDir.existsSync()) {
          isarDir.deleteSync(recursive: true);
        }
      }
    },
  );
}
