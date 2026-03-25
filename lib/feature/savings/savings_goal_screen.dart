import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/database/savings_goal_model.dart';

const _kAccentGreen = Color(0xFF2E7D32);
const _kColorPalette = [
  '#2E7D32',
  '#0277BD',
  '#E65100',
  '#6A1B9A',
  '#C62828',
  '#00695C',
  '#AD1457',
  '#F57F17',
];

const _kEmojis = ['🏖️', '🏠', '🚗', '🎓', '💍', '🎮', '💰', '📱', '🌏', '✈️'];

Color _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return _kAccentGreen;
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<JiveSavingsGoal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final isar = Isar.getInstance()!;
    final goals = await isar.jiveSavingsGoals.where().findAll();
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _loading = false;
    });
  }

  List<JiveSavingsGoal> get _activeGoals =>
      _goals.where((g) => g.status == 'active').toList();

  List<JiveSavingsGoal> get _achievedGoals =>
      _goals.where((g) => g.status == 'achieved').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '储蓄目标',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.grey[900],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _kAccentGreen),
            onPressed: () => _showGoalDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kAccentGreen,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: _kAccentGreen,
          labelStyle: GoogleFonts.lato(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '进行中'),
            Tab(text: '已达成'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kAccentGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _GoalList(
                  goals: _activeGoals,
                  onDeposit: _deposit,
                  onMarkAchieved: _markAchieved,
                  onEdit: (g) => _showGoalDialog(goal: g),
                  onDelete: _delete,
                ),
                _GoalList(
                  goals: _achievedGoals,
                  onDeposit: _deposit,
                  onMarkAchieved: _markAchieved,
                  onEdit: (g) => _showGoalDialog(goal: g),
                  onDelete: _delete,
                ),
              ],
            ),
    );
  }

  // ── Create / Edit Dialog ────────────────────────────────────────────────────

  Future<void> _showGoalDialog({JiveSavingsGoal? goal}) async {
    final nameCtrl = TextEditingController(text: goal?.name ?? '');
    final amountCtrl = TextEditingController(
        text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '');
    final noteCtrl = TextEditingController(text: goal?.note ?? '');
    String selectedEmoji = goal?.emoji ?? _kEmojis[0];
    String selectedColor = goal?.colorHex ?? _kColorPalette[0];
    DateTime? selectedDeadline = goal?.deadline;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              goal == null ? '创建储蓄目标' : '编辑储蓄目标',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  TextField(
                    controller: nameCtrl,
                    decoration: _inputDecoration('目标名称'),
                    style: GoogleFonts.lato(),
                  ),
                  const SizedBox(height: 12),

                  // Emoji picker
                  Text('选择图标',
                      style: GoogleFonts.lato(
                          color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _kEmojis.map((e) {
                      final selected = e == selectedEmoji;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedEmoji = e),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: selected
                                ? _hexColor(selectedColor).withValues(alpha: 0.15)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? _hexColor(selectedColor)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Color picker
                  Text('选择颜色',
                      style: GoogleFonts.lato(
                          color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _kColorPalette.map((hex) {
                      final selected = hex == selectedColor;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedColor = hex),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _hexColor(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _hexColor(hex).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Target amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDecoration('目标金额 (¥)'),
                    style: GoogleFonts.lato(),
                  ),
                  const SizedBox(height: 12),

                  // Deadline
                  Text('截止日期（可选）',
                      style: GoogleFonts.lato(
                          color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDeadline ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (c, child) => Theme(
                          data: ThemeData(
                              colorSchemeSeed: _kAccentGreen,
                              useMaterial3: true),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDeadline = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      selectedDeadline != null
                          ? DateFormat('yyyy-MM-dd').format(selectedDeadline!)
                          : '选择日期',
                      style: GoogleFonts.lato(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kAccentGreen,
                      side: const BorderSide(color: _kAccentGreen),
                    ),
                  ),
                  if (selectedDeadline != null)
                    TextButton(
                      onPressed: () =>
                          setDialogState(() => selectedDeadline = null),
                      child: Text('清除日期',
                          style: GoogleFonts.lato(color: Colors.red[400])),
                    ),
                  const SizedBox(height: 12),

                  // Note
                  TextField(
                    controller: noteCtrl,
                    decoration: _inputDecoration('备注（可选）'),
                    style: GoogleFonts.lato(),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('取消',
                    style: GoogleFonts.lato(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final amountText = amountCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入目标名称')),
                    );
                    return;
                  }
                  final target = double.tryParse(amountText);
                  if (target == null || target <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的目标金额')),
                    );
                    return;
                  }
                  final now = DateTime.now();
                  final isar = Isar.getInstance()!;
                  await isar.writeTxn(() async {
                    if (goal == null) {
                      final newGoal = JiveSavingsGoal()
                        ..name = name
                        ..emoji = selectedEmoji
                        ..colorHex = selectedColor
                        ..targetAmount = target
                        ..note =
                            noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()
                        ..deadline = selectedDeadline
                        ..status = 'active'
                        ..createdAt = now
                        ..updatedAt = now;
                      await isar.jiveSavingsGoals.put(newGoal);
                    } else {
                      goal
                        ..name = name
                        ..emoji = selectedEmoji
                        ..colorHex = selectedColor
                        ..targetAmount = target
                        ..note =
                            noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()
                        ..deadline = selectedDeadline
                        ..updatedAt = now;
                      await isar.jiveSavingsGoals.put(goal);
                    }
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadGoals();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('保存', style: GoogleFonts.lato()),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Deposit Dialog ──────────────────────────────────────────────────────────

  Future<void> _deposit(JiveSavingsGoal goal) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('存入金额', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration('金额 (¥)'),
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: GoogleFonts.lato(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效金额')),
                );
                return;
              }
              final isar = Isar.getInstance()!;
              await isar.writeTxn(() async {
                goal
                  ..currentAmount = goal.currentAmount + amount
                  ..updatedAt = DateTime.now();
                await isar.jiveSavingsGoals.put(goal);
              });
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadGoals();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccentGreen,
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

  // ── Mark Achieved ───────────────────────────────────────────────────────────

  Future<void> _markAchieved(JiveSavingsGoal goal) async {
    final isar = Isar.getInstance()!;
    await isar.writeTxn(() async {
      goal
        ..status = 'achieved'
        ..updatedAt = DateTime.now();
      await isar.jiveSavingsGoals.put(goal);
    });
    await _loadGoals();
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> _delete(JiveSavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('删除目标', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        content: Text('确定要删除「${goal.name}」吗？此操作不可撤销。',
            style: GoogleFonts.lato()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消',
                style: GoogleFonts.lato(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('删除', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final isar = Isar.getInstance()!;
      await isar.writeTxn(() async {
        await isar.jiveSavingsGoals.delete(goal.id);
      });
      await _loadGoals();
    }
  }
}

// ── Goal List ─────────────────────────────────────────────────────────────────

class _GoalList extends StatelessWidget {
  final List<JiveSavingsGoal> goals;
  final Future<void> Function(JiveSavingsGoal) onDeposit;
  final Future<void> Function(JiveSavingsGoal) onMarkAchieved;
  final void Function(JiveSavingsGoal) onEdit;
  final Future<void> Function(JiveSavingsGoal) onDelete;

  const _GoalList({
    required this.goals,
    required this.onDeposit,
    required this.onMarkAchieved,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return _EmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (ctx, i) => _GoalCard(
        goal: goals[i],
        onDeposit: onDeposit,
        onMarkAchieved: onMarkAchieved,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '还没有目标',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 创建第一个储蓄目标',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final JiveSavingsGoal goal;
  final Future<void> Function(JiveSavingsGoal) onDeposit;
  final Future<void> Function(JiveSavingsGoal) onMarkAchieved;
  final void Function(JiveSavingsGoal) onEdit;
  final Future<void> Function(JiveSavingsGoal) onDelete;

  const _GoalCard({
    required this.goal,
    required this.onDeposit,
    required this.onMarkAchieved,
    required this.onEdit,
    required this.onDelete,
  });

  double get _progress => goal.targetAmount > 0
      ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
      : 0.0;

  Color get _progressColor {
    final pct = goal.targetAmount > 0
        ? goal.currentAmount / goal.targetAmount
        : 0.0;
    if (pct >= 1.0) return const Color(0xFFFFD700); // gold
    if (pct >= 0.8) return Colors.orange;
    return _kAccentGreen;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _hexColor(goal.colorHex);
    final fmt = NumberFormat('#,##0.00', 'zh_CN');
    final now = DateTime.now();
    final deadline = goal.deadline;

    int? daysRemaining;
    bool isPastDeadline = false;
    if (deadline != null) {
      final diff = deadline.difference(DateTime(now.year, now.month, now.day));
      daysRemaining = diff.inDays;
      isPastDeadline = daysRemaining < 0;
    }

    final pct = goal.targetAmount > 0
        ? goal.currentAmount / goal.targetAmount
        : 0.0;
    final isComplete = pct >= 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      goal.emoji ?? '💰',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[900],
                        ),
                      ),
                      if (goal.note != null && goal.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          goal.note!,
                          style: GoogleFonts.lato(
                              fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Popup menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') onEdit(goal);
                    if (value == 'delete') onDelete(goal);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text('编辑', style: GoogleFonts.lato()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red[400]),
                          const SizedBox(width: 8),
                          Text('删除',
                              style: GoogleFonts.lato(color: Colors.red[400])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Amount progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '¥${fmt.format(goal.currentAmount)} / ¥${fmt.format(goal.targetAmount)}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: _progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
              ),
            ),
            const SizedBox(height: 10),

            // Deadline chip + action buttons
            Row(
              children: [
                // Deadline chip
                if (deadline != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPastDeadline
                          ? Colors.red[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPastDeadline
                            ? Colors.red[200]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: isPastDeadline
                              ? Colors.red[600]
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPastDeadline
                              ? '已超期 ${(-daysRemaining!)} 天'
                              : '剩 $daysRemaining 天',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: isPastDeadline
                                ? Colors.red[600]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                const Spacer(),

                // Mark achieved button (only when complete and still active)
                if (isComplete && goal.status == 'active') ...[
                  TextButton.icon(
                    onPressed: () => onMarkAchieved(goal),
                    icon: const Icon(Icons.emoji_events, size: 16),
                    label: Text('标记达成', style: GoogleFonts.lato(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Deposit button
                if (goal.status == 'active')
                  ElevatedButton.icon(
                    onPressed: () => onDeposit(goal),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('存入', style: GoogleFonts.lato(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),

                // Achieved badge
                if (goal.status == 'achieved')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            size: 14, color: Color(0xFFFFD700)),
                        const SizedBox(width: 4),
                        Text(
                          '已达成',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Color(0xFF795548),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

InputDecoration _inputDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lato(color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kAccentGreen, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
