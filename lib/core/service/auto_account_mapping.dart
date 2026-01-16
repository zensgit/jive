import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AutoAccountMapping {
  final String pattern;
  final int accountId;
  final bool regex;

  const AutoAccountMapping({
    required this.pattern,
    required this.accountId,
    required this.regex,
  });

  factory AutoAccountMapping.fromJson(Map<String, dynamic> json) {
    return AutoAccountMapping(
      pattern: json['pattern']?.toString() ?? '',
      accountId: (json['accountId'] as num?)?.toInt() ?? 0,
      regex: json['regex'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'accountId': accountId,
      'regex': regex,
    };
  }

  bool matches(String text) {
    if (pattern.isEmpty) return false;
    if (regex) {
      try {
        return RegExp(pattern, caseSensitive: false).hasMatch(text);
      } catch (_) {
        return false;
      }
    }
    return text.contains(pattern);
  }
}

class AutoAccountMappingStore {
  static const _keyMappings = 'auto_account_mappings';

  static Future<List<AutoAccountMapping>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMappings);
    if (raw == null || raw.isEmpty) return [];
    final decoded = json.decode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AutoAccountMapping.fromJson)
        .where((entry) => entry.pattern.isNotEmpty && entry.accountId > 0)
        .toList();
  }

  static Future<void> save(List<AutoAccountMapping> mappings) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode(mappings.map((entry) => entry.toJson()).toList());
    await prefs.setString(_keyMappings, payload);
  }

  static Future<void> upsert(AutoAccountMapping mapping) async {
    final mappings = await load();
    final next = [
      for (final entry in mappings)
        if (entry.pattern != mapping.pattern || entry.regex != mapping.regex) entry,
    ];
    next.add(mapping);
    await save(next);
  }

  static String sanitizePattern(String input) {
    var sanitized = input.trim();
    if (sanitized.isEmpty) return sanitized;
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\d{6,}'), '');
    return sanitized;
  }

  static AutoAccountMapping? matchMapping(String? text, List<AutoAccountMapping> mappings) {
    if (text == null || text.trim().isEmpty) return null;
    for (final entry in mappings) {
      if (entry.matches(text)) return entry;
    }
    final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    for (final entry in mappings) {
      if (entry.regex) {
        continue;
      }
      final pattern = entry.pattern.toLowerCase();
      if (pattern.isNotEmpty && normalized.contains(pattern)) return entry;
    }
    return null;
  }
}
