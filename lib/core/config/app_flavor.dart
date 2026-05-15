import 'package:flutter/foundation.dart';
import 'env.dart';

/// Represents the current application flavor/environment
enum Flavor { dev, staging, prod }

/// Application flavor configuration
///
/// This class provides environment-specific configuration for the app.
/// Use [FlavorHelper.current] to get the current flavor configuration.
class FlavorHelper {
  static Flavor? _flavor;
  static String? _name;

  /// Set the current flavor (call from main entry point)
  static void setup({required Flavor flavor, String? name}) {
    _flavor = flavor;
    _name = name ?? flavor.name;
  }

  /// Get the current flavor
  static Flavor get current => _flavor ?? Flavor.dev;

  /// Get the current flavor name
  static String get name => _name ?? 'dev';

  /// Check if running in development mode
  static bool get isDev => current == Flavor.dev;

  /// Check if running in staging mode
  static bool get isStaging => current == Flavor.staging;

  /// Check if running in production mode
  static bool get isProd => current == Flavor.prod;

  /// Get flavor-specific configuration
  static FlavorConfig get config {
    switch (current) {
      case Flavor.dev:
        return FlavorConfig(
          flavor: Flavor.dev,
          appName: 'NeoPay AI (Dev)',
          apiBaseUrl: Env.apiBaseUrl,
          enableDebugLogging: true,
          enableAnalytics: false,
          enableCrashlytics: false,
        );
      case Flavor.staging:
        return FlavorConfig(
          flavor: Flavor.staging,
          appName: 'NeoPay AI (Staging)',
          apiBaseUrl: Env.apiBaseUrl,
          enableDebugLogging: true,
          enableAnalytics: true,
          enableCrashlytics: false,
        );
      case Flavor.prod:
        return FlavorConfig(
          flavor: Flavor.prod,
          appName: 'NeoPay AI',
          apiBaseUrl: Env.apiBaseUrl,
          enableDebugLogging: false,
          enableAnalytics: true,
          enableCrashlytics: true,
        );
    }
  }

  /// Print current flavor info (for debugging)
  static void printFlavorInfo() {
    final config = FlavorHelper.config;
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║  NeoPay AI - Flavor Configuration        ║');
    debugPrint('╠══════════════════════════════════════════╣');
    debugPrint('║  Flavor: ${config.flavor.name.padRight(32)}║');
    debugPrint('║  App Name: ${config.appName.padRight(29)}║');
    debugPrint('║  API Base: ${config.apiBaseUrl.padRight(28)}║');
    debugPrint(
      '║  Debug: ${config.enableDebugLogging.toString().padRight(32)}║',
    );
    debugPrint('╚══════════════════════════════════════════╝');
  }
}

/// Flavor-specific configuration values
class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;
  final bool enableDebugLogging;
  final bool enableAnalytics;
  final bool enableCrashlytics;

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.enableDebugLogging,
    required this.enableAnalytics,
    required this.enableCrashlytics,
  });
}
