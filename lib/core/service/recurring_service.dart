import 'package:isar/isar.dart';

import '../database/auto_draft_model.dart';
import '../database/recurring_rule_model.dart';
import '../database/transaction_model.dart';
import '../service/tag_service.dart';

class RecurringProcessResult {
  final int generatedDrafts;
  final int committedTransactions;

  const RecurringProcessResult({
    required this.generatedDrafts,
    required this.committedTransactions,
  });
}

class RecurringService {
  RecurringService(this.isar);

  final Isar isar;

  Future<List<JiveRecurringRule>> getRules({bool includeInactive = true}) async {
    final list = includeInactive
        ? await isar.collection<JiveRecurringRule>().where().findAll()
        : await isar.collection<JiveRecurringRule>()
            .filter()
            .isActiveEqualTo(true)
            .findAll();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<JiveRecurringRule> createRule(JiveRecurringRule rule) async {
    final now = DateTime.now();
    rule
      ..name = rule.name.trim()
      ..isActive = rule.isActive
      ..intervalValue = rule.intervalValue <= 0 ? 1 : rule.intervalValue
      ..nextRunAt = _normalizeNextRun(rule, rule.startDate)
      ..createdAt = now
      ..updatedAt = now;
    await isar.writeTxn(() async {
      await isar.collection<JiveRecurringRule>().put(rule);
    });
    return rule;
  }

  Future<void> updateRule(JiveRecurringRule rule) async {
    rule.name = rule.name.trim();
    rule.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveRecurringRule>().put(rule);
    });
  }

  Future<void> deleteRule(int id) async {
    await isar.writeTxn(() async {
      await isar.collection<JiveRecurringRule>().delete(id);
    });
  }

  Future<void> setRuleActive(JiveRecurringRule rule, bool active) async {
    rule.isActive = active;
    rule.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveRecurringRule>().put(rule);
    });
  }

  Future<RecurringProcessResult> processDueRules({DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final rules = await isar.collection<JiveRecurringRule>()
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    if (rules.isEmpty) {
      return const RecurringProcessResult(
        generatedDrafts: 0,
        committedTransactions: 0,
      );
    }

    var draftCount = 0;
    var commitCount = 0;

    for (final rule in rules) {
      var next = rule.nextRunAt;
      final endDate = rule.endDate;
      while (!next.isAfter(reference)) {
        if (endDate != null && next.isAfter(endDate)) {
          break;
        }
        final generated = await _generateOccurrence(rule, next);
        if (generated == _RecurringGenerated.draft) {
          draftCount += 1;
        } else if (generated == _RecurringGenerated.commit) {
          commitCount += 1;
        }
        rule.lastRunAt = next;
        next = _computeNextRunAt(rule, next);
        rule.nextRunAt = next;
      }
      rule.updatedAt = DateTime.now();
    }

    await isar.writeTxn(() async {
      await isar.collection<JiveRecurringRule>().putAll(rules);
    });

    return RecurringProcessResult(
      generatedDrafts: draftCount,
      committedTransactions: commitCount,
    );
  }

  Future<_RecurringGenerated> _generateOccurrence(
    JiveRecurringRule rule,
    DateTime runAt,
  ) async {
    final recurringKey = _buildRecurringKey(rule.id, runAt);
    if (rule.commitMode == 'draft') {
      final exists = await isar.collection<JiveAutoDraft>()
          .filter()
          .dedupKeyEqualTo(recurringKey)
          .findFirst();
      if (exists != null) return _RecurringGenerated.none;

      final draft = JiveAutoDraft()
        ..amount = rule.amount
        ..source = 'Recurring'
        ..timestamp = runAt
        ..rawText = rule.name
        ..metadataJson = null
        ..type = rule.type
        ..categoryKey = rule.categoryKey
        ..subCategoryKey = rule.subCategoryKey
        ..category = null
        ..subCategory = null
        ..accountId = rule.accountId
        ..toAccountId = rule.toAccountId
        ..dedupKey = recurringKey
        ..createdAt = DateTime.now()
        ..tagKeys = List<String>.from(rule.tagKeys)
        ..recurringRuleId = rule.id
        ..recurringKey = recurringKey;

      await isar.writeTxn(() async {
        await isar.collection<JiveAutoDraft>().put(draft);
      });
      return _RecurringGenerated.draft;
    }

    final existing = await isar.collection<JiveTransaction>()
        .filter()
        .recurringKeyEqualTo(recurringKey)
        .findFirst();
    if (existing != null) return _RecurringGenerated.none;

    final tx = JiveTransaction()
      ..amount = rule.amount
      ..source = 'Recurring'
      ..timestamp = runAt
      ..rawText = rule.name
      ..type = rule.type
      ..categoryKey = rule.categoryKey
      ..subCategoryKey = rule.subCategoryKey
      ..category = null
      ..subCategory = null
      ..note = rule.note
      ..accountId = rule.accountId
      ..toAccountId = rule.toAccountId
      ..projectId = rule.projectId
      ..tagKeys = List<String>.from(rule.tagKeys)
      ..smartTagKeys = []
      ..recurringRuleId = rule.id
      ..recurringKey = recurringKey;

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
    });
    if (tx.tagKeys.isNotEmpty) {
      await TagService(isar).markTagsUsed(tx.tagKeys, tx.timestamp);
    }
    return _RecurringGenerated.commit;
  }

  DateTime _computeNextRunAt(JiveRecurringRule rule, DateTime from) {
    switch (rule.intervalType) {
      case 'day':
        return from.add(Duration(days: rule.intervalValue));
      case 'week':
        return from.add(Duration(days: 7 * rule.intervalValue));
      case 'year':
        return _addYears(from, rule.intervalValue, rule.dayOfMonth);
      case 'month':
      default:
        return _addMonths(from, rule.intervalValue, rule.dayOfMonth);
    }
  }

  DateTime _normalizeNextRun(JiveRecurringRule rule, DateTime start) {
    final base = DateTime(start.year, start.month, start.day, start.hour, start.minute);
    if (rule.intervalType == 'week' && rule.dayOfWeek != null) {
      final diff = (rule.dayOfWeek! - base.weekday) % 7;
      return base.add(Duration(days: diff));
    }
    if (rule.intervalType == 'month' && rule.dayOfMonth != null) {
      return _alignDayOfMonth(base, rule.dayOfMonth!);
    }
    if (rule.intervalType == 'year' && rule.dayOfMonth != null) {
      return _alignDayOfMonth(base, rule.dayOfMonth!);
    }
    return base;
  }

  DateTime _addMonths(DateTime from, int months, int? dayOverride) {
    final targetMonth = from.month + months;
    final targetYear = from.year + (targetMonth - 1) ~/ 12;
    final month = ((targetMonth - 1) % 12) + 1;
    final day = dayOverride ?? from.day;
    final safeDay = _clampDay(targetYear, month, day);
    return DateTime(
      targetYear,
      month,
      safeDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  DateTime _addYears(DateTime from, int years, int? dayOverride) {
    final targetYear = from.year + years;
    final day = dayOverride ?? from.day;
    final safeDay = _clampDay(targetYear, from.month, day);
    return DateTime(
      targetYear,
      from.month,
      safeDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  DateTime _alignDayOfMonth(DateTime from, int day) {
    final safeDay = _clampDay(from.year, from.month, day);
    return DateTime(
      from.year,
      from.month,
      safeDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  int _clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    if (day < 1) return 1;
    if (day > lastDay) return lastDay;
    return day;
  }

  String _buildRecurringKey(int ruleId, DateTime runAt) {
    final dayKey = DateTime(runAt.year, runAt.month, runAt.day).toIso8601String();
    return 'recurring:$ruleId:$dayKey';
  }
}

enum _RecurringGenerated { none, draft, commit }
