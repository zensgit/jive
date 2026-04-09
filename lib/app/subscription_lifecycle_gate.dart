import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_service.dart';
import '../core/payment/subscription_status_service.dart';

/// Keeps subscription truth in sync with app lifecycle and auth changes.
class SubscriptionLifecycleGate extends StatefulWidget {
  const SubscriptionLifecycleGate({super.key, required this.child});

  final Widget child;

  @override
  State<SubscriptionLifecycleGate> createState() =>
      _SubscriptionLifecycleGateState();
}

class _SubscriptionLifecycleGateState extends State<SubscriptionLifecycleGate>
    with WidgetsBindingObserver {
  AuthService? _authService;
  String? _lastSeenUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextAuthService = context.read<AuthService>();
    if (identical(_authService, nextAuthService)) return;

    _authService?.removeListener(_handleAuthChanged);
    _authService = nextAuthService;
    _lastSeenUserId = nextAuthService.currentUser?.uid;
    nextAuthService.addListener(_handleAuthChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authService?.removeListener(_handleAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(context.read<SubscriptionStatusService>().checkAndSyncIfStale());
  }

  void _handleAuthChanged() {
    final currentUserId = _authService?.currentUser?.uid;
    if (currentUserId == _lastSeenUserId) return;

    _lastSeenUserId = currentUserId;
    unawaited(context.read<SubscriptionStatusService>().checkAndSync());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
