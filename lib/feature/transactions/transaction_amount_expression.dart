class TransactionAmountExpression {
  static const _operators = '+-×÷';

  const TransactionAmountExpression._();

  static bool hasExpression(String value) {
    return value.contains('+') ||
        value.contains('×') ||
        value.contains('÷') ||
        value.indexOf('-', 1) > 0;
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
    final result = _tryEvaluate(expression);
    if (result == null || !result.isFinite) return null;
    return result < 0 ? 0 : result;
  }

  static double? _tryEvaluate(String expression) {
    final tokens = _tokenize(expression);
    if (tokens == null || tokens.length < 3 || tokens.length.isEven) {
      return null;
    }

    final nums = <double>[];
    final ops = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (i.isEven) {
        final value = double.tryParse(token);
        if (value == null) return null;
        nums.add(value);
      } else {
        if (!_isOperator(token)) return null;
        ops.add(token);
      }
    }

    if (ops.length != nums.length - 1) return null;

    var i = 0;
    while (i < ops.length) {
      if (ops[i] == '×' || ops[i] == '÷') {
        if (i + 1 >= nums.length) return null;
        if (ops[i] == '×') {
          nums[i] = nums[i] * nums[i + 1];
        } else {
          nums[i] = nums[i + 1] != 0 ? nums[i] / nums[i + 1] : 0;
        }
        nums.removeAt(i + 1);
        ops.removeAt(i);
      } else {
        i++;
      }
    }

    if (nums.isEmpty) return null;
    var result = nums[0];
    for (i = 0; i < ops.length; i++) {
      if (i + 1 >= nums.length) return null;
      if (ops[i] == '+') {
        result += nums[i + 1];
      } else {
        result -= nums[i + 1];
      }
    }

    return result;
  }

  static List<String>? _tokenize(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    final tokens = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      final isUnaryMinus = char == '-' && i == 0;
      if (_operators.contains(char) && !isUnaryMinus) {
        if (buffer.isEmpty) return null;
        tokens.add(buffer.toString());
        tokens.add(char);
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isEmpty) return null;
    tokens.add(buffer.toString());
    return tokens;
  }

  static bool _isOperator(String token) {
    return token.length == 1 && _operators.contains(token);
  }
}
