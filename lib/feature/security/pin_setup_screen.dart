import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/service/app_lock_service.dart';

/// PIN 码设置/修改屏幕
class PinSetupScreen extends StatefulWidget {
  /// 是否为修改 PIN（需要先验证旧 PIN）
  final bool isChange;

  const PinSetupScreen({super.key, this.isChange = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _SetupStep { verifyOld, enterNew, confirmNew }

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AppLockService _lockService = AppLockService();

  late _SetupStep _step;
  String _enteredPin = '';
  String _firstPin = '';
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _step = widget.isChange ? _SetupStep.verifyOld : _SetupStep.enterNew;
  }

  String get _title {
    switch (_step) {
      case _SetupStep.verifyOld:
        return '输入当前 PIN 码';
      case _SetupStep.enterNew:
        return '设置新 PIN 码';
      case _SetupStep.confirmNew:
        return '确认 PIN 码';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _SetupStep.verifyOld:
        return '请输入当前的 6 位 PIN 码';
      case _SetupStep.enterNew:
        return '请输入 6 位数字 PIN 码';
      case _SetupStep.confirmNew:
        return '请再次输入 PIN 码确认';
    }
  }

  Future<void> _onPinComplete(String pin) async {
    switch (_step) {
      case _SetupStep.verifyOld:
        final verified = await _lockService.verifyPin(pin);
        if (!mounted) return;
        if (verified) {
          setState(() {
            _step = _SetupStep.enterNew;
            _enteredPin = '';
          });
        } else {
          _showError('PIN 码错误');
        }
        break;

      case _SetupStep.enterNew:
        setState(() {
          _firstPin = pin;
          _step = _SetupStep.confirmNew;
          _enteredPin = '';
        });
        break;

      case _SetupStep.confirmNew:
        if (pin == _firstPin) {
          await _lockService.setPin(pin);
          // 检查是否可以开启生物识别
          final canBio = await _lockService.canUseBiometric();
          if (canBio && mounted) {
            final enableBio = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('启用生物识别'),
                content: const Text('是否同时启用指纹/面容识别来解锁？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('暂不'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('启用'),
                  ),
                ],
              ),
            );
            if (enableBio == true) {
              await _lockService.setBiometricEnabled(true);
            }
          }
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          _showError('两次输入不一致，请重新设置');
          setState(() {
            _step = _SetupStep.enterNew;
          });
        }
        break;
    }
  }

  void _showError(String message) {
    setState(() {
      _isError = true;
      _errorMessage = message;
      _enteredPin = '';
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isError = false);
      }
    });
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
            const SizedBox(height: 32),
            _buildPinDots(),
            if (_isError) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
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
      ['', '0', 'delete'],
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
