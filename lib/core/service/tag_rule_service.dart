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

class TagRuleEstimate {
  final int scannedCount;
  final int matchedCount;
  final int alreadyTaggedCount;
  final int willTagCount;

  const TagRuleEstimate({
    required this.scannedCount,
    required this.matchedCount,
    required this.alreadyTaggedCount,
    required this.willTagCount,
  });
}

class SmartTagCleanupEstimate {
  final int scannedCount;
  final int smartTaggedCount;
  final int willRemoveSmartCount;
  final int willRemoveTagCount;

  const SmartTagCleanupEstimate({
    required this.scannedCount,
    required this.smartTaggedCount,
    required this.willRemoveSmartCount,
    required this.willRemoveTagCount,
  });
}

class SmartTagCleanupResult {
  final int scannedCount;
  final int smartTaggedCount;
  final int updatedCount;
  final int removedTagCount;
  final bool cancelled;

  const SmartTagCleanupResult({
    required this.scannedCount,
    required this.smartTaggedCount,
    required this.updatedCount,
    required this.removedTagCount,
    required this.cancelled,
  });
}

class RuleMatchDetail {
  final JiveTagRule rule;
  final int? matchedAccountId;
  final List<String> matchedKeywords;

  const RuleMatchDetail({
    required this.rule,
    required this.matchedAccountId,
    required this.matchedKeywords,
  });
}

class SmartTagMatchExplanation {
  final String tagKey;
  final List<RuleMatchDetail> matches;

  const SmartTagMatchExplanation({
    required this.tagKey,
    required this.matches,
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

  Future<int> setEnabledForTag(String tagKey, bool enabled) async {
    final rules = await isar
        .collection<JiveTagRule>()
        .filter()
        .tagKeyEqualTo(tagKey)
        .findAll();
    if (rules.isEmpty) return 0;
    final now = DateTime.now();
    for (final rule in rules) {
      rule.isEnabled = enabled;
      rule.updatedAt = now;
    }
    await isar.writeTxn(() async {
      await isar.collection<JiveTagRule>().putAll(rules);
    });
    return rules.length;
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
      if (_isOptedOut(tx, rule.tagKey)) continue;
      if (!_matches(rule, tx)) continue;
      matched.add(rule.tagKey);
    }
    return matched.toList();
  }

  Future<List<SmartTagMatchExplanation>> explainForTransaction(
    JiveTransaction tx, {
    Set<String>? tagKeys,
    bool onlySmartTagged = false,
  }) async {
    final rules = await isar
        .collection<JiveTagRule>()
        .filter()
        .isEnabledEqualTo(true)
        .findAll();
    if (rules.isEmpty) return const [];

    final tags = await isar.collection<JiveTag>().where().findAll();
    final activeTagKeys = {
      for (final tag in tags)
        if (!tag.isArchived) tag.key,
    };
    final filterKeys = tagKeys == null ? null : {...tagKeys};
    final smartKeys = {...tx.smartTagKeys};

    final grouped = <String, List<RuleMatchDetail>>{};
    for (final rule in rules) {
      final tagKey = rule.tagKey;
      if (!activeTagKeys.contains(tagKey)) continue;
      if (_isOptedOut(tx, tagKey)) continue;
      if (filterKeys != null && !filterKeys.contains(tagKey)) continue;
      if (onlySmartTagged && !smartKeys.contains(tagKey)) continue;
      final detail = _matchDetail(rule, tx);
      if (detail == null) continue;
      grouped.putIfAbsent(tagKey, () => []).add(detail);
    }

    final result = grouped.entries
        .map(
          (entry) => SmartTagMatchExplanation(
            tagKey: entry.key,
            matches: entry.value
              ..sort((a, b) => b.rule.updatedAt.compareTo(a.rule.updatedAt)),
          ),
        )
        .toList()
      ..sort((a, b) => a.tagKey.compareTo(b.tagKey));
    return result;
  }

  Future<List<JiveTransaction>> recentSmartMatchesForTag(
    String tagKey, {
    int limit = 30,
  }) {
    return isar
        .collection<JiveTransaction>()
        .filter()
        .smartTagKeysElementEqualTo(tagKey)
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }

  Future<Map<int, SmartTagMatchExplanation>> explainForTransactionsForTag(
    String tagKey,
    List<JiveTransaction> txs,
  ) async {
    if (txs.isEmpty) return const {};
    final tag = await isar.collection<JiveTag>().filter().keyEqualTo(tagKey).findFirst();
    if (tag == null || tag.isArchived) return const {};

    final rules = await isar
        .collection<JiveTagRule>()
        .filter()
        .tagKeyEqualTo(tagKey)
        .isEnabledEqualTo(true)
        .findAll();
    if (rules.isEmpty) return const {};

    final result = <int, SmartTagMatchExplanation>{};
    for (final tx in txs) {
      if (_isOptedOut(tx, tagKey)) continue;
      final matches = <RuleMatchDetail>[];
      for (final rule in rules) {
        final detail = _matchDetail(rule, tx);
        if (detail != null) {
          matches.add(detail);
        }
      }
      if (matches.isEmpty) continue;
      matches.sort((a, b) => b.rule.updatedAt.compareTo(a.rule.updatedAt));
      result[tx.id] = SmartTagMatchExplanation(tagKey: tagKey, matches: matches);
    }
    return result;
  }

  Future<void> optOutTagForTransaction(
    int transactionId,
    String tagKey, {
    bool removeExistingSmartTag = true,
    bool removeTagToo = false,
  }) async {
    final tx = await isar.collection<JiveTransaction>().get(transactionId);
    if (tx == null) return;

    final nextOptOut = {...tx.smartTagOptOutKeys, tagKey}.toList();
    var changed = nextOptOut.length != tx.smartTagOptOutKeys.length;

    if (changed) {
      tx.smartTagOptOutKeys = nextOptOut;
    }

    if (removeExistingSmartTag && tx.smartTagKeys.contains(tagKey)) {
      final nextSmart = tx.smartTagKeys.where((key) => key != tagKey).toList();
      if (nextSmart.length != tx.smartTagKeys.length) {
        tx.smartTagKeys = nextSmart;
        changed = true;
      }
    }
    if (removeTagToo && tx.tagKeys.contains(tagKey)) {
      tx.tagKeys = tx.tagKeys.where((key) => key != tagKey).toList();
      changed = true;
    }

    if (!changed) return;

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
    });
    await TagService(isar).refreshUsageCounts(tagKeys: [tagKey]);
  }

  Future<bool> optOutAllForTransaction(
    int transactionId, {
    bool removeExistingSmartTags = true,
  }) async {
    final tx = await isar.collection<JiveTransaction>().get(transactionId);
    if (tx == null) return false;

    var changed = false;
    if (!tx.smartTagOptOutAll) {
      tx.smartTagOptOutAll = true;
      changed = true;
    }

    if (removeExistingSmartTags && tx.smartTagKeys.isNotEmpty) {
      tx.smartTagKeys = [];
      changed = true;
    }

    if (!changed) return false;

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
    });
    return true;
  }

  Future<int> restoreAllSmartTagsForTransaction(int transactionId) async {
    final tx = await isar.collection<JiveTransaction>().get(transactionId);
    if (tx == null) return 0;

    tx.smartTagOptOutAll = false;
    tx.smartTagOptOutKeys = [];

    final matched = await resolveMatchingTags(tx);
    tx.smartTagKeys = matched;
    tx.tagKeys = <String>{...tx.tagKeys, ...matched}.toList();

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
    });
    if (matched.isNotEmpty) {
      await TagService(isar).refreshUsageCounts(tagKeys: matched);
    }
    return matched.length;
  }

  Future<bool> restoreOptOutForTransaction(
    int transactionId,
    String tagKey,
  ) async {
    final tx = await isar.collection<JiveTransaction>().get(transactionId);
    if (tx == null) return false;
    if (!tx.smartTagOptOutKeys.contains(tagKey)) return false;

    tx.smartTagOptOutKeys =
        tx.smartTagOptOutKeys.where((key) => key != tagKey).toList();

    final rules = await isar
        .collection<JiveTagRule>()
        .filter()
        .tagKeyEqualTo(tagKey)
        .isEnabledEqualTo(true)
        .findAll();

    var matched = false;
    if (rules.isNotEmpty && rules.any((rule) => _matches(rule, tx))) {
      matched = true;
      tx.smartTagKeys = <String>{...tx.smartTagKeys, tagKey}.toList();
      tx.tagKeys = <String>{...tx.tagKeys, tagKey}.toList();
    }

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
    });
    await TagService(isar).refreshUsageCounts(tagKeys: [tagKey]);
    return matched;
  }

  Future<int> clearOptOutsForTransaction(
    int transactionId, {
    List<String>? tagKeys,
  }) async {
    final tx = await isar.collection<JiveTransaction>().get(transactionId);
    if (tx == null) return 0;
    if (tx.smartTagOptOutKeys.isEmpty) return 0;

    final filterKeys = tagKeys == null ? null : tagKeys.toSet();
    final original = tx.smartTagOptOutKeys;
    final next = filterKeys == null
        ? <String>[]
        : original.where((key) => !filterKeys.contains(key)).toList();
    if (next.length == original.length) return 0;

    tx.smartTagOptOutKeys = next;
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
    });
    return original.length - next.length;
  }

  Future<int> clearAllOptOutsForTransaction(int transactionId) async {
    final tx = await isar.collection<JiveTransaction>().get(transactionId);
    if (tx == null) return 0;

    final removedCount = tx.smartTagOptOutKeys.length;
    final hadAll = tx.smartTagOptOutAll;
    if (removedCount == 0 && !hadAll) return 0;

    tx.smartTagOptOutKeys = [];
    tx.smartTagOptOutAll = false;
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
    });
    return removedCount + (hadAll ? 1 : 0);
  }
  Future<TagRuleBackfillResult> backfillForTag(
    String tagKey, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
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

    final txs = await _loadTransactionsInRange(rangeStart, rangeEnd);
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
      if (_isOptedOut(tx, tagKey)) {
        continue;
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

  Future<TagRuleEstimate> estimateRule({
    required String tagKey,
    String? applyType,
    double? minAmount,
    double? maxAmount,
    List<int>? accountIds,
    String? categoryKey,
    String? subCategoryKey,
    List<String>? keywords,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final txs = await _loadTransactionsInRange(rangeStart, rangeEnd);
    if (txs.isEmpty) {
      return const TagRuleEstimate(
        scannedCount: 0,
        matchedCount: 0,
        alreadyTaggedCount: 0,
        willTagCount: 0,
      );
    }
    final now = DateTime.now();
    final rule = JiveTagRule()
      ..tagKey = tagKey
      ..isEnabled = true
      ..applyType = applyType
      ..minAmount = minAmount
      ..maxAmount = maxAmount
      ..accountIds = accountIds ?? []
      ..categoryKey = categoryKey
      ..subCategoryKey = subCategoryKey
      ..keywords = keywords ?? []
      ..createdAt = now
      ..updatedAt = now;
    var matchedCount = 0;
    var alreadyTaggedCount = 0;
    var willTagCount = 0;
    for (final tx in txs) {
      if (!_matches(rule, tx)) continue;
      matchedCount += 1;
      if (tx.tagKeys.contains(tagKey)) {
        alreadyTaggedCount += 1;
      } else {
        willTagCount += 1;
      }
    }
    return TagRuleEstimate(
      scannedCount: txs.length,
      matchedCount: matchedCount,
      alreadyTaggedCount: alreadyTaggedCount,
      willTagCount: willTagCount,
    );
  }

  Future<SmartTagCleanupEstimate> estimateCleanupForTag(
    String tagKey, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool removeTagToo = false,
  }) async {
    final txs = await _loadTransactionsInRange(rangeStart, rangeEnd);
    if (txs.isEmpty) {
      return const SmartTagCleanupEstimate(
        scannedCount: 0,
        smartTaggedCount: 0,
        willRemoveSmartCount: 0,
        willRemoveTagCount: 0,
      );
    }
    var smartTaggedCount = 0;
    var willRemoveTagCount = 0;
    for (final tx in txs) {
      if (!tx.smartTagKeys.contains(tagKey)) continue;
      smartTaggedCount += 1;
      if (removeTagToo && tx.tagKeys.contains(tagKey)) {
        willRemoveTagCount += 1;
      }
    }
    return SmartTagCleanupEstimate(
      scannedCount: txs.length,
      smartTaggedCount: smartTaggedCount,
      willRemoveSmartCount: smartTaggedCount,
      willRemoveTagCount: willRemoveTagCount,
    );
  }

  Future<SmartTagCleanupResult> cleanupForTag(
    String tagKey, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool removeTagToo = false,
    bool Function()? shouldCancel,
    void Function(int processed, int total)? onProgress,
  }) async {
    final txs = await _loadTransactionsInRange(rangeStart, rangeEnd);
    if (txs.isEmpty) {
      return const SmartTagCleanupResult(
        scannedCount: 0,
        smartTaggedCount: 0,
        updatedCount: 0,
        removedTagCount: 0,
        cancelled: false,
      );
    }
    final updates = <JiveTransaction>[];
    var smartTaggedCount = 0;
    var removedTagCount = 0;
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
      if (!tx.smartTagKeys.contains(tagKey)) continue;
      smartTaggedCount += 1;
      var changed = false;
      final nextSmart = tx.smartTagKeys.where((key) => key != tagKey).toList();
      if (nextSmart.length != tx.smartTagKeys.length) {
        tx.smartTagKeys = nextSmart;
        changed = true;
      }
      if (removeTagToo && tx.tagKeys.contains(tagKey)) {
        tx.tagKeys = tx.tagKeys.where((key) => key != tagKey).toList();
        removedTagCount += 1;
        changed = true;
      }
      if (changed) {
        updates.add(tx);
      }
    }
    if (updates.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.collection<JiveTransaction>().putAll(updates);
      });
      await TagService(isar).refreshUsageCounts(tagKeys: [tagKey]);
    }
    return SmartTagCleanupResult(
      scannedCount: total,
      smartTaggedCount: smartTaggedCount,
      updatedCount: updates.length,
      removedTagCount: removedTagCount,
      cancelled: cancelled,
    );
  }

  Future<List<JiveTransaction>> _loadTransactionsInRange(
    DateTime? rangeStart,
    DateTime? rangeEnd,
  ) async {
    final txQuery = isar.jiveTransactions.where();
    if (rangeStart != null && rangeEnd != null) {
      return txQuery.timestampBetween(
        rangeStart,
        rangeEnd,
        includeLower: true,
        includeUpper: true,
      ).findAll();
    }
    if (rangeStart != null) {
      return txQuery.timestampGreaterThan(rangeStart, include: true).findAll();
    }
    if (rangeEnd != null) {
      return txQuery.timestampLessThan(rangeEnd, include: true).findAll();
    }
    return txQuery.findAll();
  }

  bool _isOptedOut(JiveTransaction tx, String tagKey) {
    return tx.smartTagOptOutAll || tx.smartTagOptOutKeys.contains(tagKey);
  }

  RuleMatchDetail? _matchDetail(JiveTagRule rule, JiveTransaction tx) {
    if (!rule.isEnabled) return null;
    final type = (tx.type ?? 'expense').toLowerCase();
    final ruleType = (rule.applyType ?? 'all').toLowerCase();
    if (ruleType != 'all' && ruleType != type) return null;

    if (rule.minAmount != null && tx.amount < rule.minAmount!) return null;
    if (rule.maxAmount != null && tx.amount > rule.maxAmount!) return null;

    int? matchedAccountId;
    if (rule.accountIds.isNotEmpty) {
      final accountId = tx.accountId;
      final toAccountId = tx.toAccountId;
      if (accountId != null && rule.accountIds.contains(accountId)) {
        matchedAccountId = accountId;
      } else if (toAccountId != null && rule.accountIds.contains(toAccountId)) {
        matchedAccountId = toAccountId;
      } else {
        return null;
      }
    }

    if (rule.categoryKey != null && rule.categoryKey!.isNotEmpty) {
      if (tx.categoryKey != rule.categoryKey) return null;
    }
    if (rule.subCategoryKey != null && rule.subCategoryKey!.isNotEmpty) {
      if (tx.subCategoryKey != rule.subCategoryKey) return null;
    }

    var matchedKeywords = const <String>[];
    if (rule.keywords.isNotEmpty) {
      final haystack =
          '${tx.note ?? ''} ${tx.rawText ?? ''}'.toLowerCase().trim();
      if (haystack.isEmpty) return null;
      final hits = rule.keywords
          .map((keyword) => keyword.trim().toLowerCase())
          .where((keyword) => keyword.isNotEmpty && haystack.contains(keyword))
          .toList();
      if (hits.isEmpty) return null;
      matchedKeywords = hits;
    }

    return RuleMatchDetail(
      rule: rule,
      matchedAccountId: matchedAccountId,
      matchedKeywords: matchedKeywords,
    );
  }

  bool _matches(JiveTagRule rule, JiveTransaction tx) {
    return _matchDetail(rule, tx) != null;
  }
}
