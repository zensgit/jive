import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/stats_aggregation_service.dart';

/// Spending heatmap: shows expense intensity by weekday × hour.
class SpendingHeatmapScreen extends StatefulWidget {
  final int? bookId;
  const SpendingHeatmapScreen({super.key, this.bookId});

  @override
  State<SpendingHeatmapScreen> createState() => _SpendingHeatmapScreenState();
}

class _SpendingHeatmapScreenState extends State<SpendingHeatmapScreen> {
  bool _isLoading = true;
  SpendingHeatmap? _heatmap;
  int _months = 3;

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];
  static const _hourLabels = ['0', '', '', '3', '', '', '6', '', '', '9', '', '', '12', '', '', '15', '', '', '18', '', '', '21', '', ''];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final service = await StatsAggregationService.create();
    final heatmap = await service.getSpendingHeatmap(_months, bookId: widget.bookId);
    if (mounted) {
      setState(() {
        _heatmap = heatmap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final heatmap = _heatmap;
    if (heatmap == null) return const Center(child: Text('无数据'));

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Row(
            children: [
              Text('消费热力图', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 8),
          Text(
            '最近 $_months 个月的支出分布',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Heatmap grid
          _buildHeatmapGrid(heatmap, theme),
          const SizedBox(height: 16),

          // Legend
          _buildLegend(theme),
          const SizedBox(height: 24),

          // Insights
          _buildInsights(heatmap, theme),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid(SpendingHeatmap heatmap, ThemeData theme) {
    // Calculate cell size to fit screen width
    final screenWidth = MediaQuery.of(context).size.width - 32 - 24; // padding + label
    const gap = 2.0;
    final cellSize = ((screenWidth - 24 * gap) / 24).floorToDouble().clamp(8.0, 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour labels row
        Row(
          children: [
            const SizedBox(width: 24), // weekday label space
            ...List.generate(24, (h) {
              return SizedBox(
                width: cellSize + gap,
                child: Text(
                  _hourLabels[h],
                  style: TextStyle(fontSize: 8, color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 2),
        // Grid rows (one per weekday)
        ...List.generate(7, (day) {
          return Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  _weekdayLabels[day],
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              ...List.generate(24, (hour) {
                final intensity = heatmap.intensity(day, hour);
                return Tooltip(
                  message: '${_weekdayLabels[day]} $hour时: ¥${NumberFormat('#,##0').format(heatmap.get(day, hour))}',
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(gap / 2),
                    decoration: BoxDecoration(
                      color: _intensityColor(intensity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Color _intensityColor(double intensity) {
    if (intensity <= 0) return Colors.grey.shade100;
    if (intensity < 0.25) return JiveTheme.primaryGreen.withValues(alpha: 0.2);
    if (intensity < 0.5) return JiveTheme.primaryGreen.withValues(alpha: 0.4);
    if (intensity < 0.75) return JiveTheme.primaryGreen.withValues(alpha: 0.7);
    return JiveTheme.primaryGreen;
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('少', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        _legendCell(Colors.grey.shade100),
        _legendCell(JiveTheme.primaryGreen.withValues(alpha: 0.2)),
        _legendCell(JiveTheme.primaryGreen.withValues(alpha: 0.4)),
        _legendCell(JiveTheme.primaryGreen.withValues(alpha: 0.7)),
        _legendCell(JiveTheme.primaryGreen),
        const SizedBox(width: 6),
        Text('多', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _legendCell(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildInsights(SpendingHeatmap heatmap, ThemeData theme) {
    // Find peak spending time
    var peakDay = 0, peakHour = 0;
    var peakAmount = 0.0;
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        if (heatmap.get(d, h) > peakAmount) {
          peakAmount = heatmap.get(d, h);
          peakDay = d;
          peakHour = h;
        }
      }
    }

    // Weekend vs weekday total
    var weekdayTotal = 0.0, weekendTotal = 0.0;
    for (var d = 0; d < 7; d++) {
      final dayTotal = List.generate(24, (h) => heatmap.get(d, h)).fold<double>(0, (a, b) => a + b);
      if (d < 5) {
        weekdayTotal += dayTotal;
      } else {
        weekendTotal += dayTotal;
      }
    }

    if (peakAmount <= 0) return const SizedBox.shrink();

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
          Text('消费洞察', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _insightRow(
            Icons.local_fire_department,
            '消费高峰',
            '${_weekdayLabels[peakDay]}周 $peakHour:00 - ${peakHour + 1}:00',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _insightRow(
            Icons.calendar_today,
            '工作日 vs 周末',
            '工作日 ¥${NumberFormat.compact().format(weekdayTotal)} / 周末 ¥${NumberFormat.compact().format(weekendTotal)}',
            JiveTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _insightRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }
}
