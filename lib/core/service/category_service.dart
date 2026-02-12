import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import '../data/system_category_library.dart';

class CategoryService {
  final Isar isar;
  static const int _systemCategorySeedVersion = 4;
  static const String _systemCategorySeedKey = 'system_category_seed_version';
  static const String _noParentOverrideKey = '__no_parent__';
  static const Color _defaultIconColor = Color(0xFF202020);
  static const Set<String> _softIconKeys = {
    '装修__搬家__Renovation__Moving.png',
    '餐饮__请客__Catering__Treat.png',
    '餐饮__三餐__Catering__ThreeMeals.png',
    '餐饮__烧烤__Catering__Barbecue.png',
    '餐饮__生鲜__Catering__FreshFood.png',
    '餐饮__外卖__Catering__Takeaway.png',
    '餐饮__午餐__Catering__Lunch.png',
    '餐饮__西餐__Catering__WesternFood.png',
    '餐饮__烟酒__Catering__SmokeAndWine.png',
  };
  static const List<double> _grayscaleMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];
  static const double _contrastFactor = 1.02;
  static const double _contrastOffset = 128 * (1 - _contrastFactor);
  static const List<double> _contrastMatrix = [
    _contrastFactor, 0, 0, 0, _contrastOffset,
    0, _contrastFactor, 0, 0, _contrastOffset,
    0, 0, _contrastFactor, 0, _contrastOffset,
    0, 0, 0, 1, 0,
  ];
  static const double _defaultLiftTarget = 0.40;
  static const double _softLiftTarget = 0.95;
  static const Map<String, String> _systemParentAliases = {
    "心情": "表情",
  };

  CategoryService(this.isar);

  // 初始化/补齐系统分类
  Future<void> initDefaultCategories() async {
    final migrated = await _applySystemSeedIfNeeded();
    await _migrateLegacyIconPaths();
    await _ensureSystemDefaults();
    await _applySystemOverrides();
    await _mergeSystemCategoryVariants();
    await _syncSystemCategoryIcons();
    await _syncCategoryIconsFromSystemLibrary();
    if (migrated) {
      await _refreshTransactionCategoryNames();
    }
  }

  Future<void> resetCategories() async {
    await _clearCategoriesAndTransactions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_systemCategorySeedKey, _systemCategorySeedVersion);
    await _migrateLegacyIconPaths();
    await _ensureSystemDefaults();
    await _applySystemOverrides();
    await _mergeSystemCategoryVariants();
    await _syncSystemCategoryIcons();
    await _syncCategoryIconsFromSystemLibrary();
  }

  Future<bool> _applySystemSeedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_systemCategorySeedKey) ?? 0;
    if (current == _systemCategorySeedVersion) return false;
    final migrated = await _migrateSystemCategoriesByName();
    await prefs.setInt(_systemCategorySeedKey, _systemCategorySeedVersion);
    return migrated;
  }

  Future<void> _clearCategoriesAndTransactions() async {
    await isar.writeTxn(() async {
      final categories = await isar.collection<JiveCategory>().where().findAll();
      if (categories.isNotEmpty) {
        final ids = categories.map((cat) => cat.id).toList();
        await isar.collection<JiveCategory>().deleteAll(ids);
      }

      final overrides = await isar.collection<JiveCategoryOverride>().where().findAll();
      if (overrides.isNotEmpty) {
        final ids = overrides.map((ov) => ov.id).toList();
        await isar.collection<JiveCategoryOverride>().deleteAll(ids);
      }

      final txs = await isar.jiveTransactions.where().findAll();
      if (txs.isNotEmpty) {
        for (final tx in txs) {
          tx.categoryKey = null;
          tx.subCategoryKey = null;
          tx.category = null;
          tx.subCategory = null;
        }
        await isar.jiveTransactions.putAll(txs);
      }
    });
  }

  Future<void> _ensureSystemDefaults() async {
    final systemIndex = _buildSystemIndex();
    if (systemIndex.byKey.isEmpty) return;

    final overridesByKey = await _loadOverridesByKey();
    final existing = await isar.collection<JiveCategory>().where().findAll();
    final existingByKey = {for (final cat in existing) cat.key: cat};

    final now = DateTime.now();
    final toInsert = <JiveCategory>[];
    final toUpdate = <JiveCategory>[];

    for (final base in systemIndex.byKey.values) {
      final existingCat = existingByKey[base.key];
      if (existingCat == null) {
        toInsert.add(_buildSystemCategoryFromBase(base, now));
        continue;
      }

      final override = overridesByKey[base.key];
      var changed = false;
      if (!existingCat.isSystem) {
        existingCat.isSystem = true;
        changed = true;
      }
      if (existingCat.isIncome != base.isIncome) {
        existingCat.isIncome = base.isIncome;
        changed = true;
      }
      if (override?.nameOverride == null && existingCat.name != base.name) {
        existingCat.name = base.name;
        changed = true;
      }
      if (override?.iconOverride == null &&
          _normalizeIconKey(existingCat.iconName) != _normalizeIconKey(base.iconName)) {
        existingCat.iconName = base.iconName;
        changed = true;
      }
      if (override?.colorHexOverride == null && existingCat.colorHex != base.colorHex) {
        existingCat.colorHex = base.colorHex;
        changed = true;
      }
      if (override?.parentOverrideKey == null && existingCat.parentKey != base.parentKey) {
        existingCat.parentKey = base.parentKey;
        changed = true;
      }
      if (override?.orderOverride == null && existingCat.order != base.order) {
        existingCat.order = base.order;
        changed = true;
      }
      if (override?.isHiddenOverride == null && existingCat.isHidden != base.isHidden) {
        existingCat.isHidden = base.isHidden;
        changed = true;
      }

      if (changed) {
        existingCat.updatedAt = now;
        toUpdate.add(existingCat);
      }
    }

    if (toInsert.isEmpty && toUpdate.isEmpty) return;
    await isar.writeTxn(() async {
      if (toInsert.isNotEmpty) {
        await isar.collection<JiveCategory>().putAll(toInsert);
      }
      if (toUpdate.isNotEmpty) {
        await isar.collection<JiveCategory>().putAll(toUpdate);
      }
    });
  }

  Future<void> _migrateLegacyIconPaths() async {
    final legacy = await isar.collection<JiveCategory>()
        .filter()
        .iconNameStartsWith("qj/")
        .findAll();
    if (legacy.isEmpty) return;

    final now = DateTime.now();
    final updated = <JiveCategory>[];
    for (final cat in legacy) {
      var iconName = cat.iconName;
      if (iconName.startsWith("qj/")) {
        iconName = iconName.substring(3);
      }
      if (iconName == cat.iconName) continue;
      cat.iconName = iconName;
      cat.updatedAt = now;
      updated.add(cat);
    }

    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().putAll(updated);
    });
  }

  Future<void> _mergeSystemCategoryVariants() async {
    await _mergeSystemCategories(
      targetName: "Apple",
      sourceNames: const ["Apple Music", "AppleTV", "Apple iTunes"],
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "受伤",
      sourceNames: const ["受伤"],
      isIncome: false,
      removeSources: true,
      targetParentName: "医疗",
    );
    await _mergeSystemCategories(
      targetName: "足球",
      sourceNames: const ["足球"],
      isIncome: false,
      removeSources: true,
      targetParentName: "运动",
    );
    await _mergeSystemCategories(
      targetName: "获得赔付",
      sourceNames: const ["赔付", "车险"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "保险报销",
      sourceNames: const ["车险报销"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "其他收益",
      sourceNames: const [
        "其它收益",
        "其它",
        "帮买",
        "充值",
        "二手",
        "二手置换",
        "红包",
        "收红包",
        "红包退回",
      ],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "人情收入",
      sourceNames: const ["人情"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "投资收益",
      sourceNames: const ["投资", "黄金", "股票", "股票基金"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "理财收益",
      sourceNames: const ["理财"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "获得贷款",
      sourceNames: const ["贷款"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "租金收入",
      sourceNames: const ["租金"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "零花钱",
      sourceNames: const ["孩子零花钱"],
      isIncome: true,
      removeSources: true,
    );
    await _mergeSystemCategories(
      targetName: "保险",
      sourceNames: const ["上保险"],
      isIncome: false,
      removeSources: true,
      targetParentName: "理财",
    );
    await _mergeSystemCategories(
      targetName: "天猫超市",
      sourceNames: const ["超市卡-天猫", "天猫超市"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "微信读书",
      sourceNames: const ["微信读书"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "懒人听书",
      sourceNames: const ["懒人听书"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "书旗小说",
      sourceNames: const ["书旗小说"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "虎牙",
      sourceNames: const ["虎牙"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "酷狗音乐",
      sourceNames: const ["酷狗音乐"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "淘宝88VIP",
      sourceNames: const ["阿里88VIP"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "京东",
      sourceNames: const ["超市卡-京东"],
      isIncome: false,
      removeSources: true,
      targetParentName: "品牌",
    );
    await _mergeSystemCategories(
      targetName: "购买App",
      sourceNames: const ["App"],
      isIncome: false,
      removeSources: true,
      targetParentName: "数码",
    );
    await _mergeSystemCategories(
      targetName: "电子产品",
      sourceNames: const ["电器数码"],
      isIncome: false,
      removeSources: true,
      targetParentName: "数码",
    );
    await _mergeSystemCategories(
      targetName: "电器",
      sourceNames: const ["电器"],
      isIncome: false,
      removeSources: true,
      targetParentName: "购物",
    );
    await _mergeSystemCategories(
      targetName: "网费",
      sourceNames: const ["网络", "网费"],
      isIncome: false,
      removeSources: true,
      targetParentName: "日常",
    );
    await _mergeSystemCategories(
      targetName: "话费",
      sourceNames: const ["话费", "话费网费"],
      isIncome: false,
      removeSources: true,
      targetParentName: "日常",
    );
    await _mergeSystemCategories(
      targetName: "品牌",
      sourceNames: const ["电商"],
      isIncome: false,
      removeSources: true,
    );
    final ecommerceNames = <String>[
      "淘宝",
      "天猫",
      "京东",
      "京东Plus",
      "拼多多",
      "盒马鲜生",
      "山姆会员",
      "亚马逊",
      "小红书",
      "网易考拉",
      "网易严选",
      "当当网",
      "苏宁易购",
      "小米有品",
      "小米商城",
      "闲鱼",
      "唯品会",
      "微店",
      "微信小程序",
      "美团",
      "阿里1688",
      "淘宝88VIP",
      "阿里云盘",
    ];
    for (final name in ecommerceNames) {
      await _mergeSystemCategories(
        targetName: name,
        sourceNames: [name],
        isIncome: false,
        removeSources: true,
        targetParentName: "品牌",
      );
    }
  }

  Future<void> _mergeSystemCategories({
    required String targetName,
    required List<String> sourceNames,
    bool? isIncome,
    bool removeSources = false,
    String? targetParentName,
  }) async {
    if (sourceNames.isEmpty) return;
    final collection = isar.collection<JiveCategory>();
    var targetQuery = collection.filter()
        .nameEqualTo(targetName)
        .isSystemEqualTo(true);
    if (isIncome != null) {
      targetQuery = targetQuery.isIncomeEqualTo(isIncome);
    }
    if (targetParentName != null) {
      final targetParentKey = _buildSystemParentKey(targetParentName, isIncome ?? false);
      targetQuery = targetQuery.parentKeyEqualTo(targetParentKey);
    }
    final target = await targetQuery.findFirst();
    if (target == null) return;

    var candidateQuery = collection.filter().isSystemEqualTo(true);
    if (isIncome != null) {
      candidateQuery = candidateQuery.isIncomeEqualTo(isIncome);
    }
    final candidates = await candidateQuery.findAll();
    final sources = candidates.where((cat) => sourceNames.contains(cat.name)).toList();
    if (sources.isEmpty) return;

    JiveCategory? parent;
    if (target.parentKey != null) {
      parent = await isar.collection<JiveCategory>()
          .filter()
          .keyEqualTo(target.parentKey!)
          .findFirst();
    }

    final updatedCats = <JiveCategory>[];
    final updatedTxs = <int, JiveTransaction>{};
    final removeIds = <int>[];
    final now = DateTime.now();

    void assignToTarget(JiveTransaction tx) {
      if (target.parentKey == null) {
        tx.categoryKey = target.key;
        tx.subCategoryKey = null;
        tx.category = target.name;
        tx.subCategory = "";
      } else {
        tx.categoryKey = target.parentKey;
        tx.subCategoryKey = target.key;
        if (parent != null) {
          tx.category = parent.name;
        }
        tx.subCategory = target.name;
      }
    }

    for (final source in sources) {
      if (source.id == target.id) continue;
      if (removeSources) {
        removeIds.add(source.id);
      } else if (!source.isHidden) {
        source.isHidden = true;
        source.updatedAt = now;
        updatedCats.add(source);
      }

      final asParentTxs = await isar.jiveTransactions
          .filter()
          .categoryKeyEqualTo(source.key)
          .findAll();
      for (final tx in asParentTxs) {
        assignToTarget(tx);
        updatedTxs[tx.id] = tx;
      }

      final asSubTxs = await isar.jiveTransactions
          .filter()
          .subCategoryKeyEqualTo(source.key)
          .findAll();
      for (final tx in asSubTxs) {
        assignToTarget(tx);
        updatedTxs[tx.id] = tx;
      }
    }

    if (updatedCats.isEmpty && updatedTxs.isEmpty && removeIds.isEmpty) return;
    await isar.writeTxn(() async {
      if (updatedCats.isNotEmpty) {
        await isar.collection<JiveCategory>().putAll(updatedCats);
      }
      if (updatedTxs.isNotEmpty) {
        await isar.jiveTransactions.putAll(updatedTxs.values.toList());
      }
      if (removeIds.isNotEmpty) {
        await isar.collection<JiveCategory>().deleteAll(removeIds);
      }
    });
  }

  // 获取系统默认库 (只读) - 用于分类管理页
  Map<String, Map<String, dynamic>> getSystemLibrary({bool isIncome = false, bool includeIncome = false}) {
    if (includeIncome) {
      return _mergeSystemLibraries(kSystemExpenseLibrary, kSystemIncomeLibrary);
    }
    return isIncome ? kSystemIncomeLibrary : kSystemExpenseLibrary;
  }

  String buildSystemParentKey(String name, {required bool isIncome}) {
    return _buildSystemParentKey(name, isIncome);
  }

  String buildSystemChildKey(String parentName, String childName, {required bool isIncome}) {
    return _buildSystemChildKey(parentName, childName, isIncome);
  }

  String? resolveSystemParentName(String key) {
    return _buildSystemIndex().parentByKey[key]?.name;
  }

  Map<String, Map<String, dynamic>> _mergeSystemLibraries(
    Map<String, Map<String, dynamic>> expense,
    Map<String, Map<String, dynamic>> income,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final entry in expense.entries) {
      merged[entry.key] = Map<String, dynamic>.from(entry.value);
    }
    for (final entry in income.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = Map<String, dynamic>.from(entry.value);
        continue;
      }
      final existing = merged[entry.key] ?? const {};
      final existingChildren = List<Map<String, dynamic>>.from(
        (existing['children'] as List<dynamic>? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final seen = {for (final item in existingChildren) item['name'] as String};
      for (final child in (entry.value['children'] as List<dynamic>? ?? const [])) {
        final childMap = Map<String, dynamic>.from(child as Map);
        final name = childMap['name'] as String;
        if (seen.add(name)) {
          existingChildren.add(childMap);
        }
      }
      merged[entry.key] = {
        'icon': existing['icon'] ?? entry.value['icon'],
        'children': existingChildren,
      };
    }
    return merged;
  }

  Future<void> _syncSystemCategoryIcons() async {
    final iconByKey = <String, String>{};

    void indexLibrary(Map<String, Map<String, dynamic>> lib, {required bool isIncome}) {
      for (final entry in lib.entries) {
        final parentName = entry.key;
        final parentKey = _buildSystemParentKey(parentName, isIncome);
        iconByKey[parentKey] = _normalizeIconName(entry.value['icon'] as String?, parentName);

        final children = entry.value['children'] as List<dynamic>? ?? const [];
        for (final child in children) {
          final childName = child['name'] as String? ?? "";
          if (childName.trim().isEmpty) continue;
          final childKey = _buildSystemChildKey(parentName, childName, isIncome);
          iconByKey[childKey] = _normalizeIconName(
            child['icon'] as String?,
            childName,
            parentName: parentName,
          );
        }
      }
    }

    indexLibrary(kSystemExpenseLibrary, isIncome: false);
    indexLibrary(kSystemIncomeLibrary, isIncome: true);

    final overridesByKey = await _loadOverridesByKey();
    final systemCats = await isar.collection<JiveCategory>()
        .filter()
        .isSystemEqualTo(true)
        .findAll();
    if (systemCats.isEmpty) return;

    final now = DateTime.now();
    final updated = <JiveCategory>[];
    for (final cat in systemCats) {
      if (overridesByKey[cat.key]?.iconOverride != null) continue;
      final desired = iconByKey[cat.key];
      if (desired == null || desired == "category") continue;
      if (_isFileIcon(cat.iconName) || _isTextIcon(cat.iconName)) continue;
      if (_normalizeIconKey(cat.iconName) == _normalizeIconKey(desired)) continue;
      cat.iconName = desired;
      cat.updatedAt = now;
      updated.add(cat);
    }

    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().putAll(updated);
    });
  }

  Future<void> _syncCategoryIconsFromSystemLibrary() async {
    final merged = _mergeSystemLibraries(kSystemExpenseLibrary, kSystemIncomeLibrary);
    if (merged.isEmpty) return;

    final parentIconByName = <String, String>{};
    final childIconByName = <String, String>{};

    for (final entry in merged.entries) {
      final rawParentName = entry.key;
      final parentName = _systemParentAliases[rawParentName] ?? rawParentName;
      final parentKey = _normalizeMatchName(parentName);
      final parentIcon = _normalizeIconName(entry.value['icon'] as String?, parentName);
      if (parentIcon != "category") {
        parentIconByName[parentKey] = parentIcon;
      }

      final children = entry.value['children'] as List<dynamic>? ?? const [];
      for (final child in children) {
        final childName = (child['name'] as String? ?? "").trim();
        if (childName.isEmpty) continue;
        final childKey = "${parentKey}|${_normalizeMatchName(childName)}";
        final childIcon = _normalizeIconName(
          child['icon'] as String?,
          childName,
          parentName: parentName,
        );
        if (childIcon != "category") {
          childIconByName[childKey] = childIcon;
        }
      }
    }

    final overridesByKey = await _loadOverridesByKey();
    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return;

    final parentNameByKey = {
      for (final cat in categories)
        if (cat.parentKey == null) cat.key: cat.name,
    };
    final systemIconKeys = <String>{
      for (final icon in parentIconByName.values) _normalizeIconKey(icon),
      for (final icon in childIconByName.values) _normalizeIconKey(icon),
    };

    final now = DateTime.now();
    final updated = <JiveCategory>[];
    for (final cat in categories) {
      if (_isFileIcon(cat.iconName) || _isTextIcon(cat.iconName) || _isEmojiIcon(cat.iconName)) continue;
      if (cat.isSystem && overridesByKey[cat.key]?.iconOverride != null) continue;

      String? desired;
      if (cat.parentKey == null) {
        final parentName = _systemParentAliases[cat.name] ?? cat.name;
        desired = parentIconByName[_normalizeMatchName(parentName)];
      } else {
        final parentName = parentNameByKey[cat.parentKey];
        if (parentName == null) continue;
        final parentKey = _normalizeMatchName(_systemParentAliases[parentName] ?? parentName);
        final childKey = "${parentKey}|${_normalizeMatchName(cat.name)}";
        desired = childIconByName[childKey];
      }

      if (desired == null || desired == "category") continue;
      final desiredKey = _normalizeIconKey(desired);
      final currentKey = _normalizeIconKey(cat.iconName);
      if (currentKey == desiredKey) continue;
      final shouldUpdate = cat.isSystem ||
          cat.iconName == "category" ||
          cat.iconName == "attach_money" ||
          systemIconKeys.contains(currentKey);
      if (!shouldUpdate) continue;

      cat.iconName = desired;
      cat.updatedAt = now;
      updated.add(cat);
    }

    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().putAll(updated);
    });
  }

  Future<Map<String, JiveCategoryOverride>> _loadOverridesByKey() async {
    final overrides = await isar.collection<JiveCategoryOverride>().where().findAll();
    return {for (final override in overrides) override.systemKey: override};
  }

  Future<void> _applySystemOverrides() async {
    final overrides = await isar.collection<JiveCategoryOverride>().where().findAll();
    if (overrides.isEmpty) return;

    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return;
    final categoryByKey = {for (final cat in categories) cat.key: cat};

    final now = DateTime.now();
    final updated = <JiveCategory>[];
    for (final override in overrides) {
      final cat = categoryByKey[override.systemKey];
      if (cat == null) continue;
      var changed = false;

      if (override.nameOverride != null && cat.name != override.nameOverride) {
        cat.name = override.nameOverride!;
        changed = true;
      }
      if (override.iconOverride != null &&
          _normalizeIconKey(cat.iconName) != _normalizeIconKey(override.iconOverride!)) {
        cat.iconName = override.iconOverride!;
        changed = true;
      }
      if (override.colorHexOverride != null && cat.colorHex != override.colorHexOverride) {
        cat.colorHex = override.colorHexOverride;
        changed = true;
      }
      if (override.parentOverrideKey != null) {
        final desiredParentKey = override.parentOverrideKey == _noParentOverrideKey
            ? null
            : override.parentOverrideKey;
        if (desiredParentKey == null || categoryByKey.containsKey(desiredParentKey)) {
          if (cat.parentKey != desiredParentKey) {
            cat.parentKey = desiredParentKey;
            changed = true;
          }
        }
      }
      if (override.orderOverride != null && cat.order != override.orderOverride) {
        cat.order = override.orderOverride!;
        changed = true;
      }
      if (override.isHiddenOverride != null && cat.isHidden != override.isHiddenOverride) {
        cat.isHidden = override.isHiddenOverride!;
        changed = true;
      }

      if (changed) {
        cat.updatedAt = now;
        updated.add(cat);
      }
    }

    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().putAll(updated);
    });
  }

  Future<void> _syncSystemOverridesForCategories(
    List<JiveCategory> categories, {
    bool includeOrder = false,
  }) async {
    final systemCats = categories.where((cat) => cat.isSystem).toList();
    if (systemCats.isEmpty) return;

    final systemIndex = _buildSystemIndex();
    final overridesByKey = await _loadOverridesByKey();
    final now = DateTime.now();

    final toUpsert = <JiveCategoryOverride>[];
    final toDelete = <int>[];
    for (final cat in systemCats) {
      final base = systemIndex.byKey[cat.key];
      if (base == null) continue;
      final existing = overridesByKey[cat.key];
      final override = _buildOverrideFromCategory(
        cat,
        base,
        existing,
        includeOrder: includeOrder,
        now: now,
      );
      if (override == null) {
        if (existing != null) toDelete.add(existing.id);
        continue;
      }
      toUpsert.add(override);
    }

    if (toUpsert.isEmpty && toDelete.isEmpty) return;
    await isar.writeTxn(() async {
      if (toUpsert.isNotEmpty) {
        await isar.collection<JiveCategoryOverride>().putAll(toUpsert);
      }
      if (toDelete.isNotEmpty) {
        await isar.collection<JiveCategoryOverride>().deleteAll(toDelete);
      }
    });
  }

  Future<bool> _migrateSystemCategoriesByName() async {
    final systemIndex = _buildSystemIndex();
    if (systemIndex.byKey.isEmpty) return false;

    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return false;

    final overrides = await isar.collection<JiveCategoryOverride>().where().findAll();
    final overridesByKey = {for (final override in overrides) override.systemKey: override};

    final parents = <JiveCategory>[];
    final children = <JiveCategory>[];
    final parentByKey = <String, JiveCategory>{};
    for (final cat in categories) {
      if (cat.parentKey == null) {
        parents.add(cat);
        parentByKey[cat.key] = cat;
      } else {
        children.add(cat);
      }
    }

    final now = DateTime.now();
    final updated = <JiveCategory>[];
    final deletedIds = <int>[];
    final keyRemap = <String, String>{};
    final parentKeyRemap = <String, String>{};
    final overrideUpdates = <String, JiveCategoryOverride>{};
    final overrideDeleteIds = <int>{};

    void mergeOverride({
      required String systemKey,
      required JiveCategory source,
      required _SystemCategoryBase base,
      String? parentOverrideKey,
    }) {
      final incoming = _buildOverrideSnapshot(
        systemKey: systemKey,
        source: source,
        base: base,
        parentOverrideKey: parentOverrideKey,
        now: now,
      );
      if (incoming == null) return;
      final existing = overridesByKey[systemKey];
      final preferIncoming = existing == null || source.updatedAt.isAfter(existing.updatedAt);
      final merged = _mergeOverridesForMigration(
        existing: existing,
        incoming: incoming,
        preferIncoming: preferIncoming,
        now: now,
      );
      if (merged == null) return;
      overrideUpdates[systemKey] = merged;
      overridesByKey[systemKey] = merged;
    }

    for (final parent in parents) {
      final baseByKey = systemIndex.byKey[parent.key];
      if (baseByKey != null && baseByKey.parentKey == null) {
        parentKeyRemap[parent.key] = parent.key;
        if (!parent.isSystem || parent.isIncome != baseByKey.isIncome) {
          parent.isSystem = true;
          parent.isIncome = baseByKey.isIncome;
          parent.updatedAt = now;
          updated.add(parent);
        }
        mergeOverride(systemKey: parent.key, source: parent, base: baseByKey);
        continue;
      }

      final baseParent = systemIndex.parentByMatchName[_parentMatchKey(parent.name, parent.isIncome)];
      if (baseParent != null) {
        parentKeyRemap[parent.key] = baseParent.key;
        if (parent.key != baseParent.key) {
          keyRemap[parent.key] = baseParent.key;
          deletedIds.add(parent.id);
        } else if (!parent.isSystem) {
          parent.isSystem = true;
          parent.updatedAt = now;
          updated.add(parent);
        }
        mergeOverride(systemKey: baseParent.key, source: parent, base: baseParent);
        continue;
      }

      final aliasName = _systemParentAliases[parent.name];
      if (aliasName != null) {
        final aliasParent = systemIndex.parentByMatchName[_parentMatchKey(aliasName, parent.isIncome)];
        if (aliasParent != null) {
          parentKeyRemap[parent.key] = aliasParent.key;
          keyRemap[parent.key] = aliasParent.key;
          deletedIds.add(parent.id);
          mergeOverride(systemKey: aliasParent.key, source: parent, base: aliasParent);
          continue;
        }
      }

      if (parent.isSystem) {
        parent.isSystem = false;
        parent.updatedAt = now;
        updated.add(parent);
      }
    }

    for (final child in children) {
      final baseByKey = systemIndex.byKey[child.key];
      if (baseByKey != null && baseByKey.parentKey != null) {
        final parentWasRemapped = child.parentKey != null && parentKeyRemap.containsKey(child.parentKey);
        final remappedParentKey = child.parentKey == null
            ? null
            : (parentKeyRemap[child.parentKey!] ?? child.parentKey);
        if (parentWasRemapped && remappedParentKey != child.parentKey) {
          child.parentKey = remappedParentKey;
          child.updatedAt = now;
          updated.add(child);
        }
        if (!child.isSystem || child.isIncome != baseByKey.isIncome) {
          child.isSystem = true;
          child.isIncome = baseByKey.isIncome;
          child.updatedAt = now;
          updated.add(child);
        }
        final parentOverrideKey = _computeParentOverrideKey(
          currentParentKey: remappedParentKey,
          baseParentKey: baseByKey.parentKey,
        );
        mergeOverride(
          systemKey: child.key,
          source: child,
          base: baseByKey,
          parentOverrideKey: parentOverrideKey,
        );
        continue;
      }

      final parent = child.parentKey == null ? null : parentByKey[child.parentKey!];
      final parentName = parent?.name;
      final resolvedParentName =
          parentName == null ? null : (_systemParentAliases[parentName] ?? parentName);
      final baseParent = resolvedParentName == null
          ? null
          : systemIndex.parentByMatchName[_parentMatchKey(resolvedParentName, child.isIncome)];
      if (baseParent != null) {
        final baseChild = systemIndex.childByMatchName[_childMatchKey(baseParent.name, child.name, child.isIncome)];
        if (baseChild != null) {
          if (child.key != baseChild.key) {
            keyRemap[child.key] = baseChild.key;
            deletedIds.add(child.id);
          } else if (!child.isSystem) {
            child.isSystem = true;
            child.updatedAt = now;
            updated.add(child);
          }

          final parentWasRemapped = child.parentKey != null && parentKeyRemap.containsKey(child.parentKey);
          final remappedParentKey = child.parentKey == null
              ? null
              : (parentKeyRemap[child.parentKey!] ?? child.parentKey);
          if (parentWasRemapped && remappedParentKey != child.parentKey) {
            child.parentKey = remappedParentKey;
            child.updatedAt = now;
            updated.add(child);
          }

          final parentOverrideKey = _computeParentOverrideKey(
            currentParentKey: remappedParentKey,
            baseParentKey: baseChild.parentKey,
          );
          mergeOverride(
            systemKey: baseChild.key,
            source: child,
            base: baseChild,
            parentOverrideKey: parentOverrideKey,
          );
          continue;
        }
      }

      final remappedParentKey = child.parentKey == null
          ? null
          : (parentKeyRemap[child.parentKey!] ?? child.parentKey);
      if (remappedParentKey != child.parentKey) {
        child.parentKey = remappedParentKey;
        child.updatedAt = now;
        updated.add(child);
      }
      if (child.isSystem) {
        child.isSystem = false;
        child.updatedAt = now;
        updated.add(child);
      }
    }

    for (final entry in overridesByKey.entries) {
      if (!systemIndex.byKey.containsKey(entry.key)) {
        overrideDeleteIds.add(entry.value.id);
      }
    }

    final hasChanges = updated.isNotEmpty ||
        deletedIds.isNotEmpty ||
        keyRemap.isNotEmpty ||
        overrideUpdates.isNotEmpty ||
        overrideDeleteIds.isNotEmpty;
    if (!hasChanges) return false;

    await isar.writeTxn(() async {
      if (updated.isNotEmpty) {
        await isar.collection<JiveCategory>().putAll(updated);
      }
      if (deletedIds.isNotEmpty) {
        await isar.collection<JiveCategory>().deleteAll(deletedIds);
      }
      if (overrideUpdates.isNotEmpty) {
        await isar.collection<JiveCategoryOverride>().putAll(overrideUpdates.values.toList());
      }
      if (overrideDeleteIds.isNotEmpty) {
        await isar.collection<JiveCategoryOverride>().deleteAll(overrideDeleteIds.toList());
      }
    });

    if (keyRemap.isNotEmpty) {
      await _remapTransactionCategoryKeys(keyRemap);
    }
    return true;
  }

  Future<void> _remapTransactionCategoryKeys(Map<String, String> keyRemap) async {
    if (keyRemap.isEmpty) return;
    final txs = await isar.jiveTransactions.where().findAll();
    if (txs.isEmpty) return;

    final updated = <JiveTransaction>[];
    for (final tx in txs) {
      var changed = false;
      final currentParentKey = tx.categoryKey;
      if (currentParentKey != null && keyRemap.containsKey(currentParentKey)) {
        tx.categoryKey = keyRemap[currentParentKey];
        changed = true;
      }
      final currentSubKey = tx.subCategoryKey;
      if (currentSubKey != null && keyRemap.containsKey(currentSubKey)) {
        tx.subCategoryKey = keyRemap[currentSubKey];
        changed = true;
      }
      if (changed) updated.add(tx);
    }

    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.jiveTransactions.putAll(updated);
    });
  }

  Future<void> _refreshTransactionCategoryNames() async {
    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return;
    final categoryByKey = {for (final cat in categories) cat.key: cat};

    final txs = await isar.jiveTransactions.where().findAll();
    if (txs.isEmpty) return;

    final updated = <JiveTransaction>[];
    for (final tx in txs) {
      var changed = false;

      final subKey = tx.subCategoryKey;
      if (subKey != null && subKey.isNotEmpty) {
        final sub = categoryByKey[subKey];
        if (sub != null) {
          final parentKey = sub.parentKey;
          if (parentKey != null && tx.categoryKey != parentKey) {
            tx.categoryKey = parentKey;
            changed = true;
          }
          final parent = parentKey == null ? null : categoryByKey[parentKey];
          final parentName = parent?.name;
          if (parentName != null && tx.category != parentName) {
            tx.category = parentName;
            changed = true;
          }
          if (tx.subCategory != sub.name) {
            tx.subCategory = sub.name;
            changed = true;
          }
        }
      }

      final parentKey = tx.categoryKey;
      if (parentKey != null && parentKey.isNotEmpty) {
        final parent = categoryByKey[parentKey];
        if (parent != null && tx.category != parent.name) {
          tx.category = parent.name;
          changed = true;
        }
        if ((tx.subCategoryKey == null || tx.subCategoryKey!.isEmpty) &&
            (tx.subCategory ?? "").isNotEmpty) {
          tx.subCategory = "";
          changed = true;
        }
      }

      if (changed) updated.add(tx);
    }

    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.jiveTransactions.putAll(updated);
    });
  }

  // 从库中添加分类到用户账本
  Future<void> addCategoryFromLib(
    String parentName,
    Map<String, dynamic> childData, {
    bool isIncome = false,
  }) async {
    JiveCategory? parent = await isar.collection<JiveCategory>()
        .filter().nameEqualTo(parentName).parentKeyIsNull().findFirst();
    
    if (parent == null) {
      // FIX: Use stable key format consistent with initDefaultCategories
      final systemIndex = _buildSystemIndex();
      final parentKey = _buildSystemParentKey(parentName, isIncome);
      final baseOrder = systemIndex.byKey[parentKey]?.order;
      parent = JiveCategory()
        ..key = parentKey
        ..name = parentName
        ..iconName = _findParentIcon(parentName, isIncome)
        ..parentKey = null
        ..order = baseOrder ?? 99
        ..isSystem = true
        ..isHidden = false
        ..isIncome = isIncome
        ..updatedAt = DateTime.now();
      
      await isar.writeTxn(() async {
        await isar.collection<JiveCategory>().put(parent!);
      });
    }

    final childName = childData['name'];
    final systemIndex = _buildSystemIndex();
    final childKey = _buildSystemChildKey(parentName, childName, isIncome);
    
    final exists = await isar.collection<JiveCategory>().filter().keyEqualTo(childKey).findFirst();
    if (exists != null) return; 

    final baseOrder = systemIndex.byKey[childKey]?.order;
    final child = JiveCategory()
      ..key = childKey
      ..name = childName
      ..iconName = _normalizeIconName(
        childData['icon'] as String?,
        childName,
        parentName: parentName,
      )
      ..parentKey = parent.key
      ..order = baseOrder ?? 99
      ..isSystem = true
      ..isHidden = false
      ..isIncome = isIncome
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().put(child);
    });
  }

  Future<JiveCategory?> createSubCategory({
    required JiveCategory parent,
    required String name,
    required String iconName,
    String? colorHex,
    bool isSystem = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final existsByName = await isar.collection<JiveCategory>()
        .filter()
        .parentKeyEqualTo(parent.key)
        .nameEqualTo(trimmed)
        .findFirst();
    if (existsByName != null) return null;

    final systemIndex = isSystem ? _buildSystemIndex() : null;
    final baseParentName = isSystem ? systemIndex?.parentByKey[parent.key]?.name ?? parent.name : parent.name;
    var key = isSystem
        ? _buildSystemChildKey(baseParentName, trimmed, parent.isIncome)
        : _buildChildKey(parent.key, trimmed);
    final existsByKey = await isar.collection<JiveCategory>()
        .filter()
        .keyEqualTo(key)
        .findFirst();
    if (existsByKey != null) {
      if (isSystem) return null;
      key = "${key}_${DateTime.now().millisecondsSinceEpoch}";
    }

    final last = await isar.collection<JiveCategory>()
        .filter()
        .parentKeyEqualTo(parent.key)
        .sortByOrderDesc()
        .findFirst();
    final baseOrder = isSystem ? systemIndex?.byKey[key]?.order : null;

    final child = JiveCategory()
      ..key = key
      ..name = trimmed
      ..iconName = iconName
      ..colorHex = _normalizeColorHex(colorHex)
      ..parentKey = parent.key
      ..order = baseOrder ?? (last?.order ?? -1) + 1
      ..isSystem = isSystem
      ..isHidden = false
      ..isIncome = parent.isIncome
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().put(child);
    });

    return child;
  }

  Future<JiveCategory?> createParentCategory({
    required String name,
    required String iconName,
    required bool isIncome,
    String? colorHex,
    bool isSystem = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final existsByName = await isar.collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(isIncome)
        .isSystemEqualTo(isSystem)
        .nameEqualTo(trimmed)
        .findFirst();
    if (existsByName != null) return null;

    final systemIndex = isSystem ? _buildSystemIndex() : null;
    var key = isSystem ? _buildSystemParentKey(trimmed, isIncome) : _buildParentKey(trimmed);
    final existsByKey = await isar.collection<JiveCategory>()
        .filter()
        .keyEqualTo(key)
        .findFirst();
    if (existsByKey != null) {
      if (isSystem) return null;
      key = "${key}_${DateTime.now().millisecondsSinceEpoch}";
    }

    final last = await isar.collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(isIncome)
        .sortByOrderDesc()
        .findFirst();

    final baseOrder = isSystem ? systemIndex?.byKey[key]?.order : null;
    final parent = JiveCategory()
      ..key = key
      ..name = trimmed
      ..iconName = iconName
      ..colorHex = _normalizeColorHex(colorHex)
      ..parentKey = null
      ..order = baseOrder ?? (last?.order ?? -1) + 1
      ..isSystem = isSystem
      ..isHidden = false
      ..isIncome = isIncome
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().put(parent);
    });

    return parent;
  }

  Future<void> reorderParents(List<JiveCategory> parents) async {
    final updated = <JiveCategory>[];
    for (var i = 0; i < parents.length; i++) {
      final cat = parents[i];
      if (cat.order != i) {
        cat.order = i;
        cat.updatedAt = DateTime.now();
        updated.add(cat);
      }
    }
    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().putAll(updated);
    });
    await _syncSystemOverridesForCategories(updated, includeOrder: true);
  }

  Future<void> reorderChildren(String parentKey, List<JiveCategory> children) async {
    final updated = <JiveCategory>[];
    for (var i = 0; i < children.length; i++) {
      final cat = children[i];
      if (cat.parentKey != parentKey) continue;
      if (cat.order != i) {
        cat.order = i;
        cat.updatedAt = DateTime.now();
        updated.add(cat);
      }
    }
    if (updated.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().putAll(updated);
    });
    await _syncSystemOverridesForCategories(updated, includeOrder: true);
  }

  Future<bool> deleteCategory(JiveCategory category) async {
    if (category.isSystem) return false;
    if (category.parentKey == null) {
      final child = await isar.collection<JiveCategory>()
          .filter()
          .parentKeyEqualTo(category.key)
          .findFirst();
      if (child != null) return false;
    }

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().delete(category.id);
      await _syncTransactionsForCategoryDeletion(category);
    });
    return true;
  }

  Future<void> _syncTransactionsForCategoryDeletion(JiveCategory cat) async {
    final Map<int, JiveTransaction> updated = {};

    final asParentTxs = await isar.jiveTransactions
        .filter()
        .categoryKeyEqualTo(cat.key)
        .findAll();
    for (final tx in asParentTxs) {
      tx.categoryKey = null;
      if ((tx.category ?? "").isEmpty) {
        tx.category = cat.name;
      }
      updated[tx.id] = tx;
    }

    final asSubTxs = await isar.jiveTransactions
        .filter()
        .subCategoryKeyEqualTo(cat.key)
        .findAll();
    for (final tx in asSubTxs) {
      tx.subCategoryKey = null;
      if ((tx.subCategory ?? "").isEmpty) {
        tx.subCategory = cat.name;
      }
      updated[tx.id] = tx;
    }

    if (updated.isEmpty) return;
    await isar.jiveTransactions.putAll(updated.values.toList());
  }

  String _buildChildKey(String parentKey, String name) {
    final safeName = _normalizeUserKeyName(name);
    return "${parentKey}_$safeName";
  }

  String _buildParentKey(String name) {
    final safeName = _normalizeUserKeyName(name);
    return "usr_$safeName";
  }

  String _findParentIcon(String name, bool isIncome) {
    final lib = getSystemLibrary(isIncome: isIncome);
    final entry = lib[name];
    if (entry == null) return "category";
    final icon = entry['icon'] as String?;
    return _normalizeIconName(icon, name);
  }

  String _buildSystemParentKey(String name, bool isIncome) {
    final type = isIncome ? "income" : "expense";
    return _hashSystemKey("$type|${_normalizeMatchName(name)}");
  }

  String _buildSystemChildKey(String parentName, String childName, bool isIncome) {
    final type = isIncome ? "income" : "expense";
    final parentToken = _normalizeMatchName(parentName);
    final childToken = _normalizeMatchName(childName);
    return _hashSystemKey("$type|$parentToken|$childToken");
  }

  String _hashSystemKey(String raw) {
    final digest = sha1.convert(utf8.encode(raw)).toString();
    return "sys_$digest";
  }

  String _normalizeMatchName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  String _normalizeUserKeyName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), '');
  }

  String _normalizeIconKey(String name) {
    return _assetIconKey(name);
  }

  String _normalizeIconName(String? icon, String name, {String? parentName}) {
    final value = icon?.trim() ?? "";
    if (value.isNotEmpty && value != "category") return value;
    final suggested = suggestIconName(name, fallback: "category");
    if (suggested != "category") return suggested;
    if (parentName == null) return "category";
    final parentSuggested = suggestIconName(parentName, fallback: "category");
    return parentSuggested == "category" ? "category" : parentSuggested;
  }

  String? _normalizeColorHex(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith("#")) return "#$trimmed";
    return trimmed;
  }

  static bool _isAssetIcon(String name) {
    return name.endsWith(".png") || name.endsWith(".svg");
  }

  static String _assetIconPath(String name) {
    if (name.startsWith("assets/")) return name;
    if (name.startsWith("qj/")) return "assets/category_icons/${name.substring(3)}";
    return "assets/category_icons/$name";
  }

  static String _assetIconKey(String name) {
    if (name.startsWith("assets/")) {
      final trimmed = name.substring("assets/".length);
      if (trimmed.startsWith("category_icons/")) {
        return trimmed.substring("category_icons/".length);
      }
      final parts = trimmed.split("/");
      return parts.isEmpty ? name : parts.last;
    }
    if (name.startsWith("qj/")) return name.substring(3);
    return name;
  }

  static Color _resolveIconTone(String name, Color base) {
    if (!_isNeutralGray(base)) return base;
    final key = _assetIconKey(name);
    if (_softIconKeys.contains(key)) {
      return const Color(0xFFC0C0C0);
    }
    return base;
  }

  static bool _isSoftIcon(String name) {
    final key = _assetIconKey(name);
    return _softIconKeys.contains(key);
  }

  static bool _isBrandIcon(String name) {
    final key = _assetIconKey(name);
    return key.startsWith("品牌__") || key.contains("__Brand__");
  }

  static Widget _applyDetailPreservingTint(
    Widget child,
    Color color, {
    bool soften = false,
    double? liftTarget,
  }) {
    var toned = color;
    if (_isNeutralGray(toned)) {
      toned = _liftGray(toned, targetLuminance: liftTarget ?? _defaultLiftTarget);
    } else if (soften) {
      toned = Color.lerp(toned, Colors.black, 0.06) ?? toned;
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_contrastMatrix),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(toned, BlendMode.modulate),
          child: child,
        ),
      ),
    );
  }

  static bool _isNeutralGray(Color color) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;
    final maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
    return (maxChannel - minChannel) <= 4;
  }

  static Color _liftGray(Color color, {double targetLuminance = _defaultLiftTarget}) {
    final luminance = color.computeLuminance();
    if (luminance >= targetLuminance) return color;
    final raw = (targetLuminance - luminance) / (1.0 - luminance);
    final t = raw < 0 ? 0.0 : (raw > 0.55 ? 0.55 : raw);
    return Color.lerp(color, Colors.white, t) ?? color;
  }

  static bool _isFileIcon(String name) {
    return name.startsWith("file:");
  }

  static bool _isTextIcon(String name) {
    return name.startsWith("text:");
  }

  static bool _isEmojiIcon(String name) {
    return name.startsWith("emoji:");
  }

  static String _textIconValue(String name) {
    return name.substring("text:".length).trim();
  }

  static String _emojiSequence(String name) {
    return name.substring("emoji:".length).trim();
  }

  static String _emojiAssetPath(String sequence) {
    return "assets/emoji/emoji_u$sequence.png";
  }

  static String _emojiFromSequence(String sequence) {
    try {
      final codepoints = sequence.split("_").where((part) => part.isNotEmpty);
      return String.fromCharCodes(
        codepoints.map((part) => int.parse(part, radix: 16)),
      );
    } catch (_) {
      return "?";
    }
  }

  static int _cacheWidth(double size) {
    final views = ui.PlatformDispatcher.instance.views;
    final ratio = views.isEmpty ? 1.0 : views.first.devicePixelRatio;
    final pixelSize = (size * ratio).round();
    return pixelSize <= 0 ? size.round() : pixelSize;
  }

  static int compareCategoryName(String a, String b) {
    final aKey = PinyinHelper.getPinyinE(a).toLowerCase();
    final bKey = PinyinHelper.getPinyinE(b).toLowerCase();
    final cmp = aKey.compareTo(bKey);
    if (cmp != 0) return cmp;
    return a.compareTo(b);
  }

  static Widget buildIcon(
    String name, {
    double size = 20,
    Color? color,
  }) {
    final resolvedColor = color ?? _defaultIconColor;
    final isSoft = _isSoftIcon(name);
    final tonedColor = _resolveIconTone(name, resolvedColor);
    if (_isTextIcon(name)) {
      final text = _textIconValue(name);
      return Center(
        child: Text(
          text.isEmpty ? "?" : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w600,
            color: tonedColor,
          ),
        ),
      );
    }
    if (_isEmojiIcon(name)) {
      final sequence = _emojiSequence(name);
      final cacheWidth = _cacheWidth(size);
      return Image.asset(
        _emojiAssetPath(sequence),
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => Text(
          _emojiFromSequence(sequence),
          style: TextStyle(fontSize: size * 0.8),
        ),
      );
    }
    if (_isFileIcon(name)) {
      final path = name.substring("file:".length);
      final cacheWidth = _cacheWidth(size);
      return Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => Icon(Icons.category, size: size, color: tonedColor),
      );
    }
    if (_isAssetIcon(name)) {
      final path = _assetIconPath(name);
      if (path.endsWith(".svg")) {
        final svg = SvgPicture.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
        return _applyDetailPreservingTint(
          svg,
          tonedColor,
          soften: _isBrandIcon(name),
          liftTarget: isSoft ? _softLiftTarget : _defaultLiftTarget,
        );
      }
      final cacheWidth = _cacheWidth(size);
      final image = Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder:
            (_, __, ___) => Icon(Icons.category, size: size, color: tonedColor),
      );
      return _applyDetailPreservingTint(
        image,
        tonedColor,
        soften: _isBrandIcon(name),
        liftTarget: isSoft ? _softLiftTarget : _defaultLiftTarget,
      );
    }
    return Icon(getIcon(name), size: size, color: tonedColor);
  }

  static Color? parseColorHex(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    var hex = trimmed.startsWith("#") ? trimmed.substring(1) : trimmed;
    if (hex.length == 6) {
      hex = "FF$hex";
    } else if (hex.length != 8) {
      return null;
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  // 获取所有一级分类 (用于下拉菜单)
  Future<List<JiveCategory>> getAllParents() async {
    return await isar.collection<JiveCategory>()
        .filter().parentKeyIsNull().sortByOrder().findAll();
  }

  Future<void> setCategoryHidden(int id, bool isHidden) async {
    final cat = await isar.collection<JiveCategory>().get(id);
    if (cat == null) return;
    if (cat.isHidden == isHidden) return;
    cat.isHidden = isHidden;
    cat.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().put(cat);
    });
    await _syncSystemOverridesForCategories([cat]);
  }

  // 更新分类 (核心逻辑: 改名、改图标、改爸爸)
  Future<void> updateCategory(
    int id,
    String name,
    String icon,
    String? newParentKey,
    String? colorHex,
  ) async {
    final cat = await isar.collection<JiveCategory>().get(id);
    if (cat == null) return;

    // 如果变成二级分类，需要生成一个新的 Key 吗？
    // 钱迹逻辑：Key/ID 不变，只改 parentKey。这样账单不会丢。
    cat.name = name;
    cat.iconName = icon;
    cat.parentKey = newParentKey; // null = 升级为一级; 有值 = 降级为二级
    cat.colorHex = _normalizeColorHex(colorHex);
    cat.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().put(cat);
      await _syncTransactionsForCategoryChange(cat);
    });
    await _syncSystemOverridesForCategories([cat]);
  }

  Future<void> _syncTransactionsForCategoryChange(JiveCategory cat) async {
    final newParentKey = cat.parentKey;
    String? newParentName;
    if (newParentKey != null) {
      final parent = await isar.collection<JiveCategory>()
          .filter()
          .keyEqualTo(newParentKey)
          .findFirst();
      newParentName = parent?.name;
    }

    final Map<int, JiveTransaction> updated = {};

    final asParentTxs = await isar.jiveTransactions
        .filter()
        .categoryKeyEqualTo(cat.key)
        .findAll();
    for (final tx in asParentTxs) {
      if (newParentKey == null) {
        tx.category = cat.name;
      } else {
        tx.categoryKey = newParentKey;
        tx.subCategoryKey = cat.key;
        if (newParentName != null) tx.category = newParentName;
        tx.subCategory = cat.name;
      }
      updated[tx.id] = tx;
    }

    final asSubTxs = await isar.jiveTransactions
        .filter()
        .subCategoryKeyEqualTo(cat.key)
        .findAll();
    for (final tx in asSubTxs) {
      if (newParentKey == null) {
        tx.categoryKey = cat.key;
        tx.subCategoryKey = null;
        tx.category = cat.name;
        tx.subCategory = "";
      } else {
        tx.categoryKey = newParentKey;
        if (newParentName != null) tx.category = newParentName;
        tx.subCategory = cat.name;
      }
      updated[tx.id] = tx;
    }

    if (updated.isEmpty) return;
    await isar.jiveTransactions.putAll(updated.values.toList());
  }

  JiveCategory _buildSystemCategoryFromBase(_SystemCategoryBase base, DateTime now) {
    return JiveCategory()
      ..key = base.key
      ..name = base.name
      ..iconName = base.iconName
      ..colorHex = base.colorHex
      ..parentKey = base.parentKey
      ..order = base.order
      ..isSystem = true
      ..isHidden = base.isHidden
      ..isIncome = base.isIncome
      ..updatedAt = now;
  }

  _SystemCategoryIndex _buildSystemIndex() {
    final byKey = <String, _SystemCategoryBase>{};
    final parentByKey = <String, _SystemCategoryBase>{};
    final parentByMatchName = <String, _SystemCategoryBase>{};
    final childByMatchName = <String, _SystemCategoryBase>{};
    final childrenByParentKey = <String, List<_SystemCategoryBase>>{};

    void indexLibrary(Map<String, Map<String, dynamic>> lib, {required bool isIncome}) {
      final parentNames = lib.keys.toList()
        ..sort((a, b) => compareCategoryName(a, b));
      var parentOrder = 0;
      for (final parentName in parentNames) {
        final data = lib[parentName] ?? const {};
        final parentKey = _buildSystemParentKey(parentName, isIncome);
        final parentBase = _SystemCategoryBase(
          key: parentKey,
          name: parentName,
          iconName: _normalizeIconName(data['icon'] as String?, parentName),
          parentKey: null,
          parentName: null,
          isIncome: isIncome,
          order: parentOrder++,
          colorHex: null,
          isHidden: false,
        );
        byKey[parentKey] = parentBase;
        parentByKey[parentKey] = parentBase;
        parentByMatchName[_parentMatchKey(parentName, isIncome)] = parentBase;
        childrenByParentKey.putIfAbsent(parentKey, () => []);

        final rawChildren = (data['children'] as List<dynamic>? ?? const []);
        final children = rawChildren
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
          ..sort((a, b) => compareCategoryName(a['name'] as String, b['name'] as String));

        var childOrder = 0;
        for (final child in children) {
          final childName = child['name'] as String? ?? "";
          if (childName.trim().isEmpty) continue;
          final childKey = _buildSystemChildKey(parentName, childName, isIncome);
          final childBase = _SystemCategoryBase(
            key: childKey,
            name: childName,
            iconName: _normalizeIconName(
              child['icon'] as String?,
              childName,
              parentName: parentName,
            ),
            parentKey: parentKey,
            parentName: parentName,
            isIncome: isIncome,
            order: childOrder++,
            colorHex: null,
            isHidden: false,
          );
          byKey[childKey] = childBase;
          childByMatchName[_childMatchKey(parentName, childName, isIncome)] = childBase;
          childrenByParentKey[parentKey]!.add(childBase);
        }
      }
    }

    indexLibrary(kSystemExpenseLibrary, isIncome: false);
    indexLibrary(kSystemIncomeLibrary, isIncome: true);
    return _SystemCategoryIndex(
      byKey: byKey,
      parentByKey: parentByKey,
      parentByMatchName: parentByMatchName,
      childByMatchName: childByMatchName,
      childrenByParentKey: childrenByParentKey,
    );
  }

  String _parentMatchKey(String name, bool isIncome) {
    final type = isIncome ? "income" : "expense";
    return "$type|${_normalizeMatchName(name)}";
  }

  String _childMatchKey(String parentName, String childName, bool isIncome) {
    final type = isIncome ? "income" : "expense";
    return "$type|${_normalizeMatchName(parentName)}|${_normalizeMatchName(childName)}";
  }

  JiveCategoryOverride? _buildOverrideFromCategory(
    JiveCategory category,
    _SystemCategoryBase base,
    JiveCategoryOverride? existing, {
    required bool includeOrder,
    required DateTime now,
  }) {
    final override = existing ?? JiveCategoryOverride()..systemKey = category.key;
    if (existing != null) {
      override.id = existing.id;
    }
    override
      ..nameOverride = category.name != base.name ? category.name : null
      ..iconOverride = _normalizeIconKey(category.iconName) != _normalizeIconKey(base.iconName)
          ? category.iconName
          : null
      ..colorHexOverride = _normalizeColorHex(category.colorHex)
      ..parentOverrideKey = _computeParentOverrideKey(
        currentParentKey: category.parentKey,
        baseParentKey: base.parentKey,
      )
      ..orderOverride = includeOrder && category.order != base.order ? category.order : null
      ..isHiddenOverride = category.isHidden != base.isHidden ? category.isHidden : null
      ..updatedAt = now;

    if (override.colorHexOverride == base.colorHex) {
      override.colorHexOverride = null;
    }

    return _hasOverrideData(override) ? override : null;
  }

  JiveCategoryOverride? _buildOverrideSnapshot({
    required String systemKey,
    required JiveCategory source,
    required _SystemCategoryBase base,
    String? parentOverrideKey,
    required DateTime now,
  }) {
    final snapshot = JiveCategoryOverride()..systemKey = systemKey;
    snapshot
      ..nameOverride = source.name != base.name ? source.name : null
      ..iconOverride = _normalizeIconKey(source.iconName) != _normalizeIconKey(base.iconName)
          ? source.iconName
          : null
      ..colorHexOverride = _normalizeColorHex(source.colorHex)
      ..parentOverrideKey = parentOverrideKey ?? _computeParentOverrideKey(
        currentParentKey: source.parentKey,
        baseParentKey: base.parentKey,
      )
      ..orderOverride = null
      ..isHiddenOverride = source.isHidden != base.isHidden ? source.isHidden : null
      ..updatedAt = now;

    if (snapshot.colorHexOverride == base.colorHex) {
      snapshot.colorHexOverride = null;
    }

    return _hasOverrideData(snapshot) ? snapshot : null;
  }

  JiveCategoryOverride? _mergeOverridesForMigration({
    required JiveCategoryOverride? existing,
    required JiveCategoryOverride incoming,
    required bool preferIncoming,
    required DateTime now,
  }) {
    if (existing == null) {
      incoming.updatedAt = now;
      return incoming;
    }

    final merged = JiveCategoryOverride()
      ..id = existing.id
      ..systemKey = existing.systemKey
      ..nameOverride = existing.nameOverride
      ..iconOverride = existing.iconOverride
      ..colorHexOverride = existing.colorHexOverride
      ..parentOverrideKey = existing.parentOverrideKey
      ..orderOverride = existing.orderOverride
      ..isHiddenOverride = existing.isHiddenOverride
      ..updatedAt = now;

    void applyIfNeeded(String? incomingValue, void Function(String? value) setter, String? existingValue) {
      if (incomingValue == null) return;
      if (preferIncoming || existingValue == null) {
        setter(incomingValue);
      }
    }

    applyIfNeeded(incoming.nameOverride, (value) => merged.nameOverride = value, merged.nameOverride);
    applyIfNeeded(incoming.iconOverride, (value) => merged.iconOverride = value, merged.iconOverride);
    applyIfNeeded(incoming.colorHexOverride, (value) => merged.colorHexOverride = value, merged.colorHexOverride);
    applyIfNeeded(incoming.parentOverrideKey, (value) => merged.parentOverrideKey = value, merged.parentOverrideKey);
    if (incoming.isHiddenOverride != null && (preferIncoming || merged.isHiddenOverride == null)) {
      merged.isHiddenOverride = incoming.isHiddenOverride;
    }

    return _hasOverrideData(merged) ? merged : null;
  }

  String? _computeParentOverrideKey({
    required String? currentParentKey,
    required String? baseParentKey,
  }) {
    if (currentParentKey == baseParentKey) return null;
    return currentParentKey ?? _noParentOverrideKey;
  }

  bool _hasOverrideData(JiveCategoryOverride override) {
    return override.nameOverride != null ||
        override.iconOverride != null ||
        override.colorHexOverride != null ||
        override.parentOverrideKey != null ||
        override.orderOverride != null ||
        override.isHiddenOverride != null;
  }

  String suggestIconName(String name, {String fallback = "category"}) {
    final raw = name.trim();
    final lower = raw.toLowerCase();
    bool containsAny(List<String> tokens) {
      return tokens.any((token) => raw.contains(token) || lower.contains(token));
    }

        if (containsAny(["12306"])) return "brand_12306.png";
    if (containsAny(["1688", "阿里1688"])) return "brand_1688.png";
    if (containsAny(["一点点", "1dian"])) return "brand_1dian.png";
    if (containsAny(["88vip", "淘宝88VIP"])) return "brand_88vip.png";
    if (containsAny(["adidas", "Adidas"])) return "brand_adidas.png";
    if (containsAny(["adobe", "Adobe"])) return "brand_adobe.png";
    if (containsAny(["阿里云盘", "aliyundrive", "aliyun_drive", "aliyun drive"])) return "brand_aliyun_drive.png";
    if (containsAny(["亚马逊", "amazon"])) return "brand_amazon.png";
    if (containsAny(["安踏", "anta"])) return "brand_anta.png";
    if (containsAny(["App Store", "appstore", "app_store", "app store"])) return "brand_app_store.png";
    if (containsAny(["apple", "iphone", "ipad", "苹果", "mac"])) return "brand_apple.png";
    if (containsAny(["Armani", "armani"])) return "brand_armani.png";
    if (containsAny(["baidu netdisk", "baidu_netdisk", "百度网盘", "baidunetdisk"])) return "brand_baidu_netdisk.png";
    if (containsAny(["巴奴毛肚火锅", "banu"])) return "brand_banu.png";
    if (containsAny(["Bilibili", "bilibili"])) return "brand_bilibili.png";
    if (containsAny(["bosideng", "波司登"])) return "brand_bosideng.png";
    if (containsAny(["bulgari", "宝格丽"])) return "brand_bulgari.png";
    if (containsAny(["Burberry", "burberry"])) return "brand_burberry.png";
    if (containsAny(["burger king", "burgerking", "汉堡王", "burger_king"])) return "brand_burger_king.png";
    if (containsAny(["cainiao", "菜鸟"])) return "brand_cainiao.png";
    if (containsAny(["canadagoose", "canada_goose", "canada goose", "加拿大鹅"])) return "brand_canada_goose.png";
    if (containsAny(["cartier", "卡地亚"])) return "brand_cartier.png";
    if (containsAny(["chagee", "霸王茶姬"])) return "brand_chagee.png";
    if (containsAny(["Chanel", "chanel"])) return "brand_chanel.png";
    if (containsAny(["chapanda", "茶百道"])) return "brand_chapanda.png";
    if (containsAny(["china_mobile", "中国移动", "chinamobile", "china mobile"])) return "brand_china_mobile.png";
    if (containsAny(["chinatelecom", "中国电信", "china telecom", "china_telecom"])) return "brand_china_telecom.png";
    if (containsAny(["chinaunicom", "china_unicom", "china unicom", "中国联通"])) return "brand_china_unicom.png";
    if (containsAny(["Coach", "coach"])) return "brand_coach.png";
    if (containsAny(["coco", "CoCo"])) return "brand_coco.png";
    if (containsAny(["columbia", "哥伦比亚"])) return "brand_columbia.png";
    if (containsAny(["converse", "匡威"])) return "brand_converse.png";
    if (containsAny(["dangdang", "当当网"])) return "brand_dangdang.png";
    if (containsAny(["迪卡侬", "decathlon"])) return "brand_decathlon.png";
    if (containsAny(["德克士", "dicos"])) return "brand_dicos.png";
    if (containsAny(["didi", "滴滴"])) return "brand_didi.png";
    if (containsAny(["Dior", "dior"])) return "brand_dior.png";
    if (containsAny(["disney plus", "disney_plus", "Disney+", "disneyplus"])) return "brand_disney_plus.png";
    if (containsAny(["达美乐", "dominos"])) return "brand_dominos.png";
    if (containsAny(["eleme", "饿了么"])) return "brand_eleme.png";
    if (containsAny(["ems", "邮政"])) return "brand_ems.png";
    if (containsAny(["epic", "Epic"])) return "brand_epic.png";
    if (containsAny(["fila", "Fila"])) return "brand_fila.png";
    if (containsAny(["gap", "GAP"])) return "brand_gap.png";
    if (containsAny(["Google Play", "google_play", "google play", "googleplay"])) return "brand_google_play.png";
    if (containsAny(["gucci", "Gucci"])) return "brand_gucci.png";
    if (containsAny(["古茗", "guming"])) return "brand_guming.png";
    if (containsAny(["海底捞", "haidilao"])) return "brand_haidilao.png";
    if (containsAny(["hema", "盒马"])) return "brand_hema.png";
    if (containsAny(["hermes", "爱马仕"])) return "brand_hermes.png";
    if (containsAny(["喜茶", "heytea"])) return "brand_heytea.png";
    if (containsAny(["海澜之家", "hla"])) return "brand_hla.png";
    if (containsAny(["HM", "hm"])) return "brand_hm.png";
    if (containsAny(["华为", "huawei"])) return "brand_huawei.png";
    if (containsAny(["宜家", "ikea"])) return "brand_ikea.png";
    if (containsAny(["iqiyi", "爱奇艺"])) return "brand_iqiyi.png";
    if (containsAny(["jack_jones", "jackjones", "杰克琼斯", "jack jones"])) return "brand_jack_jones.png";
    if (containsAny(["京东", "jd"])) return "brand_jd.png";
    if (containsAny(["jd logistics", "jd_logistics", "jdlogistics", "京东物流"])) return "brand_jd_logistics.png";
    if (containsAny(["京东Plus", "jd plus", "jd_plus", "jdplus"])) return "brand_jd_plus.png";
    if (containsAny(["网易考拉", "kaola"])) return "brand_kaola.png";
    if (containsAny(["kfc", "kentucky", "肯德基"])) return "brand_kfc.png";
    if (containsAny(["KKV", "kkv"])) return "brand_kkv.png";
    if (containsAny(["乐高", "lego"])) return "brand_lego.png";
    if (containsAny(["lining", "李宁"])) return "brand_lining.png";
    if (containsAny(["luckin", "瑞幸"])) return "brand_luckin.png";
    if (containsAny(["lv", "LV"])) return "brand_lv.png";
    if (containsAny(["mango_tv", "mangotv", "mango tv", "芒果TV"])) return "brand_mango_tv.png";
    if (containsAny(["mannings", "万宁"])) return "brand_mannings.png";
    if (containsAny(["mcdonalds", "麦当劳", "mcdonald"])) return "brand_mcdonalds.png";
    if (containsAny(["meituan", "美团"])) return "brand_meituan.png";
    if (containsAny(["美团外卖", "meituan_takeout", "meituan takeout", "meituantakeout"])) return "brand_meituan_takeout.png";
    if (containsAny(["微软", "microsoft"])) return "brand_microsoft.png";
    if (containsAny(["名创优品", "miniso"])) return "brand_miniso.png";
    if (containsAny(["mixue", "蜜雪冰城"])) return "brand_mixue.png";
    if (containsAny(["Michael Kors", "mk"])) return "brand_mk.png";
    if (containsAny(["muji", "无印良品"])) return "brand_muji.png";
    if (containsAny(["奈雪", "nayuki"])) return "brand_nayuki.png";
    if (containsAny(["netflix", "Netflix"])) return "brand_netflix.png";
    if (containsAny(["new balance", "newbalance", "NewBalance", "new_balance"])) return "brand_new_balance.png";
    if (containsAny(["Nike", "nike"])) return "brand_nike.png";
    if (containsAny(["nintendo", "任天堂"])) return "brand_nintendo.png";
    if (containsAny(["nome", "NOME"])) return "brand_nome.png";
    if (containsAny(["north_face", "northface", "north face", "北面"])) return "brand_north_face.png";
    if (containsAny(["Ochirly", "ochirly"])) return "brand_ochirly.png";
    if (containsAny(["欧米茄", "omega"])) return "brand_omega.png";
    if (containsAny(["ONLY", "only"])) return "brand_only.png";
    if (containsAny(["OPPO", "oppo"])) return "brand_oppo.png";
    if (containsAny(["peacebird", "太平鸟"])) return "brand_peacebird.png";
    if (containsAny(["petrochina", "中石油"])) return "brand_petrochina.png";
    if (containsAny(["拼多多", "pinduoduo"])) return "brand_pinduoduo.png";
    if (containsAny(["pizza_hut", "pizzahut", "必胜客", "pizza hut"])) return "brand_pizza_hut.png";
    if (containsAny(["playstation", "PlayStation"])) return "brand_playstation.png";
    if (containsAny(["pop mart", "popmart", "pop_mart", "泡泡玛特"])) return "brand_pop_mart.png";
    if (containsAny(["prada", "Prada"])) return "brand_prada.png";
    if (containsAny(["Puma", "puma"])) return "brand_puma.png";
    if (containsAny(["夸克", "quark"])) return "brand_quark.png";
    if (containsAny(["rolex", "劳力士"])) return "brand_rolex.png";
    if (containsAny(["萨莉亚", "saizeriya"])) return "brand_saizeriya.png";
    if (containsAny(["sams club", "sams_club", "samsclub", "山姆"])) return "brand_sams_club.png";
    if (containsAny(["samsung", "三星"])) return "brand_samsung.png";
    if (containsAny(["森马", "semir"])) return "brand_semir.png";
    if (containsAny(["sephora", "丝芙兰"])) return "brand_sephora.png";
    if (containsAny(["sfexpress", "顺丰", "sf express", "sf_express"])) return "brand_sf_express.png";
    if (containsAny(["shuyi", "书亦烧仙草"])) return "brand_shuyi.png";
    if (containsAny(["sinopec", "中石化"])) return "brand_sinopec.png";
    if (containsAny(["斯凯奇", "skechers"])) return "brand_skechers.png";
    if (containsAny(["sony", "索尼"])) return "brand_sony.png";
    if (containsAny(["Spotify", "spotify"])) return "brand_spotify.png";
    if (containsAny(["星巴克", "starbucks", "starbuck"])) return "brand_starbucks.png";
    if (containsAny(["state_grid", "state grid", "stategrid", "国家电网"])) return "brand_state_grid.png";
    if (containsAny(["steam", "Steam"])) return "brand_steam.png";
    if (containsAny(["sto", "申通"])) return "brand_sto.png";
    if (containsAny(["赛百味", "subway"])) return "brand_subway.png";
    if (containsAny(["suning", "苏宁易购"])) return "brand_suning.png";
    if (containsAny(["taobao", "淘宝"])) return "brand_taobao.png";
    if (containsAny(["塔斯汀", "tastien"])) return "brand_tastien.png";
    if (containsAny(["Teenie Weenie", "teenie_weenie", "teenie weenie", "teenieweenie"])) return "brand_teenie_weenie.png";
    if (containsAny(["tencentvideo", "腾讯视频", "tencent_video", "tencent video"])) return "brand_tencent_video.png";
    if (containsAny(["tiffany", "Tiffany"])) return "brand_tiffany.png";
    if (containsAny(["天猫", "tmall"])) return "brand_tmall.png";
    if (containsAny(["玩具反斗城", "toysrus", "toys r us", "toys_r_us"])) return "brand_toys_r_us.png";
    if (containsAny(["under armour", "under_armour", "underarmour", "安德玛"])) return "brand_under_armour.png";
    if (containsAny(["uniqlo", "优衣库"])) return "brand_uniqlo.png";
    if (containsAny(["ur", "UR"])) return "brand_ur.png";
    if (containsAny(["Vans", "vans"])) return "brand_vans.png";
    if (containsAny(["vero moda", "veromoda", "Vero Moda", "vero_moda"])) return "brand_vero_moda.png";
    if (containsAny(["范思哲", "versace"])) return "brand_versace.png";
    if (containsAny(["唯品会", "vipshop"])) return "brand_vipshop.png";
    if (containsAny(["vivo"])) return "brand_vivo.png";
    if (containsAny(["wallace", "华莱士"])) return "brand_wallace.png";
    if (containsAny(["watsons", "屈臣氏"])) return "brand_watsons.png";
    if (containsAny(["微信小程序", "wechatmini", "wechat mini", "wechat_mini"])) return "brand_wechat_mini.png";
    if (containsAny(["weidian", "微店"])) return "brand_weidian.png";
    if (containsAny(["Xbox", "xbox"])) return "brand_xbox.png";
    if (containsAny(["闲鱼", "xianyu"])) return "brand_xianyu.png";
    if (containsAny(["小红书", "xiaohongshu"])) return "brand_xiaohongshu.png";
    if (containsAny(["小龙坎", "xiaolongkan"])) return "brand_xiaolongkan.png";
    if (containsAny(["小米", "xiaomibrand", "xiaomi_brand", "xiaomi brand"])) return "brand_xiaomi_brand.png";
    if (containsAny(["xiaomi_mall", "xiaomi mall", "小米商城", "xiaomimall"])) return "brand_xiaomi_mall.png";
    if (containsAny(["xiaomiyoupin", "小米有品", "xiaomi youpin", "xiaomi_youpin"])) return "brand_xiaomi_youpin.png";
    if (containsAny(["西贝莜面村", "xibei"])) return "brand_xibei.png";
    if (containsAny(["xunlei", "迅雷"])) return "brand_xunlei.png";
    if (containsAny(["yangguofu", "杨国福麻辣烫"])) return "brand_yangguofu.png";
    if (containsAny(["网易严选", "yanxuan"])) return "brand_yanxuan.png";
    if (containsAny(["吉野家", "yoshinoya"])) return "brand_yoshinoya.png";
    if (containsAny(["优酷", "youku"])) return "brand_youku.png";
    if (containsAny(["youtube", "YouTube"])) return "brand_youtube.png";
    if (containsAny(["yto", "圆通"])) return "brand_yto.png";
    if (containsAny(["韵达", "yunda"])) return "brand_yunda.png";
    if (containsAny(["zara", "ZARA"])) return "brand_zara.png";
    if (containsAny(["zhangliang", "张亮麻辣烫"])) return "brand_zhangliang.png";
    if (containsAny(["中通", "zto"])) return "brand_zto.png";

    if (containsAny(["早餐", "早饭", "breakfast"])) return "bakery_dining";
    if (containsAny(["午餐", "午饭", "lunch"])) return "lunch_dining";
    if (containsAny(["晚餐", "晚饭", "dinner"])) return "dinner_dining";
    if (containsAny(["夜宵", "宵夜", "snack"])) return "tapas";
    if (containsAny(["外卖", "delivery"])) return "delivery_dining";
    if (containsAny(["面包", "蛋糕", "烘焙", "糕点", "甜点", "面点", "包子", "馒头"])) {
      return "bakery_dining";
    }
    if (containsAny([
      "咖啡",
      "奶茶",
      "饮料",
      "饮品",
      "果汁",
      "茶",
      "coffee",
      "tea",
      "纯净水",
      "矿泉水",
      "饮用水",
      "CoCo",
      "一点点",
      "书亦",
      "古茗",
      "喜茶",
      "奈雪",
      "库迪",
      "星巴克",
      "沪上阿姨",
      "瑞幸",
      "茶百道",
      "茶颜悦色",
      "蜜雪冰城",
      "霸王茶姬",
      "益禾堂",
      "coco",
      "1点点",
      "茶",
    ])) return "local_cafe";
    if (containsAny(["冰淇淋", "雪糕", "甜品", "icecream"])) return "icecream";
    if (containsAny(["火锅", "烧烤", "烤肉", "麻辣烫", "麻辣香锅", "串串", "张亮", "杨国福", "小龙坎", "海底捞", "巴奴"])) return "local_dining";
    if (containsAny(["面条", "面食", "面粉", "拉面", "饺子", "馄饨", "米粉", "米线", "米饭", "沙县", "真功夫", "老乡鸡"])) {
      return "local_dining";
    }
    if (containsAny(["华莱士", "吉野家", "塔斯汀", "德克士", "必胜客", "汉堡王", "赛百味", "达美乐", "绝味", "周黑鸭", "小龙坎", "巴奴", "海底捞", "杨国福", "张亮", "真功夫", "老乡鸡", "沙县", "永和", "fastfood"])) {
      return "restaurant";
    }
    if (containsAny([
      "买菜",
      "生鲜",
      "grocery",
      "海鲜",
      "肉类",
      "鸡蛋",
      "牛奶",
      "豆制品",
      "粮油",
      "调味",
      "调料",
      "食材",
      "姜",
      "葱",
      "蒜",
      "盒马",
      "山姆",
      "胖东来",
      "永辉",
    ])) {
      return "shopping_basket";
    }
    if (containsAny(["水果", "果蔬", "蔬菜", "fruit"])) return "nutrition";
    if (containsAny(["聚会", "party", "请客", "宴请"])) return "celebration";
    if (containsAny(["酒吧", "bar"])) return "wine_bar";
    if (containsAny(["酒", "酒水", "liquor", "wine", "烟", "烟酒", "啤酒"])) return "liquor";

    if (containsAny(["购物", "shopping", "淘宝", "天猫", "京东", "拼多多", "苏宁", "唯品会", "闲鱼", "亚马逊", "当当", "网易", "小红书", "得物", "美团"])) return "shopping_bag";
    if (containsAny(["超市", "便利店", "杂货", "日用", "日用品", "生活用品", "711", "罗森", "全家", "屈臣氏", "名创优品", "无印良品"])) {
      return "local_convenience_store";
    }
    if (containsAny([
      "清洁",
      "清洗",
      "洗衣",
      "洗涤",
      "洗洁",
      "消毒",
      "洗衣液",
      "洗衣粉",
      "洗洁精",
      "打扫",
      "垃圾袋",
      "垃圾费",
    ])) return "cleaning_services";
    if (containsAny([
      "服饰", "衣服", "clothes", "内衣", "外套", "冲锋衣", "羽绒", "裤", "裙", "袜", "帽",
      "优衣库", "ZARA", "HM", "UR", "GAP", "ONLY", "Vero Moda", "Ochirly", "Adidas", "Nike", "Puma", "LiNing", "Anta", "Fila", "Under Armour", "NewBalance", "Skechers", "Converse", "Vans", "HOKA", "Timberland", "UGG", "ECCO",
      "LV", "Gucci", "Prada", "Chanel", "Armani", "Burberry", "Coach", "Givenchy", "Versace", "Valentino", "Dior", "Hermes",
      "uniqlo", "zara", "adidas", "nike", "puma", "fila",
    ])) {
      return "checkroom";
    }
    if (containsAny(["鞋包", "鞋", "包", "bag", "饰品", "首饰", "耳环", "项链"])) return "cases";
    if (containsAny(["数码", "手机", "digital", "电脑", "相机", "耳机", "键盘", "音响", "充电", "充电宝", "电池", "数据线"])) {
      return "phone_iphone";
    }
    if (containsAny(["家电", "电器", "厨房", "厨具", "appliance"])) return "kitchen";
    if (containsAny(["家居", "家具", "居家", "home"])) return "chair";
    if (containsAny(["快递", "物流"])) return "local_shipping";

    if (containsAny(["交通", "出行"])) return "directions_car";
    if (containsAny(["汽车", "养车", "车检", "年检", "电瓶车"])) return "directions_car";
    if (containsAny(["打车", "出租", "taxi"])) return "local_taxi";
    if (containsAny(["地铁", "subway"])) return "subway";
    if (containsAny(["公交", "bus"])) return "directions_bus";
    if (containsAny(["加油", "gas"])) return "local_gas_station";
    if (containsAny(["停车", "parking"])) return "local_parking";
    if (containsAny(["火车", "高铁", "train"])) return "train";
    if (containsAny(["飞机", "机票", "flight"])) return "flight";

    if (containsAny(["酒店", "宾馆", "住宿", "旅馆"])) return "hotel";
    if (containsAny(["居住", "住房", "房屋", "house"])) return "house";
    if (containsAny(["房租", "租房", "rent"])) return "key";
    if (containsAny(["话费", "手机费", "phone"])) return "phone_android";
    if (containsAny(["水电", "电费", "水费"])) return "lightbulb";
    if (containsAny(["燃气", "煤气", "天然气", "取暖"])) return "local_fire_department";
    if (containsAny(["卫浴", "坐便器", "马桶", "水龙头", "管道"])) return "plumbing";
    if (containsAny(["宽带", "网络", "wifi"])) return "wifi";
    if (containsAny(["物业", "property"])) return "business";
    if (containsAny(["维修", "修理", "保养", "维护", "repair", "装修", "建材", "材料", "五金", "工具"])) {
      return "build";
    }

    if (containsAny(["娱乐", "游戏", "game"])) return "sports_esports";
    if (containsAny(["电影", "影院", "影视", "movie"])) return "movie";
    if (containsAny(["KTV", "唱歌", "karaoke", "音乐", "演唱会"])) return "mic";
    if (containsAny(["钢琴", "吉他", "小提琴", "大提琴", "二胡", "古筝", "琵琶", "长笛", "萨克斯", "手风琴", "乐器"])) return "music_note";
    if (containsAny([
      "运动",
      "健身",
      "sport",
      "跑步",
      "游泳",
      "滑雪",
      "滑冰",
      "滑板",
      "攀岩",
      "徒步",
      "瑜伽",
      "射箭",
      "乒乓球",
      "羽毛球",
      "网球",
      "足球",
      "篮球",
      "排球",
      "台球",
      "搏击",
      "散打",
      "冲浪",
      "潜水",
      "漂流",
      "卡丁车",
    ])) return "sports_basketball";
    if (containsAny(["旅行", "旅游", "travel", "景点", "门票"])) return "landscape";
    if (containsAny(["会员", "member"])) return "card_membership";
    if (containsAny(["充值", "续费", "缴费"])) return "payments";
    if (containsAny(["礼品卡", "购物卡", "会员卡"])) return "card_giftcard";
    if (containsAny(["转账", "收款", "付款", "支付"])) return "payments";

    if (containsAny(["保险", "保费", "保单", "社保", "医保", "五险一金", "车险", "意外险", "寿险"])) {
      return "security";
    }
    if (containsAny(["公积金"])) return "account_balance";
    if (containsAny(["医疗", "医院", "hospital"])) return "local_hospital";
    if (containsAny(["药品", "药", "medicine"])) return "medication";
    if (containsAny(["挂号", "就诊", "pharmacy"])) return "local_pharmacy";
    if (containsAny(["检查", "体检"])) return "monitor_heart";
    if (containsAny(["牙", "口腔", "口罩", "医美", "疫苗", "核酸"])) return "healing";
    if (containsAny(["美容", "护肤", "美妆", "化妆", "美发", "美甲", "洗面奶", "面膜", "卸妆", "口红", "香水", "乳液", "精华", "护发", "洗发", "护手", "指甲油", "防晒"])) {
      return "spa";
    }

    if (containsAny(["人情", "社交", "礼物", "gift", "家人", "父母", "朋友", "恋爱"])) return "people";
    if (containsAny(["红包", "reward"])) return "redeem";

    if (containsAny(["宠物", "pet"])) return "pets";
    if (containsAny(["猫粮", "狗粮", "petfood"])) return "pest_control_rodent";
    if (containsAny(["玩具"])) return "toys";
    if (containsAny(["母婴", "婴儿", "宝宝", "奶粉", "尿不湿", "亲子", "育儿", "奶瓶", "儿童", "孩子"])) {
      return "child_friendly";
    }

    if (containsAny(["收入", "工资", "salary"])) return "attach_money";
    if (containsAny(["贷款", "借入"])) return "account_balance";
    if (containsAny(["报销"])) return "assignment";
    if (containsAny(["补贴"])) return "savings";
    if (containsAny(["压岁钱", "红包"])) return "redeem";
    if (containsAny(["奖金", "奖学金", "中奖", "bonus"])) return "military_tech";
    if (containsAny(["兼职", "工作", "job"])) return "work";
    if (containsAny(["理财", "收益", "invest"])) return "trending_up";
    if (containsAny(["二手", "卖出", "sell"])) return "sell";
    if (containsAny(["眼镜"])) return "face";
    if (containsAny(["打印", "复印"])) return "print";
    if (containsAny(["党费"])) return "flag";
    if (containsAny(["税", "关税", "罚款", "罚单", "违章", "发票", "分期", "手续费", "中介费", "律师费"])) {
      return "receipt_long";
    }
    if (containsAny(["加密货币", "比特币", "虚拟币"])) return "show_chart";
    if (containsAny(["捐赠", "捐款", "公益", "慈善"])) return "volunteer_activism";
    if (containsAny(["学习", "教育", "培训", "课程", "学校", "校园"])) return "school";
    if (containsAny(["考试", "报名", "文具", "教材", "课本"])) return "cast_for_education";
    if (containsAny(["书籍", "阅读", "小说"])) return "menu_book";
    if (containsAny(["书法", "绘画", "美术", "手工"])) return "edit";
    if (containsAny(["公司", "办公", "办公用品"])) return "business";
    if (containsAny(["餐饮", "吃喝", "美食"])) return "restaurant";
    if (containsAny(["日常", "生活"])) return "local_convenience_store";
    if (containsAny(["品牌", "兴趣", "爱好"])) return "auto_awesome";

    // if (RegExp(r'[A-Za-z]').hasMatch(raw)) return "auto_awesome";

    return fallback;
  }

  static IconData getIcon(String name) {
    switch (name) {
      case 'restaurant': return Icons.restaurant;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'dinner_dining': return Icons.dinner_dining;
      case 'tapas': return Icons.tapas;
      case 'delivery_dining': return Icons.delivery_dining;
      case 'local_cafe': return Icons.local_cafe;
      case 'icecream': return Icons.icecream;
      case 'shopping_basket': return Icons.shopping_basket;
      case 'nutrition': return Icons.eco; 
      case 'celebration': return Icons.celebration;
      case 'wine_bar': return Icons.wine_bar;
      case 'liquor': return Icons.liquor;

      case 'shopping_bag': return Icons.shopping_bag;
      case 'local_convenience_store': return Icons.local_convenience_store;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'checkroom': return Icons.checkroom;
      case 'cases': return Icons.cases; 
      case 'phone_iphone': return Icons.phone_iphone;
      case 'kitchen': return Icons.kitchen;
      case 'chair': return Icons.chair;
      case 'face': return Icons.face;
      case 'pets': return Icons.pets;
      case 'menu_book': return Icons.menu_book;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'attach_file': return Icons.attach_file;
      case 'child_friendly': return Icons.child_friendly;
      case 'local_shipping': return Icons.local_shipping;

      case 'directions_car': return Icons.directions_car;
      case 'directions_bus': return Icons.directions_bus;
      case 'subway': return Icons.subway;
      case 'local_taxi': return Icons.local_taxi;
      case 'train': return Icons.train;
      case 'flight': return Icons.flight;
      case 'local_parking': return Icons.local_parking;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'add_road': return Icons.add_road;
      case 'build': return Icons.build;
      case 'security': return Icons.security;

      case 'house': return Icons.house;
      case 'key': return Icons.key;
      case 'account_balance': return Icons.account_balance;
      case 'business': return Icons.business;
      case 'lightbulb': return Icons.lightbulb;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'wifi': return Icons.wifi;
      case 'phone_android': return Icons.phone_android;
      case 'plumbing': return Icons.plumbing;
      case 'hotel': return Icons.hotel;

      case 'sports_esports': return Icons.sports_esports;
      case 'movie': return Icons.movie;
      case 'videogame_asset': return Icons.videogame_asset;
      case 'mic': return Icons.mic;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'landscape': return Icons.landscape;
      case 'card_membership': return Icons.card_membership;
      case 'theater_comedy': return Icons.theater_comedy;

      case 'local_hospital': return Icons.local_hospital;
      case 'medication': return Icons.medication;
      case 'local_pharmacy': return Icons.local_pharmacy;
      case 'monitor_heart': return Icons.monitor_heart;
      case 'healing': return Icons.healing;
      case 'vaccines': return Icons.vaccines;
      case 'spa': return Icons.spa;

      case 'school': return Icons.school;
      case 'cast_for_education': return Icons.cast_for_education;
      case 'assignment': return Icons.assignment;
      case 'edit': return Icons.edit;

      case 'people': return Icons.people;
      case 'redeem': return Icons.redeem;
      case 'local_dining': return Icons.local_dining;
      case 'volunteer_activism': return Icons.volunteer_activism;

      case 'pest_control_rodent': return Icons.pest_control_rodent;
      case 'bone': return Icons.change_history; 
      case 'toys': return Icons.toys;

      case 'trending_up': return Icons.trending_up;
      case 'analytics': return Icons.analytics;
      case 'show_chart': return Icons.show_chart;
      case 'pie_chart': return Icons.pie_chart;
      case 'trending_down': return Icons.trending_down;

      case 'payments': return Icons.payments;
      case 'receipt_long': return Icons.receipt_long;
      case 'auto_awesome': return Icons.auto_awesome;
      
      case 'savings': return Icons.savings;
      case 'attach_money': return Icons.attach_money;
      case 'military_tech': return Icons.military_tech;
      case 'work': return Icons.work;
      case 'sell': return Icons.sell;

      case 'music_note': return Icons.music_note;
      case 'print': return Icons.print;
      case 'flag': return Icons.flag;
      case 'visibility': return Icons.visibility;
      case 'local_mall': return Icons.local_mall;
      case 'fastfood': return Icons.fastfood;

      default: return Icons.category;
    }
  }
}

class _SystemCategoryBase {
  final String key;
  final String name;
  final String iconName;
  final String? parentKey;
  final String? parentName;
  final bool isIncome;
  final int order;
  final String? colorHex;
  final bool isHidden;

  const _SystemCategoryBase({
    required this.key,
    required this.name,
    required this.iconName,
    required this.parentKey,
    required this.parentName,
    required this.isIncome,
    required this.order,
    required this.colorHex,
    required this.isHidden,
  });
}

class _SystemCategoryIndex {
  final Map<String, _SystemCategoryBase> byKey;
  final Map<String, _SystemCategoryBase> parentByKey;
  final Map<String, _SystemCategoryBase> parentByMatchName;
  final Map<String, _SystemCategoryBase> childByMatchName;
  final Map<String, List<_SystemCategoryBase>> childrenByParentKey;

  const _SystemCategoryIndex({
    required this.byKey,
    required this.parentByKey,
    required this.parentByMatchName,
    required this.childByMatchName,
    required this.childrenByParentKey,
  });
}
