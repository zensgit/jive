import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../database/category_model.dart';

/// Serializable export payload for category sharing.
class CategoryExport {
  final String shareCode;
  final String jsonData;
  final int categoryCount;

  const CategoryExport({
    required this.shareCode,
    required this.jsonData,
    required this.categoryCount,
  });
}

/// Service for exporting / importing user-created categories via share codes.
class CategoryShareService {
  final Isar isar;

  CategoryShareService(this.isar);

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Exports all non-system categories as a [CategoryExport].
  Future<CategoryExport> exportCategories() async {
    final categories = await isar
        .collection<JiveCategory>()
        .filter()
        .isSystemEqualTo(false)
        .findAll();

    final list = categories.map(_categoryToMap).toList();
    final jsonData = jsonEncode(list);
    final shareCode = _generateShareCode(jsonData);

    return CategoryExport(
      shareCode: shareCode,
      jsonData: jsonData,
      categoryCount: categories.length,
    );
  }

  /// Copies `shareCode:base64(jsonData)` to the system clipboard.
  Future<CategoryExport> exportToClipboard() async {
    final export = await exportCategories();
    final encoded = base64Encode(utf8.encode(export.jsonData));
    final payload = '${export.shareCode}:$encoded';
    await Clipboard.setData(ClipboardData(text: payload));
    return export;
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Parses a JSON string of categories and creates those that don't already
  /// exist (matched by `key`). Returns the number of newly created categories.
  Future<int> importCategories(String jsonData) async {
    final List<dynamic> list;
    try {
      list = jsonDecode(jsonData) as List<dynamic>;
    } catch (_) {
      return 0;
    }

    int imported = 0;

    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final key = item['key'] as String?;
      if (key == null || key.isEmpty) continue;

      final exists = await isar
          .collection<JiveCategory>()
          .filter()
          .keyEqualTo(key)
          .findFirst();
      if (exists != null) continue;

      final category = _mapToCategory(item);
      await isar.writeTxn(() async {
        await isar.collection<JiveCategory>().put(category);
      });
      imported++;
    }

    return imported;
  }

  /// Reads the clipboard, decodes the share-code payload, and imports.
  /// Returns the number of newly created categories.
  Future<int> importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) return 0;
    final jsonData = decodePayload(data.text!);
    if (jsonData == null) return 0;
    return importCategories(jsonData);
  }

  // ---------------------------------------------------------------------------
  // Preview helpers
  // ---------------------------------------------------------------------------

  /// Decodes a clipboard payload (`code:base64`) into the raw JSON string.
  /// Returns `null` if the format is invalid.
  String? decodePayload(String payload) {
    final colonIndex = payload.indexOf(':');
    if (colonIndex < 1) return null;
    final encoded = payload.substring(colonIndex + 1);
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  /// Parses JSON into a list of category name strings for preview.
  List<String> previewNames(String jsonData) {
    try {
      final list = jsonDecode(jsonData) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => m['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _categoryToMap(JiveCategory c) {
    return {
      'key': c.key,
      'name': c.name,
      'parentKey': c.parentKey,
      'iconName': c.iconName,
      'colorHex': c.colorHex,
      'iconForceTinted': c.iconForceTinted,
      'excludeFromBudget': c.excludeFromBudget,
      'order': c.order,
      'isIncome': c.isIncome,
      'isHidden': c.isHidden,
    };
  }

  JiveCategory _mapToCategory(Map<String, dynamic> m) {
    return JiveCategory()
      ..key = m['key'] as String
      ..name = (m['name'] as String?) ?? ''
      ..parentKey = m['parentKey'] as String?
      ..iconName = (m['iconName'] as String?) ?? 'category'
      ..colorHex = m['colorHex'] as String?
      ..iconForceTinted = (m['iconForceTinted'] as bool?) ?? false
      ..excludeFromBudget = (m['excludeFromBudget'] as bool?) ?? false
      ..order = (m['order'] as int?) ?? 99
      ..isSystem = false
      ..isHidden = (m['isHidden'] as bool?) ?? false
      ..isIncome = (m['isIncome'] as bool?) ?? false
      ..updatedAt = DateTime.now();
  }

  String _generateShareCode(String data) {
    final digest = md5.convert(utf8.encode(data));
    return digest.toString().substring(0, 8).toUpperCase();
  }
}
