import 'ocr_service.dart';

enum PaymentSource { wechat, alipay, unknown }

class ScreenshotParseResult {
  final double amount;
  final String? merchant;
  final DateTime? timestamp;
  final PaymentSource source;
  final String rawText;

  const ScreenshotParseResult({
    required this.amount,
    this.merchant,
    this.timestamp,
    required this.source,
    required this.rawText,
  });

  ScreenshotParseResult copyWith({
    double? amount,
    String? merchant,
    DateTime? timestamp,
    PaymentSource? source,
    String? rawText,
  }) {
    return ScreenshotParseResult(
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      rawText: rawText ?? this.rawText,
    );
  }
}

class ScreenshotOcrService {
  final OcrService _ocrService;

  ScreenshotOcrService({OcrService? ocrService})
      : _ocrService = ocrService ?? OcrService();

  /// Parse a payment screenshot and extract transaction data.
  Future<ScreenshotParseResult?> parsePaymentScreenshot(
    String imagePath,
  ) async {
    final rawText = await _ocrService.recognizeTextFromImagePath(imagePath);
    if (rawText.isEmpty) return null;

    final source = _detectSource(rawText);
    final amount = _extractAmount(rawText, source);
    if (amount == null) return null;

    final merchant = _extractMerchant(rawText, source);
    final timestamp = _extractTimestamp(rawText);

    return ScreenshotParseResult(
      amount: amount,
      merchant: merchant,
      timestamp: timestamp,
      source: source,
      rawText: rawText,
    );
  }

  PaymentSource _detectSource(String text) {
    // WeChat indicators
    if (RegExp(r'微信支付|付款给|微信红包').hasMatch(text)) {
      return PaymentSource.wechat;
    }
    // Alipay indicators
    if (RegExp(r'支付宝|花呗|余额宝').hasMatch(text)) {
      return PaymentSource.alipay;
    }
    return PaymentSource.unknown;
  }

  double? _extractAmount(String text, PaymentSource source) {
    // Try ¥ symbol first (WeChat style)
    final yenMatch = RegExp(r'[¥￥]\s*(\d+\.?\d*)').firstMatch(text);
    if (yenMatch != null) {
      return double.tryParse(yenMatch.group(1)!);
    }
    // Try bare number near payment keywords
    final amountMatch =
        RegExp(r'(?:金额|付款|支付|消费)\s*[:：]?\s*(\d+\.?\d*)').firstMatch(text);
    if (amountMatch != null) {
      return double.tryParse(amountMatch.group(1)!);
    }
    return null;
  }

  String? _extractMerchant(String text, PaymentSource source) {
    if (source == PaymentSource.wechat) {
      // "付款给XXX" pattern
      final m = RegExp(r'付款给\s*(.+)').firstMatch(text);
      if (m != null) return m.group(1)!.trim();
    }
    if (source == PaymentSource.alipay) {
      // "收款方 XXX" or "商户 XXX"
      final m = RegExp(r'(?:收款方|商户|商家)\s*[:：]?\s*(.+)').firstMatch(text);
      if (m != null) return m.group(1)!.trim();
    }
    // Generic merchant extraction
    final generic =
        RegExp(r'(?:收款方|商户|商家|对方)\s*[:：]?\s*(.+)').firstMatch(text);
    if (generic != null) return generic.group(1)!.trim();
    return null;
  }

  DateTime? _extractTimestamp(String text) {
    // "2024-03-15 14:30:00" or "2024/03/15 14:30"
    final full = RegExp(
      r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(text);
    if (full != null) {
      return DateTime.tryParse(
        '${full.group(1)}-${full.group(2)!.padLeft(2, '0')}-${full.group(3)!.padLeft(2, '0')} '
        '${full.group(4)!.padLeft(2, '0')}:${full.group(5)!.padLeft(2, '0')}:${(full.group(6) ?? '00').padLeft(2, '0')}',
      );
    }
    // Date only: "2024年3月15日"
    final cnDate =
        RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日').firstMatch(text);
    if (cnDate != null) {
      return DateTime.tryParse(
        '${cnDate.group(1)}-${cnDate.group(2)!.padLeft(2, '0')}-${cnDate.group(3)!.padLeft(2, '0')}',
      );
    }
    return null;
  }
}
