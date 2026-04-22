class AmountExpression {
  static const multiply = '×';
  static const divide = '÷';
  static const _operators = {'+', '-', multiply, divide};

  const AmountExpression._();

  static bool isOperator(String value) => _operators.contains(value);

  static String normalize(String expression) {
    return expression
        .replaceAll('*', multiply)
        .replaceAll('/', divide)
        .replaceAll(' ', '');
  }

  static double? evaluate(String expression) {
    final normalized = _trimIncompleteSuffix(normalize(expression));
    if (normalized.isEmpty || normalized == '-') return null;
    final tokens = _tokenize(normalized);
    if (tokens.isEmpty) return null;

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

  static List<String> _tokenize(String expression) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];
      final previous = tokens.isEmpty ? null : tokens.last;
      final canStartNegative =
          char == '-' &&
          buffer.isEmpty &&
          (tokens.isEmpty || isOperator(previous ?? '')) &&
          i + 1 < expression.length &&
          !isOperator(expression[i + 1]);

      if (isOperator(char) && !canStartNegative) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
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
        (isOperator(value[value.length - 1]) || value.endsWith('.'))) {
      value = value.substring(0, value.length - 1);
    }
    return value;
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
