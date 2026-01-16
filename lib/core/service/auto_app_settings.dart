import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auto_app_registry.dart';

class AutoAppSettingsStore {
  static const _keyEnabledMap = 'auto_app_enabled_map';

  static Future<Map<String, bool>> loadEnabledMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyEnabledMap);
    if (raw == null || raw.isEmpty) return {};
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    final map = <String, bool>{};
    decoded.forEach((key, value) {
      if (value is bool) {
        map[key] = value;
      } else if (value is String) {
        map[key] = value.toLowerCase() == 'true';
      }
    });
    return map;
  }

  static Future<void> saveEnabledMap(Map<String, bool> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEnabledMap, json.encode(map));
  }

  static bool isEnabled(Map<String, bool> enabledMap, String? packageName) {
    if (packageName == null) return true;
    final def = AutoAppRegistry.findByPackage(packageName);
    final fallback = def?.defaultEnabled ?? true;
    return enabledMap[packageName] ?? fallback;
  }

  static int enabledCount(Map<String, bool> enabledMap) {
    var count = 0;
    for (final app in AutoAppRegistry.apps) {
      if (isEnabled(enabledMap, app.packageName)) count++;
    }
    return count;
  }
}
