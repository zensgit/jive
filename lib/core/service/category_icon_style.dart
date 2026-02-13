import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CategoryIconStyle {
  colored,
  tinted,
  /// Hybrid mode:
  /// - system categories: tinted (follow category color)
  /// - user categories: keep original colored assets
  hybrid,
}

extension CategoryIconStyleLabel on CategoryIconStyle {
  String get label {
    switch (this) {
      case CategoryIconStyle.colored:
        return '彩色（默认）';
      case CategoryIconStyle.tinted:
        return '单色（全部跟随分类颜色）';
      case CategoryIconStyle.hybrid:
        return '混合（系统单色/自定义彩色）';
    }
  }

  String get storageValue {
    switch (this) {
      case CategoryIconStyle.colored:
        return 'colored';
      case CategoryIconStyle.tinted:
        return 'tinted';
      case CategoryIconStyle.hybrid:
        return 'hybrid';
    }
  }
}

extension CategoryIconStyleBehavior on CategoryIconStyle {
  /// Whether `assets/category_icons/*` should be tinted for a given category.
  ///
  /// If [isSystemCategory] is unknown, we default to `false` in hybrid mode to
  /// avoid unexpectedly turning unrelated icons monochrome.
  bool shouldTintForCategory({required bool? isSystemCategory}) {
    switch (this) {
      case CategoryIconStyle.colored:
        return false;
      case CategoryIconStyle.tinted:
        return true;
      case CategoryIconStyle.hybrid:
        return isSystemCategory == true;
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
      case 'hybrid':
        return CategoryIconStyle.hybrid;
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
