import 'package:shared_preferences/shared_preferences.dart';

typedef AutoPromptNow = DateTime Function();

class AutoPermissionPromptPolicy {
  static const String prefKeySnoozeUntilMs =
      'auto_permission_prompt_snooze_until_ms';
  static const Duration defaultSnoozeDuration = Duration(hours: 24);

  final SharedPreferences _prefs;
  final Duration _snoozeDuration;
  final AutoPromptNow _now;

  AutoPermissionPromptPolicy(
    this._prefs, {
    Duration snoozeDuration = defaultSnoozeDuration,
    AutoPromptNow? now,
  }) : _snoozeDuration = snoozeDuration,
       _now = now ?? DateTime.now;

  Future<bool> isPromptSnoozed() async {
    final untilMs = _prefs.getInt(prefKeySnoozeUntilMs);
    if (untilMs == null) return false;

    final until = DateTime.fromMillisecondsSinceEpoch(untilMs);
    if (_now().isBefore(until)) return true;

    await _prefs.remove(prefKeySnoozeUntilMs);
    return false;
  }

  Future<void> snoozePrompt() async {
    final until = _now().add(_snoozeDuration);
    await _prefs.setInt(prefKeySnoozeUntilMs, until.millisecondsSinceEpoch);
  }

  Future<void> clearSnooze() async {
    await _prefs.remove(prefKeySnoozeUntilMs);
  }

  Future<bool> shouldPrompt({
    required bool autoEnabled,
    required bool allRequiredPermissionsGranted,
    required bool dialogVisible,
  }) async {
    if (!autoEnabled) return false;
    if (allRequiredPermissionsGranted) {
      await clearSnooze();
      return false;
    }
    if (dialogVisible) return false;
    return !(await isPromptSnoozed());
  }
}
