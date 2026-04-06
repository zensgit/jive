import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A safety confirmation dialog that requires the user to type a random 6-digit
/// code before a destructive operation (e.g. data restore / import) can proceed.
class ConfirmCodeDialog extends StatefulWidget {
  final String title;
  final String description;
  final String code;

  const ConfirmCodeDialog({
    super.key,
    required this.title,
    required this.description,
    required this.code,
  });

  /// Show the confirm-code dialog and return `true` only when the user types
  /// the correct code and taps "确认".  Returns `false` on cancel / dismiss.
  static Future<bool> show(
    BuildContext context, {
    String title = '安全确认',
    String description = '此操作将覆盖现有数据',
  }) async {
    final code =
        (Random().nextInt(900000) + 100000).toString(); // 6-digit code
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmCodeDialog(
        title: title,
        description: description,
        code: code,
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmCodeDialog> createState() => _ConfirmCodeDialogState();
}

class _ConfirmCodeDialogState extends State<ConfirmCodeDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final matches = _controller.text.trim() == widget.code;
    if (matches != _matches) {
      setState(() => _matches = matches);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.description}，请输入确认码 [${widget.code}] 继续',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                letterSpacing: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('确认'),
        ),
      ],
    );
  }
}
