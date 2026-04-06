import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/service/auto_app_registry.dart';
import '../../../core/service/auto_app_settings.dart';
import '../../../core/database/auto_draft_model.dart';
import '../../../core/database/transaction_model.dart';
import '../../../core/service/auto_draft_service.dart';
import '../../../core/service/auto_permission_service.dart';
import '../../../core/service/auto_permission_prompt_policy.dart';
import '../../../core/service/auto_settings.dart';
import '../../../core/utils/logger_util.dart';
import '../main_screen_controller.dart';

enum AutoPermissionDialogAction { later, settings }

mixin AutoCaptureMixin on MainScreenController {
  static const eventChannel = EventChannel('com.jive.app/stream');
  static const kE2eMode = bool.fromEnvironment(
    'JIVE_E2E',
    defaultValue: false,
  );

  AutoSettings autoSettings = AutoSettingsStore.defaults;
  Map<String, bool> autoAppEnabled = {};
  int autoAppEnabledCount = AutoAppRegistry.apps.length;
  final List<Map<String, dynamic>> pendingAutoEvents = [];
  bool isListening = false;
  bool permissionDialogVisible = false;
  @override
  AutoPermissionPromptPolicy? autoPermissionPromptPolicy;
  int pendingDraftCount = 0;

  /// Callback for opening auto settings screen.
  /// Set this from the main State class in initState.
  VoidCallback? onOpenAutoSettings;

  void startListening() {
    if (isListening) return;
    isListening = true;
    eventChannel.receiveBroadcastStream().listen((dynamic event) async {
      if (event is! Map) return;
      final payload = Map<String, dynamic>.from(event);
      if (!dbReady) {
        pendingAutoEvents.add(payload);
        return;
      }
      await handleAutoEvent(payload);
    });
  }

  Future<void> handleAutoEvent(Map<String, dynamic> data) async {
    if (!autoSettings.enabled) {
      JiveLogger.w("AutoCapture ignored: auto disabled");
      return;
    }
    final packageName = resolveAutoPackageName(data);
    if (!isAutoAppEnabled(packageName)) {
      JiveLogger.w("AutoCapture ignored: app disabled package=$packageName");
      return;
    }
    if (autoSettings.keywordFilterEnabled) {
      final rawText = data['raw_text']?.toString() ?? '';
      if (rawText.isNotEmpty &&
          !containsAnyKeyword(rawText, autoSettings.keywordFilters)) {
        JiveLogger.w("AutoCapture ignored: keyword filter raw=$rawText");
        return;
      }
    }
    final capture = AutoCapture.fromEvent(data);
    if (!capture.isValid) {
      JiveLogger.w(
        "AutoCapture invalid: source=${capture.source} amount=${capture.amount}",
      );
      return;
    }
    JiveLogger.i(
      "AutoCapture received: source=${capture.source} amount=${capture.amount} type=${capture.type} raw=${capture.rawText}",
    );
    final result = await AutoDraftService(isar).ingestCapture(
      capture,
      directCommit: autoSettings.directCommit,
      settings: autoSettings,
    );
    if (!mounted) return;
    JiveLogger.i(
      "AutoCapture result: inserted=${result.inserted} committed=${result.committed} duplicate=${result.duplicate}",
    );
    if (result.duplicate) {
      showMessage("已忽略重复自动记账");
      return;
    }
    if (result.merged) {
      showMessage("已合并转账记录");
      await loadAutoDraftCount();
      return;
    }
    await loadAutoDraftCount();
    if (result.committed) {
      await loadTransactions();
      notifyDataChanged();
      showMessage("已自动入账");
      return;
    }
    if (result.inserted) {
      showMessage("已加入待确认");
    }
  }

  @override
  Future<void> flushPendingAutoEvents() async {
    if (pendingAutoEvents.isEmpty) return;
    final events = List<Map<String, dynamic>>.from(pendingAutoEvents);
    pendingAutoEvents.clear();
    for (final event in events) {
      await handleAutoEvent(event);
    }
  }

  bool containsAnyKeyword(String text, List<String> keywords) {
    if (keywords.isEmpty) return true;
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  String? resolveAutoPackageName(Map<String, dynamic> data) {
    final pkg = data['package_name']?.toString();
    if (pkg != null && pkg.isNotEmpty) return pkg;
    final source = data['source']?.toString();
    return AutoAppRegistry.resolvePackage(source);
  }

  bool isAutoAppEnabled(String? packageName) {
    if (packageName == null) return true;
    if (!AutoAppRegistry.isSupported(packageName)) return true;
    return AutoAppSettingsStore.isEnabled(autoAppEnabled, packageName);
  }

  @override
  Future<void> loadAutoSettings() async {
    final settings = await AutoSettingsStore.load();
    if (!mounted) return;
    setState(() {
      autoSettings = settings;
    });
  }

  @override
  Future<void> loadAutoAppSettings() async {
    final map = await AutoAppSettingsStore.loadEnabledMap();
    if (!mounted) return;
    setState(() {
      autoAppEnabled = map;
      autoAppEnabledCount = AutoAppSettingsStore.enabledCount(map);
    });
  }

  Future<void> setAutoSettings(AutoSettings settings) async {
    if (!mounted) return;
    final wasEnabled = autoSettings.enabled;
    setState(() {
      autoSettings = settings;
    });
    await AutoSettingsStore.save(settings);
    if (!wasEnabled && settings.enabled) {
      await autoPermissionPromptPolicy?.clearSnooze();
    }
    await checkAutoPermissions();
  }

  @override
  Future<void> loadAutoDraftCount() async {
    final count = await isar.collection<JiveAutoDraft>().count();
    if (!mounted) return;
    setState(() {
      pendingDraftCount = count;
    });
  }

  @override
  Future<void> checkAutoPermissions() async {
    if (kE2eMode) return;
    if (!dbReady) return;
    final promptPolicy = autoPermissionPromptPolicy;
    if (promptPolicy == null) return;
    if (!autoSettings.enabled) return;
    // Don't prompt new users — wait until they have at least 3 transactions
    final txCount = await isar.collection<JiveTransaction>().count();
    if (txCount < 3) return;
    final status = await AutoPermissionService.getStatus();
    if (!mounted) return;
    final shouldPrompt = await promptPolicy.shouldPrompt(
      autoEnabled: autoSettings.enabled,
      allRequiredPermissionsGranted: status.allRequired,
      dialogVisible: permissionDialogVisible,
    );
    if (!shouldPrompt) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || permissionDialogVisible) return;
      permissionDialogVisible = true;
      try {
        final missing = status.missingRequiredLabels();
        final action = await showDialog<AutoPermissionDialogAction>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('自动记账权限未开启'),
            content: Text('未开启：${missing.join('、')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  AutoPermissionDialogAction.later,
                ),
                child: const Text('稍后'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  AutoPermissionDialogAction.settings,
                ),
                child: const Text('去设置'),
              ),
            ],
          ),
        );

        // Any close path should enter cooldown to avoid repeated interruptions.
        await promptPolicy.snoozePrompt();
        if (action == AutoPermissionDialogAction.settings && mounted) {
          onOpenAutoSettings?.call();
        }
      } finally {
        permissionDialogVisible = false;
      }
    });
  }
}
