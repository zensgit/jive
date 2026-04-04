import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 手势图案锁服务 — 管理图案的存储、验证、失败计数与锁定
class GestureLockService {
  static const _prefKeyPatternHash = 'gesture_lock_pattern_hash';
  static const _prefKeyFailedAttempts = 'gesture_lock_failed_attempts';
  static const _prefKeyLockoutUntil = 'gesture_lock_lockout_until';

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  /// 保存手势图案（SHA-256 哈希后存储）
  Future<void> savePattern(List<int> pattern) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPattern(pattern);
    await prefs.setString(_prefKeyPatternHash, hash);
    await _resetFailedAttempts();
  }

  /// 验证手势图案是否正确
  Future<bool> verifyPattern(List<int> pattern) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_prefKeyPatternHash);
    if (storedHash == null) return false;
    return _hashPattern(pattern) == storedHash;
  }

  /// 检查是否已设置手势图案
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyPatternHash) != null;
  }

  /// 清除手势图案及相关数据
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyPatternHash);
    await prefs.remove(_prefKeyFailedAttempts);
    await prefs.remove(_prefKeyLockoutUntil);
  }

  /// 获取当前失败次数
  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyFailedAttempts) ?? 0;
  }

  /// 增加失败次数，达到上限时自动锁定
  Future<void> incrementFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_prefKeyFailedAttempts) ?? 0;
    final next = current + 1;
    await prefs.setInt(_prefKeyFailedAttempts, next);
    if (next >= maxAttempts) {
      final until = DateTime.now().add(lockoutDuration).millisecondsSinceEpoch;
      await prefs.setInt(_prefKeyLockoutUntil, until);
    }
  }

  /// 检查当前是否处于锁定状态
  Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_prefKeyLockoutUntil);
    if (until == null) return false;
    if (DateTime.now().millisecondsSinceEpoch < until) return true;
    // 锁定已过期，自动清除
    await _resetFailedAttempts();
    return false;
  }

  /// 获取锁定剩余时间
  Future<Duration> getLockoutRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_prefKeyLockoutUntil);
    if (until == null) return Duration.zero;
    final remaining = until - DateTime.now().millisecondsSinceEpoch;
    return remaining > 0 ? Duration(milliseconds: remaining) : Duration.zero;
  }

  Future<void> _resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyFailedAttempts);
    await prefs.remove(_prefKeyLockoutUntil);
  }

  String _hashPattern(List<int> pattern) {
    final raw = pattern.join('-');
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }
}
