import 'dart:io';

import 'package:flutter/services.dart';

/// 安全服务 - 提供截屏保护、越狱检测、输入清理和敏感数据脱敏
class SecurityService {
  static const _channel = MethodChannel('com.jive.app/security');

  // ---------------------------------------------------------------------------
  // Screenshot protection (Android FLAG_SECURE)
  // ---------------------------------------------------------------------------

  /// 启用截屏保护 — 在 Android 上设置 FLAG_SECURE。
  /// NOTE: Android 端 MethodChannel handler 尚未实现，后续补充。
  Future<void> enableScreenshotProtection() async {
    try {
      await _channel.invokeMethod<void>('enableScreenshotProtection');
    } on MissingPluginException {
      // Native handler not yet registered — silently ignore.
    }
  }

  /// 禁用截屏保护 — 在 Android 上移除 FLAG_SECURE。
  Future<void> disableScreenshotProtection() async {
    try {
      await _channel.invokeMethod<void>('disableScreenshotProtection');
    } on MissingPluginException {
      // Native handler not yet registered — silently ignore.
    }
  }

  // ---------------------------------------------------------------------------
  // Jailbreak / root detection
  // ---------------------------------------------------------------------------

  /// 基础越狱/root 检测。
  /// 在非移动平台上直接返回 false。
  bool isJailbroken() {
    // TODO: Enhance with more comprehensive checks (Cydia URL scheme,
    //       dyld image inspection, sandbox integrity, etc.)
    if (Platform.isIOS) {
      return _checkiOSJailbreak();
    } else if (Platform.isAndroid) {
      return _checkAndroidRoot();
    }
    // TODO: Add detection for other platforms if needed.
    return false;
  }

  bool _checkiOSJailbreak() {
    const suspiciousPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
    ];
    for (final path in suspiciousPaths) {
      if (File(path).existsSync()) return true;
    }
    return false;
  }

  bool _checkAndroidRoot() {
    const suspiciousPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
    ];
    for (final path in suspiciousPaths) {
      if (File(path).existsSync()) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Input sanitization
  // ---------------------------------------------------------------------------

  /// 清理用户输入，去除潜在的 XSS / 注入模式。
  String sanitizeInput(String input) {
    var sanitized = input;

    // Strip <script> tags (with content)
    sanitized =
        sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');

    // Strip remaining HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]+>'), '');

    // Remove javascript: protocol
    sanitized = sanitized.replaceAll(RegExp(r'javascript\s*:', caseSensitive: false), '');

    // Remove on-event handlers (onerror=, onclick=, etc.)
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // Strip suspicious SQL injection patterns
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(DROP|DELETE|INSERT|UPDATE|ALTER)\s+(TABLE|FROM|INTO|DATABASE)\b', caseSensitive: false),
      '',
    );

    // Remove stray semicolons that could terminate SQL statements
    sanitized = sanitized.replaceAll(RegExp(r';\s*--'), '');

    return sanitized.trim();
  }

  // ---------------------------------------------------------------------------
  // Sensitive data masking
  // ---------------------------------------------------------------------------

  /// 脱敏显示信用卡号（仅保留末4位）。
  /// 例如 "4111111111111111" → "**** **** **** 1111"
  String maskSensitiveData(String data) {
    // Credit card numbers (13-19 digits, possibly with spaces/dashes)
    final ccPattern = RegExp(r'\b(\d[ -]*?){13,19}\b');
    var masked = data.replaceAllMapped(ccPattern, (match) {
      final digits = match.group(0)!.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length < 4) return match.group(0)!;
      final lastFour = digits.substring(digits.length - 4);
      return '**** **** **** $lastFour';
    });

    // Phone numbers (various formats, 7-15 digits with optional separators)
    final phonePattern = RegExp(r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}');
    masked = masked.replaceAllMapped(phonePattern, (match) {
      final digits = match.group(0)!.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length < 7) return match.group(0)!;
      final lastFour = digits.substring(digits.length - 4);
      return '***-***-$lastFour';
    });

    return masked;
  }

  // ---------------------------------------------------------------------------
  // API key configuration validation
  // ---------------------------------------------------------------------------

  /// 验证 Supabase URL 和 Key 是否通过 dart-define 配置（非硬编码）。
  /// 返回诊断消息列表；空列表表示配置正常。
  List<String> validateApiKeyConfiguration() {
    final issues = <String>[];

    // These should be injected via --dart-define at build time.
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty) {
      issues.add('SUPABASE_URL is not configured via --dart-define.');
    }
    if (supabaseKey.isEmpty) {
      issues.add('SUPABASE_ANON_KEY is not configured via --dart-define.');
    }

    return issues;
  }
}
