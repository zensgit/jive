import 'package:shared_preferences/shared_preferences.dart';

import 'widget_data_service.dart';

/// Pushes today's spending summary into SharedPreferences so the Android
/// native home-screen widget can read it without a Flutter engine.
class HomeWidgetUpdater {
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
}
