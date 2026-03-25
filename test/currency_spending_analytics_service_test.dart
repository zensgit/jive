import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/service/currency_spending_analytics_service.dart';

void main() {
  const service = CurrencySpendingAnalyticsService();

  test('buildSpendingData aggregates across accounts and currencies', () async {
    final now = DateTime(2026, 2, 21, 9);
    final accountById = {
      1: _account(id: 1, currency: 'usd'),
      2: _account(id: 2, currency: 'EUR'),
      3: _account(id: 3, currency: 'CNY'),
    };

    final result = await service.buildSpendingData(
      transactions: [
        _transaction(
          amount: 10,
          accountId: 1,
          type: 'expense',
          timestamp: DateTime(2025, 12, 5),
        ),
        _transaction(
          amount: 5,
          accountId: 1,
          type: 'income',
          timestamp: DateTime(2026, 1, 10),
        ),
        _transaction(
          amount: 20,
          accountId: 2,
          type: 'expense',
          timestamp: DateTime(2026, 1, 15),
        ),
        _transaction(
          amount: 30,
          accountId: 3,
          type: 'expense',
          timestamp: DateTime(2026, 2, 2),
        ),
        _transaction(
          amount: 40,
          accountId: 1,
          type: 'expense',
          timestamp: DateTime(2026, 2, 3),
        ),
        _transaction(
          amount: 999,
          accountId: 1,
          type: 'expense',
          timestamp: DateTime(2025, 11, 30),
        ),
      ],
      accountById: accountById,
      baseCurrency: 'CNY',
      selectedMonths: 3,
      now: now,
      converter: (amount, from, to) async {
        if (from == to) {
          return amount;
        }
        if (from == 'USD' && to == 'CNY') {
          return amount * 7;
        }
        if (from == 'EUR' && to == 'CNY') {
          return amount * 8;
        }
        return null;
      },
    );

    expect(result.spendingByCurrency.map((e) => e.currency), [
      'USD',
      'EUR',
      'CNY',
    ]);
    expect(result.totalConvertedSpending, 575);

    final byCurrency = {
      for (final item in result.spendingByCurrency) item.currency: item,
    };

    final usd = byCurrency['USD']!;
    expect(usd.totalAmount, 55);
    expect(usd.convertedAmount, 385);
    expect(usd.transactionCount, 3);
    expect(usd.monthlyData.map((m) => m.amount).toList(), [10, 5, 40]);

    final eur = byCurrency['EUR']!;
    expect(eur.totalAmount, 20);
    expect(eur.convertedAmount, 160);
    expect(eur.transactionCount, 1);
    expect(eur.monthlyData.map((m) => m.amount).toList(), [0, 20, 0]);

    final cny = byCurrency['CNY']!;
    expect(cny.totalAmount, 30);
    expect(cny.convertedAmount, 30);
    expect(cny.transactionCount, 1);
    expect(cny.monthlyData.map((m) => m.amount).toList(), [0, 0, 30]);
  });

  test(
    'buildSpendingData falls back to base currency when account is missing',
    () async {
      final now = DateTime(2026, 2, 21, 9);
      final accountById = {
        1: _account(id: 1, currency: 'USD'),
        2: _account(id: 2, currency: '  '),
      };

      final result = await service.buildSpendingData(
        transactions: [
          _transaction(
            amount: 50,
            accountId: 999,
            type: 'expense',
            timestamp: DateTime(2026, 2, 2),
          ),
          _transaction(
            amount: 10,
            accountId: null,
            type: 'income',
            timestamp: DateTime(2026, 2, 3),
          ),
          _transaction(
            amount: 5,
            accountId: 2,
            type: 'expense',
            timestamp: DateTime(2026, 2, 4),
          ),
          _transaction(
            amount: 20,
            accountId: 1,
            type: 'expense',
            timestamp: DateTime(2026, 2, 5),
          ),
        ],
        accountById: accountById,
        baseCurrency: 'EUR',
        selectedMonths: 1,
        now: now,
        converter: (amount, from, to) async {
          if (from == 'USD' && to == 'EUR') {
            return amount * 2;
          }
          return null;
        },
      );

      final byCurrency = {
        for (final item in result.spendingByCurrency) item.currency: item,
      };

      expect(byCurrency['EUR']!.totalAmount, 65);
      expect(byCurrency['EUR']!.transactionCount, 3);
      expect(byCurrency['EUR']!.convertedAmount, 65);

      expect(byCurrency['USD']!.totalAmount, 20);
      expect(byCurrency['USD']!.convertedAmount, 40);

      expect(result.totalConvertedSpending, 105);
    },
  );

  test('buildSpendingData fills missing months with zero', () async {
    final now = DateTime(2026, 2, 21, 9);
    final accountById = {1: _account(id: 1, currency: 'USD')};

    final result = await service.buildSpendingData(
      transactions: [
        _transaction(
          amount: 12,
          accountId: 1,
          type: 'expense',
          timestamp: DateTime(2025, 12, 10),
        ),
        _transaction(
          amount: 8,
          accountId: 1,
          type: 'expense',
          timestamp: DateTime(2026, 2, 3),
        ),
      ],
      accountById: accountById,
      baseCurrency: 'USD',
      selectedMonths: 4,
      now: now,
    );

    expect(result.spendingByCurrency, hasLength(1));
    final monthly = result.spendingByCurrency.single.monthlyData;

    expect(monthly.map((m) => m.month).toList(), [
      DateTime(2025, 11, 1),
      DateTime(2025, 12, 1),
      DateTime(2026, 1, 1),
      DateTime(2026, 2, 1),
    ]);
    expect(monthly.map((m) => m.amount).toList(), [0, 12, 0, 8]);
  });

  test(
    'buildSpendingData accumulates converted totals from grouped amounts',
    () async {
      final now = DateTime(2026, 2, 21, 9);
      final accountById = {
        1: _account(id: 1, currency: 'USD'),
        2: _account(id: 2, currency: 'JPY'),
        3: _account(id: 3, currency: 'CNY'),
      };
      final conversionCalls = <String>[];

      final result = await service.buildSpendingData(
        transactions: [
          _transaction(
            amount: 10,
            accountId: 1,
            type: 'expense',
            timestamp: DateTime(2026, 2, 1),
          ),
          _transaction(
            amount: 20,
            accountId: 1,
            type: 'expense',
            timestamp: DateTime(2026, 2, 2),
          ),
          _transaction(
            amount: 1000,
            accountId: 2,
            type: 'expense',
            timestamp: DateTime(2026, 2, 3),
          ),
          _transaction(
            amount: 40,
            accountId: 3,
            type: 'expense',
            timestamp: DateTime(2026, 2, 4),
          ),
        ],
        accountById: accountById,
        baseCurrency: 'CNY',
        selectedMonths: 1,
        now: now,
        converter: (amount, from, to) async {
          conversionCalls.add('$from->$to:$amount');
          if (from == 'USD' && to == 'CNY') {
            return 210;
          }
          if (from == 'JPY' && to == 'CNY') {
            return 50;
          }
          return null;
        },
      );

      expect(conversionCalls, ['USD->CNY:30.0', 'JPY->CNY:1000.0']);

      final byCurrency = {
        for (final item in result.spendingByCurrency) item.currency: item,
      };
      expect(byCurrency['USD']!.totalAmount, 30);
      expect(byCurrency['USD']!.convertedAmount, 210);
      expect(byCurrency['JPY']!.totalAmount, 1000);
      expect(byCurrency['JPY']!.convertedAmount, 50);
      expect(byCurrency['CNY']!.convertedAmount, 40);

      expect(result.totalConvertedSpending, 300);
    },
  );
}

JiveAccount _account({required int id, required String currency}) {
  return JiveAccount()
    ..id = id
    ..key = 'account_$id'
    ..name = 'Account $id'
    ..type = 'asset'
    ..currency = currency
    ..iconName = 'account_balance_wallet'
    ..order = id
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..updatedAt = DateTime(2026, 1, 1);
}

JiveTransaction _transaction({
  required double amount,
  required int? accountId,
  required String type,
  required DateTime timestamp,
}) {
  return JiveTransaction()
    ..amount = amount
    ..source = 'seed'
    ..timestamp = timestamp
    ..type = type
    ..accountId = accountId;
}
