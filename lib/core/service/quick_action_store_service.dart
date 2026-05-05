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
    final records = await getRecords(onlyVisible: true);
    final actions = records.map(toQuickAction).toList(growable: false);
    if (limit <= 0 || actions.length <= limit) return actions;
    return actions.take(limit).toList(growable: false);
  }

  Future<List<JiveQuickAction>> getRecords({bool onlyVisible = false}) async {
    await syncFromTemplates();
    final records = await _isar.jiveQuickActions.where().findAll();
    final active =
        records
            .where((record) => !record.archived)
            .where((record) => !onlyVisible || record.showOnHome)
            .toList()
          ..sort(_compareRecords);
    return active;
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
            ..isPinned = existing.isPinned
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

  Future<void> updatePresentation(
    String stableId, {
    String? iconName,
    String? colorHex,
    bool? showOnHome,
    bool? isPinned,
  }) async {
    final record = await _activeRecord(stableId);
    if (record == null) return;
    final now = DateTime.now();

    await _isar.writeTxn(() async {
      if (iconName != null) record.iconName = iconName;
      if (colorHex != null) record.colorHex = colorHex;
      if (showOnHome != null) record.showOnHome = showOnHome;
      if (isPinned != null) record.isPinned = isPinned;
      record.updatedAt = now;
      await _isar.jiveQuickActions.put(record);

      if (isPinned != null && record.legacyTemplateId != null) {
        final template = await _isar.jiveTemplates.get(
          record.legacyTemplateId!,
        );
        if (template != null) {
          template.isPinned = isPinned;
          await _isar.jiveTemplates.put(template);
        }
      }
    });
  }

  Future<void> moveAction(String stableId, int direction) async {
    if (direction == 0) return;
    final records = await getRecords();
    final index = records.indexWhere((record) => record.stableId == stableId);
    if (index < 0) return;
    final targetIndex = direction < 0 ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= records.length) return;

    for (var i = 0; i < records.length; i++) {
      records[i].sortOrder = i;
    }
    final current = records[index];
    final target = records[targetIndex];
    final currentOrder = current.sortOrder;
    current.sortOrder = target.sortOrder;
    target.sortOrder = currentOrder;
    current.updatedAt = DateTime.now();
    target.updatedAt = current.updatedAt;

    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.putAll(records);
    });
  }

  Future<void> reorderActions(
    List<String> orderedStableIds, {
    bool? showOnHome,
  }) async {
    if (orderedStableIds.isEmpty) return;

    final records = await getRecords();
    final scoped = records.where((record) {
      if (showOnHome == null) return true;
      return record.showOnHome == showOnHome;
    }).toList();
    final scopedById = {for (final record in scoped) record.stableId: record};
    final nextOrder = <JiveQuickAction>[];

    for (final stableId in orderedStableIds) {
      final record = scopedById.remove(stableId);
      if (record != null) nextOrder.add(record);
    }
    nextOrder.addAll(
      scoped.where((record) => scopedById.containsKey(record.stableId)),
    );
    if (nextOrder.isEmpty) return;

    final now = DateTime.now();
    for (var i = 0; i < nextOrder.length; i++) {
      nextOrder[i]
        ..sortOrder = i
        ..updatedAt = now;
    }

    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.putAll(nextOrder);
    });
  }

  Future<void> deleteAction(String stableId) async {
    final record = await _activeRecord(stableId);
    if (record == null) return;
    if (record.source == sourceTemplate && record.legacyTemplateId != null) {
      await _templateService.deleteTemplate(record.legacyTemplateId!);
      await syncFromTemplates();
      return;
    }

    record
      ..archived = true
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.put(record);
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
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    final usage = b.usageCount.compareTo(a.usageCount);
    if (usage != 0) return usage;
    return a.name.compareTo(b.name);
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

  Future<JiveQuickAction?> _activeRecord(String stableId) async {
    final id = stableId.trim();
    if (id.isEmpty) return null;
    await syncFromTemplates();
    final record = await _isar.jiveQuickActions.getByStableId(id);
    if (record == null || record.archived) return null;
    return record;
  }
}
