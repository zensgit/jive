import 'package:flutter/material.dart';

import '../model/quick_action.dart';
import 'quick_action_service.dart';

/// A registered intent that the app can surface to external systems (widgets,
/// shortcuts, deep-links).
class AppIntent {
  final String id;
  final String name;
  final String? icon;
  final Uri deepLinkUri;
  final String? quickActionId;

  const AppIntent({
    required this.id,
    required this.name,
    this.icon,
    required this.deepLinkUri,
    this.quickActionId,
  });

  @override
  String toString() => 'AppIntent($id, $name)';
}

/// Central routing service for all external entry points into the app.
///
/// Deep-links, quick-action shortcuts, widget taps, and share-receive intents
/// are all funnelled through this service so that the rest of the app only
/// needs a single integration point.
class AppIntentService {
  final QuickActionService _quickActionService;

  /// Optional navigator key for programmatic navigation.
  final GlobalKey<NavigatorState>? navigatorKey;

  AppIntentService(
    this._quickActionService, {
    this.navigatorKey,
  });

  // ---------------------------------------------------------------------------
  // Deep-link handling
  // ---------------------------------------------------------------------------

  /// Parses a deep-link [uri] and navigates to the corresponding screen.
  ///
  /// Supported paths:
  /// - `/transaction/<id>` — opens transaction detail
  /// - `/quick-action/<id>` — executes a quick action
  /// - `/scene/<id>` — switches to scene
  /// - `/stats` — opens statistics screen
  void handleDeepLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return;

    switch (segments.first) {
      case 'transaction':
        if (segments.length > 1) {
          _navigate('/transaction/${segments[1]}');
        }
        break;
      case 'quick-action':
        if (segments.length > 1) {
          handleQuickAction(segments[1]);
        }
        break;
      case 'scene':
        if (segments.length > 1) {
          _navigate('/scene/${segments[1]}');
        }
        break;
      case 'stats':
        _navigate('/stats');
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Quick-action handling
  // ---------------------------------------------------------------------------

  /// Executes the [QuickAction] identified by [actionId].
  ///
  /// For direct-mode actions the transaction is created immediately; for
  /// confirm/edit-mode actions the entry screen is opened with prefilled data.
  Future<void> handleQuickAction(String actionId) async {
    final actions = await _quickActionService.listForHome();
    final action = actions.where((a) => a.id == actionId).firstOrNull;
    if (action == null) return;

    if (action.mode == QuickActionMode.direct) {
      await _quickActionService.executeDirect(action);
    } else {
      _navigate('/entry?quickAction=$actionId');
    }
  }

  // ---------------------------------------------------------------------------
  // Widget tap handling
  // ---------------------------------------------------------------------------

  /// Handles a tap from a native home-screen widget.
  ///
  /// [widgetType] values: `summary`, `quick_add`, `budget`.
  void handleWidgetTap(String widgetType) {
    switch (widgetType) {
      case 'summary':
        _navigate('/stats');
        break;
      case 'quick_add':
        _navigate('/entry');
        break;
      case 'budget':
        _navigate('/budget');
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Share-receive handling
  // ---------------------------------------------------------------------------

  /// Parses incoming text (e.g. from Android share-sheet) and opens the
  /// transaction entry screen with the parsed amount/note prefilled.
  void handleShareReceive(String text) {
    final amount = _parseAmount(text);
    final note = text.replaceAll(RegExp(r'[\d.]+'), '').trim();
    final query = <String>[];
    if (amount != null) query.add('amount=$amount');
    if (note.isNotEmpty) query.add('note=${Uri.encodeComponent(note)}');
    _navigate('/entry${query.isNotEmpty ? "?${query.join("&")}" : ""}');
  }

  // ---------------------------------------------------------------------------
  // Intent registry
  // ---------------------------------------------------------------------------

  /// Returns all intents that external systems (widgets / shortcuts) can
  /// register.
  Future<List<AppIntent>> getAvailableIntents() async {
    final intents = <AppIntent>[
      AppIntent(
        id: 'quick_add',
        name: '快速记账',
        icon: 'add_circle',
        deepLinkUri: Uri.parse('jive://entry'),
      ),
      AppIntent(
        id: 'view_stats',
        name: '查看统计',
        icon: 'bar_chart',
        deepLinkUri: Uri.parse('jive://stats'),
      ),
    ];

    // Expose home-pinned quick actions as intents.
    final actions = await _quickActionService.listForHome();
    for (final a in actions) {
      intents.add(AppIntent(
        id: 'qa_${a.id}',
        name: a.name,
        icon: a.iconName,
        deepLinkUri: Uri.parse('jive://quick-action/${a.id}'),
        quickActionId: a.id,
      ));
    }

    return intents;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _navigate(String routePath) {
    navigatorKey?.currentState?.pushNamed(routePath);
  }

  double? _parseAmount(String text) {
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }
}
