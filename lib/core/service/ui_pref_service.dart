import 'package:shared_preferences/shared_preferences.dart';

class UiPrefService {
  static const _keyShowSmartTagBadge = 'ui_show_smart_tag_badge';
  static const _keySmartCleanupRemoveTagToo = 'ui_smart_cleanup_remove_tag_too';

  static Future<bool> getShowSmartTagBadge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowSmartTagBadge) ?? true;
  }

  static Future<void> setShowSmartTagBadge(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowSmartTagBadge, value);
  }

  static Future<bool> getSmartCleanupRemoveTagToo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySmartCleanupRemoveTagToo) ?? false;
  }

  static Future<void> setSmartCleanupRemoveTagToo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartCleanupRemoveTagToo, value);
  }
}
