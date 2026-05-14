import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/currency_model.dart';
import 'package:jive/core/service/currency_service.dart';

class _FakeCurrencyService extends CurrencyService {
  final Map<String, double> rates;

  _FakeCurrencyService(super.isar, this.rates);

  @override
  Future<ExchangeRateResponse?> fetchLiveRate(String from, String to) async {
    final value = rates['${from.toUpperCase()}/${to.toUpperCase()}'];
    if (value == null) return null;
    return ExchangeRateResponse(
      from: from.toUpperCase(),
      to: to.toUpperCase(),
      rate: value,
      date: DateTime.now(),
      source: 'test',
    );
  }
}

void main() {
  late Isar isar;
  late Directory dir;
  late CurrencyService service;

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
    dir = await Directory.systemTemp.createTemp('jive_currency_test_');
    isar = await Isar.open([
      JiveCurrencySchema,
      JiveExchangeRateSchema,
      JiveCurrencyPreferenceSchema,
      JiveExchangeRateHistorySchema,
    ], directory: dir.path);
    service = CurrencyService(isar);
    await service.initCurrencies();
  });

  tearDown(() async {
    CurrencyService.clearCache();
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test(
    'setManualRate refreshes cache immediately for both directions',
    () async {
      final before = await service.getRate('USD', 'CNY');
      expect(before, isNotNull);

      await service.setManualRate('USD', 'CNY', 8.0);

      final direct = await service.getRate('USD', 'CNY');
      final reverse = await service.getRate('CNY', 'USD');
      expect(direct, 8.0);
      expect(reverse, closeTo(0.125, 1e-9));
    },
  );

  test('setManualRate rejects non-positive rates', () async {
    expect(service.setManualRate('USD', 'CNY', 0), throwsArgumentError);
    expect(service.setManualRate('USD', 'CNY', -1), throwsArgumentError);
  });

  test(
    'fetchAndUpdateRates overrides stale cache and writes reverse cache',
    () async {
      final fake = _FakeCurrencyService(isar, {'USD/EUR': 0.5});
      await fake.initCurrencies();

      final before = await fake.getRate('USD', 'EUR');
      expect(before, isNotNull);
      expect(before, isNot(0.5));

      final updated = await fake.fetchAndUpdateRates('USD', ['EUR']);
      expect(updated['EUR'], 0.5);

      final direct = await fake.getRate('USD', 'EUR');
      final reverse = await fake.getRate('EUR', 'USD');
      expect(direct, 0.5);
      expect(reverse, closeTo(2.0, 1e-9));
    },
  );

  test('fetchAndUpdateRates ignores invalid non-positive live rates', () async {
    final fake = _FakeCurrencyService(isar, {'USD/JPY': 0});
    await fake.initCurrencies();

    final before = await fake.getRate('USD', 'JPY');
    expect(before, isNotNull);

    final updated = await fake.fetchAndUpdateRates('USD', ['JPY']);
    expect(updated, isEmpty);

    final after = await fake.getRate('USD', 'JPY');
    expect(after, before);
  });

  test('multi-currency overview shows account group display paths', () async {
    final overview = await service.calculateMultiCurrencyOverview(
      [
        _account(
          id: 1,
          name: '活期',
          groupName: '中国银行',
          currency: 'CNY',
          openingBalance: 1200,
        ),
        _account(
          id: 2,
          name: 'Visa 尾号 8899',
          groupName: '信用卡账户',
          type: 'liability',
          currency: 'CNY',
          openingBalance: -300,
        ),
      ],
      {1: 1200, 2: -300},
      'CNY',
    );

    expect(
      overview.assetGroups.single.accounts.single.accountName,
      '中国银行 / 活期 / CNY',
    );
    expect(
      overview.liabilityGroups.single.accounts.single.accountName,
      'Visa 尾号 8899',
    );
  });
}

JiveAccount _account({
  required int id,
  required String name,
  String type = 'asset',
  String currency = 'CNY',
  String? groupName,
  double openingBalance = 0,
}) {
  return JiveAccount()
    ..id = id
    ..name = name
    ..type = type
    ..currency = currency
    ..groupName = groupName
    ..openingBalance = openingBalance
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..iconName = 'account_balance_wallet';
}
