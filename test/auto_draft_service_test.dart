import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/auto_draft_model.dart';
import 'package:jive/core/database/tag_model.dart';
import 'package:jive/core/database/tag_rule_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/auto_draft_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Isar isar;
  late Directory dir;
  late AutoDraftService service;

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
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp(
      'jive_auto_draft_service_test_',
    );
    isar = await Isar.open([
      JiveAutoDraftSchema,
      JiveTransactionSchema,
      JiveAccountSchema,
      JiveTagSchema,
      JiveTagGroupSchema,
      JiveTagRuleSchema,
    ], directory: dir.path);
    service = AutoDraftService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test(
    'confirmDraft resolves transfer target account from metadata before commit',
    () async {
      final wechat = JiveAccount()
        ..key = 'acct_wechat'
        ..name = '微信'
        ..type = 'asset'
        ..currency = 'CNY'
        ..iconName = 'wallet'
        ..order = 0
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = DateTime(2026, 3, 16);
      final bank = JiveAccount()
        ..key = 'acct_cmb'
        ..name = '招商银行'
        ..type = 'asset'
        ..currency = 'CNY'
        ..iconName = 'card'
        ..order = 1
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = DateTime(2026, 3, 16);
      await isar.writeTxn(() async {
        await isar.collection<JiveAccount>().putAll([wechat, bank]);
      });

      final draft = JiveAutoDraft()
        ..amount = 188.8
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 3, 16, 9)
        ..rawText = '微信零钱转到招商银行'
        ..type = 'transfer'
        ..category = '转账'
        ..subCategory = '转账'
        ..accountId = wechat.id
        ..metadataJson = jsonEncode({
          'transferToAccountName': '招商银行',
          'transferServiceCharge': 1.5,
        })
        ..createdAt = DateTime(2026, 3, 16, 9, 1);
      await isar.writeTxn(() async {
        await isar.collection<JiveAutoDraft>().put(draft);
      });

      await service.confirmDraft(draft);

      final transactions = await isar
          .collection<JiveTransaction>()
          .where()
          .findAll();
      expect(transactions, hasLength(1));
      expect(transactions.single.type, 'transfer');
      expect(transactions.single.accountId, wechat.id);
      expect(transactions.single.toAccountId, bank.id);
      expect(transactions.single.exchangeFee, 1.5);
      expect(await isar.collection<JiveAutoDraft>().count(), 0);
    },
  );

  test(
    'confirmDraft blocks transfer without resolvable target account',
    () async {
      final wechat = JiveAccount()
        ..key = 'acct_wechat'
        ..name = '微信'
        ..type = 'asset'
        ..currency = 'CNY'
        ..iconName = 'wallet'
        ..order = 0
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = DateTime(2026, 3, 16);
      await isar.writeTxn(() async {
        await isar.collection<JiveAccount>().put(wechat);
      });

      final draft = JiveAutoDraft()
        ..amount = 120
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 3, 16, 10)
        ..rawText = '微信零钱转到建设银行'
        ..type = 'transfer'
        ..category = '转账'
        ..subCategory = '转账'
        ..accountId = wechat.id
        ..metadataJson = jsonEncode({'transferToAccountName': '建设银行'})
        ..createdAt = DateTime(2026, 3, 16, 10, 1);
      await isar.writeTxn(() async {
        await isar.collection<JiveAutoDraft>().put(draft);
      });

      await expectLater(
        service.confirmDraft(draft),
        throwsA(
          isA<AutoDraftConfirmException>().having(
            (error) => error.code,
            'code',
            'missing_transfer_target_account',
          ),
        ),
      );

      expect(await isar.collection<JiveTransaction>().count(), 0);
      expect(await isar.collection<JiveAutoDraft>().count(), 1);
    },
  );

  test(
    'confirmDraft blocks same-account transfer after fallback resolution',
    () async {
      final wechat = JiveAccount()
        ..key = 'acct_wechat'
        ..name = '微信'
        ..type = 'asset'
        ..currency = 'CNY'
        ..iconName = 'wallet'
        ..order = 0
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..updatedAt = DateTime(2026, 3, 16);
      await isar.writeTxn(() async {
        await isar.collection<JiveAccount>().put(wechat);
      });

      final draft = JiveAutoDraft()
        ..amount = 66
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 3, 16, 11)
        ..rawText = '微信零钱转到微信零钱'
        ..type = 'transfer'
        ..category = '转账'
        ..subCategory = '转账'
        ..accountId = wechat.id
        ..metadataJson = jsonEncode({'transferToAccountName': '微信零钱'})
        ..createdAt = DateTime(2026, 3, 16, 11, 1);
      await isar.writeTxn(() async {
        await isar.collection<JiveAutoDraft>().put(draft);
      });

      await expectLater(
        service.confirmDraft(draft),
        throwsA(
          isA<AutoDraftConfirmException>().having(
            (error) => error.code,
            'code',
            'same_transfer_account',
          ),
        ),
      );

      expect(await isar.collection<JiveTransaction>().count(), 0);
      expect(await isar.collection<JiveAutoDraft>().count(), 1);
    },
  );
}
