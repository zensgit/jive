import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lpinyin/lpinyin.dart';

class BankEntry {
  final String name;
  final String name2;
  final String name3;
  final String icon;
  final String color;
  final String type;
  final String sort;
  final String searchKey;

  BankEntry({
    required this.name,
    required this.name2,
    required this.name3,
    required this.icon,
    required this.color,
    required this.type,
    required this.sort,
    required this.searchKey,
  });

  factory BankEntry.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?) ?? '';
    final name2 = (json['name2'] as String?) ?? '';
    final name3 = (json['name3'] as String?) ?? '';
    final icon = (json['icon'] as String?) ?? '';
    final color = (json['color'] as String?) ?? '';
    final type = (json['type'] as String?) ?? '';
    final sort = (json['sort'] as String?) ?? '';
    final raw = [name, name2, name3].where((item) => item.isNotEmpty).join(' ');
    final pinyin = raw.isEmpty ? '' : PinyinHelper.getPinyinE(raw);
    final searchKey = '$raw $pinyin'.toLowerCase();
    return BankEntry(
      name: name,
      name2: name2,
      name3: name3,
      icon: icon,
      color: color,
      type: type,
      sort: sort,
      searchKey: searchKey,
    );
  }

  String get assetPath {
    if (icon.isEmpty) return '';
    if (icon.startsWith('assets/')) return icon;
    return 'assets/account_icons/$icon';
  }
}

class BankCatalog {
  static const String _assetPath = 'assets/account_icons/banks.json';
  static List<BankEntry>? _cached;

  static Future<List<BankEntry>> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final banks = (decoded['banks'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BankEntry.fromJson)
        .toList();
    _cached = banks;
    return banks;
  }

  static List<BankEntry> filter(List<BankEntry> banks, String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return banks;
    return banks.where((entry) => entry.searchKey.contains(keyword)).toList();
  }

  static BankEntry? findByIcon(List<BankEntry> banks, String? iconName) {
    if (iconName == null || iconName.trim().isEmpty) return null;
    final normalized = iconName.replaceFirst('assets/account_icons/', '');
    for (final bank in banks) {
      if (bank.icon.isNotEmpty && bank.icon == normalized) return bank;
    }
    return null;
  }
}
