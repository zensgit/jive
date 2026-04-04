import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/dream_log_model.dart';
import '../../core/database/savings_goal_model.dart';
import '../../core/service/dream_service.dart';

const _kAccentGreen = Color(0xFF2E7D32);

Color _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return _kAccentGreen;
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

class DreamDetailScreen extends StatefulWidget {
  final int goalId;

  const DreamDetailScreen({super.key, required this.goalId});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  late final DreamService _dreamService;
  JiveSavingsGoal? _goal;
  GoalStats? _stats;
  List<JiveDreamLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final isar = Isar.getInstance()!;
    _dreamService = DreamService(isar);
    _load();
  }

  Future<void> _load() async {
    final isar = Isar.getInstance()!;
    final goal = await isar.jiveSavingsGoals.get(widget.goalId);
    if (goal == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final stats = await _dreamService.getGoalStats(widget.goalId);
    final logs = await _dreamService.getDepositHistory(widget.goalId);
    if (!mounted) return;
    setState(() {
      _goal = goal;
      _stats = stats;
      _logs = logs;
      _loading = false;
    });
  }

  double get _progress {
    final g = _goal;
    if (g == null || g.targetAmount <= 0) return 0;
    return (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
  }

  Color get _accent => _hexColor(_goal?.colorHex);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(
            child: CircularProgressIndicator(color: _kAccentGreen)),
      );
    }

    final goal = _goal!;
    final stats = _stats!;
    final fmt = NumberFormat('#,##0.00', 'zh_CN');
    final remaining = (goal.targetAmount - goal.currentAmount)
        .clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // ── App bar ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _accent,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroSection(
                goal: goal,
                progress: _progress,
                accent: _accent,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareProgress(goal, stats, fmt),
              ),
            ],
          ),

          // ── Stats row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  _StatTile(
                    label: '已存',
                    value: '\u00a5${fmt.format(goal.currentAmount)}',
                    color: _accent,
                  ),
                  _StatTile(
                    label: '目标',
                    value: '\u00a5${fmt.format(goal.targetAmount)}',
                    color: Colors.grey[700]!,
                  ),
                  _StatTile(
                    label: '剩余',
                    value: '\u00a5${fmt.format(remaining)}',
                    color: Colors.orange[700]!,
                  ),
                  _StatTile(
                    label: '预计完成',
                    value: stats.projectedCompletionDate != null
                        ? DateFormat('yyyy/MM')
                            .format(stats.projectedCompletionDate!)
                        : '--',
                    color: Colors.blue[700]!,
                  ),
                ],
              ),
            ),
          ),

          // ── Section header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '存款记录',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),

          // ── Deposit timeline ──
          if (_logs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    '还没有存款记录\n点击下方按钮开始存入',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.lato(fontSize: 14, color: Colors.grey[400]),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final log = _logs[index];
                  final isFirst = index == 0;
                  final isLast = index == _logs.length - 1;
                  return _TimelineItem(
                    log: log,
                    accent: _accent,
                    isFirst: isFirst,
                    isLast: isLast,
                  );
                },
                childCount: _logs.length,
              ),
            ),

          // Bottom padding so FAB doesn't obscure content.
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
      floatingActionButton: goal.status == 'active'
          ? FloatingActionButton.extended(
              onPressed: _showDepositDialog,
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text('存入', style: GoogleFonts.lato()),
            )
          : null,
    );
  }

  // ── Deposit dialog ──

  Future<void> _showDepositDialog() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text('存入金额', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco('金额 (\u00a5)'),
              style: GoogleFonts.lato(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: _inputDeco('备注（可选）'),
              style: GoogleFonts.lato(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('取消', style: GoogleFonts.lato(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效金额')),
                );
                return;
              }
              await _dreamService.addDeposit(
                goalId: widget.goalId,
                amount: amount,
                note: noteCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('确认', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
  }

  // ── Share progress ──

  Future<void> _shareProgress(
    JiveSavingsGoal goal,
    GoalStats stats,
    NumberFormat fmt,
  ) async {
    final pct = (_progress * 100).toStringAsFixed(1);
    final text = StringBuffer()
      ..writeln('${goal.emoji ?? "💰"} ${goal.name}')
      ..writeln('已存 \u00a5${fmt.format(goal.currentAmount)} '
          '/ \u00a5${fmt.format(goal.targetAmount)} ($pct%)')
      ..writeln('月均存入 \u00a5${fmt.format(stats.avgMonthlyDeposit)}');
    if (stats.projectedCompletionDate != null) {
      text.writeln(
          '预计完成 ${DateFormat("yyyy/MM").format(stats.projectedCompletionDate!)}');
    }
    text.writeln('—— 来自 Jive 记账');

    // Try share_plus first, fall back to clipboard.
    try {
      await SharePlus.instance.share(ShareParams(text: text.toString()));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制到剪贴板')),
        );
      }
    }
  }
}

// ── Hero section with progress ring ──

class _HeroSection extends StatelessWidget {
  final JiveSavingsGoal goal;
  final double progress;
  final Color accent;

  const _HeroSection({
    required this.goal,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent, accent.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // Progress ring
            SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _RingPainter(progress: progress, color: Colors.white),
                child: Center(
                  child: Text(
                    goal.emoji ?? '💰',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              goal.name,
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Circular progress ring painter ──

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ── Stat tile ──

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timeline item ──

class _TimelineItem extends StatelessWidget {
  final JiveDreamLog log;
  final Color accent;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.log,
    required this.accent,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'zh_CN');
    final dateFmt = DateFormat('MM/dd HH:mm');
    final isPositive = log.amount >= 0;

    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline column
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  if (!isFirst)
                    Expanded(child: Container(width: 2, color: Colors.grey[300]))
                  else
                    const Expanded(child: SizedBox()),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: Colors.grey[300]))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFmt.format(log.createdAt),
                              style: GoogleFonts.lato(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                            if (log.note.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                log.note,
                                style: GoogleFonts.lato(
                                    fontSize: 13, color: Colors.grey[800]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '${isPositive ? "+" : ""}${fmt.format(log.amount)}',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? accent : Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input decoration helper ──

InputDecoration _inputDeco(String label) => InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lato(color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kAccentGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
