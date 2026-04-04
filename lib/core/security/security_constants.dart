/// 安全审计相关常量
class SecurityConstants {
  SecurityConstants._();

  /// 最大登录尝试次数
  static const int maxLoginAttempts = 5;

  /// 锁定时长（分钟）
  static const int lockoutDurationMinutes = 15;

  /// 会话超时时长（分钟）
  static const int sessionTimeoutMinutes = 30;

  /// PIN 码最小长度
  static const int minPinLength = 4;

  /// PIN 码最大长度
  static const int maxPinLength = 8;

  /// 用于检测敏感数据的正则表达式模式
  static final List<RegExp> sensitiveFieldPatterns = [
    // Credit card numbers (13-19 digits, optionally separated)
    RegExp(r'\b(?:\d[ -]*?){13,19}\b'),
    // Social Security Numbers (US format)
    RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),
    // Email addresses
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
    // Phone numbers (international / domestic)
    RegExp(r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}'),
    // Chinese ID card numbers (18 digits, last may be X)
    RegExp(r'\b\d{17}[\dXx]\b'),
    // Bank account / IBAN-like patterns
    RegExp(r'\b[A-Z]{2}\d{2}[A-Z0-9]{4}\d{7}([A-Z0-9]?){0,16}\b'),
    // API key-like strings (long hex or base64 tokens)
    RegExp(r'\b[A-Za-z0-9_-]{32,}\b'),
  ];
}
