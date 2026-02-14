import 'package:shared_preferences/shared_preferences.dart';

class BudgetPrefService {
  static const _keyBudgetSaveAlertEnabled = 'budget_save_alert_enabled';
  static const _keyBudgetTrendChartEnabled = 'budget_trend_chart_enabled';
  static const _keyBudgetPullToExcludeEnabled =
      'budget_pull_to_exclude_enabled';
  static const _keyBudgetMonthlyAutoCopyEnabled =
      'budget_monthly_auto_copy_enabled';
  static const _keyBudgetCarryoverAddEnabled = 'budget_carryover_add_enabled';
  static const _keyBudgetCarryoverReduceEnabled =
      'budget_carryover_reduce_enabled';

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

  static Future<bool> getBudgetMonthlyAutoCopyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetMonthlyAutoCopyEnabled) ?? true;
  }

  static Future<void> setBudgetMonthlyAutoCopyEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetMonthlyAutoCopyEnabled, value);
  }

  static Future<bool> getBudgetCarryoverAddEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetCarryoverAddEnabled) ?? false;
  }

  static Future<void> setBudgetCarryoverAddEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetCarryoverAddEnabled, value);
  }

  static Future<bool> getBudgetCarryoverReduceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetCarryoverReduceEnabled) ?? false;
  }

  static Future<void> setBudgetCarryoverReduceEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetCarryoverReduceEnabled, value);
  }
}
