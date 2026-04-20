import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

Future<DateTime?> showTransactionDateTimeSheet(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: JiveTheme.cardColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) => _Sheet(
      initial: initial,
      firstDate: firstDate ?? DateTime(DateTime.now().year - 5),
      lastDate: lastDate ?? DateTime(DateTime.now().year + 1),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode
// ─────────────────────────────────────────────────────────────────────────────

enum _Mode { date, input, hour, minute }

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _Sheet extends StatefulWidget {
  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  const _Sheet({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> with TickerProviderStateMixin {
  late DateTime _value;
  late DateTime _todayMidnight;
  _Mode _mode = _Mode.date;
  int _pickerRebuildKey = 0;
  int _selectedHour = 0;
  int _selectedMinute = 0;

  // 手输控制器
  late TextEditingController _hourInputCtrl;
  late TextEditingController _minuteInputCtrl;
  final _hourFocus = FocusNode();
  final _minuteFocus = FocusNode();

  // 指针角度动画
  late AnimationController _handAnimCtrl;
  double _prevAngle = 0;
  double _targetAngle = 0;

  // 选中圈缩放动画
  late AnimationController _scaleAnimCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    _selectedHour = _value.hour;
    _selectedMinute = _value.minute;
    final now = DateTime.now();
    _todayMidnight = DateTime(now.year, now.month, now.day);

    _hourInputCtrl = TextEditingController(
      text: _selectedHour.toString().padLeft(2, '0'),
    );
    _minuteInputCtrl = TextEditingController(
      text: _selectedMinute.toString().padLeft(2, '0'),
    );

    _handAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..value = 1.0;

    _scaleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleAnimCtrl, curve: Curves.easeOutBack),
    );
    _scaleAnimCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _handAnimCtrl.dispose();
    _scaleAnimCtrl.dispose();
    _hourInputCtrl.dispose();
    _minuteInputCtrl.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  // ── Date helpers ──

  void _jumpToOffset(int daysBack) {
    final target = _todayMidnight.subtract(Duration(days: daysBack));
    setState(() {
      _value = DateTime(
        target.year, target.month, target.day,
        _value.hour, _value.minute,
      );
      _pickerRebuildKey++;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Time mode transitions ──

  void _enterTimeMode() {
    _hourInputCtrl.text = _value.hour.toString().padLeft(2, '0');
    _minuteInputCtrl.text = _value.minute.toString().padLeft(2, '0');
    setState(() {
      _selectedHour = _value.hour;
      _selectedMinute = _value.minute;
      _mode = _Mode.input; // 默认手输
    });
    Future.microtask(() => _hourFocus.requestFocus());
  }

  void _switchToDial() {
    _applyInputValues();
    _prevAngle = _valueToAngle(_selectedHour, true);
    _targetAngle = _prevAngle;
    _handAnimCtrl.value = 1.0;
    setState(() => _mode = _Mode.hour);
    _scaleAnimCtrl.forward(from: 0);
  }

  void _switchToInput() {
    _hourInputCtrl.text = _selectedHour.toString().padLeft(2, '0');
    _minuteInputCtrl.text = _selectedMinute.toString().padLeft(2, '0');
    setState(() => _mode = _Mode.input);
    Future.microtask(() => _hourFocus.requestFocus());
  }

  void _backToDate() {
    _applyInputValues();
    setState(() {
      _value = DateTime(
        _value.year, _value.month, _value.day,
        _selectedHour, _selectedMinute,
      );
      _mode = _Mode.date;
    });
  }

  void _applyInputValues() {
    final h = int.tryParse(_hourInputCtrl.text) ?? _selectedHour;
    final m = int.tryParse(_minuteInputCtrl.text) ?? _selectedMinute;
    _selectedHour = h.clamp(0, 23);
    _selectedMinute = m.clamp(0, 59);
  }

  // ── Clock dial callbacks ──

  void _onHourSelected(int hour) {
    if (hour == _selectedHour) return;
    final oldAngle = _valueToAngle(_selectedHour, true);
    final newAngle = _valueToAngle(hour, true);
    _prevAngle = oldAngle;
    _targetAngle = newAngle;
    _handAnimCtrl.forward(from: 0);
    _scaleAnimCtrl.forward(from: 0);
    setState(() => _selectedHour = hour);
  }

  void _onMinuteSelected(int minute) {
    if (minute == _selectedMinute) return;
    final oldAngle = _valueToAngle(_selectedMinute, false);
    final newAngle = _valueToAngle(minute, false);
    _prevAngle = oldAngle;
    _targetAngle = newAngle;
    _handAnimCtrl.forward(from: 0);
    _scaleAnimCtrl.forward(from: 0);
    setState(() => _selectedMinute = minute);
  }

  void _onHourPanEnd() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _prevAngle = _valueToAngle(_selectedMinute, false);
      _targetAngle = _prevAngle;
      _handAnimCtrl.value = 1.0;
      _scaleAnimCtrl.forward(from: 0);
      setState(() => _mode = _Mode.minute);
    });
  }

  double _valueToAngle(int value, bool isHour) {
    if (isHour) {
      return (value % 12) * 30 * math.pi / 180;
    }
    return value * 6 * math.pi / 180;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isDark = JiveTheme.isDark(context);
    final textColor = JiveTheme.textColor(context);
    final secColor = JiveTheme.secondaryTextColor(context);
    final isTimeMode = _mode != _Mode.date;
    final h = isTimeMode ? _selectedHour : _value.hour;
    final m = isTimeMode ? _selectedMinute : _value.minute;
    final hourStr = h.toString().padLeft(2, '0');
    final minuteStr = m.toString().padLeft(2, '0');

    // 日期预览文字
    final dateLabel = _smartDateLabel();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Grabber ──
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // ── 日期 + 时间 预览 ──
              GestureDetector(
                onTap: isTimeMode ? null : _enterTimeMode,
                child: Column(
                  children: [
                    // 日期标签
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: secColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 时间数字
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimeDigit(
                          hourStr,
                          isActive: _mode == _Mode.hour,
                          color: textColor,
                          onTap: (_mode == _Mode.hour || _mode == _Mode.minute)
                              ? () {
                                  _prevAngle = _valueToAngle(_selectedHour, true);
                                  _targetAngle = _prevAngle;
                                  _handAnimCtrl.value = 1.0;
                                  setState(() => _mode = _Mode.hour);
                                  _scaleAnimCtrl.forward(from: 0);
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            ':',
                            style: GoogleFonts.rubik(
                              fontSize: 32, fontWeight: FontWeight.w200,
                              color: secColor, height: 1.0,
                            ),
                          ),
                        ),
                        _buildTimeDigit(
                          minuteStr,
                          isActive: _mode == _Mode.minute,
                          color: textColor.withValues(alpha: 0.45),
                          onTap: (_mode == _Mode.hour || _mode == _Mode.minute)
                              ? () {
                                  _prevAngle = _valueToAngle(_selectedMinute, false);
                                  _targetAngle = _prevAngle;
                                  _handAnimCtrl.value = 1.0;
                                  setState(() => _mode = _Mode.minute);
                                  _scaleAnimCtrl.forward(from: 0);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // ── 主体区 ──
              if (_mode == _Mode.date) _buildDatePicker(isDark, textColor),
              if (_mode == _Mode.input) _buildTimeInput(isDark, textColor),
              if (_mode == _Mode.hour || _mode == _Mode.minute)
                AnimatedBuilder(
                  animation: Listenable.merge([_handAnimCtrl, _scaleAnimCtrl]),
                  builder: (_, __) {
                    final t = Curves.easeInOutCubic.transform(
                      _handAnimCtrl.value,
                    );
                    final angleDiff = _shortestAngleDiff(_prevAngle, _targetAngle);
                    final currentAngle = _prevAngle + angleDiff * t;

                    return _JiveClockDial(
                      isHourMode: _mode == _Mode.hour,
                      selectedValue: _mode == _Mode.hour
                          ? _selectedHour
                          : _selectedMinute,
                      isDark: isDark,
                      handAngle: currentAngle,
                      selectionScale: _scaleAnim.value,
                      onValueChanged: _mode == _Mode.hour
                          ? _onHourSelected
                          : _onMinuteSelected,
                      onPanEnd: _mode == _Mode.hour ? _onHourPanEnd : null,
                    );
                  },
                ),

              const SizedBox(height: 10),
              _buildBottom(isDark),
            ],
          ),
        ),
      ),
    );
  }

  String _smartDateLabel() {
    final day = DateTime(_value.year, _value.month, _value.day);
    if (_isSameDay(day, _todayMidnight)) return '今天';
    if (_isSameDay(day, _todayMidnight.subtract(const Duration(days: 1)))) {
      return '昨天';
    }
    if (_isSameDay(day, _todayMidnight.subtract(const Duration(days: 2)))) {
      return '前天';
    }
    final now = DateTime.now();
    return now.year == _value.year
        ? DateFormat('MM-dd EEE', 'zh_CN').format(_value)
        : DateFormat('yyyy-MM-dd', 'zh_CN').format(_value);
  }

  Widget _buildTimeDigit(
    String text, {
    required bool isActive,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.rubik(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: isActive ? JiveTheme.primaryGreen : color,
          height: 1.0,
        ),
      ),
    );
  }

  // ── 手输时间 ──
  Widget _buildTimeInput(bool isDark, Color textColor) {
    final accent = JiveTheme.primaryGreen;
    final bgColor = isDark ? Colors.white10 : Colors.grey.shade100;
    const inputFontSize = 36.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _hourInputCtrl,
              focusNode: _hourFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 2,
              style: GoogleFonts.rubik(
                fontSize: inputFontSize,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '00',
                hintStyle: GoogleFonts.rubik(
                  fontSize: inputFontSize,
                  fontWeight: FontWeight.w300,
                  color: textColor.withValues(alpha: 0.2),
                ),
                filled: true,
                fillColor: _hourFocus.hasFocus
                    ? accent.withValues(alpha: 0.1)
                    : bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val != null && val >= 0 && val <= 23) {
                  _selectedHour = val;
                }
                if (v.length == 2) _minuteFocus.requestFocus();
              },
              onTap: () => _hourInputCtrl.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _hourInputCtrl.text.length,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ':',
              style: GoogleFonts.rubik(
                fontSize: inputFontSize, fontWeight: FontWeight.w200,
                color: textColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _minuteInputCtrl,
              focusNode: _minuteFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 2,
              style: GoogleFonts.rubik(
                fontSize: inputFontSize,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '00',
                hintStyle: GoogleFonts.rubik(
                  fontSize: inputFontSize,
                  fontWeight: FontWeight.w300,
                  color: textColor.withValues(alpha: 0.2),
                ),
                filled: true,
                fillColor: _minuteFocus.hasFocus
                    ? accent.withValues(alpha: 0.1)
                    : bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val != null && val >= 0 && val <= 59) {
                  _selectedMinute = val;
                }
              },
              onTap: () => _minuteInputCtrl.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _minuteInputCtrl.text.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Date picker ──
  Widget _buildDatePicker(bool isDark, Color textColor) {
    return SizedBox(
      height: 180,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(fontSize: 20, color: textColor),
          ),
        ),
        child: CupertinoDatePicker(
          key: ValueKey(_pickerRebuildKey),
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _value,
          minimumDate: widget.firstDate,
          maximumDate: widget.lastDate,
          onDateTimeChanged: (d) {
            setState(() {
              _value = DateTime(
                d.year, d.month, d.day, _value.hour, _value.minute,
              );
            });
          },
        ),
      ),
    );
  }

  // ── Bottom row ──
  Widget _buildBottom(bool isDark) {
    final valueDay = DateTime(_value.year, _value.month, _value.day);
    final isToday = _isSameDay(valueDay, _todayMidnight);
    final isYesterday =
        _isSameDay(valueDay, _todayMidnight.subtract(const Duration(days: 1)));
    final isDayBefore =
        _isSameDay(valueDay, _todayMidnight.subtract(const Duration(days: 2)));
    final isTimeMode = _mode != _Mode.date;
    final isDial = _mode == _Mode.hour || _mode == _Mode.minute;

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            // 今/昨/前 — 所有模式都显示
            _PresetChip(label: '今', isActive: isToday, onTap: () => _jumpToOffset(0)),
            _PresetChip(label: '昨', isActive: isYesterday, onTap: () => _jumpToOffset(1)),
            _PresetChip(label: '前', isActive: isDayBefore, onTap: () => _jumpToOffset(2)),
            if (!isTimeMode)
              _PresetChip(
                label: '时间 ${DateFormat('HH:mm').format(_value)}',
                isActive: false, icon: Icons.access_time,
                onTap: _enterTimeMode,
              ),
            if (isTimeMode) ...[
              _PresetChip(
                label: '日期 ${DateFormat('MM-dd').format(_value)}',
                isActive: false, icon: Icons.calendar_today,
                onTap: _backToDate,
              ),
              _PresetChip(
                label: isDial ? '键盘' : '表盘',
                isActive: false,
                icon: isDial ? Icons.keyboard_outlined : Icons.access_time,
                onTap: isDial ? _switchToInput : _switchToDial,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (_mode == _Mode.input) _applyInputValues();
                final result = _mode == _Mode.date
                    ? _value
                    : DateTime(
                        _value.year, _value.month, _value.day,
                        _selectedHour, _selectedMinute,
                      );
                Navigator.pop(context, result);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Angle helpers
// ─────────────────────────────────────────────────────────────────────────────

/// 最短角度差（处理 350°→10° 这种跨越 0° 的情况）
double _shortestAngleDiff(double from, double to) {
  var diff = to - from;
  while (diff > math.pi) {
    diff -= 2 * math.pi;
  }
  while (diff < -math.pi) {
    diff += 2 * math.pi;
  }
  return diff;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom clock dial widget
// ─────────────────────────────────────────────────────────────────────────────

class _JiveClockDial extends StatelessWidget {
  final bool isHourMode;
  final int selectedValue;
  final bool isDark;
  final double handAngle;
  final double selectionScale;
  final ValueChanged<int> onValueChanged;
  final VoidCallback? onPanEnd;

  const _JiveClockDial({
    required this.isHourMode,
    required this.selectedValue,
    required this.isDark,
    required this.handAngle,
    required this.selectionScale,
    required this.onValueChanged,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    const double dialSize = 240;
    const double radius = dialSize / 2;

    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: GestureDetector(
        onPanStart: (d) => _handleTouch(d.localPosition, radius),
        onPanUpdate: (d) => _handleTouch(d.localPosition, radius),
        onPanEnd: (_) => onPanEnd?.call(),
        onTapUp: (d) {
          _handleTouch(d.localPosition, radius);
          onPanEnd?.call();
        },
        child: CustomPaint(
          painter: _ClockDialPainter(
            isHourMode: isHourMode,
            selectedValue: selectedValue,
            isDark: isDark,
            handAngle: handAngle,
            selectionScale: selectionScale,
          ),
          size: const Size(dialSize, dialSize),
        ),
      ),
    );
  }

  void _handleTouch(Offset pos, double radius) {
    final center = Offset(radius, radius);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 16) return;

    var angle = math.atan2(dx, -dy) * 180 / math.pi;
    angle = (angle + 360) % 360;

    if (isHourMode) {
      final segment = ((angle + 15) % 360) ~/ 30;
      final isInner = dist < radius * 0.58;
      int hour;
      if (isInner) {
        hour = segment == 0 ? 0 : segment + 12;
      } else {
        hour = segment == 0 ? 12 : segment;
      }
      onValueChanged(hour);
    } else {
      final minute = ((angle + 3) % 360) ~/ 6;
      onValueChanged(minute);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clock dial painter
// ─────────────────────────────────────────────────────────────────────────────

class _ClockDialPainter extends CustomPainter {
  final bool isHourMode;
  final int selectedValue;
  final bool isDark;
  final double handAngle; // 当前动画角度 (rad)
  final double selectionScale; // 0..1+ (easeOutBack)

  _ClockDialPainter({
    required this.isHourMode,
    required this.selectedValue,
    required this.isDark,
    required this.handAngle,
    required this.selectionScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── 背景圆 ──
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFEEEEEE);
    canvas.drawCircle(center, radius, bgPaint);

    // ── 参数 ──
    final outerR = radius * 0.82;
    final innerR = radius * 0.54;
    final selCircleR = isHourMode ? 17.0 : 15.0;

    // ── 选中点在哪个半径 ──
    final bool isInner =
        isHourMode && (selectedValue == 0 || selectedValue > 12);
    final selR = isHourMode ? (isInner ? innerR : outerR) : outerR;

    // ── 用动画角度画指针 ──
    final handX = center.dx + selR * math.sin(handAngle);
    final handY = center.dy - selR * math.cos(handAngle);
    final handEnd = Offset(handX, handY);

    final handPaint = Paint()
      ..color = JiveTheme.primaryGreen
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, handEnd, handPaint);

    // ── 中心圆点 ──
    canvas.drawCircle(
      center,
      3.5,
      Paint()
        ..color = JiveTheme.primaryGreen
        ..style = PaintingStyle.fill,
    );

    // ── 选中背景圆（在实际选中位置，用 scale 动画） ──
    final selAngle = _valueToAngle(selectedValue);
    final selX = center.dx + selR * math.sin(selAngle);
    final selY = center.dy - selR * math.cos(selAngle);
    canvas.drawCircle(
      Offset(selX, selY),
      selCircleR * selectionScale,
      Paint()
        ..color = JiveTheme.primaryGreen
        ..style = PaintingStyle.fill,
    );

    // ── 数字 ──
    if (isHourMode) {
      _drawHourNumbers(canvas, center, outerR, innerR);
    } else {
      _drawMinuteNumbers(canvas, center, outerR);
    }
  }

  void _drawHourNumbers(
    Canvas canvas, Offset center, double outerR, double innerR,
  ) {
    // 外圈 1-12
    for (int i = 1; i <= 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final x = center.dx + outerR * math.sin(angle);
      final y = center.dy - outerR * math.cos(angle);
      _drawNumber(
        canvas, Offset(x, y), i.toString(),
        fontSize: 15,
        color: selectedValue == i
            ? Colors.white
            : (isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87),
      );
    }
    // 内圈 00, 13-23
    for (int i = 0; i < 12; i++) {
      final hour = i == 0 ? 0 : i + 12;
      final angle = i * 30 * math.pi / 180;
      final x = center.dx + innerR * math.sin(angle);
      final y = center.dy - innerR * math.cos(angle);
      _drawNumber(
        canvas, Offset(x, y), hour.toString().padLeft(2, '0'),
        fontSize: 11,
        color: selectedValue == hour
            ? Colors.white
            : (isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black38),
      );
    }
  }

  void _drawMinuteNumbers(Canvas canvas, Offset center, double outerR) {
    for (int i = 0; i < 60; i++) {
      final angle = i * 6 * math.pi / 180;
      final x = center.dx + outerR * math.sin(angle);
      final y = center.dy - outerR * math.cos(angle);
      if (i % 5 == 0) {
        _drawNumber(
          canvas, Offset(x, y), i.toString().padLeft(2, '0'),
          fontSize: 14,
          color: selectedValue == i
              ? Colors.white
              : (isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87),
        );
      } else if (selectedValue != i) {
        canvas.drawCircle(
          Offset(x, y), 1.5,
          Paint()
            ..color = isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black12,
        );
      }
    }
  }

  void _drawNumber(
    Canvas canvas, Offset pos, String text, {
    required double fontSize,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  double _valueToAngle(int value) {
    if (isHourMode) return (value % 12) * 30 * math.pi / 180;
    return value * 6 * math.pi / 180;
  }

  @override
  bool shouldRepaint(covariant _ClockDialPainter old) =>
      old.selectedValue != selectedValue ||
      old.isHourMode != isHourMode ||
      old.isDark != isDark ||
      old.handAngle != handAngle ||
      old.selectionScale != selectionScale;
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset chip
// ─────────────────────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData? icon;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = JiveTheme.isDark(context);
    final activeColor = JiveTheme.primaryGreen;
    final bg = isActive
        ? activeColor.withValues(alpha: 0.18)
        : (isDark ? Colors.white12 : Colors.grey.shade100);
    final fg = isActive ? activeColor : JiveTheme.secondaryTextColor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14, color: fg,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
