import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animates a numeric amount from 0 (or its previous value) to the target,
/// formatted with currency symbol and comma separators.
class AnimatedAmountText extends StatefulWidget {
  /// Target amount to animate towards.
  final double amount;

  /// Duration of the counting animation.
  final Duration duration;

  /// Text style applied to the formatted amount.
  final TextStyle? style;

  /// Prefix shown before the number (e.g. "¥" or "$").
  final String prefix;

  const AnimatedAmountText({
    super.key,
    required this.amount,
    this.duration = const Duration(milliseconds: 500),
    this.style,
    this.prefix = '¥',
  });

  @override
  State<AnimatedAmountText> createState() => _AnimatedAmountTextState();
}

class _AnimatedAmountTextState extends State<AnimatedAmountText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static final NumberFormat _formatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.amount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedAmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _animation = Tween<double>(
        begin: oldWidget.amount,
        end: widget.amount,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_formatter.format(_animation.value)}',
          style: widget.style,
        );
      },
    );
  }
}
