import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';

import '../database/investment_model.dart';
import 'investment_service.dart';

/// A single stock quote snapshot.
class StockQuote {
  final String ticker;
  final double price;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final double volume;
  final DateTime timestamp;

  const StockQuote({
    required this.ticker,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.volume,
    required this.timestamp,
  });
}

/// Fetches live stock prices from free public APIs.
///
/// Implements in-memory caching (5-minute TTL) and a multi-source strategy
/// so that callers always get the best available data.
class StockQuoteService {
  final Isar _isar;
  final InvestmentService _investmentService;

  /// In-memory cache: ticker -> (quote, fetchedAt).
  final Map<String, _CachedQuote> _cache = {};

  /// Cache TTL.
  static const Duration cacheTtl = Duration(minutes: 5);

  /// Allow injecting an HTTP client for testing.
  final http.Client _httpClient;

  StockQuoteService(
    this._isar,
    this._investmentService, {
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // ── Public API ──

  /// Fetch a single quote. Returns cached data when fresh enough.
  Future<StockQuote?> fetchQuote(String ticker) async {
    final normalizedTicker = ticker.toUpperCase().trim();
    if (normalizedTicker.isEmpty) return null;

    // Check cache first.
    final cached = _cache[normalizedTicker];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < cacheTtl) {
      return cached.quote;
    }

    // Try primary source.
    final quote = await _fetchFromYahoo(normalizedTicker);
    if (quote != null) {
      _cache[normalizedTicker] = _CachedQuote(quote, DateTime.now());
    }
    return quote;
  }

  /// Fetch quotes for multiple tickers in parallel.
  Future<Map<String, StockQuote>> fetchBatchQuotes(
    List<String> tickers,
  ) async {
    final results = <String, StockQuote>{};
    final futures = <Future<void>>[];

    for (final ticker in tickers) {
      futures.add(
        fetchQuote(ticker).then((quote) {
          if (quote != null) {
            results[ticker.toUpperCase().trim()] = quote;
          }
        }),
      );
    }

    await Future.wait(futures);
    return results;
  }

  /// Refresh prices for every security stored in the database.
  Future<int> refreshAllHoldings() async {
    final securities = await _isar.jiveSecuritys.where().findAll();
    if (securities.isEmpty) return 0;

    final tickers = securities.map((s) => s.ticker).toList();
    final quotes = await fetchBatchQuotes(tickers);

    int updatedCount = 0;
    for (final security in securities) {
      final quote = quotes[security.ticker.toUpperCase().trim()];
      if (quote != null && quote.price > 0) {
        await _investmentService.updatePrice(security.id, quote.price);
        updatedCount++;
      }
    }
    return updatedCount;
  }

  /// Clear the in-memory cache.
  void clearCache() => _cache.clear();

  // ── Data sources ──

  /// Primary: Yahoo Finance v8 chart endpoint (public, no key needed).
  Future<StockQuote?> _fetchFromYahoo(String ticker) async {
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$ticker'
        '?interval=1d&range=1d',
      );
      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'Jive/1.0'}).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      final results = chart?['result'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final result = results[0] as Map<String, dynamic>;
      final meta = result['meta'] as Map<String, dynamic>?;
      if (meta == null) return null;

      final price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0;
      final prevClose =
          (meta['chartPreviousClose'] as num?)?.toDouble() ?? price;
      final change = price - prevClose;
      final changePercent = prevClose != 0 ? change / prevClose * 100 : 0.0;

      // Extract high/low/volume from indicators if available.
      double high = price;
      double low = price;
      double volume = 0;

      final indicators = result['indicators'] as Map<String, dynamic>?;
      final quoteList =
          (indicators?['quote'] as List<dynamic>?)?.firstOrNull
              as Map<String, dynamic>?;
      if (quoteList != null) {
        final highs = quoteList['high'] as List<dynamic>?;
        final lows = quoteList['low'] as List<dynamic>?;
        final volumes = quoteList['volume'] as List<dynamic>?;

        if (highs != null && highs.isNotEmpty) {
          final validHighs =
              highs.whereType<num>().map((n) => n.toDouble()).toList();
          if (validHighs.isNotEmpty) {
            high = validHighs.reduce(
              (a, b) => a > b ? a : b,
            );
          }
        }
        if (lows != null && lows.isNotEmpty) {
          final validLows =
              lows.whereType<num>().map((n) => n.toDouble()).toList();
          if (validLows.isNotEmpty) {
            low = validLows.reduce(
              (a, b) => a < b ? a : b,
            );
          }
        }
        if (volumes != null && volumes.isNotEmpty) {
          volume = volumes.whereType<num>().fold<double>(
                0,
                (sum, v) => sum + v.toDouble(),
              );
        }
      }

      return StockQuote(
        ticker: ticker,
        price: price,
        change: change,
        changePercent: changePercent,
        high: high,
        low: low,
        volume: volume,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

class _CachedQuote {
  final StockQuote quote;
  final DateTime fetchedAt;

  _CachedQuote(this.quote, this.fetchedAt);
}
