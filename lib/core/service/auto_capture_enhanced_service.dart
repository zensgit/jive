import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auto_rule_engine.dart';
import 'payment_notification_parser.dart';

/// Result from the enhanced capture pipeline.
class EnhancedCaptureResult {
  final bool captured;
  final bool duplicate;
  final PaymentNotification? notification;
  final String? categoryParent;
  final String? categorySub;

  const EnhancedCaptureResult({
    required this.captured,
    this.duplicate = false,
    this.notification,
    this.categoryParent,
    this.categorySub,
  });

  static const skipped = EnhancedCaptureResult(captured: false);
  static const deduped = EnhancedCaptureResult(captured: false, duplicate: true);
}

/// Statistics for auto-captured items.
class CaptureStats {
  final int today;
  final int thisWeek;
  final int thisMonth;

  const CaptureStats({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });

  static const zero = CaptureStats(today: 0, thisWeek: 0, thisMonth: 0);
}

/// Persisted record of a single captured notification.
class CaptureRecord {
  final double amount;
  final String type;
  final String source;
  final String? merchant;
  final String rawText;
  final DateTime timestamp;

  const CaptureRecord({
    required this.amount,
    required this.type,
    required this.source,
    this.merchant,
    required this.rawText,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'type': type,
        'source': source,
        'merchant': merchant,
        'rawText': rawText,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory CaptureRecord.fromJson(Map<String, dynamic> json) => CaptureRecord(
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        type: json['type'] as String? ?? 'expense',
        source: json['source'] as String? ?? 'unknown',
        merchant: json['merchant'] as String?,
        rawText: json['rawText'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int? ?? 0,
        ),
      );
}

/// Enhanced auto-capture service that routes notifications to the correct
/// parser, applies rule-engine category matching, deduplicates, and records
/// captures for later review.
class AutoCaptureEnhancedService {
  AutoCaptureEnhancedService();

  // ---- Deduplication state (in-memory, resets on restart) ----

  final List<_DedupeEntry> _recentEntries = [];
  static const _dedupeWindowMs = 2 * 60 * 1000; // 2 minutes

  // ---- Capture history (in-memory, max 50) ----

  final List<CaptureRecord> _captureHistory = [];
  static const _maxHistory = 50;

  // ---- SharedPreferences keys for per-source toggles ----

  static const _keyWeChatEnabled = 'auto_capture_wechat_enabled';
  static const _keyAlipayEnabled = 'auto_capture_alipay_enabled';
  static const _keyBankEnabled = 'auto_capture_bank_enabled';

  // ---------------------------------------------------------------------------
  // Core pipeline
  // ---------------------------------------------------------------------------

  /// Process an incoming notification.
  ///
  /// [packageName] is the Android package name that fired the notification.
  /// [text] is the notification body text.
  Future<EnhancedCaptureResult> processNotification(
    String packageName,
    String text,
  ) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return EnhancedCaptureResult.skipped;

    // Route to the correct parser based on package name.
    final notification = _routeToParser(packageName, trimmed);
    if (notification == null || !notification.isValid) {
      return EnhancedCaptureResult.skipped;
    }

    // Check per-source toggle.
    final sourceEnabled = await _isSourceEnabled(notification.source);
    if (!sourceEnabled) return EnhancedCaptureResult.skipped;

    // Deduplicate: same amount + same merchant within 2 minutes → skip.
    if (_isDuplicate(notification)) {
      debugPrint(
        '[AutoCaptureEnhanced] duplicate skipped: '
        '${notification.amount} ${notification.merchant}',
      );
      return EnhancedCaptureResult.deduped;
    }

    // Apply AutoRuleEngine for category.
    String? categoryParent;
    String? categorySub;
    try {
      final engine = await AutoRuleEngine.instance();
      final match = engine.match(text: trimmed, source: notification.sourceLabel);
      categoryParent = match.parent;
      categorySub = match.sub;
    } catch (e) {
      debugPrint('[AutoCaptureEnhanced] rule engine error: $e');
    }

    // Record capture.
    _recordCapture(notification);

    return EnhancedCaptureResult(
      captured: true,
      notification: notification,
      categoryParent: categoryParent,
      categorySub: categorySub,
    );
  }

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  PaymentNotification? _routeToParser(String packageName, String text) {
    final pkg = packageName.toLowerCase();
    if (pkg.contains('com.tencent.mm')) {
      return PaymentNotificationParser.parseWeChatNotification(text);
    }
    if (pkg.contains('com.eg.android.alipaygphone')) {
      return PaymentNotificationParser.parseAlipayNotification(text);
    }
    // Bank SMS or unknown — try all parsers.
    return PaymentNotificationParser.parse(text);
  }

  // ---------------------------------------------------------------------------
  // Deduplication
  // ---------------------------------------------------------------------------

  bool _isDuplicate(PaymentNotification notification) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Purge expired entries.
    _recentEntries.removeWhere((e) => now - e.timestampMs > _dedupeWindowMs);

    final isDupe = _recentEntries.any(
      (e) =>
          e.amount == notification.amount &&
          e.merchant == (notification.merchant ?? ''),
    );

    if (!isDupe) {
      _recentEntries.add(_DedupeEntry(
        amount: notification.amount,
        merchant: notification.merchant ?? '',
        timestampMs: now,
      ));
    }

    return isDupe;
  }

  // ---------------------------------------------------------------------------
  // Capture history
  // ---------------------------------------------------------------------------

  void _recordCapture(PaymentNotification notification) {
    final record = CaptureRecord(
      amount: notification.amount,
      type: notification.typeLabel,
      source: notification.sourceLabel,
      merchant: notification.merchant,
      rawText: notification.rawText,
      timestamp: notification.timestamp,
    );
    _captureHistory.insert(0, record);
    if (_captureHistory.length > _maxHistory) {
      _captureHistory.removeRange(_maxHistory, _captureHistory.length);
    }
  }

  /// Return the last [count] captured items.
  List<CaptureRecord> getRecentCaptures({int count = 20}) {
    final end = count.clamp(0, _captureHistory.length);
    return List.unmodifiable(_captureHistory.sublist(0, end));
  }

  /// Return capture statistics for today / this week / this month.
  CaptureStats getCaptureStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);

    int today = 0;
    int week = 0;
    int month = 0;
    for (final record in _captureHistory) {
      if (!record.timestamp.isBefore(monthStart)) month++;
      if (!record.timestamp.isBefore(weekStart)) week++;
      if (!record.timestamp.isBefore(todayStart)) today++;
    }
    return CaptureStats(today: today, thisWeek: week, thisMonth: month);
  }

  // ---------------------------------------------------------------------------
  // Per-source toggles
  // ---------------------------------------------------------------------------

  Future<bool> _isSourceEnabled(PaymentSource source) async {
    final prefs = await SharedPreferences.getInstance();
    switch (source) {
      case PaymentSource.wechat:
        return prefs.getBool(_keyWeChatEnabled) ?? true;
      case PaymentSource.alipay:
        return prefs.getBool(_keyAlipayEnabled) ?? true;
      case PaymentSource.bank:
        return prefs.getBool(_keyBankEnabled) ?? true;
      case PaymentSource.unknown:
        return true;
    }
  }

  static Future<bool> getSourceEnabled(PaymentSource source) async {
    final prefs = await SharedPreferences.getInstance();
    switch (source) {
      case PaymentSource.wechat:
        return prefs.getBool(_keyWeChatEnabled) ?? true;
      case PaymentSource.alipay:
        return prefs.getBool(_keyAlipayEnabled) ?? true;
      case PaymentSource.bank:
        return prefs.getBool(_keyBankEnabled) ?? true;
      case PaymentSource.unknown:
        return true;
    }
  }

  static Future<void> setSourceEnabled(
    PaymentSource source, {
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    switch (source) {
      case PaymentSource.wechat:
        await prefs.setBool(_keyWeChatEnabled, enabled);
      case PaymentSource.alipay:
        await prefs.setBool(_keyAlipayEnabled, enabled);
      case PaymentSource.bank:
        await prefs.setBool(_keyBankEnabled, enabled);
      case PaymentSource.unknown:
        break;
    }
  }
}

class _DedupeEntry {
  final double amount;
  final String merchant;
  final int timestampMs;

  const _DedupeEntry({
    required this.amount,
    required this.merchant,
    required this.timestampMs,
  });
}
