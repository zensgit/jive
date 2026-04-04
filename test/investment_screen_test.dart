import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';
import 'package:jive/core/database/investment_model.dart';
import 'package:jive/core/service/investment_service.dart';
import 'package:jive/feature/investment/investment_screen.dart';

void main() {
  setUpAll(() async => setupGoogleFontsForTests());

  testWidgets(
    'screen shows unheld securities alongside holdings and displays correct currency symbols',
    (tester) async {
      final apple = JiveSecurity()
        ..id = 1
        ..ticker = 'AAPL'
        ..name = 'Apple'
        ..type = SecurityType.stock
        ..currency = 'USD';
      final bitcoin = JiveSecurity()
        ..id = 2
        ..ticker = 'BTC-USD'
        ..name = 'Bitcoin'
        ..type = SecurityType.crypto
        ..currency = 'USD'
        ..latestPrice = 60000;
      final holding = JiveHolding()
        ..id = 11
        ..securityId = 1
        ..quantity = 1
        ..costBasis = 80;
      final summary = PortfolioSummary(
        baseCurrency: 'CNY',
        totalMarketValue: 725,
        totalCost: 580,
        totalProfitLoss: 145,
        totalProfitLossPercent: 25,
        holdingCount: 1,
        holdings: [
          HoldingValuation(
            holding: holding,
            security: apple..latestPrice = 100,
            baseCurrency: 'CNY',
            currentPrice: 100,
            marketValue: 100,
            totalCost: 80,
            profitLoss: 20,
            marketValueInBase: 725,
            totalCostInBase: 580,
            profitLossInBase: 145,
            profitLossPercent: 25,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InvestmentScreen(
            debugPortfolio: summary,
            debugBaseCurrency: 'CNY',
            debugSecurities: [apple, bitcoin],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('持仓明细'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('未持有证券'), 200);
      expect(find.text('未持有证券'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Bitcoin (BTC-USD)'), findsOneWidget);
      expect(find.text('\$100.00'), findsOneWidget);
      expect(find.text('¥725.00'), findsOneWidget);
    },
  );
}
