import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoSupportedApp {
  final String id;
  final String name;
  final String? description;
  final List<String> packages;
  final List<String> aliases;
  final bool enabledByDefault;

  AutoSupportedApp({
    required this.id,
    required this.name,
    required this.description,
    required this.packages,
    required this.aliases,
    required this.enabledByDefault,
  });

  factory AutoSupportedApp.fromJson(Map<String, dynamic> json) {
    return AutoSupportedApp(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      packages: _stringList(json['packages']),
      aliases: _stringList(json['aliases']),
      enabledByDefault: json['enabled'] == null ? true : json['enabled'] == true,
    );
  }

  bool matches(String source) {
    final normalized = AutoSupportedAppsStore.normalize(source);
    if (normalized.isEmpty) return false;
    for (final pkg in packages) {
      final token = AutoSupportedAppsStore.normalize(pkg);
      if (token.isEmpty) continue;
      if (normalized == token || normalized.contains(token)) return true;
    }
    for (final alias in aliases) {
      final token = AutoSupportedAppsStore.normalize(alias);
      if (token.isEmpty) continue;
      if (normalized == token || normalized.contains(token)) return true;
    }
    return false;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((entry) => entry.toString()).toList();
  }
}

class AutoSupportedAppsStore {
  static const _prefKeyEnabled = 'auto_supported_apps_enabled';
  static List<AutoSupportedApp>? _cachedApps;
  static Set<String>? _cachedEnabled;

  static Future<List<AutoSupportedApp>> loadApps() async {
    final cached = _cachedApps;
    if (cached != null) return cached;
    final payload = await rootBundle.loadString('assets/auto_supported_apps.json');
    final data = json.decode(payload) as Map<String, dynamic>;
    final raw = (data['apps'] as List<dynamic>? ?? const []);
    final apps = raw
        .map((entry) => AutoSupportedApp.fromJson(entry as Map<String, dynamic>))
        .where((app) => app.id.isNotEmpty)
        .toList();
    _cachedApps = apps;
    return apps;
  }

  static Future<Set<String>> loadEnabledIds({List<AutoSupportedApp>? apps}) async {
    final cached = _cachedEnabled;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefKeyEnabled);
    if (stored != null) {
      _cachedEnabled = stored.toSet();
      return _cachedEnabled!;
    }
    final defaultApps = apps ?? await loadApps();
    final defaults = <String>{
      for (final app in defaultApps)
        if (app.enabledByDefault) app.id,
    };
    _cachedEnabled = defaults;
    return defaults;
  }

  static Future<void> saveEnabledIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyEnabled, ids.toList());
    _cachedEnabled = ids;
  }

  static Future<bool> isEnabled(String source) async {
    final apps = await loadApps();
    final match = matchApp(source, apps);
    if (match == null) return true;
    final enabled = await loadEnabledIds(apps: apps);
    return enabled.contains(match.id);
  }

  static AutoSupportedApp? matchApp(String source, List<AutoSupportedApp> apps) {
    for (final app in apps) {
      if (app.matches(source)) return app;
    }
    return null;
  }

  static String normalize(String input) {
    return input.toLowerCase().trim();
  }
}
