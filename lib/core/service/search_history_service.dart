import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent search queries (max 10).
class SearchHistoryService {
  static const _prefKey = 'search_history';
  static const _maxItems = 10;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefKey) ?? [];
  }

  static Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_prefKey) ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }
    await prefs.setStringList(_prefKey, history);
  }

  static Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_prefKey) ?? [];
    history.remove(query);
    await prefs.setStringList(_prefKey, history);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
