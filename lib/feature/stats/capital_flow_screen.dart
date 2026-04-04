import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/capital_flow_service.dart';

/// Capital flow visualization: income sources -> pool -> expense categories.
class CapitalFlowScreen extends StatefulWidget {
  final int? bookId;
  const CapitalFlowScreen({super.key, this.bookId});

  @override
  State<CapitalFlowScreen> createState() => _CapitalFlowScreenState();
}

class _CapitalFlowScreenState extends State<CapitalFlowScreen> {
  bool _isLoading = true;
  CapitalFlowData? _data;
  int _months = 3;
  String? _tappedLabel;
  double? _tappedAmount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final service = await CapitalFlowService.create();
    final data =
        await service.getCapitalFlow(_months, bookId: widget.bookId);
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
        _tappedLabel = null;
        _tappedAmount = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final data = _data;
    if (data == null) return const Center(child: Text('无数据'));

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with period selector
          Row(
            children: [
              Text('资金流向',
                  style: GoogleFonts.lato(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1月')),
                  ButtonSegment(value: 3, label: Text('3月')),
                  ButtonSegment(value: 6, label: Text('6月')),
                ],
                selected: {_months},
                onSelectionChanged: (s) {
                  _months = s.first;
                  _load();
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    GoogleFonts.lato(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '最近 $_months 个月资金来源与去向',
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Summary cards
          _buildSummaryRow(data, theme),
          const SizedBox(height: 20),

          // Flow diagram
          if (data.totalIncome > 0 || data.totalExpense > 0)
            _buildFlowDiagram(data, theme),

          // Tapped detail tooltip
          if (_tappedLabel != null) ...[
            const SizedBox(height: 12),
            _buildTappedDetail(theme),
          ],

          // Transfer section
          if (data.transferFlows.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildTransferSection(data, theme),
          ],
        ],
      ),
    );
  }

  // ── Summary cards ──

  Widget _buildSummaryRow(CapitalFlowData data, ThemeData theme) {
    final fmt = NumberFormat('#,##0.00');
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            '收入',
            fmt.format(data.totalIncome),
            const Color(0xFF388E3C),
            theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            '支出',
            fmt.format(data.totalExpense),
            const Color(0xFFD32F2F),
            theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            '净流入',
            fmt.format(data.netFlow),
            data.netFlow >= 0
                ? const Color(0xFF388E3C)
                : const Color(0xFFD32F2F),
            theme,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text('¥$value',
                style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }

  // ── Flow diagram ──

  Widget _buildFlowDiagram(CapitalFlowData data, ThemeData theme) {
    // Sort entries by amount descending, take top items
    final incomeEntries = data.incomeBySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final expenseEntries = data.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topIncome = incomeEntries.take(8).toList();
    final topExpense = expenseEntries.take(8).toList();

    final maxRows = math.max(topIncome.length, topExpense.length);
    final diagramHeight = math.max(maxRows * 44.0 + 40, 200.0);

    return SizedBox(
      height: diagramHeight,
      child: CustomPaint(
        painter: _FlowDiagramPainter(
          incomeEntries: topIncome,
          expenseEntries: topExpense,
          totalIncome: data.totalIncome,
          totalExpense: data.totalExpense,
          onTap: null, // painting only; taps handled via GestureDetector
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            _handleTap(details.localPosition, topIncome, topExpense,
                diagramHeight);
          },
        ),
      ),
    );
  }

  void _handleTap(
    Offset position,
    List<MapEntry<String, double>> incomeEntries,
    List<MapEntry<String, double>> expenseEntries,
    double height,
  ) {
    // Check income bars (left side)
    final barHeight = 32.0;
    final barSpacing = 44.0;
    final topPadding = 20.0;

    for (int i = 0; i < incomeEntries.length; i++) {
      final y = topPadding + i * barSpacing;
      if (position.dx < 120 &&
          position.dy >= y &&
          position.dy <= y + barHeight) {
        setState(() {
          _tappedLabel = incomeEntries[i].key;
          _tappedAmount = incomeEntries[i].value;
        });
        return;
      }
    }

    // Check expense bars (right side, approximate)
    final screenWidth =
        (context.findRenderObject() as RenderBox?)?.size.width ?? 400;
    for (int i = 0; i < expenseEntries.length; i++) {
      final y = topPadding + i * barSpacing;
      if (position.dx > screenWidth - 152 &&
          position.dy >= y &&
          position.dy <= y + barHeight) {
        setState(() {
          _tappedLabel = expenseEntries[i].key;
          _tappedAmount = expenseEntries[i].value;
        });
        return;
      }
    }

    // Tap on center pool
    if (position.dx > 120 && position.dx < screenWidth - 152) {
      setState(() {
        _tappedLabel = null;
        _tappedAmount = null;
      });
    }
  }

  Widget _buildTappedDetail(ThemeData theme) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$_tappedLabel: ¥${fmt.format(_tappedAmount ?? 0)}',
            style: GoogleFonts.lato(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Transfers section ──

  Widget _buildTransferSection(CapitalFlowData data, ThemeData theme) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('账户间转账',
              style:
                  GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...data.transferFlows.take(10).map((flow) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(flow.fromAccount,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(flow.toAccount,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('¥${fmt.format(flow.amount)}',
                      style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Custom Painter ──

class _FlowDiagramPainter extends CustomPainter {
  final List<MapEntry<String, double>> incomeEntries;
  final List<MapEntry<String, double>> expenseEntries;
  final double totalIncome;
  final double totalExpense;
  final VoidCallback? onTap;

  _FlowDiagramPainter({
    required this.incomeEntries,
    required this.expenseEntries,
    required this.totalIncome,
    required this.totalExpense,
    this.onTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barHeight = 32.0;
    const barSpacing = 44.0;
    const topPadding = 20.0;
    const labelWidth = 60.0;
    const barMaxWidth = 60.0;
    const centerPoolWidth = 50.0;

    final centerX = size.width / 2;
    final poolLeft = centerX - centerPoolWidth / 2;
    final poolRight = centerX + centerPoolWidth / 2;

    final incomeBarLeft = labelWidth;
    final expenseBarRight = size.width - labelWidth;

    final fmt = NumberFormat.compact(locale: 'zh');

    // Draw center pool
    final poolTop = topPadding;
    final maxRows = math.max(incomeEntries.length, expenseEntries.length);
    final poolBottom = topPadding + maxRows * barSpacing;
    final poolRect =
        RRect.fromLTRBR(poolLeft, poolTop, poolRight, poolBottom,
            const Radius.circular(8));
    final poolPaint = Paint()
      ..color = const Color(0xFF546E7A).withValues(alpha: 0.15);
    canvas.drawRRect(poolRect, poolPaint);

    // Pool label
    final poolLabelPainter = TextPainter(
      text: TextSpan(
        text: '资金池',
        style: TextStyle(
          fontSize: 11,
          color: const Color(0xFF546E7A).withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    poolLabelPainter.paint(
      canvas,
      Offset(centerX - poolLabelPainter.width / 2, poolTop + 4),
    );

    // Draw income bars (left side) with flow lines to center
    for (int i = 0; i < incomeEntries.length; i++) {
      final entry = incomeEntries[i];
      final fraction =
          totalIncome > 0 ? (entry.value / totalIncome) : 0.0;
      final barW = barMaxWidth * fraction.clamp(0.15, 1.0);
      final y = topPadding + i * barSpacing;

      // Bar
      final barRect = RRect.fromLTRBR(
          incomeBarLeft, y, incomeBarLeft + barW, y + barHeight,
          const Radius.circular(4));
      final barPaint = Paint()
        ..color = const Color(0xFF388E3C)
            .withValues(alpha: 0.3 + 0.7 * fraction);
      canvas.drawRRect(barRect, barPaint);

      // Label (left of bar)
      final label = entry.key.length > 4
          ? '${entry.key.substring(0, 4)}..'
          : entry.key;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF424242)),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(incomeBarLeft - labelPainter.width - 4,
            y + (barHeight - labelPainter.height) / 2),
      );

      // Amount on bar
      final amountPainter = TextPainter(
        text: TextSpan(
          text: fmt.format(entry.value),
          style: const TextStyle(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      if (amountPainter.width < barW - 4) {
        amountPainter.paint(
          canvas,
          Offset(incomeBarLeft + (barW - amountPainter.width) / 2,
              y + (barHeight - amountPainter.height) / 2),
        );
      }

      // Flow line: bar right edge -> pool left
      final flowPaint = Paint()
        ..color =
            const Color(0xFF388E3C).withValues(alpha: 0.15 + 0.35 * fraction)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 4 * fraction;

      final barRight = incomeBarLeft + barW;
      final barCenterY = y + barHeight / 2;
      final poolY = poolTop +
          (poolBottom - poolTop) *
              (i + 0.5) /
              math.max(incomeEntries.length, 1);

      final path = Path()
        ..moveTo(barRight, barCenterY)
        ..cubicTo(
          barRight + (poolLeft - barRight) * 0.5,
          barCenterY,
          poolLeft - (poolLeft - barRight) * 0.5,
          poolY,
          poolLeft,
          poolY,
        );
      canvas.drawPath(path, flowPaint);
    }

    // Draw expense bars (right side) with flow lines from center
    for (int i = 0; i < expenseEntries.length; i++) {
      final entry = expenseEntries[i];
      final fraction =
          totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
      final barW = barMaxWidth * fraction.clamp(0.15, 1.0);
      final y = topPadding + i * barSpacing;

      // Bar
      final barRect = RRect.fromLTRBR(
          expenseBarRight - barW, y, expenseBarRight, y + barHeight,
          const Radius.circular(4));
      final barPaint = Paint()
        ..color = const Color(0xFFD32F2F)
            .withValues(alpha: 0.3 + 0.7 * fraction);
      canvas.drawRRect(barRect, barPaint);

      // Label (right of bar)
      final label = entry.key.length > 4
          ? '${entry.key.substring(0, 4)}..'
          : entry.key;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF424242)),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(expenseBarRight + 4,
            y + (barHeight - labelPainter.height) / 2),
      );

      // Amount on bar
      final amountPainter = TextPainter(
        text: TextSpan(
          text: fmt.format(entry.value),
          style: const TextStyle(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      if (amountPainter.width < barW - 4) {
        amountPainter.paint(
          canvas,
          Offset(
              expenseBarRight - barW + (barW - amountPainter.width) / 2,
              y + (barHeight - amountPainter.height) / 2),
        );
      }

      // Flow line: pool right -> bar left edge
      final flowPaint = Paint()
        ..color =
            const Color(0xFFD32F2F).withValues(alpha: 0.15 + 0.35 * fraction)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 4 * fraction;

      final barLeft = expenseBarRight - barW;
      final barCenterY = y + barHeight / 2;
      final poolY = poolTop +
          (poolBottom - poolTop) *
              (i + 0.5) /
              math.max(expenseEntries.length, 1);

      final path = Path()
        ..moveTo(poolRight, poolY)
        ..cubicTo(
          poolRight + (barLeft - poolRight) * 0.5,
          poolY,
          barLeft - (barLeft - poolRight) * 0.5,
          barCenterY,
          barLeft,
          barCenterY,
        );
      canvas.drawPath(path, flowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowDiagramPainter oldDelegate) {
    return oldDelegate.incomeEntries != incomeEntries ||
        oldDelegate.expenseEntries != expenseEntries;
  }
}
