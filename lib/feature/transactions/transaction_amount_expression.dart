class TransactionAmountExpression {
  static const multiply = '×';
  static const divide = '÷';
  static const _operators = {'+', '-', multiply, divide};

  const TransactionAmountExpression._();

  static bool hasExpression(String value) {
    final normalized = normalize(value);
    return normalized.contains('+') ||
        normalized.contains(multiply) ||
        normalized.contains(divide) ||
        normalized.indexOf('-', 1) > 0;
  }

  static bool isComplete(String value) {
    if (!hasExpression(value)) return false;
    final tokens = _tokenize(value);
    if (tokens == null || tokens.length < 3 || tokens.length.isEven) {
      return false;
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (i.isEven) {
        if (double.tryParse(token) == null) return false;
      } else if (!_isOperator(token)) {
        return false;
      }
    }

    return true;
  }

  static String evaluate(
    String expression,
    String Function(double) formatAmount,
  ) {
    final result = preview(expression);
    if (result == null) return expression;
    return formatAmount(result);
  }

  static double? preview(String expression) {
    final result = _tryEvaluate(_trimIncompleteSuffix(normalize(expression)));
    if (result == null || !result.isFinite) return null;
    return result < 0 ? 0 : result;
  }

  static double? _tryEvaluate(String expression) {
    final tokens = _tokenize(expression);
    if (tokens == null || tokens.isEmpty) {
      return null;
    }

    final values = <double>[];
    final ops = <String>[];

    void applyTopOperator() {
      if (values.length < 2 || ops.isEmpty) return;
      final right = values.removeLast();
      final left = values.removeLast();
      final op = ops.removeLast();
      values.add(_apply(left, right, op));
    }

    for (final token in tokens) {
      final number = double.tryParse(token);
      if (number != null) {
        values.add(number);
        continue;
      }
      while (ops.isNotEmpty &&
          _precedence(ops.last) >= _precedence(token) &&
          values.length >= 2) {
        applyTopOperator();
      }
      ops.add(token);
    }

    while (ops.isNotEmpty && values.length >= 2) {
      applyTopOperator();
    }

    if (values.length != 1 || values.single.isNaN || values.single.isInfinite) {
      return null;
    }
    return values.single;
  }

  static String normalize(String expression) {
    return expression
        .replaceAll('*', multiply)
        .replaceAll('/', divide)
        .replaceAll(' ', '');
  }

  static List<String>? _tokenize(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;

    final tokens = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      final previous = tokens.isEmpty ? null : tokens.last;
      final canStartNegative =
          char == '-' &&
          buffer.isEmpty &&
          (tokens.isEmpty || _isOperator(previous ?? '')) &&
          i + 1 < trimmed.length &&
          !_isOperator(trimmed[i + 1]);

      if (_isOperator(char) && !canStartNegative) {
        if (buffer.isEmpty) return null;
        tokens.add(buffer.toString());
        tokens.add(char);
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }
    return tokens;
  }

  static String _trimIncompleteSuffix(String expression) {
    var value = expression;
    while (value.isNotEmpty &&
        (_isOperator(value[value.length - 1]) || value.endsWith('.'))) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static bool _isOperator(String token) {
    return token.length == 1 && _operators.contains(token);
  }

  static int _precedence(String op) {
    return (op == multiply || op == divide) ? 2 : 1;
  }

  static double _apply(double left, double right, String op) {
    switch (op) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case multiply:
        return left * right;
      case divide:
        if (right == 0) return double.nan;
        return left / right;
    }
    return double.nan;
  }
}
