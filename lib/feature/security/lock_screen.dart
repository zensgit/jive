import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/service/app_lock_service.dart';

/// 应用锁屏 - PIN 输入 + 生物识别
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AppLockService _lockService = AppLockService();
  String _enteredPin = '';
  bool _isError = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final enabled = await _lockService.isBiometricEnabled();
    final canUse = await _lockService.canUseBiometric();
    if (mounted) {
      setState(() {
        _biometricAvailable = enabled && canUse;
      });
      if (_biometricAvailable) {
        _tryBiometric();
      }
    }
  }

  Future<void> _tryBiometric() async {
    final success = await _lockService.authenticateWithBiometric();
    if (success) {
      widget.onUnlocked();
    }
  }

  Future<void> _onPinComplete(String pin) async {
    final verified = await _lockService.verifyPin(pin);
    if (!mounted) return;
    if (verified) {
      widget.onUnlocked();
    } else {
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isError = false);
      }
    }
  }

  void _onKeyTap(String key) {
    if (key == 'delete') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        });
      }
      return;
    }
    if (key == 'bio') {
      _tryBiometric();
      return;
    }
    if (_enteredPin.length >= 6) return;
    final newPin = _enteredPin + key;
    setState(() {
      _enteredPin = newPin;
    });
    if (newPin.length == 6) {
      _onPinComplete(newPin);
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
              '输入 PIN 码解锁',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _buildPinDots(),
            if (_isError) ...[
              const SizedBox(height: 12),
              Text(
                'PIN 码错误，请重试',
                style: GoogleFonts.lato(color: Colors.redAccent.shade100, fontSize: 14),
              ),
            ],
            const Spacer(flex: 1),
            _buildKeypad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isError
                ? Colors.redAccent.shade100
                : (filled ? Colors.white : Colors.white.withValues(alpha: 0.3)),
            border: Border.all(
              color: _isError ? Colors.redAccent.shade100 : Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [_biometricAvailable ? 'bio' : '', '0', 'delete'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 72, height: 72);
                }
                return _buildKey(key);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    Widget child;
    if (key == 'delete') {
      child = const Icon(Icons.backspace_outlined, color: Colors.white, size: 24);
    } else if (key == 'bio') {
      child = const Icon(Icons.fingerprint, color: Colors.white, size: 28);
    } else {
      child = Text(
        key,
        style: GoogleFonts.rubik(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500),
      );
    }
    return InkWell(
      onTap: () => _onKeyTap(key),
      customBorder: const CircleBorder(),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: child,
      ),
    );
  }
}
