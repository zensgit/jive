import 'package:shared_preferences/shared_preferences.dart';

class BudgetPrefService {
  static const _keyBudgetSaveAlertEnabled = 'budget_save_alert_enabled';
  static const _keyBudgetTrendChartEnabled = 'budget_trend_chart_enabled';
  static const _keyBudgetPullToExcludeEnabled =
      'budget_pull_to_exclude_enabled';

  static Future<bool> getBudgetSaveAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetSaveAlertEnabled) ?? true;
  }

  static Future<void> setBudgetSaveAlertEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetSaveAlertEnabled, value);
  }

  static Future<bool> getBudgetTrendChartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetTrendChartEnabled) ?? true;
  }

  static Future<void> setBudgetTrendChartEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetTrendChartEnabled, value);
  }

  static Future<bool> getBudgetPullToExcludeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetPullToExcludeEnabled) ?? true;
  }

  static Future<void> setBudgetPullToExcludeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetPullToExcludeEnabled, value);
  }
}
