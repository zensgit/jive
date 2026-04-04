import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 数据加密服务 - 提供哈希、令牌生成和金额脱敏功能
class DataEncryptionService {
  /// 使用 SHA-256 对 PIN 码进行哈希，用于安全存储。
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证用户输入的 PIN 是否与已存储的哈希匹配。
  bool verifyPin(String input, String storedHash) {
    final inputHash = hashPin(input);
    // Constant-time comparison to mitigate timing attacks.
    if (inputHash.length != storedHash.length) return false;
    var result = 0;
    for (var i = 0; i < inputHash.length; i++) {
      result |= inputHash.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return result == 0;
  }

  /// 生成指定长度的安全随机字母数字令牌。
  String generateSecureToken(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 对金额进行脱敏处理，用于敏感显示场景。
  ///
  /// [partial] 为 true 时显示部分信息（如 "¥**2.50"），
  /// 否则完全隐藏为 "***"。
  String obfuscateAmount(double amount, {bool partial = false}) {
    if (!partial) return '***';

    // Show only the decimal portion for partial obfuscation.
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';

    if (intPart.length <= 1) {
      return '**$intPart.$decPart';
    }
    final masked = '*' * (intPart.length - 1) + intPart[intPart.length - 1];
    return '$masked.$decPart';
  }
}
