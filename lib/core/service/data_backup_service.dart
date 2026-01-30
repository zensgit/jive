import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../database/account_model.dart';
import '../database/auto_draft_model.dart';
import '../database/category_model.dart';
import '../database/currency_model.dart';
import '../database/tag_conversion_log.dart';
import '../database/tag_model.dart';
import '../database/tag_rule_model.dart';
import '../database/transaction_model.dart';

class BackupImportSummary {
  final int accounts;
  final int categories;
  final int categoryOverrides;
  final int tags;
  final int tagGroups;
  final int transactions;
  final int autoDrafts;
  final int tagConversionLogs;
  final int tagRules;
  final int exchangeRates;
  final int currencyPreferences;

  const BackupImportSummary({
    required this.accounts,
    required this.categories,
    required this.categoryOverrides,
    required this.tags,
    required this.tagGroups,
    required this.transactions,
    required this.autoDrafts,
    required this.tagConversionLogs,
    required this.tagRules,
    this.exchangeRates = 0,
    this.currencyPreferences = 0,
  });
}

class JiveDataBackupService {
  static const int schemaVersion = 2;

  static Future<File> exportToFile(Isar isar) async {
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final overrides = await isar.collection<JiveCategoryOverride>().where().findAll();
    final tags = await isar.collection<JiveTag>().where().findAll();
    final tagGroups = await isar.collection<JiveTagGroup>().where().findAll();
    final tagRules = await isar.collection<JiveTagRule>().where().findAll();
    final transactions = await isar.collection<JiveTransaction>().where().findAll();
    final autoDrafts = await isar.collection<JiveAutoDraft>().where().findAll();
    final logs = await isar.collection<JiveTagConversionLog>().where().findAll();
    final exchangeRates = await isar.collection<JiveExchangeRate>().where().findAll();
    final currencyPrefs = await isar.collection<JiveCurrencyPreference>().where().findAll();

    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts.map(_accountToMap).toList(),
      'categories': categories.map(_categoryToMap).toList(),
      'categoryOverrides': overrides.map(_categoryOverrideToMap).toList(),
      'tags': tags.map(_tagToMap).toList(),
      'tagGroups': tagGroups.map(_tagGroupToMap).toList(),
      'tagRules': tagRules.map(_tagRuleToMap).toList(),
      'transactions': transactions.map(_transactionToMap).toList(),
      'autoDrafts': autoDrafts.map(_autoDraftToMap).toList(),
      'tagConversionLogs': logs.map(_tagConversionLogToMap).toList(),
      'exchangeRates': exchangeRates.map(_exchangeRateToMap).toList(),
      'currencyPreferences': currencyPrefs.map(_currencyPreferenceToMap).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/jive_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  static Future<BackupImportSummary> importFromFile(
    Isar isar,
    File file, {
    bool clearBefore = true,
  }) async {
    final raw = await file.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final accounts = _decodeList(data['accounts'], _accountFromMap);
    final categories = _decodeList(data['categories'], _categoryFromMap);
    final overrides = _decodeList(data['categoryOverrides'], _categoryOverrideFromMap);
    final tags = _decodeList(data['tags'], _tagFromMap);
    final tagGroups = _decodeList(data['tagGroups'], _tagGroupFromMap);
    final tagRules = _decodeList(data['tagRules'], _tagRuleFromMap);
    final transactions = _decodeList(data['transactions'], _transactionFromMap);
    final autoDrafts = _decodeList(data['autoDrafts'], _autoDraftFromMap);
    final logs = _decodeList(data['tagConversionLogs'], _tagConversionLogFromMap);
    final exchangeRates = _decodeList(data['exchangeRates'], _exchangeRateFromMap);
    final currencyPrefs = _decodeList(data['currencyPreferences'], _currencyPreferenceFromMap);

    await isar.writeTxn(() async {
      if (clearBefore) {
        await isar.collection<JiveTransaction>().clear();
        await isar.collection<JiveAccount>().clear();
        await isar.collection<JiveCategory>().clear();
        await isar.collection<JiveCategoryOverride>().clear();
        await isar.collection<JiveAutoDraft>().clear();
        await isar.collection<JiveTag>().clear();
        await isar.collection<JiveTagGroup>().clear();
        await isar.collection<JiveTagConversionLog>().clear();
        await isar.collection<JiveExchangeRate>().clear();
        await isar.collection<JiveCurrencyPreference>().clear();
      }

      if (accounts.isNotEmpty) {
        await isar.collection<JiveAccount>().putAll(accounts);
      }
      if (categories.isNotEmpty) {
        await isar.collection<JiveCategory>().putAll(categories);
      }
      if (overrides.isNotEmpty) {
        await isar.collection<JiveCategoryOverride>().putAll(overrides);
      }
      if (tags.isNotEmpty) {
        await isar.collection<JiveTag>().putAll(tags);
      }
      if (tagGroups.isNotEmpty) {
        await isar.collection<JiveTagGroup>().putAll(tagGroups);
      }
      if (tagRules.isNotEmpty) {
        await isar.collection<JiveTagRule>().putAll(tagRules);
      }
      if (transactions.isNotEmpty) {
        await isar.collection<JiveTransaction>().putAll(transactions);
      }
      if (autoDrafts.isNotEmpty) {
        await isar.collection<JiveAutoDraft>().putAll(autoDrafts);
      }
      if (logs.isNotEmpty) {
        await isar.collection<JiveTagConversionLog>().putAll(logs);
      }
      if (exchangeRates.isNotEmpty) {
        await isar.collection<JiveExchangeRate>().putAll(exchangeRates);
      }
      if (currencyPrefs.isNotEmpty) {
        await isar.collection<JiveCurrencyPreference>().putAll(currencyPrefs);
      }
    });

    return BackupImportSummary(
      accounts: accounts.length,
      categories: categories.length,
      categoryOverrides: overrides.length,
      tags: tags.length,
      tagGroups: tagGroups.length,
      tagRules: tagRules.length,
      transactions: transactions.length,
      autoDrafts: autoDrafts.length,
      tagConversionLogs: logs.length,
      exchangeRates: exchangeRates.length,
      currencyPreferences: currencyPrefs.length,
    );
  }

  static List<T> _decodeList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => mapper(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Map<String, dynamic> _accountToMap(JiveAccount account) => {
        'id': account.id,
        'key': account.key,
        'name': account.name,
        'type': account.type,
        'subType': account.subType,
        'groupName': account.groupName,
        'currency': account.currency,
        'iconName': account.iconName,
        'colorHex': account.colorHex,
        'order': account.order,
        'includeInBalance': account.includeInBalance,
        'isHidden': account.isHidden,
        'isArchived': account.isArchived,
        'billingDay': account.billingDay,
        'repaymentDay': account.repaymentDay,
        'creditLimit': account.creditLimit,
        'openingBalance': account.openingBalance,
        'updatedAt': account.updatedAt.toIso8601String(),
      };

  static JiveAccount _accountFromMap(Map<String, dynamic> map) {
    final account = JiveAccount()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..key = map['key']?.toString() ?? ''
      ..name = map['name']?.toString() ?? ''
      ..type = map['type']?.toString() ?? 'asset'
      ..subType = map['subType']?.toString()
      ..groupName = map['groupName']?.toString()
      ..currency = map['currency']?.toString() ?? 'CNY'
      ..iconName = map['iconName']?.toString() ?? ''
      ..colorHex = map['colorHex']?.toString()
      ..order = _parseInt(map['order']) ?? 0
      ..includeInBalance = map['includeInBalance'] == true
      ..isHidden = map['isHidden'] == true
      ..isArchived = map['isArchived'] == true
      ..billingDay = _parseInt(map['billingDay'])
      ..repaymentDay = _parseInt(map['repaymentDay'])
      ..creditLimit = _parseDouble(map['creditLimit'])
      ..openingBalance = _parseDouble(map['openingBalance']) ?? 0
      ..updatedAt = _parseDate(map['updatedAt']) ?? DateTime.now();
    return account;
  }

  static Map<String, dynamic> _categoryToMap(JiveCategory category) => {
        'id': category.id,
        'key': category.key,
        'name': category.name,
        'iconName': category.iconName,
        'colorHex': category.colorHex,
        'parentKey': category.parentKey,
        'sourceTagKey': category.sourceTagKey,
        'order': category.order,
        'isSystem': category.isSystem,
        'isHidden': category.isHidden,
        'isIncome': category.isIncome,
        'updatedAt': category.updatedAt.toIso8601String(),
      };

  static JiveCategory _categoryFromMap(Map<String, dynamic> map) {
    final category = JiveCategory()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..key = map['key']?.toString() ?? ''
      ..name = map['name']?.toString() ?? ''
      ..iconName = map['iconName']?.toString() ?? ''
      ..colorHex = map['colorHex']?.toString()
      ..parentKey = map['parentKey']?.toString()
      ..sourceTagKey = map['sourceTagKey']?.toString()
      ..order = _parseInt(map['order']) ?? 0
      ..isSystem = map['isSystem'] == true
      ..isHidden = map['isHidden'] == true
      ..isIncome = map['isIncome'] == true
      ..updatedAt = _parseDate(map['updatedAt']) ?? DateTime.now();
    return category;
  }

  static Map<String, dynamic> _categoryOverrideToMap(JiveCategoryOverride override) => {
        'id': override.id,
        'systemKey': override.systemKey,
        'nameOverride': override.nameOverride,
        'iconOverride': override.iconOverride,
        'colorHexOverride': override.colorHexOverride,
        'parentOverrideKey': override.parentOverrideKey,
        'orderOverride': override.orderOverride,
        'isHiddenOverride': override.isHiddenOverride,
        'updatedAt': override.updatedAt.toIso8601String(),
      };

  static JiveCategoryOverride _categoryOverrideFromMap(Map<String, dynamic> map) {
    final override = JiveCategoryOverride()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..systemKey = map['systemKey']?.toString() ?? ''
      ..nameOverride = map['nameOverride']?.toString()
      ..iconOverride = map['iconOverride']?.toString()
      ..colorHexOverride = map['colorHexOverride']?.toString()
      ..parentOverrideKey = map['parentOverrideKey']?.toString()
      ..orderOverride = _parseInt(map['orderOverride'])
      ..isHiddenOverride = map['isHiddenOverride'] as bool?
      ..updatedAt = _parseDate(map['updatedAt']) ?? DateTime.now();
    return override;
  }

  static Map<String, dynamic> _tagToMap(JiveTag tag) => {
        'id': tag.id,
        'key': tag.key,
        'name': tag.name,
        'colorHex': tag.colorHex,
        'iconName': tag.iconName,
        'iconText': tag.iconText,
        'groupKey': tag.groupKey,
        'redirectCategoryKey': tag.redirectCategoryKey,
        'order': tag.order,
        'isArchived': tag.isArchived,
        'usageCount': tag.usageCount,
        'lastUsedAt': tag.lastUsedAt?.toIso8601String(),
        'createdAt': tag.createdAt.toIso8601String(),
        'updatedAt': tag.updatedAt.toIso8601String(),
      };

  static JiveTag _tagFromMap(Map<String, dynamic> map) {
    final tag = JiveTag()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..key = map['key']?.toString() ?? ''
      ..name = map['name']?.toString() ?? ''
      ..colorHex = map['colorHex']?.toString()
      ..iconName = map['iconName']?.toString()
      ..iconText = map['iconText']?.toString()
      ..groupKey = map['groupKey']?.toString()
      ..redirectCategoryKey = map['redirectCategoryKey']?.toString()
      ..order = _parseInt(map['order']) ?? 0
      ..isArchived = map['isArchived'] == true
      ..usageCount = _parseInt(map['usageCount']) ?? 0
      ..lastUsedAt = _parseDate(map['lastUsedAt'])
      ..createdAt = _parseDate(map['createdAt']) ?? DateTime.now()
      ..updatedAt = _parseDate(map['updatedAt']) ?? DateTime.now();
    return tag;
  }

  static Map<String, dynamic> _tagGroupToMap(JiveTagGroup group) => {
        'id': group.id,
        'key': group.key,
        'name': group.name,
        'colorHex': group.colorHex,
        'iconName': group.iconName,
        'iconText': group.iconText,
        'order': group.order,
        'isArchived': group.isArchived,
        'createdAt': group.createdAt.toIso8601String(),
        'updatedAt': group.updatedAt.toIso8601String(),
      };

  static JiveTagGroup _tagGroupFromMap(Map<String, dynamic> map) {
    final group = JiveTagGroup()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..key = map['key']?.toString() ?? ''
      ..name = map['name']?.toString() ?? ''
      ..colorHex = map['colorHex']?.toString()
      ..iconName = map['iconName']?.toString()
      ..iconText = map['iconText']?.toString()
      ..order = _parseInt(map['order']) ?? 0
      ..isArchived = map['isArchived'] == true
      ..createdAt = _parseDate(map['createdAt']) ?? DateTime.now()
      ..updatedAt = _parseDate(map['updatedAt']) ?? DateTime.now();
    return group;
  }

  static Map<String, dynamic> _tagRuleToMap(JiveTagRule rule) => {
        'id': rule.id,
        'tagKey': rule.tagKey,
        'isEnabled': rule.isEnabled,
        'applyType': rule.applyType,
        'minAmount': rule.minAmount,
        'maxAmount': rule.maxAmount,
        'accountIds': rule.accountIds,
        'categoryKey': rule.categoryKey,
        'subCategoryKey': rule.subCategoryKey,
        'keywords': rule.keywords,
        'createdAt': rule.createdAt.toIso8601String(),
        'updatedAt': rule.updatedAt.toIso8601String(),
      };

  static JiveTagRule _tagRuleFromMap(Map<String, dynamic> map) {
    final rule = JiveTagRule()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..tagKey = map['tagKey']?.toString() ?? ''
      ..isEnabled = map['isEnabled'] == true
      ..applyType = map['applyType']?.toString()
      ..minAmount = _parseDouble(map['minAmount'])
      ..maxAmount = _parseDouble(map['maxAmount'])
      ..accountIds = List<int>.from(map['accountIds'] ?? [])
      ..categoryKey = map['categoryKey']?.toString()
      ..subCategoryKey = map['subCategoryKey']?.toString()
      ..keywords = List<String>.from(map['keywords'] ?? [])
      ..createdAt = _parseDate(map['createdAt']) ?? DateTime.now()
      ..updatedAt = _parseDate(map['updatedAt']) ?? DateTime.now();
    return rule;
  }

  static Map<String, dynamic> _transactionToMap(JiveTransaction tx) => {
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
        'projectId': tx.projectId,
        'tagKeys': tx.tagKeys,
        'smartTagKeys': tx.smartTagKeys,
      };

  static JiveTransaction _transactionFromMap(Map<String, dynamic> map) {
    final tx = JiveTransaction()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..amount = _parseDouble(map['amount']) ?? 0
      ..source = map['source']?.toString() ?? ''
      ..timestamp = _parseDate(map['timestamp']) ?? DateTime.now()
      ..rawText = map['rawText']?.toString()
      ..category = map['category']?.toString()
      ..subCategory = map['subCategory']?.toString()
      ..categoryKey = map['categoryKey']?.toString()
      ..subCategoryKey = map['subCategoryKey']?.toString()
      ..type = map['type']?.toString()
      ..note = map['note']?.toString()
      ..accountId = _parseInt(map['accountId'])
      ..toAccountId = _parseInt(map['toAccountId'])
      ..toAmount = _parseDouble(map['toAmount'])
      ..exchangeRate = _parseDouble(map['exchangeRate'])
      ..projectId = _parseInt(map['projectId'])
      ..tagKeys = List<String>.from(map['tagKeys'] ?? [])
      ..smartTagKeys = List<String>.from(map['smartTagKeys'] ?? []);
    return tx;
  }

  static Map<String, dynamic> _autoDraftToMap(JiveAutoDraft draft) => {
        'id': draft.id,
        'amount': draft.amount,
        'source': draft.source,
        'timestamp': draft.timestamp.toIso8601String(),
        'rawText': draft.rawText,
        'type': draft.type,
        'category': draft.category,
        'subCategory': draft.subCategory,
        'categoryKey': draft.categoryKey,
        'subCategoryKey': draft.subCategoryKey,
        'accountId': draft.accountId,
        'toAccountId': draft.toAccountId,
        'dedupKey': draft.dedupKey,
        'createdAt': draft.createdAt.toIso8601String(),
        'tagKeys': draft.tagKeys,
      };

  static JiveAutoDraft _autoDraftFromMap(Map<String, dynamic> map) {
    final draft = JiveAutoDraft()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..amount = _parseDouble(map['amount']) ?? 0
      ..source = map['source']?.toString() ?? ''
      ..timestamp = _parseDate(map['timestamp']) ?? DateTime.now()
      ..rawText = map['rawText']?.toString()
      ..type = map['type']?.toString()
      ..category = map['category']?.toString()
      ..subCategory = map['subCategory']?.toString()
      ..categoryKey = map['categoryKey']?.toString()
      ..subCategoryKey = map['subCategoryKey']?.toString()
      ..accountId = _parseInt(map['accountId'])
      ..toAccountId = _parseInt(map['toAccountId'])
      ..dedupKey = map['dedupKey']?.toString()
      ..createdAt = _parseDate(map['createdAt']) ?? DateTime.now()
      ..tagKeys = List<String>.from(map['tagKeys'] ?? []);
    return draft;
  }

  static Map<String, dynamic> _tagConversionLogToMap(JiveTagConversionLog log) => {
        'id': log.id,
        'tagKey': log.tagKey,
        'tagName': log.tagName,
        'categoryKey': log.categoryKey,
        'parentCategoryKey': log.parentCategoryKey,
        'categoryName': log.categoryName,
        'parentCategoryName': log.parentCategoryName,
        'categoryIsIncome': log.categoryIsIncome,
        'migratePolicy': log.migratePolicy,
        'keepTagActive': log.keepTagActive,
        'taggedTransactionCount': log.taggedTransactionCount,
        'updatedTransactionCount': log.updatedTransactionCount,
        'skippedExistingCategoryCount': log.skippedExistingCategoryCount,
        'skippedTypeMismatchCount': log.skippedTypeMismatchCount,
        'skippedUnknownCategoryCount': log.skippedUnknownCategoryCount,
        'skippedByPolicyCount': log.skippedByPolicyCount,
        'updatedTransactionIds': log.updatedTransactionIds,
        'createdAt': log.createdAt.toIso8601String(),
      };

  static JiveTagConversionLog _tagConversionLogFromMap(Map<String, dynamic> map) {
    final log = JiveTagConversionLog()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..tagKey = map['tagKey']?.toString() ?? ''
      ..tagName = map['tagName']?.toString() ?? ''
      ..categoryKey = map['categoryKey']?.toString() ?? ''
      ..parentCategoryKey = map['parentCategoryKey']?.toString()
      ..categoryName = map['categoryName']?.toString() ?? ''
      ..parentCategoryName = map['parentCategoryName']?.toString()
      ..categoryIsIncome = map['categoryIsIncome'] == true
      ..migratePolicy = map['migratePolicy']?.toString() ?? ''
      ..keepTagActive = map['keepTagActive'] == true
      ..taggedTransactionCount = _parseInt(map['taggedTransactionCount']) ?? 0
      ..updatedTransactionCount = _parseInt(map['updatedTransactionCount']) ?? 0
      ..skippedExistingCategoryCount = _parseInt(map['skippedExistingCategoryCount']) ?? 0
      ..skippedTypeMismatchCount = _parseInt(map['skippedTypeMismatchCount']) ?? 0
      ..skippedUnknownCategoryCount = _parseInt(map['skippedUnknownCategoryCount']) ?? 0
      ..skippedByPolicyCount = _parseInt(map['skippedByPolicyCount']) ?? 0
      ..updatedTransactionIds = List<int>.from(map['updatedTransactionIds'] ?? [])
      ..createdAt = _parseDate(map['createdAt']) ?? DateTime.now();
    return log;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  // 汇率数据转换
  static Map<String, dynamic> _exchangeRateToMap(JiveExchangeRate rate) => {
        'id': rate.id,
        'fromCurrency': rate.fromCurrency,
        'toCurrency': rate.toCurrency,
        'rate': rate.rate,
        'effectiveDate': rate.effectiveDate.toIso8601String(),
        'source': rate.source,
        'updatedAt': rate.updatedAt?.toIso8601String(),
      };

  static JiveExchangeRate _exchangeRateFromMap(Map<String, dynamic> map) {
    final rate = JiveExchangeRate()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..fromCurrency = map['fromCurrency']?.toString() ?? ''
      ..toCurrency = map['toCurrency']?.toString() ?? ''
      ..rate = _parseDouble(map['rate']) ?? 1.0
      ..effectiveDate = _parseDate(map['effectiveDate']) ?? DateTime.now()
      ..source = map['source']?.toString() ?? 'backup'
      ..updatedAt = _parseDate(map['updatedAt']);
    return rate;
  }

  // 货币偏好数据转换
  static Map<String, dynamic> _currencyPreferenceToMap(JiveCurrencyPreference pref) => {
        'id': pref.id,
        'baseCurrency': pref.baseCurrency,
        'enabledCurrencies': pref.enabledCurrencies,
        'autoUpdateRates': pref.autoUpdateRates,
        'lastRateUpdate': pref.lastRateUpdate?.toIso8601String(),
      };

  static JiveCurrencyPreference _currencyPreferenceFromMap(Map<String, dynamic> map) {
    final pref = JiveCurrencyPreference()
      ..id = _parseInt(map['id']) ?? Isar.autoIncrement
      ..baseCurrency = map['baseCurrency']?.toString() ?? 'CNY'
      ..enabledCurrencies = List<String>.from(map['enabledCurrencies'] ?? [])
      ..autoUpdateRates = map['autoUpdateRates'] == true
      ..lastRateUpdate = _parseDate(map['lastRateUpdate']);
    return pref;
  }
}
