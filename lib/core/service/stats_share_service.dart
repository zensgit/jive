import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/currency_model.dart';
import 'stats_aggregation_service.dart';

class StatsShareService {
  final StatsAggregationService _statsService;

  StatsShareService(this._statsService);

  static Future<StatsShareService> create() async {
    final stats = await StatsAggregationService.create();
    return StatsShareService(stats);
  }

  /// Generate a 600x800 branded PNG card for the given month.
  Future<Uint8List> generateMonthlyShareImage(
    DateTime month, {
    String? currencyCode,
    int? bookId,
  }) async {
    final currency = currencyCode ?? 'CNY';
    final symbol = CurrencyDefaults.getSymbol(currency);
    final summary = await _statsService.getMonthSummary(
      month,
      currencyCode: currency,
      bookId: bookId,
    );
    final categories = await _statsService.getCategoryBreakdown(
      month,
      isExpense: true,
      currencyCode: currency,
      bookId: bookId,
    );
    final topCategories = categories.take(5).toList();

    const double width = 600;
    const double height = 800;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      ).createShader(const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(24),
      ),
      bgPaint,
    );

    double y = 40;

    // Header: "Jive 积叶"
    _drawText(canvas, 'Jive 积叶', 0, y, width,
        fontSize: 28,
        color: const Color(0xFFE0E0E0),
        fontWeight: FontWeight.bold,
        align: TextAlign.center);
    y += 48;

    // Month label
    final monthLabel = DateFormat('yyyy年M月').format(month);
    _drawText(canvas, monthLabel, 0, y, width,
        fontSize: 20,
        color: const Color(0xFF90CAF9),
        align: TextAlign.center);
    y += 50;

    // Divider
    final dividerPaint = Paint()
      ..color = const Color(0xFF3A3A5C)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(40, y), Offset(width - 40, y), dividerPaint);
    y += 24;

    // Income / Expense / Balance
    final fmt = NumberFormat('#,##0.00');

    _drawText(canvas, '收入', 40, y, 200,
        fontSize: 14, color: const Color(0xFF81C784));
    _drawText(canvas, '$symbol${fmt.format(summary.totalIncome)}', 200, y, 360,
        fontSize: 18,
        color: const Color(0xFF81C784),
        fontWeight: FontWeight.bold,
        align: TextAlign.right);
    y += 36;

    _drawText(canvas, '支出', 40, y, 200,
        fontSize: 14, color: const Color(0xFFE57373));
    _drawText(
        canvas, '$symbol${fmt.format(summary.totalExpense)}', 200, y, 360,
        fontSize: 18,
        color: const Color(0xFFE57373),
        fontWeight: FontWeight.bold,
        align: TextAlign.right);
    y += 36;

    _drawText(canvas, '结余', 40, y, 200,
        fontSize: 14, color: const Color(0xFF90CAF9));
    _drawText(canvas, '$symbol${fmt.format(summary.balance)}', 200, y, 360,
        fontSize: 18,
        color: summary.balance >= 0
            ? const Color(0xFF81C784)
            : const Color(0xFFE57373),
        fontWeight: FontWeight.bold,
        align: TextAlign.right);
    y += 50;

    // Divider
    canvas.drawLine(Offset(40, y), Offset(width - 40, y), dividerPaint);
    y += 24;

    // Top 5 categories header
    _drawText(canvas, '支出 TOP 5', 40, y, 520,
        fontSize: 16,
        color: const Color(0xFFE0E0E0),
        fontWeight: FontWeight.bold);
    y += 36;

    final barColors = [
      const Color(0xFF64B5F6),
      const Color(0xFF81C784),
      const Color(0xFFFFB74D),
      const Color(0xFFBA68C8),
      const Color(0xFF4DD0E1),
    ];

    final maxAmount =
        topCategories.isNotEmpty ? topCategories.first.amount : 1.0;

    for (int i = 0; i < topCategories.length; i++) {
      final cat = topCategories[i];
      final barColor = barColors[i % barColors.length];

      // Category name
      _drawText(canvas, cat.name, 40, y, 140,
          fontSize: 13, color: const Color(0xFFBDBDBD));

      // Bar
      final barMaxWidth = 280.0;
      final barWidth =
          maxAmount > 0 ? (cat.amount / maxAmount) * barMaxWidth : 0.0;
      final barPaint = Paint()..color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(180, y + 2, barWidth, 16),
          const Radius.circular(4),
        ),
        barPaint,
      );

      // Amount
      _drawText(
          canvas, '$symbol${fmt.format(cat.amount)}', 470, y, 90,
          fontSize: 12,
          color: const Color(0xFFBDBDBD),
          align: TextAlign.right);

      y += 34;
    }

    // If fewer than 5 categories, pad spacing
    if (topCategories.length < 5) {
      y += (5 - topCategories.length) * 34;
    }

    y = height - 50;
    // Footer
    _drawText(canvas, '— Generated by Jive 积叶 —', 0, y, width,
        fontSize: 12,
        color: const Color(0xFF616161),
        align: TextAlign.center);

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(width.toInt(), height.toInt());
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw Exception('Failed to encode share image');
    }
    return byteData.buffer.asUint8List();
  }

  /// Write PNG to temp file and share via share_plus.
  Future<void> shareMonthlyStats(
    DateTime month, {
    String? currencyCode,
    int? bookId,
  }) async {
    final png = await generateMonthlyShareImage(
      month,
      currencyCode: currencyCode,
      bookId: bookId,
    );
    final dir = await getTemporaryDirectory();
    final monthStr = DateFormat('yyyy-MM').format(month);
    final file = File('${dir.path}/jive_stats_$monthStr.png');
    await file.writeAsBytes(png);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Jive 积叶 $monthStr 月度统计',
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double maxWidth, {
    double fontSize = 14,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign align = TextAlign.left,
  }) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: align,
      fontSize: fontSize,
      fontWeight: fontWeight,
    ))
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize))
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, Offset(x, y));
  }
}
