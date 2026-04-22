import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/transactions/amount_expression.dart';

void main() {
  group('AmountExpression', () {
    test('evaluates live formula with multiplication precedence', () {
      expect(AmountExpression.evaluate('1+2×3'), 7);
      expect(AmountExpression.evaluate('10-6÷3'), 8);
      expect(AmountExpression.evaluate('-1+2'), 1);
    });

    test('keeps last valid result while expression is incomplete', () {
      expect(AmountExpression.evaluate('1+2×'), 3);
      expect(AmountExpression.evaluate('4.'), 4);
    });

    test('normalizes ascii operators from external input', () {
      expect(AmountExpression.evaluate('2*3+8/4'), 8);
    });

    test('rejects invalid division result', () {
      expect(AmountExpression.evaluate('1÷0'), isNull);
    });

    test('normalizes incomplete and chained input safely', () {
      expect(AmountExpression.evaluate('12+'), 12);
      expect(AmountExpression.evaluate('12+3-'), 15);
      expect(AmountExpression.evaluate('0.5+1.25'), 1.75);
    });
  });
}
