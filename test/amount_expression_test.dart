import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/transactions/transaction_amount_expression.dart';

void main() {
  group('TransactionAmountExpression', () {
    test('evaluates live formula with multiplication precedence', () {
      expect(TransactionAmountExpression.preview('1+2×3'), 7);
      expect(TransactionAmountExpression.preview('10-6÷3'), 8);
      expect(TransactionAmountExpression.preview('-1+2'), 1);
      expect(TransactionAmountExpression.preview('1-2'), 0);
    });

    test('keeps last valid result while expression is incomplete', () {
      expect(TransactionAmountExpression.preview('1+2×'), 3);
      expect(TransactionAmountExpression.preview('4.'), 4);
    });

    test('normalizes ascii operators from external input', () {
      expect(TransactionAmountExpression.preview('2*3+8/4'), 8);
    });

    test('rejects invalid division result', () {
      expect(TransactionAmountExpression.preview('1÷0'), isNull);
    });

    test('normalizes incomplete and chained input safely', () {
      expect(TransactionAmountExpression.preview('12+'), 12);
      expect(TransactionAmountExpression.preview('12+3-'), 15);
      expect(TransactionAmountExpression.preview('0.5+1.25'), 1.75);
    });
  });
}
