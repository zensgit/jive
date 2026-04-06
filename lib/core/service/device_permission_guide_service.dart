import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single step in a device-specific permission guide.
class PermissionStep {
  final String title;
  final String description;
  final String? intentAction;

  const PermissionStep({
    required this.title,
    required this.description,
    this.intentAction,
  });
}

/// Service that provides device-brand-aware battery/autostart permission guides.
class DevicePermissionGuideService {
  static const _channel = MethodChannel('com.jive.app/device_info');
  static const _settingsChannel = MethodChannel('com.jive.app/settings');
  static const _completedKeyPrefix = 'device_guide_step_completed_';

  /// Detect the device brand (lowercase).
  /// Returns one of: xiaomi, huawei, oppo, vivo, samsung, oneplus, meizu,
  /// realme, other.
  String getDeviceBrand() {
    // On non-Android platforms, return 'other'.
    if (defaultTargetPlatform != TargetPlatform.android) return 'other';

    // In production this would come from the platform channel; we use a
    // synchronous best-effort heuristic based on the build info cached at
    // startup.  For now, return 'other' — the native side will be wired later.
    return 'other';
  }

  /// Async version that queries the platform channel.
  Future<String> getDeviceBrandAsync() async {
    if (defaultTargetPlatform != TargetPlatform.android) return 'other';
    try {
      final brand =
          await _channel.invokeMethod<String>('getDeviceBrand') ?? '';
      return _normalizeBrand(brand);
    } catch (_) {
      return 'other';
    }
  }

  String _normalizeBrand(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('xiaomi') || lower.contains('redmi') || lower.contains('poco')) {
      return 'xiaomi';
    }
    if (lower.contains('huawei') || lower.contains('honor')) return 'huawei';
    if (lower.contains('oppo')) return 'oppo';
    if (lower.contains('vivo')) return 'vivo';
    if (lower.contains('samsung')) return 'samsung';
    if (lower.contains('oneplus')) return 'oneplus';
    if (lower.contains('meizu')) return 'meizu';
    if (lower.contains('realme')) return 'realme';
    return 'other';
  }

  /// Return brand-specific permission guide steps.
  List<PermissionStep> getPermissionGuideSteps(String brand) {
    switch (brand) {
      case 'xiaomi':
        return const [
          PermissionStep(
            title: '打开设置',
            description: '设置→应用设置→应用管理',
            intentAction: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          ),
          PermissionStep(
            title: '找到Jive',
            description: '在应用列表中找到Jive并点击进入',
          ),
          PermissionStep(
            title: '开启自启动',
            description: '找到自启动选项并开启',
            intentAction:
                'miui.intent.action.OP_AUTO_START',
          ),
          PermissionStep(
            title: '修改省电策略',
            description: '省电策略改为无限制',
            intentAction:
                'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ),
        ];
      case 'huawei':
        return const [
          PermissionStep(
            title: '打开设置',
            description: '设置→应用→应用启动管理',
            intentAction:
                'huawei.intent.action.HSM_BOOTAPP_MANAGER',
          ),
          PermissionStep(
            title: '找到Jive',
            description: '在应用启动管理列表中找到Jive',
          ),
          PermissionStep(
            title: '关闭自动管理',
            description: '关闭自动管理开关',
          ),
          PermissionStep(
            title: '手动开启权限',
            description: '手动打开三个开关（自启动、关联启动、后台活动）',
          ),
        ];
      case 'oppo':
      case 'oneplus':
      case 'realme':
        return const [
          PermissionStep(
            title: '打开设置',
            description: '设置→电池→应用省电管理',
            intentAction:
                'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ),
          PermissionStep(
            title: '找到Jive',
            description: '在应用列表中找到Jive',
          ),
          PermissionStep(
            title: '选择不优化',
            description: '将Jive设置为不优化电池',
          ),
        ];
      case 'vivo':
        return const [
          PermissionStep(
            title: '打开设置',
            description: '设置→电池→后台高耗电',
            intentAction:
                'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ),
          PermissionStep(
            title: '允许后台运行',
            description: '允许Jive后台运行',
          ),
        ];
      case 'samsung':
        return const [
          PermissionStep(
            title: '打开设置',
            description: '设置→应用→Jive',
            intentAction: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          ),
          PermissionStep(
            title: '进入电池设置',
            description: '点击电池选项',
          ),
          PermissionStep(
            title: '设为不受限制',
            description: '将电池使用设置为不受限制',
          ),
        ];
      case 'meizu':
        return const [
          PermissionStep(
            title: '打开应用管理',
            description: '设置→应用管理→Jive',
            intentAction: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          ),
          PermissionStep(
            title: '进入权限管理',
            description: '点击权限管理',
          ),
          PermissionStep(
            title: '修改后台管理',
            description: '后台管理改为允许',
          ),
        ];
      default:
        return const [
          PermissionStep(
            title: '打开系统设置',
            description: '设置→应用→Jive',
            intentAction: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          ),
          PermissionStep(
            title: '进入电池设置',
            description: '找到电池/电量管理选项',
          ),
          PermissionStep(
            title: '关闭电池优化',
            description: '将Jive设置为不优化',
            intentAction:
                'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          ),
        ];
    }
  }

  /// Open battery optimization settings via platform channel.
  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _settingsChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      debugPrint('Failed to open battery optimization settings: $e');
    }
  }

  /// Try to open auto-start settings via platform channel.
  Future<void> openAutoStartSettings() async {
    try {
      await _settingsChannel.invokeMethod('openAutoStartSettings');
    } catch (e) {
      debugPrint('Failed to open auto-start settings: $e');
    }
  }

  // -- Step completion persistence --

  Future<bool> isStepCompleted(int stepIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_completedKeyPrefix$stepIndex') ?? false;
  }

  Future<void> setStepCompleted(int stepIndex, {required bool completed}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_completedKeyPrefix$stepIndex', completed);
  }

  Future<List<bool>> loadAllStepCompletions(int stepCount) async {
    final prefs = await SharedPreferences.getInstance();
    return List.generate(
      stepCount,
      (i) => prefs.getBool('$_completedKeyPrefix$i') ?? false,
    );
  }
}
