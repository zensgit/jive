import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

/// Full-screen overlay showing a transaction success animation.
///
/// Use the static [show] method to display the overlay:
/// ```dart
/// JiveSuccessAnimation.show(context, 128.50);
/// ```
class JiveSuccessAnimation extends StatefulWidget {
  /// The transaction amount to display.
  final double amount;

  /// Called when the animation completes and the overlay should be removed.
  final VoidCallback onDismiss;

  const JiveSuccessAnimation({
    super.key,
    required this.amount,
    required this.onDismiss,
  });

  /// Convenience method to show the success overlay on top of the current
  /// route. Auto-dismisses after 1.5 seconds.
  static void show(BuildContext context, double amount) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => JiveSuccessAnimation(
        amount: amount,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<JiveSuccessAnimation> createState() => _JiveSuccessAnimationState();
}

class _JiveSuccessAnimationState extends State<JiveSuccessAnimation>
    with TickerProviderStateMixin {
  static final NumberFormat _formatter = NumberFormat('#,##0.00');

  // Checkmark scale: 0 → 1.2 → 1.0
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  // Amount counting 0 → amount
  late final AnimationController _amountController;
  late final Animation<double> _amountValue;

  // Confetti particles
  late final AnimationController _confettiController;
  late final Animation<double> _confettiProgress;

  // Fade-out at the end
  late final AnimationController _fadeOutController;
  late final Animation<double> _fadeOut;

  // Particle data generated once
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    final rng = Random();
    _particles = List.generate(8, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      return _Particle(
        angle: angle,
        distance: 80 + rng.nextDouble() * 60,
        color: _particleColors[rng.nextInt(_particleColors.length)],
        size: 6 + rng.nextDouble() * 6,
      );
    });

    // Checkmark: 400ms with overshoot.
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOut,
    ));

    // Amount counting: 500ms, starts after checkmark finishes.
    _amountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _amountValue = Tween<double>(begin: 0, end: widget.amount).animate(
      CurvedAnimation(parent: _amountController, curve: Curves.easeOutCubic),
    );

    // Confetti: 600ms, starts with check.
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiProgress = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );

    // Fade out: 300ms at the very end.
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );
    _fadeOutController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Play check + confetti together.
    _checkController.forward();
    _confettiController.forward();

    // Start amount counter after a short delay.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _amountController.forward();

    // Wait until total elapsed ~1.5s then fade out.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _fadeOutController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _amountController.dispose();
    _confettiController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOut,
      child: Material(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confetti + checkmark stack
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Particles
                    ..._particles.map(_buildParticle),
                    // Checkmark
                    ScaleTransition(
                      scale: _checkScale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: JiveTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Animated amount
              AnimatedBuilder(
                animation: _amountValue,
                builder: (context, _) {
                  return Text(
                    '¥${_formatter.format(_amountValue.value)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                '记账成功',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(_Particle p) {
    return AnimatedBuilder(
      animation: _confettiProgress,
      builder: (context, child) {
        final t = _confettiProgress.value;
        final dx = cos(p.angle) * p.distance * t;
        final dy = sin(p.angle) * p.distance * t;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                color: p.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  static const List<Color> _particleColors = [
    JiveTheme.primaryGreen,
    JiveTheme.accentLime,
    Color(0xFF81C784),
    Color(0xFFA5D6A7),
    Color(0xFFFFD54F),
    Color(0xFF4CAF50),
  ];
}

class _Particle {
  final double angle;
  final double distance;
  final Color color;
  final double size;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.color,
    required this.size,
  });
}
