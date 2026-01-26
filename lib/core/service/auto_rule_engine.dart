import 'dart:convert';

import 'package:flutter/services.dart';

class AutoRuleEngine {
  AutoRuleEngine({
    required this.rules,
    required this.incomeKeywords,
    required this.transferKeywords,
  });

  final List<AutoRule> rules;
  final List<String> incomeKeywords;
  final List<String> transferKeywords;

  static AutoRuleEngine? _cached;

  static Future<AutoRuleEngine> instance() async {
    final cached = _cached;
    if (cached != null) return cached;
    final payload = await rootBundle.loadString('assets/auto_rules.json');
    final data = json.decode(payload) as Map<String, dynamic>;
    final rulesRaw = (data['rules'] as List<dynamic>? ?? const []);
    final rules = rulesRaw
        .map((entry) => AutoRule.fromJson(entry as Map<String, dynamic>))
        .toList();
    final incomeKeywords = _normalizeList(data['income_keywords']);
    final transferKeywords = _normalizeList(data['transfer_keywords']);
    final engine = AutoRuleEngine(
      rules: rules,
      incomeKeywords: incomeKeywords,
      transferKeywords: transferKeywords,
    );
    _cached = engine;
    return engine;
  }

  AutoMatch match({
    required String text,
    String? source,
  }) {
    final normalized = _normalize(text);
    AutoRule? matched;
    for (final rule in rules) {
      if (!rule.matches(normalized, source: source)) continue;
      matched = rule;
      break;
    }
    final type = matched?.type ?? _inferType(normalized);
    return AutoMatch(
      type: type,
      parent: matched?.parent,
      sub: matched?.sub,
      tags: matched?.tags ?? const [],
      ruleName: matched?.name,
    );
  }

  String _inferType(String normalized) {
    if (_containsAny(normalized, transferKeywords)) return 'transfer';
    if (_containsAny(normalized, incomeKeywords)) return 'income';
    return 'expense';
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[\s`~!@#$%^&*()+=|{}\[\]:;,.<>/?，。！？、【】（）《》“”‘’￥…—-]"), '');
  }

  static List<String> _normalizeList(dynamic value) {
    if (value is! List) return const [];
    return value.map((entry) => _normalize(entry.toString())).toList();
  }
}

class AutoRule {
  final String name;
  final List<String> keywords;
  final List<String>? sources;
  final String? parent;
  final String? sub;
  final String? type;
  final List<String> tags;

  AutoRule({
    required this.name,
    required this.keywords,
    this.sources,
    this.parent,
    this.sub,
    this.type,
    required this.tags,
  });

  factory AutoRule.fromJson(Map<String, dynamic> json) {
    return AutoRule(
      name: json['name']?.toString() ?? 'rule',
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .map((entry) => AutoRuleEngine._normalize(entry.toString()))
          .toList(),
      sources: (json['sources'] as List<dynamic>?)
          ?.map((entry) => entry.toString())
          .toList(),
      parent: json['parent']?.toString(),
      sub: json['sub']?.toString(),
      type: json['type']?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  bool matches(String normalizedText, {String? source}) {
    if (normalizedText.isEmpty) return false;
    if (sources != null && sources!.isNotEmpty && source != null) {
      if (!sources!.contains(source)) return false;
    } else if (sources != null && sources!.isNotEmpty && source == null) {
      return false;
    }
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (normalizedText.contains(keyword)) return true;
    }
    return false;
  }
}

class AutoMatch {
  final String type;
  final String? parent;
  final String? sub;
  final List<String> tags;
  final String? ruleName;

  AutoMatch({
    required this.type,
    this.parent,
    this.sub,
    required this.tags,
    this.ruleName,
  });
}
