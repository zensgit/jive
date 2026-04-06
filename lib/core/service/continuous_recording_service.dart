import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages "continuous recording" mode.
///
/// When enabled, saving a transaction immediately resets the form for a new
/// entry, pre-filling the last-used account and category so the user can
/// quickly enter successive transactions.
class ContinuousRecordingService {
  static const _keyContinuousMode = 'continuous_recording_mode';
  static const _keyLastAccountId = 'continuous_last_account_id';
  static const _keyLastCategoryKey = 'continuous_last_category_key';
  static const _keyLastSubCategoryKey = 'continuous_last_sub_category_key';

  // ---------------------------------------------------------------------------
  // Continuous-mode toggle
  // ---------------------------------------------------------------------------

  /// Whether continuous-recording mode is currently enabled.
  static Future<bool> isContinuousMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyContinuousMode) ?? false;
  }

  /// Toggle continuous-recording mode on/off and return the new value.
  static Future<bool> toggleContinuousMode() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool(_keyContinuousMode) ?? false;
    final next = !current;
    await prefs.setBool(_keyContinuousMode, next);
    return next;
  }

  /// Explicitly set continuous-recording mode.
  static Future<void> setContinuousMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyContinuousMode, value);
  }

  // ---------------------------------------------------------------------------
  // Last-used defaults (for pre-filling the next entry)
  // ---------------------------------------------------------------------------

  /// Persist the most recently used account & category so we can pre-fill the
  /// next form when continuous mode is active.
  static Future<void> saveLastRecordDefaults({
    int? accountId,
    String? categoryKey,
    String? subCategoryKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (accountId != null) {
      await prefs.setInt(_keyLastAccountId, accountId);
    }
    if (categoryKey != null) {
      await prefs.setString(_keyLastCategoryKey, categoryKey);
    }
    if (subCategoryKey != null) {
      await prefs.setString(_keyLastSubCategoryKey, subCategoryKey);
    } else {
      await prefs.remove(_keyLastSubCategoryKey);
    }
  }

  /// Returns the last-used account ID, category key and sub-category key.
  static Future<ContinuousRecordDefaults> getLastRecordDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return ContinuousRecordDefaults(
      accountId: prefs.getInt(_keyLastAccountId),
      categoryKey: prefs.getString(_keyLastCategoryKey),
      subCategoryKey: prefs.getString(_keyLastSubCategoryKey),
    );
  }
}

/// Data class holding the last-used defaults for continuous recording.
class ContinuousRecordDefaults {
  final int? accountId;
  final String? categoryKey;
  final String? subCategoryKey;

  const ContinuousRecordDefaults({
    this.accountId,
    this.categoryKey,
    this.subCategoryKey,
  });
}
