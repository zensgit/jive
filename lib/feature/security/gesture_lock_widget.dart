import 'package:flutter/material.dart';

/// 3x3 手势图案锁控件
///
/// 用户在 3x3 网格上拖动手指连接圆点，完成后通过
/// [onPatternComplete] 回调返回选中的圆点索引列表 (0-8)。
class GestureLockWidget extends StatefulWidget {
  /// 图案绘制完成时的回调，参数为选中圆点的索引列表
  final ValueChanged<List<int>> onPatternComplete;

  /// 最少需要连接的圆点数
  final int minDots;

  /// 控件尺寸（正方形边长）
  final double size;

  /// 是否处于错误状态（圆点变红 + 抖动）
  final bool showError;

  const GestureLockWidget({
    super.key,
    required this.onPatternComplete,
    this.minDots = 4,
    this.size = 280,
    this.showError = false,
  });

  @override
  State<GestureLockWidget> createState() => GestureLockWidgetState();
}

class GestureLockWidgetState extends State<GestureLockWidget>
    with SingleTickerProviderStateMixin {
  final List<int> _selected = [];
  Offset? _currentTouch;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  /// 圆点半径
  static const double _dotRadius = 20.0;

  /// 选中时内圈半径
  static const double _innerRadius = 8.0;

  /// 触摸命中检测半径
  static const double _hitRadius = 36.0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void didUpdateWidget(GestureLockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showError && !oldWidget.showError) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// 重置图案（外部可调用）
  void reset() {
    setState(() {
      _selected.clear();
      _currentTouch = null;
    });
  }

  List<Offset> get _dotCenters {
    final spacing = widget.size / 4;
    return List.generate(9, (i) {
      final row = i ~/ 3;
      final col = i % 3;
      return Offset(
        spacing + col * spacing,
        spacing + row * spacing,
      );
    });
  }

  int? _hitTest(Offset position) {
    final centers = _dotCenters;
    for (var i = 0; i < centers.length; i++) {
      if ((position - centers[i]).distance <= _hitRadius) {
        return i;
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.showError) return;
    final pos = details.localPosition;
    final hit = _hitTest(pos);
    setState(() {
      _selected.clear();
      _currentTouch = pos;
      if (hit != null) {
        _selected.add(hit);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.showError) return;
    final pos = details.localPosition;
    final hit = _hitTest(pos);
    setState(() {
      _currentTouch = pos;
      if (hit != null && !_selected.contains(hit)) {
        _selected.add(hit);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.showError) return;
    setState(() {
      _currentTouch = null;
    });
    if (_selected.length >= widget.minDots) {
      widget.onPatternComplete(List<int>.from(_selected));
    } else {
      // 不够长度，清空
      setState(() {
        _selected.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _PatternPainter(
              dotCenters: _dotCenters,
              selected: _selected,
              currentTouch: _currentTouch,
              showError: widget.showError,
              dotRadius: _dotRadius,
              innerRadius: _innerRadius,
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<Offset> dotCenters;
  final List<int> selected;
  final Offset? currentTouch;
  final bool showError;
  final double dotRadius;
  final double innerRadius;

  _PatternPainter({
    required this.dotCenters,
    required this.selected,
    required this.currentTouch,
    required this.showError,
    required this.dotRadius,
    required this.innerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final idlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final selectedPaint = Paint()
      ..color = showError ? Colors.redAccent : const Color(0xFF66BB6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = showError ? Colors.redAccent : const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = (showError ? Colors.redAccent : const Color(0xFF66BB6A))
          .withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // 绘制连线
    if (selected.length > 1) {
      final path = Path();
      path.moveTo(dotCenters[selected[0]].dx, dotCenters[selected[0]].dy);
      for (var i = 1; i < selected.length; i++) {
        path.lineTo(dotCenters[selected[i]].dx, dotCenters[selected[i]].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // 绘制到当前触摸点的线
    if (selected.isNotEmpty && currentTouch != null) {
      canvas.drawLine(
        dotCenters[selected.last],
        currentTouch!,
        linePaint,
      );
    }

    // 绘制圆点
    for (var i = 0; i < dotCenters.length; i++) {
      final center = dotCenters[i];
      final isSelected = selected.contains(i);
      // 外圈
      canvas.drawCircle(
        center,
        dotRadius,
        isSelected ? selectedPaint : idlePaint,
      );
      // 内圈（选中时填充）
      if (isSelected) {
        canvas.drawCircle(center, innerRadius, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.currentTouch != currentTouch ||
        oldDelegate.showError != showError;
  }
}
