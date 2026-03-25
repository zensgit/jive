import 'package:flutter/material.dart';

import '../../core/service/app_lock_service.dart';
import 'lock_screen.dart';

/// 应用锁门控 - 包裹在 MainScreen 外层
/// 冷启动和切回前台时检查是否需要锁定
class LockGate extends StatefulWidget {
  final Widget child;

  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final AppLockService _lockService = AppLockService();
  bool _isLocked = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkLockOnStart() async {
    final enabled = await _lockService.isLockEnabled();
    if (mounted) {
      setState(() {
        _isLocked = enabled;
        _initialized = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _onAppPaused();
    }
  }

  Future<void> _onAppPaused() async {
    final enabled = await _lockService.isLockEnabled();
    final lockOnExit = await _lockService.isLockOnExitEnabled();
    if (enabled && lockOnExit && mounted) {
      setState(() => _isLocked = true);
    }
  }

  void _onUnlocked() {
    if (mounted) {
      setState(() => _isLocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF2E7D32),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_isLocked) {
      return LockScreen(onUnlocked: _onUnlocked);
    }

    return widget.child;
  }
}
