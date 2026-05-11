import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:neopay_ai/core/services/currency_service.dart';
import 'package:neopay_ai/core/services/exchange_rate_model.dart';

/// Provider for currency conversion and formatting
/// 
/// This provider manages exchange rates and provides methods for:
/// - Converting between currencies
/// - Formatting currency values for display
/// - Tracking loading and error states
/// 
/// Usage in widgets:
/// ```dart
/// final currencyProvider = context.watch<CurrencyProvider>();
/// final convertedAmount = currencyProvider.convert(100, 'USD', 'IDR');
/// final formatted = currencyProvider.formatCurrency(convertedAmount, 'IDR');
/// ```
class CurrencyProvider extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService.instance;

  ExchangeRateModel _rates = ExchangeRateModel.empty();
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  DateTime? _lastFetchedAt;

  // Getters
  ExchangeRateModel get rates => _rates;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  DateTime? get lastFetchedAt => _lastFetchedAt;
  
  /// Check if rates are available
  bool get hasRates => _rates.rates.isNotEmpty;

  /// Initialize the provider and fetch rates
  /// Call this on app startup
  Future<void> init() async {
    try {
      await _currencyService.init();
      await fetchRates();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Check if rates are stale (> 12 hours old) and refresh if needed
  /// Call this when app resumes from background
  Future<void> refreshIfStale() async {
    if (_lastFetchedAt == null) {
      await fetchRates();
      return;
    }
    final age = DateTime.now().difference(_lastFetchedAt!);
    if (age > const Duration(hours: 12)) {
      debugPrint('[CurrencyProvider] Rates stale (${age.inHours}h), refreshing...');
      await fetchRates(forceRefresh: true);
    }
  }

  /// Fetch latest exchange rates from the service
  /// This is called automatically on init, but can be called manually to refresh
  Future<void> fetchRates({bool forceRefresh = false}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _rates = await _currencyService.fetchLatestRates(forceRefresh: forceRefresh);
      _lastFetchedAt = DateTime.now();
      _isLoading = false;
      debugPrint('[CurrencyProvider] Rates updated: ${_rates.rates.length} currencies');
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Convert amount from one currency to another
  /// 
  /// Returns the converted amount, or the original amount if conversion is not possible
  /// 
  /// Example:
  /// ```dart
  /// // Convert 100 USD to IDR
  /// final result = provider.convert(100, 'USD', 'IDR');
  /// // result would be approximately 1,550,000 (if rate is 15500)
  /// ```
  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    if (amount == 0) return 0;

    final rate = _rates.getRate(from, to);
    if (rate == null) {
      debugPrint('[CurrencyProvider] No rate available for $from -> $to');
      return amount; // Return original amount if no rate
    }

    return amount * rate;
  }

  /// Get the exchange rate between two currencies
  /// Returns null if rate is not available
  double? getRate(String from, String to) {
    if (from == to) return 1.0;
    return _rates.getRate(from, to);
  }

  /// Format a currency value for display
  /// 
  /// Uses the intl package for proper locale-aware formatting
  /// 
  /// Example:
  /// ```dart
  /// provider.formatCurrency(1500000, 'IDR') // Returns "Rp 1.500.000"
  /// provider.formatCurrency(99.99, 'USD')   // Returns "$99.99"
  /// ```
  String formatCurrency(double value, String currencyCode, {int? decimalDigits}) {
    final symbol = SupportedCurrencies.getSymbol(currencyCode);
    
    // Determine decimal digits based on currency if not specified
    final digits = decimalDigits ?? _getDefaultDecimalDigits(currencyCode);
    
    try {
      final format = NumberFormat.currency(
        symbol: symbol,
        decimalDigits: digits,
        locale: _getLocaleForCurrency(currencyCode),
      );
      return format.format(value);
    } catch (e) {
      // Fallback to simple formatting
      return '$symbol${value.toStringAsFixed(digits)}';
    }
  }

  /// Format with custom pattern
  /// 
  /// Example:
  /// ```dart
  /// provider.formatCurrencyCustom(1500000, 'IDR', '#,##0.00')
  /// ```
  String formatCurrencyCustom(double value, String currencyCode, String pattern) {
    final symbol = SupportedCurrencies.getSymbol(currencyCode);
    try {
      final format = NumberFormat(pattern, _getLocaleForCurrency(currencyCode));
      return '$symbol${format.format(value)}';
    } catch (e) {
      return '$symbol$value';
    }
  }

  /// Get a short formatted version (e.g., "1.5M" for millions)
  String formatCurrencyShort(double value, String currencyCode) {
    final symbol = SupportedCurrencies.getSymbol(currencyCode);
    
    if (value >= 1000000000) {
      return '$symbol${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}K';
    }
    
    return formatCurrency(value, currencyCode);
  }

  /// Get exchange rate as a formatted string
  String formatRate(String from, String to) {
    if (from == to) return '1.00';
    
    final rate = getRate(from, to);
    if (rate == null) return 'N/A';
    
    if (rate >= 1000) {
      return '1 $from = ${rate.toStringAsFixed(2)} $to';
    } else if (rate >= 1) {
      return '1 $from = ${rate.toStringAsFixed(4)} $to';
    } else {
      return '1 $from = ${rate.toStringAsFixed(6)} $to';
    }
  }

  /// Get all supported currencies
  List<String> getSupportedCurrencies() {
    return _rates.rates.keys.toList();
  }

  /// Check if a currency is supported
  bool isCurrencySupported(String currencyCode) {
    return _rates.rates.containsKey(currencyCode);
  }

  /// Refresh rates silently (without changing loading state)
  /// Useful for background updates
  Future<void> refreshSilently() async {
    try {
      _rates = await _currencyService.fetchLatestRates(forceRefresh: true);
      _lastFetchedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      // Silently fail for background refresh
      debugPrint('[CurrencyProvider] Silent refresh failed: $e');
    }
  }

  /// Clear cached rates and reset state
  Future<void> clearCache() async {
    await _currencyService.clearCache();
    _rates = ExchangeRateModel.empty();
    _lastFetchedAt = null;
    notifyListeners();
  }

  void _setError(String error) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = error;
    debugPrint('[CurrencyProvider] Error: $error');
    notifyListeners();
  }

  /// Get default decimal digits for a currency
  int _getDefaultDecimalDigits(String currencyCode) {
    // Currencies with 0 decimal places (typically high-value currencies)
    const zeroDecimalCurrencies = ['IDR', 'JPY', 'KRW', 'VND', 'LAK', 'KHR'];
    
    if (zeroDecimalCurrencies.contains(currencyCode)) {
      return 0;
    }
    
    // Most currencies use 2 decimal places
    return 2;
  }

  /// Get locale for currency formatting
  String _getLocaleForCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'USD': return 'en_US';
      case 'EUR': return 'de_DE';
      case 'GBP': return 'en_GB';
      case 'JPY': return 'ja_JP';
      case 'IDR': return 'id_ID';
      case 'CNY': return 'zh_CN';
      case 'SGD': return 'en_SG';
      case 'MYR': return 'ms_MY';
      case 'AUD': return 'en_AU';
      case 'CAD': return 'en_CA';
      case 'CHF': return 'de_CH';
      case 'HKD': return 'zh_HK';
      case 'NZD': return 'en_NZ';
      case 'SEK': return 'sv_SE';
      case 'KRW': return 'ko_KR';
      case 'TRY': return 'tr_TR';
      case 'INR': return 'en_IN';
      case 'RUB': return 'ru_RU';
      case 'BRL': return 'pt_BR';
      case 'ZAR': return 'en_ZA';
      default: return 'en_US';
    }
  }

  @override
  void dispose() {
    // Don't dispose CurrencyService here as it's a singleton
    super.dispose();
  }
}