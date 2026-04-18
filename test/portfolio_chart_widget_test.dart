import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/investment_model.dart';
import 'package:jive/core/service/investment_service.dart';
import 'package:jive/feature/investment/portfolio_chart_widget.dart';

void main() {
  testWidgets('portfolio chart groups allocation by base-currency market value', (
    tester,
  ) async {
    final usdStock = JiveSecurity()
      ..id = 1
      ..ticker = 'AAPL'
      ..name = 'Apple'
      ..type = SecurityType.stock
      ..currency = 'USD'
      ..latestPrice = 100;
    final cnyFund = JiveSecurity()
      ..id = 2
      ..ticker = 'FUND'
      ..name = 'Fund'
      ..type = SecurityType.fund
      ..currency = 'CNY'
      ..latestPrice = 200;

    final usdHolding = JiveHolding()
      ..id = 11
      ..securityId = 1
      ..quantity = 1
      ..costBasis = 90;
    final cnyHolding = JiveHolding()
      ..id = 12
      ..securityId = 2
      ..quantity = 1
      ..costBasis = 180;

    final portfolio = PortfolioSummary(
      baseCurrency: 'CNY',
      totalMarketValue: 900,
      totalCost: 810,
      totalProfitLoss: 90,
      totalProfitLossPercent: 11.1,
      holdingCount: 2,
      holdings: [
        HoldingValuation(
          holding: usdHolding,
          security: usdStock,
          baseCurrency: 'CNY',
          currentPrice: 100,
          marketValue: 100,
          totalCost: 90,
          profitLoss: 10,
          marketValueInBase: 700,
          totalCostInBase: 630,
          profitLossInBase: 70,
          profitLossPercent: 11.1,
        ),
        HoldingValuation(
          holding: cnyHolding,
          security: cnyFund,
          baseCurrency: 'CNY',
          currentPrice: 200,
          marketValue: 200,
          totalCost: 180,
          profitLoss: 20,
          marketValueInBase: 200,
          totalCostInBase: 180,
          profitLossInBase: 20,
          profitLossPercent: 11.1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortfolioChartWidget(portfolio: portfolio),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('持仓分布'), findsOneWidget);
    expect(find.text('77.8%'), findsOneWidget);
    expect(find.text('22.2%'), findsOneWidget);
  });
}
