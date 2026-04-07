import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/quick_action.dart';
import 'app_intent_service.dart';

/// Bridge between Android home-screen widget taps and in-app actions.
///
/// Quick-action IDs are written to [SharedPreferences] so the native widget
/// can display them, and a [MethodChannel] is used to receive tap events back
/// into Flutter for routing via [AppIntentService].
class WidgetActionBridge {
  final AppIntentService _intentService;
  final SharedPreferences _prefs;

  static const _channel = MethodChannel('com.jivemoney.app/widget_action');
  static const _kWidgetActionsKey = 'widget_action_ids';

  WidgetActionBridge(this._intentService, this._prefs) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // ---------------------------------------------------------------------------
  // Registration — write action IDs for the native widget to read
  // ---------------------------------------------------------------------------

  /// Stores the IDs of the given [actions] in SharedPreferences so the native
  /// Android widget can render shortcut buttons.
  Future<void> registerActions(List<QuickAction> actions) async {
    final ids = actions.map((a) => a.id).toList();
    await _prefs.setStringList(_kWidgetActionsKey, ids);
  }

  /// Returns the quick-action IDs currently registered for the widget.
  List<String> getWidgetActionIds() {
    return _prefs.getStringList(_kWidgetActionsKey) ?? [];
  }

  // ---------------------------------------------------------------------------
  // Incoming calls from native side
  // ---------------------------------------------------------------------------

  /// Routes an action ID received from the widget to [AppIntentService].
  Future<void> handleWidgetAction(String actionId) async {
    await _intentService.handleQuickAction(actionId);
  }

  // ---------------------------------------------------------------------------
  // MethodChannel handler
  // ---------------------------------------------------------------------------

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'executeAction':
        final actionId = call.arguments as String?;
        if (actionId != null) {
          await handleWidgetAction(actionId);
        }
        break;
      case 'openApp':
        final widgetType = call.arguments as String? ?? 'summary';
        _intentService.handleWidgetTap(widgetType);
        break;
    }
  }
}
