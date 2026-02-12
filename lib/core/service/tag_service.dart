import 'dart:math';

import 'package:isar/isar.dart';
import '../database/tag_model.dart';
import '../database/tag_conversion_log.dart';
import '../database/transaction_model.dart';
import '../database/category_model.dart';
import 'category_service.dart';
import 'tag_rule_service.dart';

enum TagMigratePolicy {
  onlyNull,
  overwrite,
  none,
}

class TagService {
  TagService(this.isar);

  final Isar isar;
  static const int maxTagNameLength = 9;
  static const int maxGroupNameLength = 12;

  static const List<String> defaultColors = [
    '#1d4ed8',
    '#0ea5e9',
    '#0d9488',
    '#16a34a',
    '#65a30d',
    '#ca8a04',
    '#ea580c',
    '#dc2626',
    '#be185d',
    '#7c3aed',
    '#4f46e5',
    '#92400e',
    '#6b7280',
  ];

  Future<void> initDefaultGroups() async {
    final existing = await isar.collection<JiveTagGroup>().where().findAll();
    if (existing.isNotEmpty) return;
    final now = DateTime.now();
    final defaults = [
      _TagGroupSeed('工作相关', defaultColors[0], 'work'),
      _TagGroupSeed('生活方式', defaultColors[1], 'lifestyle'),
      _TagGroupSeed('个人', defaultColors[2], 'person'),
      _TagGroupSeed('优先级', defaultColors[3], 'flag'),
    ];
    final groups = <JiveTagGroup>[];
    for (var i = 0; i < defaults.length; i++) {
      final seed = defaults[i];
      final group = JiveTagGroup()
        ..key = _newKey()
        ..name = seed.name
        ..colorHex = seed.colorHex
        ..iconName = seed.iconName
        ..order = i
        ..isArchived = false
        ..createdAt = now
        ..updatedAt = now;
      groups.add(group);
    }
    await isar.writeTxn(() async {
      await isar.collection<JiveTagGroup>().putAll(groups);
    });
  }

  Future<List<JiveTagGroup>> getGroups({bool includeArchived = true}) async {
    final list = includeArchived
        ? await isar.collection<JiveTagGroup>().where().findAll()
        : await isar.collection<JiveTagGroup>()
            .filter()
            .isArchivedEqualTo(false)
            .findAll();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<List<JiveTag>> getTags({bool includeArchived = true}) async {
    final list = includeArchived
        ? await isar.collection<JiveTag>().where().findAll()
        : await isar.collection<JiveTag>()
            .filter()
            .isArchivedEqualTo(false)
            .findAll();
    list.sort((a, b) {
      final order = a.order.compareTo(b.order);
      if (order != 0) return order;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  Future<Map<String, JiveTag>> getTagMap({bool includeArchived = true}) async {
    final list = await getTags(includeArchived: includeArchived);
    return {for (final tag in list) tag.key: tag};
  }

  Future<JiveTagGroup> createGroup({
    required String name,
    String? colorHex,
    String? iconName,
    String? iconText,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('group name is required');
    }
    if (trimmed.length > maxGroupNameLength) {
      throw ArgumentError('最多12字');
    }
    final normalized = _normalizeName(trimmed);
    final exists = await isar.collection<JiveTagGroup>()
        .filter()
        .nameEqualTo(normalized, caseSensitive: false)
        .findFirst();
    if (exists != null) {
      throw ArgumentError('group name exists');
    }
    final last = await isar.collection<JiveTagGroup>()
        .where()
        .sortByOrderDesc()
        .findFirst();
    final now = DateTime.now();
    final group = JiveTagGroup()
      ..key = _newKey()
      ..name = trimmed
      ..colorHex = colorHex ?? _pickColor(trimmed)
      ..iconName = iconName
      ..iconText = iconText
      ..order = (last?.order ?? -1) + 1
      ..isArchived = false
      ..createdAt = now
      ..updatedAt = now;
    await isar.writeTxn(() async {
      await isar.collection<JiveTagGroup>().put(group);
    });
    return group;
  }

  Future<JiveTagGroup> updateGroup(JiveTagGroup group) async {
    final trimmed = group.name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('group name is required');
    }
    if (trimmed.length > maxGroupNameLength) {
      throw ArgumentError('最多12字');
    }
    final existing = await isar.collection<JiveTagGroup>()
        .filter()
        .nameEqualTo(trimmed, caseSensitive: false)
        .findAll();
    final conflict = existing.any((item) => item.key != group.key);
    if (conflict) {
      throw ArgumentError('group name exists');
    }
    group.name = trimmed;
    group.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveTagGroup>().put(group);
    });
    return group;
  }

  Future<void> deleteGroup(String groupKey) async {
    final group = await isar.collection<JiveTagGroup>()
        .filter()
        .keyEqualTo(groupKey)
        .findFirst();
    if (group == null) return;
    final tags = await isar.collection<JiveTag>()
        .filter()
        .groupKeyEqualTo(groupKey)
        .findAll();
    await isar.writeTxn(() async {
      if (tags.isNotEmpty) {
        for (final tag in tags) {
          tag.groupKey = null;
          tag.updatedAt = DateTime.now();
        }
        await isar.collection<JiveTag>().putAll(tags);
      }
      await isar.collection<JiveTagGroup>().delete(group.id);
    });
  }

  Future<void> setGroupArchived(String groupKey, bool archived) async {
    final group = await isar.collection<JiveTagGroup>()
        .filter()
        .keyEqualTo(groupKey)
        .findFirst();
    if (group == null) return;
    group.isArchived = archived;
    group.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveTagGroup>().put(group);
    });
  }

  Future<JiveTag> createTag({
    required String name,
    String? colorHex,
    String? iconName,
    String? iconText,
    String? groupKey,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('tag name is required');
    }
    if (trimmed.length > maxTagNameLength) {
      throw ArgumentError('最多9字');
    }
    final exists = await isar.collection<JiveTag>()
        .filter()
        .nameEqualTo(trimmed, caseSensitive: false)
        .findFirst();
    if (exists != null) {
      throw ArgumentError('tag name exists');
    }
    final last = await isar.collection<JiveTag>()
        .where()
        .sortByOrderDesc()
        .findFirst();
    final now = DateTime.now();
    final tag = JiveTag()
      ..key = _newKey()
      ..name = trimmed
      ..colorHex = colorHex ?? _pickColor(trimmed)
      ..iconName = iconName
      ..iconText = iconText
      ..groupKey = groupKey
      ..redirectCategoryKey = null
      ..order = (last?.order ?? -1) + 1
      ..isArchived = false
      ..usageCount = 0
      ..lastUsedAt = null
      ..createdAt = now
      ..updatedAt = now;
    await isar.writeTxn(() async {
      await isar.collection<JiveTag>().put(tag);
    });
    return tag;
  }

  Future<JiveTag> updateTag(JiveTag tag) async {
    final trimmed = tag.name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('tag name is required');
    }
    if (trimmed.length > maxTagNameLength) {
      throw ArgumentError('最多9字');
    }
    final existing = await isar.collection<JiveTag>()
        .filter()
        .nameEqualTo(trimmed, caseSensitive: false)
        .findAll();
    final conflict = existing.any((item) => item.key != tag.key);
    if (conflict) {
      throw ArgumentError('tag name exists');
    }
    tag.name = trimmed;
    tag.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveTag>().put(tag);
    });
    return tag;
  }

  Future<void> setTagArchived(String tagKey, bool archived) async {
    final tag = await isar.collection<JiveTag>()
        .filter()
        .keyEqualTo(tagKey)
        .findFirst();
    if (tag == null) return;
    tag.isArchived = archived;
    tag.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveTag>().put(tag);
    });
  }

  Future<void> deleteTag(String tagKey) async {
    final tag = await isar.collection<JiveTag>()
        .filter()
        .keyEqualTo(tagKey)
        .findFirst();
    if (tag == null) return;
    final txs = await isar.jiveTransactions
        .filter()
        .tagKeysElementEqualTo(tagKey)
        .findAll();
    await isar.writeTxn(() async {
      if (txs.isNotEmpty) {
        for (final tx in txs) {
          tx.tagKeys = _removeTagKey(tx.tagKeys, tagKey);
        }
        await isar.jiveTransactions.putAll(txs);
      }
      await isar.collection<JiveTag>().delete(tag.id);
    });
    await TagRuleService(isar).deleteRulesByTag(tagKey);
  }

  Future<int> mergeTags({
    required String targetKey,
    required List<String> sourceKeys,
  }) async {
    final uniqueSources = sourceKeys.toSet()..remove(targetKey);
    if (uniqueSources.isEmpty) return 0;
    final target = await isar.collection<JiveTag>()
        .filter()
        .keyEqualTo(targetKey)
        .findFirst();
    if (target == null) return 0;
    final allTxs = await isar.jiveTransactions.where().findAll();
    final txs = allTxs.where((tx) {
      if (tx.tagKeys.isEmpty) return false;
      return tx.tagKeys.any((key) => uniqueSources.contains(key));
    }).toList();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      if (txs.isNotEmpty) {
        for (final tx in txs) {
          var updated = tx.tagKeys;
          updated = updated.where((key) => !uniqueSources.contains(key)).toList();
          if (!updated.contains(targetKey)) {
            updated.add(targetKey);
          }
          tx.tagKeys = updated;
        }
        await isar.jiveTransactions.putAll(txs);
      }
      final toDelete = await isar.collection<JiveTag>()
          .where()
          .anyOf(uniqueSources.toList(), (query, key) => query.keyEqualTo(key))
          .findAll();
      if (toDelete.isNotEmpty) {
        final ids = toDelete.map((tag) => tag.id).toList();
        await isar.collection<JiveTag>().deleteAll(ids);
      }
      target.updatedAt = now;
      await isar.collection<JiveTag>().put(target);
    });
    await TagRuleService(isar).reassignRules(
      sourceKeys: uniqueSources.toList(),
      targetKey: targetKey,
    );
    await refreshUsageCounts(tagKeys: [targetKey]);
    return uniqueSources.length;
  }

  Future<List<String>> resolveTagKeysByNames(
    List<String> names, {
    String? groupKey,
    bool createIfMissing = true,
  }) async {
    final result = <String>[];
    for (final raw in names) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final existing = await isar.collection<JiveTag>()
          .filter()
          .nameEqualTo(trimmed, caseSensitive: false)
          .findFirst();
      if (existing != null) {
        result.add(existing.key);
        continue;
      }
      if (!createIfMissing) continue;
      final created = await createTag(
        name: trimmed,
        groupKey: groupKey,
      );
      result.add(created.key);
    }
    return result;
  }

  Future<void> refreshUsageCounts({List<String>? tagKeys}) async {
    final keys = tagKeys ??
        (await isar.collection<JiveTag>().where().findAll())
            .map((tag) => tag.key)
            .toList();
    if (keys.isEmpty) return;
    final now = DateTime.now();
    final updates = <JiveTag>[];
    for (final key in keys) {
      final tag = await isar.collection<JiveTag>()
          .filter()
          .keyEqualTo(key)
          .findFirst();
      if (tag == null) continue;
      final count = await isar.jiveTransactions
          .filter()
          .tagKeysElementEqualTo(key)
          .count();
      if (tag.usageCount != count) {
        tag.usageCount = count;
        tag.updatedAt = now;
        updates.add(tag);
      }
    }
    if (updates.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveTag>().putAll(updates);
    });
  }

  Future<void> markTagsUsed(List<String> tagKeys, DateTime timestamp) async {
    if (tagKeys.isEmpty) return;
    final uniqueKeys = tagKeys.toSet().toList();
    final tags = await isar.collection<JiveTag>()
        .where()
        .anyOf(uniqueKeys, (query, key) => query.keyEqualTo(key))
        .findAll();
    if (tags.isEmpty) return;
    final now = DateTime.now();
    for (final tag in tags) {
      tag.usageCount += 1;
      tag.lastUsedAt = timestamp;
      tag.updatedAt = now;
    }
    await isar.writeTxn(() async {
      await isar.collection<JiveTag>().putAll(tags);
    });
  }

  Future<JiveCategory?> convertTagToCategory({
    required String tagKey,
    required bool isIncome,
    String? parentKey,
    TagMigratePolicy migratePolicy = TagMigratePolicy.onlyNull,
    bool keepTagActive = true,
    String? renameTo,
    String? existingCategoryKey,
  }) async {
    final tag = await isar.collection<JiveTag>()
        .filter()
        .keyEqualTo(tagKey)
        .findFirst();
    if (tag == null) return null;
    if (tag.redirectCategoryKey != null) {
      final existing = await isar.collection<JiveCategory>()
          .filter()
          .keyEqualTo(tag.redirectCategoryKey!)
          .findFirst();
      if (existing != null) return existing;
      tag.redirectCategoryKey = null;
    }
    final targetName = (renameTo ?? tag.name).trim();
    if (targetName.isEmpty) return null;

    final categoryService = CategoryService(isar);
    JiveCategory? category;
    if (existingCategoryKey != null && existingCategoryKey.isNotEmpty) {
      category = await isar.collection<JiveCategory>()
          .filter()
          .keyEqualTo(existingCategoryKey)
          .findFirst();
    }
    if (category == null && parentKey != null) {
      final parent = await isar.collection<JiveCategory>()
          .filter()
          .keyEqualTo(parentKey)
          .findFirst();
      if (parent == null) return null;
      category = await categoryService.createSubCategory(
        parent: parent,
        name: targetName,
        iconName: tag.iconName ?? categoryService.suggestIconName(targetName),
        colorHex: tag.colorHex,
      );
    } else {
      category ??= await categoryService.createParentCategory(
        name: targetName,
        iconName: tag.iconName ?? categoryService.suggestIconName(targetName),
        isIncome: isIncome,
        colorHex: tag.colorHex,
      );
    }
    if (category == null) {
      final query = isar.collection<JiveCategory>()
          .filter()
          .nameEqualTo(targetName);
      if (parentKey != null) {
        category = await query.parentKeyEqualTo(parentKey).findFirst();
      } else {
        category = await query.parentKeyIsNull().isIncomeEqualTo(isIncome).findFirst();
      }
    }
    if (category == null) return null;

    final now = DateTime.now();
    category.sourceTagKey = tag.key;
    category.updatedAt = now;
    tag.redirectCategoryKey = category.key;
    if (!keepTagActive) {
      tag.isArchived = true;
    }
    tag.updatedAt = now;

    final txs = await isar.jiveTransactions
        .filter()
        .tagKeysElementEqualTo(tag.key)
        .findAll();
    final updatedTxs = <JiveTransaction>[];
    var skippedExisting = 0;
    var skippedTypeMismatch = 0;
    var skippedUnknown = 0;
    var skippedByPolicy = 0;
    final categoryTypeByKey = <String, bool>{};
    if (migratePolicy == TagMigratePolicy.overwrite) {
      final allCategories = await isar.collection<JiveCategory>().where().findAll();
      for (final item in allCategories) {
        categoryTypeByKey[item.key] = item.isIncome;
      }
    }
    String? parentName;
    if (category.parentKey != null) {
      final parent = await isar.collection<JiveCategory>()
          .filter()
          .keyEqualTo(category.parentKey!)
          .findFirst();
      parentName = parent?.name;
    }
    if (migratePolicy != TagMigratePolicy.none) {
      for (final tx in txs) {
        final categoryEmpty = tx.categoryKey == null || tx.categoryKey!.isEmpty;
        if (migratePolicy == TagMigratePolicy.onlyNull) {
          if (!categoryEmpty) {
            skippedExisting += 1;
            continue;
          }
        } else if (migratePolicy == TagMigratePolicy.overwrite) {
          if (!categoryEmpty) {
            final type = categoryTypeByKey[tx.categoryKey!];
            if (type == null) {
              skippedUnknown += 1;
              continue;
            }
            if (type != isIncome) {
              skippedTypeMismatch += 1;
              continue;
            }
          }
        }
        if (category.parentKey == null) {
          tx.categoryKey = category.key;
          tx.subCategoryKey = null;
          tx.category = category.name;
          tx.subCategory = null;
        } else {
          tx.categoryKey = category.parentKey;
          tx.subCategoryKey = category.key;
          tx.category = parentName ?? tx.category;
          tx.subCategory = category.name;
        }
        updatedTxs.add(tx);
      }
    } else {
      skippedByPolicy = txs.length;
    }

    final log = JiveTagConversionLog()
      ..tagKey = tag.key
      ..tagName = tag.name
      ..categoryKey = category.key
      ..parentCategoryKey = category.parentKey
      ..categoryName = category.name
      ..parentCategoryName = parentName
      ..categoryIsIncome = category.isIncome
      ..migratePolicy = migratePolicy.name
      ..keepTagActive = keepTagActive
      ..taggedTransactionCount = txs.length
      ..updatedTransactionCount = updatedTxs.length
      ..skippedExistingCategoryCount = skippedExisting
      ..skippedTypeMismatchCount = skippedTypeMismatch
      ..skippedUnknownCategoryCount = skippedUnknown
      ..skippedByPolicyCount = skippedByPolicy
      ..updatedTransactionIds = updatedTxs.map((tx) => tx.id).toList()
      ..createdAt = now;

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().put(category!);
      await isar.collection<JiveTag>().put(tag);
      await isar.collection<JiveTagConversionLog>().put(log);
      if (updatedTxs.isNotEmpty) {
        await isar.jiveTransactions.putAll(updatedTxs);
      }
    });
    return category;
  }

  String _pickColor(String name) {
    final hash = _hashName(name);
    return defaultColors[hash % defaultColors.length];
  }

  int _hashName(String name) {
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  String _newKey() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String _normalizeName(String name) {
    return name.trim().toLowerCase();
  }

  List<String> _removeTagKey(List<String> keys, String tagKey) {
    if (keys.isEmpty) return const [];
    final updated = keys.where((key) => key != tagKey).toList();
    return updated;
  }
}

class _TagGroupSeed {
  final String name;
  final String colorHex;
  final String iconName;

  const _TagGroupSeed(this.name, this.colorHex, this.iconName);
}
