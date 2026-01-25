import 'package:isar/isar.dart';

import '../database/tag_model.dart';
import '../database/tag_rule_model.dart';
import '../database/transaction_model.dart';
import 'tag_service.dart';

class TagRuleBackfillResult {
  final int scannedCount;
  final int matchedCount;
  final int updatedCount;
  final int skippedCount;
  final bool cancelled;

  const TagRuleBackfillResult({
    required this.scannedCount,
    required this.matchedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.cancelled,
  });
}

class TagRuleService {
  final Isar isar;

  TagRuleService(this.isar);

  Future<List<JiveTagRule>> getRules(String tagKey) {
    return isar
        .collection<JiveTagRule>()
        .filter()
        .tagKeyEqualTo(tagKey)
        .findAll();
  }

  Future<JiveTagRule> createRule({
    required String tagKey,
    required bool isEnabled,
    String? applyType,
    double? minAmount,
    double? maxAmount,
    List<int>? accountIds,
    String? categoryKey,
    String? subCategoryKey,
    List<String>? keywords,
  }) async {
    final now = DateTime.now();
    final rule = JiveTagRule()
      ..tagKey = tagKey
      ..isEnabled = isEnabled
      ..applyType = applyType
      ..minAmount = minAmount
      ..maxAmount = maxAmount
      ..accountIds = accountIds ?? []
      ..categoryKey = categoryKey
      ..subCategoryKey = subCategoryKey
      ..keywords = keywords ?? []
      ..createdAt = now
      ..updatedAt = now;
    await isar.writeTxn(() async {
      await isar.collection<JiveTagRule>().put(rule);
    });
    return rule;
  }

  Future<void> updateRule(JiveTagRule rule) async {
    rule.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveTagRule>().put(rule);
    });
  }

  Future<void> deleteRule(JiveTagRule rule) async {
    await isar.writeTxn(() async {
      await isar.collection<JiveTagRule>().delete(rule.id);
    });
  }

  Future<void> deleteRulesByTag(String tagKey) async {
    final rules = await getRules(tagKey);
    if (rules.isEmpty) return;
    final ids = rules.map((rule) => rule.id).toList();
    await isar.writeTxn(() async {
      await isar.collection<JiveTagRule>().deleteAll(ids);
    });
  }

  Future<void> reassignRules({
    required List<String> sourceKeys,
    required String targetKey,
  }) async {
    if (sourceKeys.isEmpty) return;
    final rules = await isar
        .collection<JiveTagRule>()
        .where()
        .anyOf(sourceKeys, (query, key) => query.tagKeyEqualTo(key))
        .findAll();
    if (rules.isEmpty) return;
    final now = DateTime.now();
    for (final rule in rules) {
      rule.tagKey = targetKey;
      rule.updatedAt = now;
    }
    await isar.writeTxn(() async {
      await isar.collection<JiveTagRule>().putAll(rules);
    });
  }

  Future<List<String>> resolveMatchingTags(JiveTransaction tx) async {
    final rules = await isar
        .collection<JiveTagRule>()
        .filter()
        .isEnabledEqualTo(true)
        .findAll();
    if (rules.isEmpty) return [];

    final tags = await isar.collection<JiveTag>().where().findAll();
    final activeTagKeys = {
      for (final tag in tags)
        if (!tag.isArchived) tag.key,
    };

    final matched = <String>{};
    for (final rule in rules) {
      if (!activeTagKeys.contains(rule.tagKey)) continue;
      if (!_matches(rule, tx)) continue;
      matched.add(rule.tagKey);
    }
    return matched.toList();
  }

  Future<TagRuleBackfillResult> backfillForTag(
    String tagKey, {
    bool Function()? shouldCancel,
    void Function(int processed, int total)? onProgress,
  }) async {
    final rules = await isar
        .collection<JiveTagRule>()
        .filter()
        .tagKeyEqualTo(tagKey)
        .isEnabledEqualTo(true)
        .findAll();
    if (rules.isEmpty) {
      return const TagRuleBackfillResult(
        scannedCount: 0,
        matchedCount: 0,
        updatedCount: 0,
        skippedCount: 0,
        cancelled: false,
      );
    }

    final txs = await isar.jiveTransactions.where().findAll();
    if (txs.isEmpty) {
      return const TagRuleBackfillResult(
        scannedCount: 0,
        matchedCount: 0,
        updatedCount: 0,
        skippedCount: 0,
        cancelled: false,
      );
    }

    final updates = <JiveTransaction>[];
    var matchedCount = 0;
    var updatedCount = 0;
    var processed = 0;
    var cancelled = false;
    final total = txs.length;
    for (final tx in txs) {
      processed += 1;
      if (processed % 20 == 0 && onProgress != null) {
        onProgress(processed, total);
      }
      if (shouldCancel != null && shouldCancel()) {
        cancelled = true;
        break;
      }
      final matched = rules.any((rule) => _matches(rule, tx));
      if (!matched) continue;
      matchedCount += 1;
      if (tx.tagKeys.contains(tagKey)) {
        continue;
      }
      tx.tagKeys = <String>{...tx.tagKeys, tagKey}.toList();
      tx.smartTagKeys = <String>{...tx.smartTagKeys, tagKey}.toList();
      updates.add(tx);
      updatedCount += 1;
    }

    if (updates.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().putAll(updates);
      });
      await TagService(isar).refreshUsageCounts(tagKeys: [tagKey]);
    }

    return TagRuleBackfillResult(
      scannedCount: total,
      matchedCount: matchedCount,
      updatedCount: updatedCount,
      skippedCount: matchedCount - updatedCount,
      cancelled: cancelled,
    );
  }

  bool _matches(JiveTagRule rule, JiveTransaction tx) {
    if (!rule.isEnabled) return false;
    final type = (tx.type ?? 'expense').toLowerCase();
    final ruleType = (rule.applyType ?? 'all').toLowerCase();
    if (ruleType != 'all' && ruleType != type) return false;

    if (rule.minAmount != null && tx.amount < rule.minAmount!) return false;
    if (rule.maxAmount != null && tx.amount > rule.maxAmount!) return false;

    if (rule.accountIds.isNotEmpty) {
      final accountId = tx.accountId;
      final toAccountId = tx.toAccountId;
      final match =
          (accountId != null && rule.accountIds.contains(accountId)) ||
              (toAccountId != null && rule.accountIds.contains(toAccountId));
      if (!match) return false;
    }

    if (rule.categoryKey != null && rule.categoryKey!.isNotEmpty) {
      if (tx.categoryKey != rule.categoryKey) return false;
    }
    if (rule.subCategoryKey != null && rule.subCategoryKey!.isNotEmpty) {
      if (tx.subCategoryKey != rule.subCategoryKey) return false;
    }

    if (rule.keywords.isNotEmpty) {
      final haystack =
          '${tx.note ?? ''} ${tx.rawText ?? ''}'.toLowerCase().trim();
      if (haystack.isEmpty) return false;
      final match = rule.keywords.any((keyword) => haystack.contains(keyword));
      if (!match) return false;
    }

    return true;
  }
}
