import 'package:shared_preferences/shared_preferences.dart';

import 'widget_data_service.dart';

/// Pushes today's spending summary into SharedPreferences so the Android
/// native home-screen widget can read it without a Flutter engine.
class HomeWidgetUpdater {
  static const widgetQuickActionIdKey = 'widget_quick_action_id';
  static const widgetQuickActionLabelKey = 'widget_quick_action_label';

  final WidgetDataService _widgetDataService;

  HomeWidgetUpdater(this._widgetDataService);

  /// Fetch the latest [WidgetSummary] and persist the values that the native
  /// Android widget reads via SharedPreferences.
  Future<void> updateWidgetData() async {
    final summary = await _widgetDataService.getTodaySummary();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('today_expense', summary.todayExpense);
    await prefs.setDouble('today_income', summary.todayIncome);
    await prefs.setInt('today_count', summary.todayCount);
    await prefs.setDouble('month_expense', summary.monthExpense);
  }

  /// Configure the Android widget quick button to run a saved quick action.
  ///
  /// Passing a blank or null [actionId] restores the default
  /// `jive://transaction/new` quick-add behavior.
  static Future<void> setQuickActionShortcut({
    required String? actionId,
    String? label,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedId = actionId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      await prefs.remove(widgetQuickActionIdKey);
      await prefs.remove(widgetQuickActionLabelKey);
      return;
    }

    await prefs.setString(widgetQuickActionIdKey, normalizedId);

    final normalizedLabel = label?.trim();
    if (normalizedLabel == null || normalizedLabel.isEmpty) {
      await prefs.remove(widgetQuickActionLabelKey);
    } else {
      await prefs.setString(widgetQuickActionLabelKey, normalizedLabel);
    }
  }
}
