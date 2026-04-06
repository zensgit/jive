import 'package:flutter/material.dart';

/// Custom numeric keypad with arithmetic expression support.
///
/// Replaces the system keyboard for amount input. Supports basic
/// arithmetic (+, -, x, /) with left-to-right evaluation and a
/// live "= result" preview.
class CalculatorKeypad extends StatefulWidget {
  /// Called when the user taps the confirm button with the final amount.
  final ValueChanged<double> onAmountConfirmed;

  /// Called on every keystroke with the current expression string.
  final ValueChanged<String>? onExpressionChanged;

  const CalculatorKeypad({
    super.key,
    required this.onAmountConfirmed,
    this.onExpressionChanged,
  });

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad> {
  String _expression = '';

  // ── colours ──
  static const _greyButton = Color(0xFFF5F5F5);
  static const _orangeButton = Color(0xFFFB8C00);
  static const _greenButton = Color(0xFF43A047);

  // ── expression evaluation ──

  /// Evaluate [expr] left-to-right (no precedence) and return the result,
  /// or `null` if the expression is incomplete / invalid.
  static double? _evaluate(String expr) {
    if (expr.isEmpty) return null;

    // Tokenise: numbers and operators
    final tokens = <String>[];
    final buf = StringBuffer();

    for (var i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if ('+-×÷'.contains(ch)) {
        if (buf.isEmpty) {
          // Leading minus or consecutive operator → skip evaluation
          if (ch == '-' && tokens.isEmpty) {
            buf.write(ch);
            continue;
          }
          return null;
        }
        tokens.add(buf.toString());
        tokens.add(ch);
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) tokens.add(buf.toString());

    if (tokens.isEmpty) return null;

    var result = double.tryParse(tokens.first);
    if (result == null) return null;

    for (var i = 1; i + 1 < tokens.length; i += 2) {
      final op = tokens[i];
      final right = double.tryParse(tokens[i + 1]);
      if (right == null) return null;
      switch (op) {
        case '+':
          result = result! + right;
        case '-':
          result = result! - right;
        case '×':
          result = result! * right;
        case '÷':
          if (right == 0) return null;
          result = result! / right;
      }
    }

    return result;
  }

  String get _preview {
    if (_expression.isEmpty) return '';
    // Only show preview when there is at least one operator
    if (!_expression.contains(RegExp('[+\\-×÷]'))) return '';
    final val = _evaluate(_expression);
    if (val == null) return '';
    // Format nicely: drop trailing ".0"
    final formatted =
        val == val.roundToDouble() ? val.toInt().toString() : val.toStringAsFixed(2);
    return '= $formatted';
  }

  void _append(String ch) {
    // Prevent consecutive operators
    if ('+-×÷'.contains(ch) && _expression.isNotEmpty && '+-×÷'.contains(_expression[_expression.length - 1])) {
      // Replace last operator
      setState(() => _expression = _expression.substring(0, _expression.length - 1) + ch);
    } else if (ch == '.' && _currentNumberHasDot) {
      return; // already has a dot
    } else {
      setState(() => _expression += ch);
    }
    widget.onExpressionChanged?.call(_expression);
  }

  bool get _currentNumberHasDot {
    // Find the last number segment
    final lastOpIdx = _expression.lastIndexOf(RegExp('[+\\-×÷]'));
    final segment = lastOpIdx == -1 ? _expression : _expression.substring(lastOpIdx + 1);
    return segment.contains('.');
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() => _expression = _expression.substring(0, _expression.length - 1));
    widget.onExpressionChanged?.call(_expression);
  }

  void _clear() {
    setState(() => _expression = '');
    widget.onExpressionChanged?.call(_expression);
  }

  void _calculate() {
    final val = _evaluate(_expression);
    if (val == null) return;
    final formatted =
        val == val.roundToDouble() ? val.toInt().toString() : val.toStringAsFixed(2);
    setState(() => _expression = formatted);
    widget.onExpressionChanged?.call(_expression);
  }

  void _confirm() {
    if (_expression.isEmpty) return;
    final val = _evaluate(_expression);
    if (val != null) {
      widget.onAmountConfirmed(val);
    } else {
      // Try parsing the expression directly (single number)
      final parsed = double.tryParse(_expression);
      if (parsed != null) widget.onAmountConfirmed(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preview bar
        if (_preview.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.grey.shade100,
            child: Text(
              _preview,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        // 4x4 number grid
        _buildRow(['7', '8', '9', '÷']),
        _buildRow(['4', '5', '6', '×']),
        _buildRow(['1', '2', '3', '-']),
        _buildRow(['.', '0', '⌫', '+']),
        // Bottom action row
        _buildActionRow(),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((k) {
        final isOp = '+-×÷'.contains(k);
        final isBackspace = k == '⌫';
        return Expanded(
          child: _KeyButton(
            label: k,
            backgroundColor: isOp ? _orangeButton : _greyButton,
            textColor: isOp ? Colors.white : Colors.black87,
            onTap: isBackspace ? _backspace : () => _append(k),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _KeyButton(
            label: 'C',
            backgroundColor: _greyButton,
            textColor: Colors.red,
            onTap: _clear,
          ),
        ),
        Expanded(
          child: _KeyButton(
            label: '=',
            backgroundColor: _greyButton,
            textColor: Colors.black87,
            onTap: _calculate,
          ),
        ),
        Expanded(
          flex: 2,
          child: _KeyButton(
            label: '✓',
            backgroundColor: _greenButton,
            textColor: Colors.white,
            onTap: _confirm,
          ),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
