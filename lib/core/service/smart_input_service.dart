import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SmartInputResult {
  final double? amount;
  final String? description;
  final DateTime? date;
  final String source;
  final String rawText;

  SmartInputResult({
    required this.rawText,
    required this.source,
    this.amount,
    this.description,
    this.date,
  });

  bool get hasData => amount != null || (description != null && description!.trim().isNotEmpty);

  String toSpeechText() {
    final buffer = StringBuffer();
    final desc = description?.trim();
    if (desc != null && desc.isNotEmpty) {
      buffer.write(desc);
      buffer.write(' ');
    }
    if (amount != null) {
      final normalized = amount!.toStringAsFixed(amount == amount!.roundToDouble() ? 0 : 2);
      buffer.write('$normalized 元');
    }
    return buffer.toString().trim();
  }
}

class SmartTextParser {
  static final _alipayPattern = RegExp(r'支付宝.*付款-?(¥|￥)?\s*([0-9,.]+)', caseSensitive: false);
  static final _wechatPattern = RegExp(r'微信支付.*付款-?(¥|￥)?\s*([0-9,.]+)', caseSensitive: false);
  static final _amountPattern = RegExp(r'(¥|￥|CNY)?\s*([0-9,.]+)\s*(元)?', caseSensitive: false);
  static final _datePattern = RegExp(r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})');

  static SmartInputResult? parse(String text, {String source = 'text'}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    double? amount;
    String? description;
    DateTime? date;

    final alipayMatch = _alipayPattern.firstMatch(trimmed);
    if (alipayMatch != null) {
      amount = _parseAmount(alipayMatch.group(2));
      description = '支付宝付款';
    }

    if (amount == null) {
      final wechatMatch = _wechatPattern.firstMatch(trimmed);
      if (wechatMatch != null) {
        amount = _parseAmount(wechatMatch.group(2));
        description = '微信支付';
      }
    }

    if (amount == null) {
      final amountMatch = _amountPattern.firstMatch(trimmed);
      if (amountMatch != null) {
        amount = _parseAmount(amountMatch.group(2));
      }
    }

    final dateMatch = _datePattern.firstMatch(trimmed);
    if (dateMatch != null) {
      try {
        date = DateTime(
          int.parse(dateMatch.group(1)!),
          int.parse(dateMatch.group(2)!),
          int.parse(dateMatch.group(3)!),
        );
      } catch (e) { debugPrint('Failed to parse date from input: $e'); }
    }

    if (description == null) {
      final lines = trimmed.split('\n');
      if (lines.isNotEmpty) {
        final firstLine = lines.first.trim();
        if (firstLine.length < 20 && !firstLine.contains(RegExp(r'[0-9]'))) {
          description = firstLine;
        } else {
          final voiceMatch = RegExp(r'(.*)(花了|支付了|用掉)(.*)').firstMatch(trimmed);
          if (voiceMatch != null) {
            description = voiceMatch.group(1)?.trim();
          }
        }
      }
    }

    if (amount == null && (description == null || description.isEmpty)) {
      return null;
    }

    return SmartInputResult(
      rawText: trimmed,
      source: source,
      amount: amount,
      description: description,
      date: date,
    );
  }

  static double? _parseAmount(String? str) {
    if (str == null) return null;
    final cleanStr = str.replaceAll(',', '');
    return double.tryParse(cleanStr);
  }
}

class ClipboardParser {
  Future<SmartInputResult?> parseClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return SmartTextParser.parse(text, source: 'clipboard');
  }
}
