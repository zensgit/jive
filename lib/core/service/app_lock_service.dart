import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用锁服务 - 管理 PIN 码和生物识别认证
class AppLockService {
  static const _prefKeyLockEnabled = 'app_lock_enabled';
  static const _prefKeyPinHash = 'app_lock_pin_hash';
  static const _prefKeyBiometricEnabled = 'app_lock_biometric';
  static const _prefKeyLockOnExit = 'app_lock_on_exit';

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 检查是否已启用应用锁
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyLockEnabled) ?? false;
  }

  /// 检查是否启用了生物识别
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyBiometricEnabled) ?? false;
  }

  /// 检查是否切后台即锁定
  Future<bool> isLockOnExitEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyLockOnExit) ?? true;
  }

  /// 检查设备是否支持生物识别
  Future<bool> canUseBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// 设置 PIN 码
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    await prefs.setString(_prefKeyPinHash, hash);
    await prefs.setBool(_prefKeyLockEnabled, true);
  }

  /// 验证 PIN 码
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_prefKeyPinHash);
    if (storedHash == null) return false;
    return _hashPin(pin) == storedHash;
  }

  /// 尝试生物识别认证
  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: '请验证身份以解锁积叶',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// 启用/禁用生物识别
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyBiometricEnabled, enabled);
  }

  /// 启用/禁用切后台锁定
  Future<void> setLockOnExit(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyLockOnExit, enabled);
  }

  /// 禁用应用锁（需要先验证 PIN）
  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyLockEnabled, false);
    await prefs.remove(_prefKeyPinHash);
    await prefs.setBool(_prefKeyBiometricEnabled, false);
  }

  /// 修改 PIN（需要先验证旧 PIN）
  Future<bool> changePin(String oldPin, String newPin) async {
    final verified = await verifyPin(oldPin);
    if (!verified) return false;
    await setPin(newPin);
    return true;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
