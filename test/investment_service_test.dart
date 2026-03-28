import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/currency_model.dart';
import 'package:jive/core/database/investment_model.dart';
import 'package:jive/core/service/currency_service.dart';
import 'package:jive/core/service/investment_service.dart';

class _NullRateCurrencyService extends CurrencyService {
  _NullRateCurrencyService(super.isar);

  @override
  Future<double?> convert(double amount, String from, String to) async {
    return null;
  }
}

void main() {
  late Isar isar;
  late Directory dir;
  late CurrencyService currencyService;
  late InvestmentService investmentService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pubCache =
        Platform.environment['PUB_CACHE'] ??
        '${Platform.environment['HOME']}/.pub-cache';
    String? libPath;
    if (Platform.isMacOS) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    } else if (Platform.isLinux) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/linux/libisar.so';
    } else if (Platform.isWindows) {
      libPath =
          '$pubCache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/windows/isar.dll';
    }
    if (libPath != null && File(libPath).existsSync()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): libPath});
    } else {
      throw StateError('Isar core library not found for tests.');
    }
  });

  setUp(() async {
    CurrencyService.clearCache();
    dir = await Directory.systemTemp.createTemp(
      'jive_investment_service_test_',
    );
    isar = await Isar.open([
      JiveSecuritySchema,
      JiveHoldingSchema,
      JiveInvestmentTransactionSchema,
      JivePriceHistorySchema,
      JiveCurrencySchema,
      JiveExchangeRateSchema,
      JiveCurrencyPreferenceSchema,
      JiveExchangeRateHistorySchema,
    ], directory: dir.path);
    currencyService = CurrencyService(isar);
    await currencyService.initCurrencies();
    investmentService = InvestmentService(isar);
  });

  tearDown(() async {
    CurrencyService.clearCache();
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test(
    'portfolio summary converts foreign-currency holdings into base currency',
    () async {
      await currencyService.setManualRate('USD', 'CNY', 7.25);
      final security = await investmentService.addSecurity(
        ticker: 'AAPL',
        name: 'Apple',
        type: SecurityType.stock,
        currency: 'USD',
        latestPrice: 100,
      );

      await investmentService.addHolding(
        securityId: security.id,
        quantity: 2,
        costBasis: 80,
      );

      final summary = await investmentService.getPortfolioSummary(
        currencyService: currencyService,
        baseCurrency: 'CNY',
      );

      expect(summary.baseCurrency, 'CNY');
      expect(summary.holdingCount, 1);
      expect(summary.totalMarketValue, closeTo(1450, 1e-9));
      expect(summary.totalCost, closeTo(1160, 1e-9));
      expect(summary.totalProfitLoss, closeTo(290, 1e-9));

      final valuation = summary.holdings.single;
      expect(valuation.marketValue, 200);
      expect(valuation.marketValueInBase, closeTo(1450, 1e-9));
      expect(valuation.totalCostInBase, closeTo(1160, 1e-9));
      expect(valuation.profitLossInBase, closeTo(290, 1e-9));
    },
  );

  test(
    'recordTransaction rejects selling more than available holdings',
    () async {
      final security = await investmentService.addSecurity(
        ticker: 'TSLA',
        name: 'Tesla',
        type: SecurityType.stock,
        currency: 'USD',
        latestPrice: 200,
      );

      await investmentService.recordTransaction(
        securityId: security.id,
        action: 'buy',
        quantity: 1,
        price: 200,
        accountId: 7,
      );

      await expectLater(
        investmentService.recordTransaction(
          securityId: security.id,
          action: 'sell',
          quantity: 2,
          price: 210,
          accountId: 7,
        ),
        throwsA(
          isA<InvestmentValidationException>().having(
            (error) => error.code,
            'code',
            'insufficient_holding',
          ),
        ),
      );

      final holding = await investmentService.getHolding(
        securityId: security.id,
        accountId: 7,
      );
      expect(holding, isNotNull);
      expect(holding!.quantity, 1);
    },
  );

  test('syncHolding keeps positions isolated by accountId', () async {
    final security = await investmentService.addSecurity(
      ticker: 'NVDA',
      name: 'NVIDIA',
      type: SecurityType.stock,
      currency: 'USD',
      latestPrice: 120,
    );

    await investmentService.recordTransaction(
      securityId: security.id,
      action: 'buy',
      quantity: 10,
      price: 10,
      accountId: 1,
    );
    await investmentService.recordTransaction(
      securityId: security.id,
      action: 'buy',
      quantity: 5,
      price: 20,
      accountId: 2,
    );
    await investmentService.recordTransaction(
      securityId: security.id,
      action: 'sell',
      quantity: 5,
      price: 12,
      accountId: 1,
    );

    final holdings = await investmentService.getHoldings();
    holdings.sort((a, b) => (a.accountId ?? 0).compareTo(b.accountId ?? 0));

    expect(holdings, hasLength(2));
    expect(holdings[0].accountId, 1);
    expect(holdings[0].quantity, 5);
    expect(holdings[0].costBasis, closeTo(10, 1e-9));
    expect(holdings[1].accountId, 2);
    expect(holdings[1].quantity, 5);
    expect(holdings[1].costBasis, closeTo(20, 1e-9));
  });

  test('portfolio summary throws when exchange rate is missing', () async {
    final security = await investmentService.addSecurity(
      ticker: 'MSFT',
      name: 'Microsoft',
      type: SecurityType.stock,
      currency: 'USD',
      latestPrice: 100,
    );

    await investmentService.addHolding(
      securityId: security.id,
      quantity: 1,
      costBasis: 90,
    );

    await expectLater(
      investmentService.getPortfolioSummary(
        currencyService: _NullRateCurrencyService(isar),
        baseCurrency: 'CNY',
      ),
      throwsA(
        isA<InvestmentValidationException>().having(
          (error) => error.code,
          'code',
          'missing_exchange_rate',
        ),
      ),
    );
  });
}
