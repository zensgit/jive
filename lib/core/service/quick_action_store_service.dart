import 'package:isar/isar.dart';

import '../database/quick_action_model.dart';
import '../database/template_model.dart';
import '../model/quick_action.dart';
import 'template_service.dart';

/// Persistent store for MoneyThings-style One Touch quick actions.
///
/// This service intentionally keeps templates as a compatibility source. It
/// backfills them into [JiveQuickAction] records without deleting or mutating
/// the original templates.
class QuickActionStoreService {
  static const sourceTemplate = 'template';

  final Isar _isar;
  late final TemplateService _templateService = TemplateService(_isar);

  QuickActionStoreService(this._isar);

  Future<List<QuickAction>> getActions({int limit = 0}) async {
    await syncFromTemplates();
    final records = await _isar.jiveQuickActions.where().findAll();
    final active = records.where((record) => !record.archived).toList()
      ..sort(_compareRecords);
    final actions = active.map(toQuickAction).toList(growable: false);
    if (limit <= 0 || actions.length <= limit) return actions;
    return actions.take(limit).toList(growable: false);
  }

  Future<QuickAction?> findAction(String stableId) async {
    final id = stableId.trim();
    if (id.isEmpty) return null;
    await syncFromTemplates();
    final records = await _isar.jiveQuickActions.where().findAll();
    for (final record in records) {
      if (!record.archived && record.stableId == id) {
        return toQuickAction(record);
      }
    }
    return null;
  }

  Future<void> syncFromTemplates() async {
    final templates = await _templateService.getTemplates();
    final records = await _isar.jiveQuickActions.where().findAll();
    final byStableId = {for (final record in records) record.stableId: record};
    final activeTemplateIds = templates.map((t) => t.id).toSet();
    final now = DateTime.now();
    final toSave = <JiveQuickAction>[];

    for (var i = 0; i < templates.length; i++) {
      final template = templates[i];
      final stableId = 'template:${template.id}';
      final existing = byStableId[stableId];
      if (existing == null) {
        toSave.add(
          fromTemplate(template, sortOrder: records.length + i, now: now),
        );
        continue;
      }
      final next =
          fromTemplate(template, sortOrder: existing.sortOrder, now: now)
            ..id = existing.id
            ..iconName = existing.iconName
            ..colorHex = existing.colorHex
            ..showOnHome = existing.showOnHome
            ..usageCount = existing.usageCount > template.usageCount
                ? existing.usageCount
                : template.usageCount
            ..lastUsedAt = _latest(existing.lastUsedAt, template.lastUsedAt)
            ..archived = false;
      toSave.add(next);
    }

    for (final record in records) {
      if (record.source == sourceTemplate &&
          record.legacyTemplateId != null &&
          !activeTemplateIds.contains(record.legacyTemplateId) &&
          !record.archived) {
        record
          ..archived = true
          ..updatedAt = now;
        toSave.add(record);
      }
    }

    if (toSave.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.putAll(toSave);
    });
  }

  Future<void> markUsed(QuickAction action) async {
    final now = DateTime.now();
    final stableId = action.id.trim();
    final records = await _isar.jiveQuickActions.where().findAll();
    JiveQuickAction? record;
    for (final candidate in records) {
      if (candidate.stableId == stableId) {
        record = candidate;
        break;
      }
    }

    await _isar.writeTxn(() async {
      if (record != null) {
        record
          ..usageCount += 1
          ..lastUsedAt = now
          ..updatedAt = now;
        await _isar.jiveQuickActions.put(record);
      }
    });
  }

  static JiveQuickAction fromTemplate(
    JiveTemplate template, {
    int sortOrder = 0,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return JiveQuickAction()
      ..stableId = 'template:${template.id}'
      ..source = sourceTemplate
      ..legacyTemplateId = template.id
      ..name = template.name
      ..transactionType = template.type
      ..accountId = template.accountId
      ..toAccountId = template.toAccountId
      ..categoryKey = template.categoryKey
      ..subCategoryKey = template.subCategoryKey
      ..categoryName = template.category
      ..subCategoryName = template.subCategory
      ..defaultAmount = template.amount > 0 ? template.amount : null
      ..defaultNote = template.note
      ..mode = _inferTemplateMode(template).name
      ..isPinned = template.isPinned
      ..sortOrder = sortOrder
      ..usageCount = template.usageCount
      ..lastUsedAt = template.lastUsedAt
      ..createdAt = template.createdAt
      ..updatedAt = timestamp;
  }

  static QuickAction toQuickAction(JiveQuickAction record) {
    return QuickAction(
      id: record.stableId,
      name: record.name,
      iconName: record.iconName,
      colorHex: record.colorHex,
      transactionType: _normalizedType(record.transactionType),
      bookId: record.bookId,
      accountId: record.accountId,
      toAccountId: record.toAccountId,
      categoryKey: record.categoryKey,
      subCategoryKey: record.subCategoryKey,
      categoryName: record.categoryName,
      subCategoryName: record.subCategoryName,
      tagKeys: List<String>.from(record.tagKeys),
      defaultAmount: record.defaultAmount,
      defaultNote: record.defaultNote,
      mode: _mode(record.mode),
      showOnHome: record.showOnHome,
      usageCount: record.usageCount,
      lastUsedAt: record.lastUsedAt,
      legacyTemplateId: record.legacyTemplateId,
    );
  }

  static int _compareRecords(JiveQuickAction a, JiveQuickAction b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    final usage = b.usageCount.compareTo(a.usageCount);
    if (usage != 0) return usage;
    return a.sortOrder.compareTo(b.sortOrder);
  }

  static DateTime? _latest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }

  static QuickActionMode _mode(String raw) {
    switch (raw) {
      case 'direct':
        return QuickActionMode.direct;
      case 'confirm':
        return QuickActionMode.confirm;
      case 'edit':
        return QuickActionMode.edit;
      default:
        return QuickActionMode.edit;
    }
  }

  static String _normalizedType(String raw) {
    switch (raw) {
      case 'income':
      case 'transfer':
      case 'expense':
        return raw;
      default:
        return 'expense';
    }
  }

  static QuickActionMode _inferTemplateMode(JiveTemplate template) {
    final type = template.type;
    final hasAmount = template.amount > 0;
    final hasAccount = template.accountId != null;
    final hasCategory =
        (template.categoryKey != null && template.categoryKey!.isNotEmpty) ||
        (template.subCategoryKey != null &&
            template.subCategoryKey!.isNotEmpty);

    if (type == 'transfer') return QuickActionMode.edit;
    if (hasAccount && hasCategory && hasAmount) return QuickActionMode.direct;
    if (hasAccount && hasCategory) return QuickActionMode.confirm;
    return QuickActionMode.edit;
  }
}
