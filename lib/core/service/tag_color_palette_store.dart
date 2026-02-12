import 'package:shared_preferences/shared_preferences.dart';

class TagColorPaletteStore {
  static const _paletteKey = 'tag_color_palette_v1';

  static Future<List<String>> load({List<String>? fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_paletteKey);
    if (stored == null || stored.isEmpty) {
      return List<String>.from(fallback ?? const <String>[]);
    }
    return List<String>.from(stored);
  }

  static Future<void> save(List<String> colors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_paletteKey, List<String>.from(colors));
  }
}
