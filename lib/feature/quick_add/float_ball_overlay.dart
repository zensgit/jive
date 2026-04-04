import 'package:flutter/material.dart';

import '../../core/service/float_ball_service.dart';
import 'quick_add_sheet.dart';

/// A draggable floating action button that hovers over the app content.
///
/// * 48x48 green circle with a "+" icon.
/// * Can be dragged anywhere; snaps to the nearest horizontal edge on release.
/// * Semi-transparent when idle, opaque when touched.
/// * Tapping opens [QuickAddSheet] as a compact bottom-sheet.
/// * Persists its position via [FloatBallService].
class FloatBallOverlay extends StatefulWidget {
  final int? bookId;
  final VoidCallback? onTransactionSaved;

  const FloatBallOverlay({
    super.key,
    this.bookId,
    this.onTransactionSaved,
  });

  // ---------------------------------------------------------------------------
  // Static helpers to manage the overlay entry
  // ---------------------------------------------------------------------------

  static OverlayEntry? _overlayEntry;

  /// Show the float ball on the given overlay if not already visible.
  static void show(
    BuildContext context, {
    int? bookId,
    VoidCallback? onTransactionSaved,
  }) {
    if (_overlayEntry != null) return;
    final entry = OverlayEntry(
      builder: (_) => FloatBallOverlay(
        bookId: bookId,
        onTransactionSaved: onTransactionSaved,
      ),
    );
    _overlayEntry = entry;
    Overlay.of(context).insert(entry);
  }

  /// Remove the float ball from the overlay.
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Whether the overlay is currently visible.
  static bool get isShowing => _overlayEntry != null;

  @override
  State<FloatBallOverlay> createState() => _FloatBallOverlayState();
}

class _FloatBallOverlayState extends State<FloatBallOverlay> {
  static const double _ballSize = 48;

  double _x = 0;
  double _y = 0;
  bool _dragging = false;
  bool _positionLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final pos = await FloatBallService.getPosition();
    if (mounted) {
      setState(() {
        if (pos != null) {
          _x = pos.x;
          _y = pos.y;
        }
        _positionLoaded = true;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Position helpers
  // ---------------------------------------------------------------------------

  /// Clamp position inside the screen and then snap to the nearest edge.
  void _snapToEdge(Size screen) {
    final safePadding = MediaQuery.of(context).padding;
    final minY = safePadding.top + 8;
    final maxY = screen.height - safePadding.bottom - _ballSize - 8;
    final minX = safePadding.left + 4;
    final maxX = screen.width - safePadding.right - _ballSize - 4;

    _y = _y.clamp(minY, maxY);

    // Snap to whichever horizontal edge is closest.
    final midX = (minX + maxX) / 2;
    _x = _x < midX ? minX : maxX;
  }

  void _onDragEnd(Size screen) {
    _snapToEdge(screen);
    FloatBallService.savePosition(_x, _y);
  }

  // ---------------------------------------------------------------------------
  // Tap action
  // ---------------------------------------------------------------------------

  void _onTap() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickAddSheet(bookId: widget.bookId),
    ).then((saved) {
      if (saved == true) {
        widget.onTransactionSaved?.call();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_positionLoaded) return const SizedBox.shrink();

    final screen = MediaQuery.of(context).size;

    // Initialise to right edge if this is the first launch (no persisted pos).
    if (_x == 0 && _y == 0) {
      final safePadding = MediaQuery.of(context).padding;
      _x = screen.width - _ballSize - safePadding.right - 4;
      _y = screen.height * 0.65;
      _snapToEdge(screen);
    }

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
          });
        },
        onPanEnd: (_) {
          setState(() {
            _dragging = false;
            _onDragEnd(screen);
          });
        },
        onTap: _onTap,
        child: AnimatedOpacity(
          opacity: _dragging ? 1.0 : 0.6,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: _ballSize,
            height: _ballSize,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
