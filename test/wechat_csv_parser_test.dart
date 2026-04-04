import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/wechat_csv_parser.dart';

void main() {
  group('WechatCsvParser', () {
    group('isWechatFormat', () {
      test('returns true for WeChat header content', () {
        const content = '微信支付账单明细\n'
            '微信昵称：[测试用户]\n'
            '起始时间：[2025-01-01] 终止时间：[2025-03-31]\n';
        expect(WechatCsvParser.isWechatFormat(content), isTrue);
      });

      test('returns true when header contains 交易时间 and 交易对方', () {
        const content = '交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注\n';
        expect(WechatCsvParser.isWechatFormat(content), isTrue);
      });

      test('returns false for random CSV', () {
        const content = 'name,age,city\nAlice,30,Shanghai\nBob,25,Beijing\n';
        expect(WechatCsvParser.isWechatFormat(content), isFalse);
      });
    });

    group('parse', () {
      const sampleCsv = '微信支付账单明细\n'
          '微信昵称：[测试用户]\n'
          '起始时间：[2025-01-01 00:00:00] 终止时间：[2025-03-31 23:59:59]\n'
          '导出类型：[全部]\n'
          '导出时间：[2025-04-01 10:00:00]\n'
          '\n'
          '----------------------微信支付账单明细列表--------------------\n'
          '交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注\n'
          '2025-01-15 12:30:00,商户消费,美团外卖,午餐,支出,¥35.50,招商银行(1234),支付成功,T001,M001,/\n'
          '2025-01-16 09:00:00,转账,张三,转账,收入,¥200.00,零钱,已收钱,T002,,/\n'
          '2025-01-17 18:00:00,商户消费,滴滴出行,打车,支出,¥28.00,招商银行(1234),支付成功,T003,M003,/\n'
          '2025-01-18 20:00:00,商户消费,京东商城,购物,支出,¥99.00,招商银行(1234),已退款,T004,M004,/\n';

      test('extracts correct records from sample WeChat CSV', () {
        final records = WechatCsvParser.parse(sampleCsv);
        expect(records.length, 4);

        // First record: expense
        expect(records[0].amount, 35.50);
        expect(records[0].source, '微信支付');
        expect(records[0].type, 'expense');
        expect(records[0].rawText, contains('美团外卖'));
        expect(records[0].timestamp, DateTime(2025, 1, 15, 12, 30, 0));

        // Second record: income
        expect(records[1].amount, 200.00);
        expect(records[1].type, 'income');

        // Third record: expense
        expect(records[2].amount, 28.00);
        expect(records[2].type, 'expense');
      });

      test('skips non-completed transactions', () {
        const csvWithPending = '微信支付账单明细\n'
            '交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注\n'
            '2025-01-15 12:30:00,商户消费,美团外卖,午餐,支出,¥35.50,招商银行(1234),支付成功,T001,M001,/\n'
            '2025-01-16 12:00:00,商户消费,某商家,商品,支出,¥100.00,招商银行(1234),等待支付,T005,M005,/\n'
            '2025-01-17 12:00:00,商户消费,某商家,商品,支出,¥50.00,招商银行(1234),已取消,T006,M006,/\n';

        final records = WechatCsvParser.parse(csvWithPending);
        // Only the first record with 支付成功 should be included
        expect(records.length, 1);
        expect(records[0].amount, 35.50);
      });

      test('correctly identifies income vs expense', () {
        final records = WechatCsvParser.parse(sampleCsv);

        // 支出 -> expense
        expect(records[0].type, 'expense');
        // 收入 with 已收钱 -> income
        expect(records[1].type, 'income');
        // 已退款 -> income
        expect(records[3].type, 'income');
      });

      test('returns empty list for invalid content', () {
        final records = WechatCsvParser.parse('random,data\n1,2\n');
        expect(records, isEmpty);
      });

      test('returns empty list for empty content', () {
        final records = WechatCsvParser.parse('');
        expect(records, isEmpty);
      });
    });
  });
}
