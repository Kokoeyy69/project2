/// Data model for storing exchange rates with timestamp
/// Used for caching and in-memory rate storage
class ExchangeRateModel {
  /// Map of currency code to exchange rate (relative to USD)
  final Map<String, double> rates;

  /// Timestamp when these rates were fetched
  final DateTime timestamp;

  /// Base currency for these rates
  final String baseCurrency;

  const ExchangeRateModel({
    required this.rates,
    required this.timestamp,
    this.baseCurrency = 'USD',
  });

  /// Create from JSON map (for Hive/storage serialization)
  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    final ratesJson = json['rates'] as Map<String, dynamic>;
    final rates = ratesJson.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ExchangeRateModel(
      rates: rates,
      timestamp: DateTime.parse(json['timestamp'] as String),
      baseCurrency: json['baseCurrency'] as String? ?? 'USD',
    );
  }

  /// Convert to JSON map (for Hive/storage serialization)
  Map<String, dynamic> toJson() {
    return {
      'rates': rates,
      'timestamp': timestamp.toIso8601String(),
      'baseCurrency': baseCurrency,
    };
  }

  /// Check if these rates are stale (older than specified duration)
  bool isStale({Duration maxAge = const Duration(hours: 12)}) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  /// Get exchange rate from one currency to another
  /// Returns null if either currency is not supported
  double? getRate(String from, String to) {
    if (from == to) return 1.0;

    final fromRate = rates[from];
    final toRate = rates[to];

    if (fromRate == null || toRate == null) return null;

    // Convert: from -> USD -> to
    return toRate / fromRate;
  }

  /// Create empty model
  static ExchangeRateModel empty() {
    return ExchangeRateModel(rates: {}, timestamp: DateTime(2000));
  }
}

/// Supported currencies for the app
class SupportedCurrencies {
  static const String IDR = 'IDR';
  static const String USD = 'USD';
  static const String CNY = 'CNY';
  static const String EUR = 'EUR';
  static const String GBP = 'GBP';
  static const String JPY = 'JPY';
  static const String SGD = 'SGD';
  static const String MYR = 'MYR';
  static const String AUD = 'AUD';
  static const String CAD = 'CAD';
  static const String CHF = 'CHF';
  static const String HKD = 'HKD';
  static const String NZD = 'NZD';
  static const String SEK = 'SEK';
  static const String KRW = 'KRW';
  static const String TRY = 'TRY';
  static const String INR = 'INR';
  static const String RUB = 'RUB';
  static const String BRL = 'BRL';
  static const String ZAR = 'ZAR';

  /// List of primary currencies supported by the app
  static const List<String> primary = [IDR, USD, CNY];

  /// List of all supported currencies
  static const List<String> all = [
    IDR,
    USD,
    CNY,
    EUR,
    GBP,
    JPY,
    SGD,
    MYR,
    AUD,
    CAD,
    CHF,
    HKD,
    NZD,
    SEK,
    KRW,
    TRY,
    INR,
    RUB,
    BRL,
    ZAR,
  ];

  /// Get currency symbol for display
  static String getSymbol(String currencyCode) {
    switch (currencyCode) {
      case USD:
        return '\$';
      case EUR:
        return '€';
      case GBP:
        return '£';
      case JPY:
        return '¥';
      case IDR:
        return 'Rp';
      case CNY:
        return '¥';
      case SGD:
        return 'S\$';
      case MYR:
        return 'RM';
      case INR:
        return '₹';
      case KRW:
        return '₩';
      case BRL:
        return 'R\$';
      case ZAR:
        return 'R';
      case TRY:
        return '₺';
      case RUB:
        return '₽';
      default:
        return currencyCode;
    }
  }

  /// Get currency name for display
  static String getName(String currencyCode) {
    switch (currencyCode) {
      case USD:
        return 'US Dollar';
      case EUR:
        return 'Euro';
      case GBP:
        return 'British Pound';
      case JPY:
        return 'Japanese Yen';
      case IDR:
        return 'Indonesian Rupiah';
      case CNY:
        return 'Chinese Yuan';
      case SGD:
        return 'Singapore Dollar';
      case MYR:
        return 'Malaysian Ringgit';
      case AUD:
        return 'Australian Dollar';
      case CAD:
        return 'Canadian Dollar';
      case CHF:
        return 'Swiss Franc';
      case HKD:
        return 'Hong Kong Dollar';
      case NZD:
        return 'New Zealand Dollar';
      case SEK:
        return 'Swedish Krona';
      case KRW:
        return 'South Korean Won';
      case TRY:
        return 'Turkish Lira';
      case INR:
        return 'Indian Rupee';
      case RUB:
        return 'Russian Ruble';
      case BRL:
        return 'Brazilian Real';
      case ZAR:
        return 'South African Rand';
      default:
        return currencyCode;
    }
  }

  /// Get flag emoji for currency
  static String getFlagEmoji(String currencyCode) {
    switch (currencyCode) {
      case USD:
        return '🇺🇸';
      case EUR:
        return '🇪🇺';
      case GBP:
        return '🇬🇧';
      case JPY:
        return '🇯🇵';
      case IDR:
        return '🇮🇩';
      case CNY:
        return '🇨🇳';
      case SGD:
        return '🇸🇬';
      case MYR:
        return '🇲🇾';
      case AUD:
        return '🇦🇺';
      case CAD:
        return '🇨🇦';
      case CHF:
        return '🇨🇭';
      case HKD:
        return '🇭🇰';
      case NZD:
        return '🇳🇿';
      case SEK:
        return '🇸🇪';
      case KRW:
        return '🇰🇷';
      case TRY:
        return '🇹🇷';
      case INR:
        return '🇮🇳';
      case RUB:
        return '🇷🇺';
      case BRL:
        return '🇧🇷';
      case ZAR:
        return '🇿🇦';
      default:
        return '💱';
    }
  }
}
