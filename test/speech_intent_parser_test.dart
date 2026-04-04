import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/speech_intent_parser.dart';

void main() {
  late SpeechIntentParser parser;
  final fixedNow = DateTime(2026, 4, 4, 10, 0, 0);

  setUp(() {
    parser = SpeechIntentParser();
  });

  group('SpeechIntentParser.parse', () {
    test('returns null for empty string', () {
      expect(parser.parse('', now: fixedNow), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(parser.parse('   ', now: fixedNow), isNull);
    });

    test('parses expense with amount: 买了咖啡35块', () {
      final result = parser.parse('买了咖啡35块', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 35.0);
      expect(result.type, 'expense');
      expect(result.isValid, isTrue);
    });

    test('parses income with amount: 收到工资8000元', () {
      final result = parser.parse('收到工资8000元', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 8000.0);
      expect(result.type, 'income');
      expect(result.isValid, isTrue);
    });

    test('parses transfer with amount: 转账给妈妈500', () {
      final result = parser.parse('转账给妈妈500', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 500.0);
      expect(result.type, 'transfer');
      expect(result.isValid, isTrue);
    });

    test('parses decimal amount: 昨天打车25块5', () {
      final result = parser.parse('昨天打车25块5', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 25.5);
      expect(result.type, 'expense');
      expect(result.isValid, isTrue);
    });

    test('parses yesterday timestamp: 昨天打车25块5', () {
      final result = parser.parse('昨天打车25块5', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.timestamp.day, fixedNow.day - 1);
      expect(result.timestamp.month, fixedNow.month);
      expect(result.timestamp.year, fixedNow.year);
    });

    test('rawText preserves original input', () {
      final result = parser.parse('买了咖啡35块', now: fixedNow);
      expect(result!.rawText, '买了咖啡35块');
    });

    test('isValid is false when no amount extracted', () {
      final result = parser.parse('今天天气不错', now: fixedNow);
      // Even if parse returns a result, without a recognized amount > 0
      // isValid should reflect that
      if (result != null && result.amount == null) {
        expect(result.isValid, isFalse);
      }
    });

    test('parses expense keyword: 外卖30元', () {
      final result = parser.parse('外卖30元', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 30.0);
      expect(result.type, 'expense');
    });

    test('parses income keyword: 奖金5000元', () {
      final result = parser.parse('奖金5000元', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 5000.0);
      expect(result.type, 'income');
    });

    test('parses transfer keyword: 还款1000元', () {
      final result = parser.parse('还款1000元', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 1000.0);
      expect(result.type, 'transfer');
    });

    test('parses amount with 毛 unit', () {
      final result = parser.parse('花了5毛', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.amount, 0.5);
    });

    test('parses date: 前天买了水果20元', () {
      final result = parser.parse('前天买了水果20元', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.timestamp.day, fixedNow.day - 2);
      expect(result.amount, 20.0);
      expect(result.type, 'expense');
    });

    test('cleanedText removes amount and cleanup tokens', () {
      final result = parser.parse('帮我记账买了咖啡35块', now: fixedNow);

      expect(result, isNotNull);
      expect(result!.cleanedText, isNotNull);
      // The cleaned text should not contain the amount token or cleanup tokens
      expect(result.cleanedText!.contains('35块'), isFalse);
      expect(result.cleanedText!.contains('帮我'), isFalse);
      expect(result.cleanedText!.contains('记账'), isFalse);
    });
  });

  group('SpeechIntent', () {
    test('isValid returns true for positive amount', () {
      final intent = SpeechIntent(
        rawText: 'test',
        cleanedText: 'test',
        amount: 100.0,
        timestamp: DateTime(2026, 1, 1),
        type: 'expense',
        accountHint: null,
        toAccountHint: null,
      );
      expect(intent.isValid, isTrue);
    });

    test('isValid returns false for null amount', () {
      final intent = SpeechIntent(
        rawText: 'test',
        cleanedText: 'test',
        amount: null,
        timestamp: DateTime(2026, 1, 1),
        type: null,
        accountHint: null,
        toAccountHint: null,
      );
      expect(intent.isValid, isFalse);
    });
  });
}
