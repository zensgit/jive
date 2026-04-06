import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to show / hide a persistent Android notification reflecting the
/// current auto-capture status.  The toggle is user-controllable and stored in
/// SharedPreferences.
///
/// The actual Android-side notification rendering is handled via a
/// MethodChannel (`com.jivemoney.app/notification`) whose native
/// implementation is maintained separately.
class AutoCaptureNotificationService {
  AutoCaptureNotificationService._();
  static final AutoCaptureNotificationService instance =
      AutoCaptureNotificationService._();

  static const _prefKey = 'auto_capture_status_notification_enabled';
  static const _channel = MethodChannel('com.jivemoney.app/notification');

  static const Map<String, String> _statusLabels = {
    'running': '自动记账运行中',
    'paused': '自动记账已暂停',
    'capturing': '正在捕获交易...',
  };

  // ── Preference helpers ──────────────────────────────────────────────────

  /// Whether the persistent status notification is enabled (default `false`).
  Future<bool> isStatusNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Persist the user's preference.
  Future<void> setStatusNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    if (!enabled) {
      await hideStatusNotification();
    }
  }

  // ── Notification helpers ────────────────────────────────────────────────

  /// Show (or update) the persistent notification.
  ///
  /// [status] must be one of `'running'`, `'paused'`, or `'capturing'`.
  Future<void> showStatusNotification(String status) async {
    final label = _statusLabels[status];
    if (label == null) return;

    try {
      await _channel.invokeMethod('showStatusNotification', {
        'status': status,
        'label': label,
      });
    } on MissingPluginException {
      // Native side not implemented yet -- silently ignore on non-Android.
    }
  }

  /// Remove the persistent notification.
  Future<void> hideStatusNotification() async {
    try {
      await _channel.invokeMethod('hideStatusNotification');
    } on MissingPluginException {
      // Native side not implemented yet.
    }
  }

  /// Returns the localised label for a given status key, or `null`.
  String? labelForStatus(String status) => _statusLabels[status];
}
