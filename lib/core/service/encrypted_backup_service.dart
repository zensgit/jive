import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/tag_model.dart';
import '../database/transaction_model.dart';

/// Result of creating an encrypted backup.
class BackupResult {
  final String filePath;
  final int fileSize;
  final int recordCount;

  const BackupResult({
    required this.filePath,
    required this.fileSize,
    required this.recordCount,
  });
}

/// Result of restoring an encrypted backup.
class RestoreResult {
  final int recordCount;
  final bool success;
  final String? error;

  const RestoreResult({
    required this.recordCount,
    required this.success,
    this.error,
  });
}

/// Creates and restores encrypted backups of the Isar database.
///
/// Encryption uses XOR cipher with a SHA-256 derived key (no external AES
/// package required). Data is JSON-serialized and gzip-compressed before
/// encryption.
class EncryptedBackupService {
  static final DateFormat _fileDateFmt = DateFormat('yyyyMMdd_HHmmss');

  final Isar _isar;

  const EncryptedBackupService(this._isar);

  // ---------------------------------------------------------------------------
  // Create backup
  // ---------------------------------------------------------------------------

  /// Export all core data, compress, encrypt, and write to a file.
  Future<BackupResult> createEncryptedBackup(String password) async {
    // 1. Collect data
    final transactions =
        await _isar.jiveTransactions.where().findAll();
    final accounts =
        await _isar.collection<JiveAccount>().where().findAll();
    final categories =
        await _isar.collection<JiveCategory>().where().findAll();
    final tags = await _isar.collection<JiveTag>().where().findAll();

    final recordCount = transactions.length +
        accounts.length +
        categories.length +
        tags.length;

    final payload = <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map(_txToMap).toList(),
      'accounts': accounts.map(_accountToMap).toList(),
      'categories': categories.map(_categoryToMap).toList(),
      'tags': tags.map(_tagToMap).toList(),
    };

    // 2. JSON -> compress -> encrypt
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final compressed = gzip.encode(jsonBytes);
    final key = _deriveKey(password);
    final encrypted = _xorCipher(Uint8List.fromList(compressed), key);

    // 3. Write to file
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'jive_backup_${_fileDateFmt.format(DateTime.now())}.jbak';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(encrypted, flush: true);

    return BackupResult(
      filePath: file.path,
      fileSize: encrypted.length,
      recordCount: recordCount,
    );
  }

  // ---------------------------------------------------------------------------
  // Restore backup
  // ---------------------------------------------------------------------------

  /// Decrypt, decompress, and restore data from a backup file.
  Future<RestoreResult> restoreEncryptedBackup(
    String filePath,
    String password,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const RestoreResult(
          recordCount: 0,
          success: false,
          error: '备份文件不存在',
        );
      }

      final encrypted = await file.readAsBytes();
      final key = _deriveKey(password);
      final compressed = _xorCipher(Uint8List.fromList(encrypted), key);

      List<int> jsonBytes;
      try {
        jsonBytes = gzip.decode(compressed);
      } catch (_) {
        return const RestoreResult(
          recordCount: 0,
          success: false,
          error: '密码错误或文件已损坏',
        );
      }

      final Map<String, dynamic> payload;
      try {
        payload = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      } catch (_) {
        return const RestoreResult(
          recordCount: 0,
          success: false,
          error: '密码错误或文件已损坏',
        );
      }

      var recordCount = 0;

      await _isar.writeTxn(() async {
        // Restore transactions
        final txList = (payload['transactions'] as List<dynamic>?) ?? [];
        for (final raw in txList) {
          final map = raw as Map<String, dynamic>;
          await _isar.jiveTransactions.put(_mapToTx(map));
          recordCount++;
        }

        // Restore accounts
        final accList = (payload['accounts'] as List<dynamic>?) ?? [];
        for (final raw in accList) {
          final map = raw as Map<String, dynamic>;
          await _isar.collection<JiveAccount>().put(_mapToAccount(map));
          recordCount++;
        }

        // Restore categories
        final catList = (payload['categories'] as List<dynamic>?) ?? [];
        for (final raw in catList) {
          final map = raw as Map<String, dynamic>;
          await _isar.collection<JiveCategory>().put(_mapToCategory(map));
          recordCount++;
        }

        // Restore tags
        final tagList = (payload['tags'] as List<dynamic>?) ?? [];
        for (final raw in tagList) {
          final map = raw as Map<String, dynamic>;
          await _isar.collection<JiveTag>().put(_mapToTag(map));
          recordCount++;
        }
      });

      return RestoreResult(recordCount: recordCount, success: true);
    } catch (e) {
      return RestoreResult(
        recordCount: 0,
        success: false,
        error: '恢复失败：$e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Crypto helpers
  // ---------------------------------------------------------------------------

  /// Derive a 32-byte key from the password using SHA-256.
  Uint8List _deriveKey(String password) {
    final hash = sha256.convert(utf8.encode(password));
    return Uint8List.fromList(hash.bytes);
  }

  /// XOR cipher — symmetric, so encrypt and decrypt use the same call.
  Uint8List _xorCipher(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Serialization: Transaction
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _txToMap(JiveTransaction tx) {
    return {
      'id': tx.id,
      'amount': tx.amount,
      'source': tx.source,
      'timestamp': tx.timestamp.toIso8601String(),
      'rawText': tx.rawText,
      'category': tx.category,
      'subCategory': tx.subCategory,
      'categoryKey': tx.categoryKey,
      'subCategoryKey': tx.subCategoryKey,
      'type': tx.type,
      'note': tx.note,
      'accountId': tx.accountId,
      'toAccountId': tx.toAccountId,
      'toAmount': tx.toAmount,
      'exchangeRate': tx.exchangeRate,
      'exchangeFee': tx.exchangeFee,
      'exchangeFeeType': tx.exchangeFeeType,
      'projectId': tx.projectId,
      'tagKeys': tx.tagKeys,
      'excludeFromBudget': tx.excludeFromBudget,
      'bookId': tx.bookId,
    };
  }

  JiveTransaction _mapToTx(Map<String, dynamic> m) {
    return JiveTransaction()
      ..id = (m['id'] as num?)?.toInt() ?? Isar.autoIncrement
      ..amount = (m['amount'] as num).toDouble()
      ..source = m['source'] as String? ?? ''
      ..timestamp = DateTime.parse(m['timestamp'] as String)
      ..rawText = m['rawText'] as String?
      ..category = m['category'] as String?
      ..subCategory = m['subCategory'] as String?
      ..categoryKey = m['categoryKey'] as String?
      ..subCategoryKey = m['subCategoryKey'] as String?
      ..type = m['type'] as String?
      ..note = m['note'] as String?
      ..accountId = (m['accountId'] as num?)?.toInt()
      ..toAccountId = (m['toAccountId'] as num?)?.toInt()
      ..toAmount = (m['toAmount'] as num?)?.toDouble()
      ..exchangeRate = (m['exchangeRate'] as num?)?.toDouble()
      ..exchangeFee = (m['exchangeFee'] as num?)?.toDouble()
      ..exchangeFeeType = m['exchangeFeeType'] as String?
      ..projectId = (m['projectId'] as num?)?.toInt()
      ..tagKeys = _toStringList(m['tagKeys'])
      ..excludeFromBudget = m['excludeFromBudget'] as bool? ?? false
      ..bookId = (m['bookId'] as num?)?.toInt();
  }

  // ---------------------------------------------------------------------------
  // Serialization: Account
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _accountToMap(JiveAccount a) {
    return {
      'id': a.id,
      'key': a.key,
      'name': a.name,
      'type': a.type,
      'subType': a.subType,
      'groupName': a.groupName,
      'currency': a.currency,
      'iconName': a.iconName,
      'colorHex': a.colorHex,
      'order': a.order,
      'includeInBalance': a.includeInBalance,
      'isHidden': a.isHidden,
      'isArchived': a.isArchived,
      'billingDay': a.billingDay,
      'repaymentDay': a.repaymentDay,
      'creditLimit': a.creditLimit,
      'openingBalance': a.openingBalance,
      'updatedAt': a.updatedAt.toIso8601String(),
      'bookId': a.bookId,
    };
  }

  JiveAccount _mapToAccount(Map<String, dynamic> m) {
    return JiveAccount()
      ..id = (m['id'] as num?)?.toInt() ?? Isar.autoIncrement
      ..key = m['key'] as String
      ..name = m['name'] as String
      ..type = m['type'] as String
      ..subType = m['subType'] as String?
      ..groupName = m['groupName'] as String?
      ..currency = m['currency'] as String
      ..iconName = m['iconName'] as String
      ..colorHex = m['colorHex'] as String?
      ..order = (m['order'] as num).toInt()
      ..includeInBalance = m['includeInBalance'] as bool
      ..isHidden = m['isHidden'] as bool
      ..isArchived = m['isArchived'] as bool
      ..billingDay = (m['billingDay'] as num?)?.toInt()
      ..repaymentDay = (m['repaymentDay'] as num?)?.toInt()
      ..creditLimit = (m['creditLimit'] as num?)?.toDouble()
      ..openingBalance = (m['openingBalance'] as num?)?.toDouble() ?? 0
      ..updatedAt = DateTime.parse(m['updatedAt'] as String)
      ..bookId = (m['bookId'] as num?)?.toInt();
  }

  // ---------------------------------------------------------------------------
  // Serialization: Category
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _categoryToMap(JiveCategory c) {
    return {
      'id': c.id,
      'key': c.key,
      'name': c.name,
      'iconName': c.iconName,
      'colorHex': c.colorHex,
      'iconForceTinted': c.iconForceTinted,
      'excludeFromBudget': c.excludeFromBudget,
      'parentKey': c.parentKey,
      'sourceTagKey': c.sourceTagKey,
      'order': c.order,
      'isSystem': c.isSystem,
      'isHidden': c.isHidden,
      'isIncome': c.isIncome,
      'updatedAt': c.updatedAt.toIso8601String(),
    };
  }

  JiveCategory _mapToCategory(Map<String, dynamic> m) {
    return JiveCategory()
      ..id = (m['id'] as num?)?.toInt() ?? Isar.autoIncrement
      ..key = m['key'] as String
      ..name = m['name'] as String
      ..iconName = m['iconName'] as String
      ..colorHex = m['colorHex'] as String?
      ..iconForceTinted = m['iconForceTinted'] as bool? ?? false
      ..excludeFromBudget = m['excludeFromBudget'] as bool? ?? false
      ..parentKey = m['parentKey'] as String?
      ..sourceTagKey = m['sourceTagKey'] as String?
      ..order = (m['order'] as num).toInt()
      ..isSystem = m['isSystem'] as bool
      ..isHidden = m['isHidden'] as bool
      ..isIncome = m['isIncome'] as bool
      ..updatedAt = DateTime.parse(m['updatedAt'] as String);
  }

  // ---------------------------------------------------------------------------
  // Serialization: Tag
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _tagToMap(JiveTag t) {
    return {
      'id': t.id,
      'key': t.key,
      'name': t.name,
      'colorHex': t.colorHex,
      'iconName': t.iconName,
      'iconText': t.iconText,
      'groupKey': t.groupKey,
      'redirectCategoryKey': t.redirectCategoryKey,
      'order': t.order,
      'isArchived': t.isArchived,
      'usageCount': t.usageCount,
      'lastUsedAt': t.lastUsedAt?.toIso8601String(),
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': t.updatedAt.toIso8601String(),
    };
  }

  JiveTag _mapToTag(Map<String, dynamic> m) {
    return JiveTag()
      ..id = (m['id'] as num?)?.toInt() ?? Isar.autoIncrement
      ..key = m['key'] as String
      ..name = m['name'] as String
      ..colorHex = m['colorHex'] as String?
      ..iconName = m['iconName'] as String?
      ..iconText = m['iconText'] as String?
      ..groupKey = m['groupKey'] as String?
      ..redirectCategoryKey = m['redirectCategoryKey'] as String?
      ..order = (m['order'] as num).toInt()
      ..isArchived = m['isArchived'] as bool
      ..usageCount = (m['usageCount'] as num).toInt()
      ..lastUsedAt = m['lastUsedAt'] != null
          ? DateTime.parse(m['lastUsedAt'] as String)
          : null
      ..createdAt = DateTime.parse(m['createdAt'] as String)
      ..updatedAt = DateTime.parse(m['updatedAt'] as String);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }
}
