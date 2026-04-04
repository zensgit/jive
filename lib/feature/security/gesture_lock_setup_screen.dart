import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/service/gesture_lock_service.dart';
import 'gesture_lock_widget.dart';
import 'pin_setup_screen.dart';

/// 手势图案锁设置屏幕
///
/// 两步流程：
/// 1. 绘制图案
/// 2. 确认图案
class GestureLockSetupScreen extends StatefulWidget {
  const GestureLockSetupScreen({super.key});

  @override
  State<GestureLockSetupScreen> createState() => _GestureLockSetupScreenState();
}

enum _SetupStep { draw, confirm }

class _GestureLockSetupScreenState extends State<GestureLockSetupScreen> {
  final GestureLockService _service = GestureLockService();
  final GlobalKey<GestureLockWidgetState> _widgetKey = GlobalKey();

  _SetupStep _step = _SetupStep.draw;
  List<int> _firstPattern = [];
  bool _showError = false;
  String _errorMessage = '';

  String get _title {
    switch (_step) {
      case _SetupStep.draw:
        return '请绘制手势图案';
      case _SetupStep.confirm:
        return '请再次确认';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _SetupStep.draw:
        return '至少连接 4 个点';
      case _SetupStep.confirm:
        return '再次绘制相同的图案';
    }
  }

  void _onPatternComplete(List<int> pattern) {
    switch (_step) {
      case _SetupStep.draw:
        setState(() {
          _firstPattern = pattern;
          _step = _SetupStep.confirm;
          _showError = false;
          _errorMessage = '';
        });
        _widgetKey.currentState?.reset();
        break;

      case _SetupStep.confirm:
        if (_patternsMatch(pattern, _firstPattern)) {
          _saveAndFinish(pattern);
        } else {
          _showPatternError('两次图案不一致，请重新设置');
          setState(() {
            _step = _SetupStep.draw;
            _firstPattern = [];
          });
        }
        break;
    }
  }

  bool _patternsMatch(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _saveAndFinish(List<int> pattern) async {
    await _service.savePattern(pattern);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showPatternError(String message) {
    setState(() {
      _showError = true;
      _errorMessage = message;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showError = false);
        _widgetKey.currentState?.reset();
      }
    });
  }

  void _navigateToPinSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const PinSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Text(
              _title,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            GestureLockWidget(
              key: _widgetKey,
              onPatternComplete: _onPatternComplete,
              showError: _showError,
            ),
            if (_showError) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: GoogleFonts.lato(
                  color: Colors.redAccent.shade100,
                  fontSize: 14,
                ),
              ),
            ],
            const Spacer(flex: 2),
            TextButton(
              onPressed: _navigateToPinSetup,
              child: Text(
                '使用 PIN 码替代',
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
