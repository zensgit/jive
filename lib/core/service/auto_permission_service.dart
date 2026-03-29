import 'package:flutter/services.dart';

class AutoPermissionStatus {
  final bool notification;
  final bool accessibility;
  final bool overlay;
  final bool batteryOptimization;

  const AutoPermissionStatus({
    required this.notification,
    required this.accessibility,
    required this.overlay,
    required this.batteryOptimization,
  });

  static const empty = AutoPermissionStatus(
    notification: false,
    accessibility: false,
    overlay: false,
    batteryOptimization: false,
  );

  bool get allRequired => notification && accessibility && overlay;

  List<String> missingRequiredLabels() {
    final items = <String>[];
    if (!notification) items.add('通知读取权限');
    if (!accessibility) items.add('无障碍权限');
    if (!overlay) items.add('悬浮窗权限');
    return items;
  }
}

class AutoPermissionService {
  static const MethodChannel _channel = MethodChannel('com.jive.app/methods');

  static Future<AutoPermissionStatus> getStatus() async {
    try {
      final result = await _channel.invokeMethod('getAutoPermissionStatus');
      if (result is Map) {
        return AutoPermissionStatus(
          notification: result['notification'] == true,
          accessibility: result['accessibility'] == true,
          overlay: result['overlay'] == true,
          batteryOptimization: result['battery'] == true,
        );
      }
      return AutoPermissionStatus.empty;
    } catch (_) {
      return AutoPermissionStatus.empty;
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) { debugPrint('Failed to open notification settings: $e'); }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) { debugPrint('Failed to open accessibility settings: $e'); }
  }

  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (e) { debugPrint('Failed to open overlay settings: $e'); }
  }

  static Future<void> openAppDetails() async {
    try {
      await _channel.invokeMethod('openAppDetails');
    } catch (e) { debugPrint('Failed to open app details: $e'); }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) { debugPrint('Failed to request ignore battery optimizations: $e'); }
  }
}
