import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages the floating ball quick-add overlay state.
///
/// Persists enabled/disabled state and the last screen position to
/// [SharedPreferences] so the ball reappears at the same spot after restart.
class FloatBallService {
  static const _keyEnabled = 'float_ball_enabled';
  static const _keyPositionX = 'float_ball_position_x';
  static const _keyPositionY = 'float_ball_position_y';

  // ---------------------------------------------------------------------------
  // Enabled toggle
  // ---------------------------------------------------------------------------

  static Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  // ---------------------------------------------------------------------------
  // Position persistence
  // ---------------------------------------------------------------------------

  /// Returns the last saved (x, y) position, or `null` if none was saved.
  static Future<({double x, double y})?> getPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_keyPositionX);
    final y = prefs.getDouble(_keyPositionY);
    if (x == null || y == null) return null;
    return (x: x, y: y);
  }

  /// Persists the current position so it can be restored on next launch.
  static Future<void> savePosition(double x, double y) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPositionX, x);
    await prefs.setDouble(_keyPositionY, y);
  }
}
