import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CategoryIconStyle {
  colored,
  tinted,
}

extension CategoryIconStyleLabel on CategoryIconStyle {
  String get label {
    switch (this) {
      case CategoryIconStyle.colored:
        return '彩色';
      case CategoryIconStyle.tinted:
        return '单色 (跟随分类颜色)';
    }
  }

  String get storageValue {
    switch (this) {
      case CategoryIconStyle.colored:
        return 'colored';
      case CategoryIconStyle.tinted:
        return 'tinted';
    }
  }
}

class CategoryIconStyleStore {
  static const _key = 'category_icon_style_v1';

  static Future<CategoryIconStyle> load({
    CategoryIconStyle fallback = CategoryIconStyle.colored,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final value = raw?.trim();
    if (value == null || value.isEmpty) return fallback;
    switch (value) {
      case 'tinted':
        return CategoryIconStyle.tinted;
      case 'colored':
        return CategoryIconStyle.colored;
      default:
        return fallback;
    }
  }

  static Future<void> save(CategoryIconStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style.storageValue);
  }
}

/// In-memory config used by icon rendering. Wrap the app root in a
/// `ValueListenableBuilder` if you need UI to refresh immediately on change.
class CategoryIconStyleConfig {
  static final ValueNotifier<CategoryIconStyle> notifier =
      ValueNotifier<CategoryIconStyle>(CategoryIconStyle.colored);

  static CategoryIconStyle get current => notifier.value;

  static set current(CategoryIconStyle value) {
    notifier.value = value;
  }
}

