import 'package:envied/envied.dart';

part 'env.g.dart';

// force rebuild v2 - ensure build_runner detects changes

/// Environment configuration with obfuscated API keys
///
/// This class provides secure access to environment variables.
/// Keys are obfuscated at compile time to prevent easy reverse engineering.
///
/// Usage:
/// ```dart
/// final geminiKey = Env.geminiApiKey;
/// final exchangeRateKey = Env.exchangeRateApiKey;
/// ```
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  /// Gemini AI API Key for Google Generative AI
  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true)
  static final String geminiApiKey = _Env.geminiApiKey;

  /// Exchange Rate API Key for currency conversion
  @EnviedField(varName: 'EXCHANGE_RATE_API_KEY', obfuscate: true)
  static final String exchangeRateApiKey = _Env.exchangeRateApiKey;

  /// Current flavor name (dev, staging, prod)
  @EnviedField(varName: 'FLAVOR_NAME', obfuscate: false)
  static const String flavorName = _Env.flavorName;

  /// Base URL for the NeoPay API
  @EnviedField(varName: 'API_BASE_URL', obfuscate: false)
  static const String apiBaseUrl = _Env.apiBaseUrl;

  /// API Key for NeoPay backend authentication
  @EnviedField(varName: 'NEOPAY_API_KEY', obfuscate: true)
  static final String neopayApiKey = _Env.neopayApiKey;
}
