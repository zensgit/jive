import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/transactions/transaction_amount_expression.dart';

void main() {
  String format(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceAll(RegExp(r'\.?0+$'), '');
  }

  test('previews incomplete operator expressions with last valid result', () {
    expect(TransactionAmountExpression.hasExpression('1+'), isTrue);
    expect(TransactionAmountExpression.isComplete('1+'), isFalse);
    expect(TransactionAmountExpression.preview('1+'), 1);
    expect(TransactionAmountExpression.evaluate('1+', format), '1');

    expect(TransactionAmountExpression.preview('1-'), 1);
    expect(TransactionAmountExpression.evaluate('1-', format), '1');
  });

  test('evaluates complete expressions with multiplication precedence', () {
    expect(TransactionAmountExpression.isComplete('1+2×3-4÷2'), isTrue);
    expect(TransactionAmountExpression.preview('1+2×3-4÷2'), 5);
    expect(TransactionAmountExpression.evaluate('1+2×3-4÷2', format), '5');
  });

  test('clamps negative expression result to zero', () {
    expect(TransactionAmountExpression.preview('1-2'), 0);
    expect(TransactionAmountExpression.evaluate('1-2', format), '0');
  });
}
