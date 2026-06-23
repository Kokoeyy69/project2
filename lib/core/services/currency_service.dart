import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/env.dart';
import 'exchange_rate_model.dart';

/// Resilient currency exchange service with automatic failover
///
/// This service implements a robust currency rate fetching system:
/// 1. Primary API: ExchangeRate-API (requires API key)
/// 2. Fallback API: Frankfurter API (no key required, EU Central Bank rates)
///
/// Caching Strategy:
/// - Rates are cached in Hive for 12 hours
/// - Cache is checked before any API call
/// - If cache is valid (< 12 hours old), cached data is used
/// - Network is only called when cache is expired or missing
///
/// Failover Logic:
/// - If primary API returns 429 (rate limit), timeout, or error -> try fallback
/// - If fallback also fails -> return cached data if available
/// - If no cache available -> throw exception with last error
class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static CurrencyService get instance => _instance;

  final Dio _dio = Dio();

  // API Configuration - Using obfuscated key from Env
  static final String _primaryBaseUrl =
      'https://v6.exchangerate-api.com/v6/${Env.exchangeRateApiKey}/latest/USD';
  static const String _fallbackBaseUrl =
      'https://api.frankfurter.app/latest?from=USD';

  // Cache configuration
  static const String _cacheBoxName = 'currency_cache';
  static const String _cacheKey = 'latest_rates';
  static const Duration _cacheMaxAge = Duration(hours: 12);

  // Supported currencies for primary API (ExchangeRate-API supports ~160+ currencies)
  static const List<String> _supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'IDR',
    'CNY',
    'JPY',
    'SGD',
    'MYR',
    'AUD',
    'CAD',
    'CHF',
    'HKD',
    'NZD',
    'SEK',
    'KRW',
    'TRY',
    'INR',
    'RUB',
    'BRL',
    'ZAR',
  ];

  late Box _cacheBox;
  bool _initialized = false;

  /// Initialize the service (call after HiveCacheService.init())
  Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      _cacheBox = await Hive.openBox(_cacheBoxName);
      _initialized = true;
      debugPrint('[CurrencyService] Initialized successfully');
    } catch (e) {
      debugPrint('[CurrencyService] Initialization error: $e');
      rethrow;
    }
  }

  /// Fetch latest exchange rates with failover and caching
  ///
  /// Returns [ExchangeRateModel] with current rates
  /// Throws exception if both APIs fail and no cache is available
  Future<ExchangeRateModel> fetchLatestRates({
    bool forceRefresh = false,
  }) async {
    // Step 1: Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedRates = await _getCachedRates();
      if (cachedRates != null && !cachedRates.isStale(maxAge: _cacheMaxAge)) {
        debugPrint(
          '[CurrencyService] Using cached rates from ${cachedRates.timestamp}',
        );
        return cachedRates;
      }
    }

    // Step 2: Try primary API (ExchangeRate-API)
    try {
      final rates = await _fetchFromPrimaryApi();
      await _cacheRates(rates);
      debugPrint('[CurrencyService] Fetched rates from primary API');
      return rates;
    } catch (e) {
      debugPrint('[CurrencyService] Primary API failed: $e');
      // Continue to fallback
    }

    // Step 3: Try fallback API (Frankfurter)
    try {
      final rates = await _fetchFromFallbackApi();
      await _cacheRates(rates);
      debugPrint('[CurrencyService] Fetched rates from fallback API');
      return rates;
    } catch (e) {
      debugPrint('[CurrencyService] Fallback API failed: $e');
    }

    // Step 4: If both APIs fail, return cached data if available (even if stale)
    final staleCache = await _getCachedRates();
    if (staleCache != null) {
      debugPrint('[CurrencyService] Both APIs failed, using stale cache');
      return staleCache;
    }

    // Step 5: No data available at all
    throw Exception(
      'Failed to fetch exchange rates: both APIs are unavailable and no cache exists. '
      'Please check your internet connection.',
    );
  }

  /// Get cached rates from Hive
  Future<ExchangeRateModel?> _getCachedRates() async {
    try {
      final cachedJson = _cacheBox.get(_cacheKey);
      if (cachedJson != null) {
        if (cachedJson is Map<String, dynamic>) {
          return ExchangeRateModel.fromJson(cachedJson);
        } else if (cachedJson is String) {
          // Handle legacy string storage
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          return ExchangeRateModel.fromJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('[CurrencyService] Error reading cache: $e');
    }
    return null;
  }

  /// Cache rates to Hive
  Future<void> _cacheRates(ExchangeRateModel rates) async {
    try {
      await _cacheBox.put(_cacheKey, rates.toJson());
      debugPrint('[CurrencyService] Rates cached successfully');
    } catch (e) {
      debugPrint('[CurrencyService] Error caching rates: $e');
    }
  }

  /// Fetch from primary API (ExchangeRate-API)
  ///
  /// API Response format:
  /// {
  ///   "result": "success",
  ///   "documentation": "...",
  ///   "terms_of_use": "...",
  ///   "time_last_update_unix": 1234567890,
  ///   "time_last_update_utc": "Mon, 01 Jan 2024 00:00:00 +0000",
  ///   "time_next_update_utc": "Tue, 02 Jan 2024 00:00:00 +0000",
  ///   "base_code": "USD",
  ///   "conversion_rates": { "USD": 1, "EUR": 0.85, ... }
  /// }
  Future<ExchangeRateModel> _fetchFromPrimaryApi() async {
    try {
      final response = await _dio.get(
        _primaryBaseUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check for API-level errors
        if (data['result'] == 'error') {
          throw Exception(
            'ExchangeRate-API error: ${data['error-type'] ?? 'Unknown error'}',
          );
        }

        final conversionRates =
            data['conversion_rates'] as Map<String, dynamic>?;
        if (conversionRates == null) {
          throw Exception('Invalid response format from ExchangeRate-API');
        }

        // Convert to our format (rates relative to USD)
        final rates = <String, double>{};
        for (final currency in _supportedCurrencies) {
          final rate = conversionRates[currency];
          if (rate != null) {
            rates[currency] = (rate as num).toDouble();
          }
        }

        // Ensure USD base rate is 1.0
        rates['USD'] = 1.0;

        return ExchangeRateModel(
          rates: rates,
          timestamp: DateTime.now(),
          baseCurrency: 'USD',
        );
      } else if (response.statusCode == 429) {
        throw Exception('ExchangeRate-API rate limit exceeded (429)');
      } else {
        throw Exception(
          'ExchangeRate-API returned status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('ExchangeRate-API timeout');
      }
      if (e.response?.statusCode == 429) {
        throw Exception('ExchangeRate-API rate limit exceeded (429)');
      }
      throw Exception('ExchangeRate-API error: ${e.message}');
    }
  }

  /// Fetch from fallback API (Frankfurter - EU Central Bank rates)
  ///
  /// API Response format:
  /// {
  ///   "amount": 1,
  ///   "base": "USD",
  ///   "start_date": "2024-01-01",
  ///   "end_date": "2024-01-01",
  ///   "rates": { "EUR": 0.85, "GBP": 0.73, ... }
  /// }
  ///
  /// Note: Frankfurter API has limited currency support (~30 currencies)
  /// but is reliable and doesn't require an API key.
  Future<ExchangeRateModel> _fetchFromFallbackApi() async {
    try {
      final response = await _dio.get(
        _fallbackBaseUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final ratesJson = data['rates'] as Map<String, dynamic>?;

        if (ratesJson == null) {
          throw Exception('Invalid response format from Frankfurter API');
        }

        // Convert to our format (rates relative to USD)
        final rates = <String, double>{'USD': 1.0};

        for (final entry in ratesJson.entries) {
          final currency = entry.key;
          final rate = entry.value;
          if (rate != null && _supportedCurrencies.contains(currency)) {
            rates[currency] = (rate as num).toDouble();
          }
        }

        // Add manually defined rates for currencies not in Frankfurter
        // These are approximate and should be updated from primary API when available
        _addFallbackApproximateRates(rates);

        return ExchangeRateModel(
          rates: rates,
          timestamp: DateTime.now(),
          baseCurrency: 'USD',
        );
      } else {
        throw Exception(
          'Frankfurter API returned status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Frankfurter API timeout');
      }
      throw Exception('Frankfurter API error: ${e.message}');
    }
  }

  /// Add approximate rates for currencies not available in Frankfurter API
  /// These are rough estimates and should be replaced with real data when available
  void _addFallbackApproximateRates(Map<String, double> rates) {
    // Only add if not already present
    if (!rates.containsKey('IDR')) {
      rates['IDR'] = 15500.0; // Approximate USD to IDR
    }
    if (!rates.containsKey('CNY')) {
      rates['CNY'] = 7.2; // Approximate USD to CNY
    }
    if (!rates.containsKey('SGD')) {
      rates['SGD'] = 1.34;
    }
    if (!rates.containsKey('MYR')) {
      rates['MYR'] = 4.7;
    }
    if (!rates.containsKey('KRW')) {
      rates['KRW'] = 1300.0;
    }
    if (!rates.containsKey('TRY')) {
      rates['TRY'] = 29.0;
    }
    if (!rates.containsKey('INR')) {
      rates['INR'] = 83.0;
    }
    if (!rates.containsKey('RUB')) {
      rates['RUB'] = 90.0;
    }
    if (!rates.containsKey('BRL')) {
      rates['BRL'] = 5.0;
    }
    if (!rates.containsKey('ZAR')) {
      rates['ZAR'] = 18.5;
    }
    if (!rates.containsKey('HKD')) {
      rates['HKD'] = 7.82;
    }
    if (!rates.containsKey('NZD')) {
      rates['NZD'] = 1.6;
    }
    if (!rates.containsKey('SEK')) {
      rates['SEK'] = 10.3;
    }
  }

  /// Get current rates from cache only (no network call)
  Future<ExchangeRateModel?> getCachedRates() => _getCachedRates();

  /// Clear the currency cache
  Future<void> clearCache() async {
    try {
      await _cacheBox.delete(_cacheKey);
      debugPrint('[CurrencyService] Cache cleared');
    } catch (e) {
      debugPrint('[CurrencyService] Error clearing cache: $e');
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    if (_initialized) {
      await _cacheBox.close();
      _initialized = false;
      debugPrint('[CurrencyService] Disposed');
    }
  }
}
