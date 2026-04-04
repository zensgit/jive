import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/service/gesture_lock_service.dart';
import 'gesture_lock_widget.dart';

/// 手势图案锁验证屏幕
///
/// 最多尝试 [GestureLockService.maxAttempts] 次，
/// 超过后锁定 15 分钟。提供「忘记图案？」入口通过 PIN 重置。
class GestureLockVerifyScreen extends StatefulWidget {
  /// 解锁成功时的回调
  final VoidCallback onUnlocked;

  /// 「忘记图案？」时的回调（通常导航到 PIN 验证界面）
  final VoidCallback? onForgotPattern;

  const GestureLockVerifyScreen({
    super.key,
    required this.onUnlocked,
    this.onForgotPattern,
  });

  @override
  State<GestureLockVerifyScreen> createState() =>
      _GestureLockVerifyScreenState();
}

class _GestureLockVerifyScreenState extends State<GestureLockVerifyScreen> {
  final GestureLockService _service = GestureLockService();
  final GlobalKey<GestureLockWidgetState> _widgetKey = GlobalKey();

  bool _showError = false;
  String _statusMessage = '';
  bool _isLockedOut = false;
  Timer? _lockoutTimer;
  String _lockoutDisplay = '';

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockout() async {
    final locked = await _service.isLockedOut();
    if (locked) {
      _startLockoutCountdown();
    }
    if (mounted) {
      setState(() => _isLockedOut = locked);
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = await _service.getLockoutRemaining();
      if (remaining <= Duration.zero) {
        _lockoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _isLockedOut = false;
            _statusMessage = '';
            _lockoutDisplay = '';
          });
        }
      } else if (mounted) {
        final mins = remaining.inMinutes;
        final secs = remaining.inSeconds % 60;
        setState(() {
          _isLockedOut = true;
          _lockoutDisplay = '${mins.toString().padLeft(2, '0')}:'
              '${secs.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  Future<void> _onPatternComplete(List<int> pattern) async {
    if (_isLockedOut) return;

    final correct = await _service.verifyPattern(pattern);
    if (!mounted) return;

    if (correct) {
      widget.onUnlocked();
    } else {
      await _service.incrementFailedAttempts();
      final attempts = await _service.getFailedAttempts();
      final locked = await _service.isLockedOut();

      if (locked) {
        _startLockoutCountdown();
        if (mounted) {
          setState(() {
            _isLockedOut = true;
            _showError = true;
            _statusMessage = '尝试次数过多，请稍后再试';
          });
        }
      } else if (mounted) {
        final remaining = GestureLockService.maxAttempts - attempts;
        setState(() {
          _showError = true;
          _statusMessage = '图案错误，还可尝试 $remaining 次';
        });
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _showError = false);
          _widgetKey.currentState?.reset();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              _isLockedOut ? '账户已锁定' : '请绘制解锁图案',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isLockedOut && _lockoutDisplay.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '请等待 $_lockoutDisplay 后重试',
                style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
              ),
            ],
            const SizedBox(height: 40),
            IgnorePointer(
              ignoring: _isLockedOut,
              child: Opacity(
                opacity: _isLockedOut ? 0.4 : 1.0,
                child: GestureLockWidget(
                  key: _widgetKey,
                  onPatternComplete: _onPatternComplete,
                  showError: _showError,
                ),
              ),
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: GoogleFonts.lato(
                  color: Colors.redAccent.shade100,
                  fontSize: 14,
                ),
              ),
            ],
            const Spacer(flex: 1),
            if (widget.onForgotPattern != null)
              TextButton(
                onPressed: widget.onForgotPattern,
                child: Text(
                  '忘记图案？',
                  style: GoogleFonts.lato(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
