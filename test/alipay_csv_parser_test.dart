import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/alipay_csv_parser.dart';

void main() {
  group('AlipayCsvParser', () {
    group('isAlipayFormat', () {
      test('returns true for Alipay header', () {
        const content = '支付宝交易记录明细查询\n'
            '账号：[test@example.com]\n'
            '起始日期：[2025-01-01 00:00:00] 终止日期：[2025-03-31 23:59:59]\n'
            '交易号,商家订单号,交易创建时间\n';
        expect(AlipayCsvParser.isAlipayFormat(content), isTrue);
      });

      test('returns false for non-Alipay content', () {
        const content = 'name,age,city\nAlice,30,Shanghai\n';
        expect(AlipayCsvParser.isAlipayFormat(content), isFalse);
      });
    });

    group('parse', () {
      const sampleCsv = '支付宝交易记录明细查询\n'
          '账号：[test@example.com]\n'
          '起始日期：[2025-01-01 00:00:00]    终止日期：[2025-03-31 23:59:59]\n'
          '\n'
          '交易号,商家订单号,交易创建时间,付款时间,最近修改时间,交易来源地,类型,交易对方,商品名称,金额（元）,收/支,交易状态,服务费（元）,成功退款（元）,备注,资金状态\n'
          'T001,M001,2025-01-15 12:00:00,2025-01-15 12:00:01,2025-01-15 12:00:01,其他,即时到账,美团外卖,午餐,35.50,支出,交易成功,0,0,,已支出\n'
          'T002,M002,2025-01-16 09:00:00,2025-01-16 09:00:01,2025-01-16 09:00:01,其他,转账,张三,转账,200.00,收入,交易成功,0,0,,已收入\n'
          'T003,M003,2025-01-17 18:00:00,2025-01-17 18:00:01,2025-01-17 18:00:01,其他,即时到账,滴滴出行,打车,28.00,支出,交易成功,0,0,,已支出\n';

      test('extracts correct records from sample Alipay CSV', () {
        final records = AlipayCsvParser.parse(sampleCsv);
        expect(records.length, 3);

        expect(records[0].amount, 35.50);
        expect(records[0].source, '支付宝');
        expect(records[0].type, 'expense');
        expect(records[0].rawText, contains('美团外卖'));

        expect(records[1].amount, 200.00);
        expect(records[1].type, 'income');

        expect(records[2].amount, 28.00);
        expect(records[2].type, 'expense');
      });

      test('handles refunds as income type', () {
        const refundCsv = '支付宝交易记录明细查询\n'
            '账号：[test@example.com]\n'
            '\n'
            '交易号,商家订单号,交易创建时间,付款时间,最近修改时间,交易来源地,类型,交易对方,商品名称,金额（元）,收/支,交易状态,服务费（元）,成功退款（元）,备注,资金状态\n'
            'T010,M010,2025-02-01 10:00:00,2025-02-01 10:00:01,2025-02-05 14:00:00,其他,即时到账,淘宝商家,退货商品,99.00,支出,退款成功,0,99.00,,已支出\n';

        final records = AlipayCsvParser.parse(refundCsv);
        expect(records.length, 1);
        expect(records[0].type, 'income');
        expect(records[0].amount, 99.00);
      });

      test('skips 不计收支 transactions', () {
        const noCountCsv = '支付宝交易记录明细查询\n'
            '账号：[test@example.com]\n'
            '\n'
            '交易号,商家订单号,交易创建时间,付款时间,最近修改时间,交易来源地,类型,交易对方,商品名称,金额（元）,收/支,交易状态,服务费（元）,成功退款（元）,备注,资金状态\n'
            'T020,M020,2025-03-01 10:00:00,2025-03-01 10:00:01,2025-03-01 10:00:01,其他,即时到账,余额宝,转入余额宝,500.00,支出,交易成功,0,0,,不计收支\n'
            'T021,M021,2025-03-02 12:00:00,2025-03-02 12:00:01,2025-03-02 12:00:01,其他,即时到账,超市,日用品,45.00,支出,交易成功,0,0,,已支出\n';

        final records = AlipayCsvParser.parse(noCountCsv);
        expect(records.length, 1);
        expect(records[0].amount, 45.00);
        expect(records[0].rawText, contains('超市'));
      });

      test('returns empty list for invalid content', () {
        final records = AlipayCsvParser.parse('random,stuff\n1,2\n');
        expect(records, isEmpty);
      });
    });
  });
}
